# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

class ProtectedArtifactSetTest < AceRuntimeTestCase
  Set = Ace::Runtime::Molecules::ProtectedArtifactSet
  Unavailable = Ace::Runtime::RuntimeUnavailableError
  Stat = Struct.new(:uid, :mode, :kind) do
    def file? = kind == :file
    def directory? = kind == :directory
  end
  Handle = Struct.new(:stat)

  def test_supported_local_posix_mounts_and_readonly_modes_are_authenticated
    Set::Protection::FILESYSTEMS.each do |filesystem|
      mounts = Minitest::Mock.new
      handle = Handle.new(Stat.new(0, 0o100640, :file))
      mounts.expect(:mount_identity, {"filesystem_type" => filesystem}, [handle])
      Set::Protection.new(mounts: mounts).verify!("/evidence/artifact", handle, directory: false)
      mounts.verify
    end
  end

  def test_unknown_and_non_posix_filesystem_models_refuse
    %w[nfs fuse overlay proc unknown].each do |filesystem|
      mounts = Minitest::Mock.new
      handle = Handle.new(Stat.new(0, 0o100644, :file))
      mounts.expect(:mount_identity, {"filesystem_type" => filesystem}, [handle])
      assert_raises(Unavailable) { Set::Protection.new(mounts: mounts).verify!("/evidence/artifact", handle, directory: false) }
      mounts.verify
    end
  end

  def test_wrong_owner_write_mask_and_wrong_kind_refuse_before_mount_lookup
    [Stat.new(1001, 0o100644, :file), Stat.new(0, 0o100664, :file), Stat.new(0, 0o100646, :file),
      Stat.new(0, 0o040755, :directory)].each do |stat|
      mounts = Minitest::Mock.new
      assert_raises(Unavailable) do
        Set::Protection.new(mounts: mounts).verify!("/evidence/artifact", Handle.new(stat), directory: false)
      end
      mounts.verify
    end
  end

  def test_directory_uses_same_posix_mask_and_requires_directory_type
    mounts = Minitest::Mock.new
    handle = Handle.new(Stat.new(0, 0o040750, :directory))
    mounts.expect(:mount_identity, {"filesystem_type" => "ext4"}, [handle])
    Set::Protection.new(mounts: mounts).verify!("/evidence", handle, directory: true)
    mounts.verify
    assert_raises(Unavailable) do
      Set::Protection.new(mounts: mounts).verify!("/evidence", Handle.new(Stat.new(0, 0o100644, :file)), directory: true)
    end
  end

  class ControlledProtection
    def root_path!(_path); end
    def verify!(_path, _handle, directory:); end
  end

  def with_artifacts
    Dir.mktmpdir("protected-artifact-budgets") do |directory|
      yield File.realpath(directory)
    end
  end

  def reference(path)
    bytes = File.binread(path)
    {"path" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
  end

  def test_default_budgets_still_refuse_artifacts_above_one_mib
    with_artifacts do |directory|
      path = File.join(directory, "large")
      File.binwrite(path, "x" * (Set::LIMIT + 1))
      Set.new(protection: ControlledProtection.new).with do |set|
        assert_raises(Unavailable) { set.read!(reference(path)) }
        assert_raises(Unavailable) { set.read_path!(path) }
        assert_raises(ArgumentError) { set.read_path!(path, limit: Set::LIMIT + 1) }
      end
    end
  end

  def test_trusted_custom_file_budget_reads_exact_bound_and_preserves_references
    with_artifacts do |directory|
      path = File.join(directory, "binary")
      bytes = "x" * (Set::LIMIT + 1)
      File.binwrite(path, bytes)
      Set.new(protection: ControlledProtection.new, file_limit: bytes.bytesize, total_limit: bytes.bytesize).with do |set|
        observed, selected = set.read_path!(path)
        assert_equal bytes, observed
        assert_equal reference(path), selected
        assert_same observed, set.read!(selected)
        assert set.verify_unchanged!
      end
    end
  end

  def test_custom_total_budget_cannot_be_exceeded_by_multiple_files
    with_artifacts do |directory|
      first, second = %w[first second].map { |name| File.join(directory, name) }
      File.write(first, "12345")
      File.write(second, "67890")
      Set.new(protection: ControlledProtection.new, file_limit: 5, total_limit: 9).with do |set|
        assert_equal "12345", set.read!(reference(first))
        assert_raises(Unavailable) { set.read!(reference(second)) }
        assert_raises(Unavailable) { set.read_path!(second) }
        assert_equal "12345", set.read_path!(first).first
      end
    end
  end

  def test_custom_file_budget_and_per_read_limit_remain_bounded
    with_artifacts do |directory|
      path = File.join(directory, "large")
      File.write(path, "123456")
      Set.new(protection: ControlledProtection.new, file_limit: 5, total_limit: 10).with do |set|
        assert_raises(Unavailable) { set.read!(reference(path)) }
        assert_raises(Unavailable) { set.read_path!(path) }
        assert_raises(ArgumentError) { set.read_path!(path, limit: 6) }
      end
    end
  end

  def test_invalid_trusted_budget_types_or_order_refuse_at_construction
    [[0, 1], [-1, 10], [1.0, 10], [1, 10.0], [1, 0], [1, -10], [10, 5],
      [nil, 10], [1, nil], [true, 10]].each do |file, total|
      assert_raises(ArgumentError) { Set.new(protection: ControlledProtection.new, file_limit: file, total_limit: total) }
    end
  end

  def test_default_count_refuses_257th_unique_artifact_but_trusted_budget_accepts_it
    with_artifacts do |directory|
      paths = Array.new(Set::COUNT_LIMIT + 1) do |index|
        path = File.join(directory, index.to_s)
        File.write(path, "x")
        path
      end
      Set.new(protection: ControlledProtection.new).with do |set|
        paths.first(Set::COUNT_LIMIT).each { |path| set.read_path!(path) }
        assert_raises(Unavailable) { set.read_path!(paths.last) }
        assert_raises(Unavailable) { set.read!(reference(paths.last)) }
        assert_equal "x", set.read!(reference(paths.first))
      end
      Set.new(protection: ControlledProtection.new, count_limit: paths.size).with do |set|
        paths.each { |path| set.read!(reference(path)) }
        assert_equal "x", set.read_path!(paths.last).first
        assert set.verify_unchanged!
      end
    end
  end

  def test_custom_count_is_shared_by_both_read_paths_and_repeated_reads_do_not_spend_it
    with_artifacts do |directory|
      first, second, third = %w[first second third].map do |name|
        path = File.join(directory, name)
        File.write(path, name)
        path
      end
      Set.new(protection: ControlledProtection.new, count_limit: 2).with do |set|
        bytes, selected = set.read_path!(first)
        assert_same bytes, set.read!(selected)
        assert_equal "second", set.read!(reference(second))
        assert_raises(Unavailable) { set.read!(reference(third)) }
        assert_raises(Unavailable) { set.read_path!(third) }
        assert_equal "second", set.read_path!(second).first
        assert set.verify_unchanged!
      end
    end
  end

  def test_invalid_trusted_count_budgets_refuse_at_construction
    [nil, false, true, 0, -1, 1.0, "2"].each do |count|
      assert_raises(ArgumentError) { Set.new(protection: ControlledProtection.new, count_limit: count) }
    end
  end

end
