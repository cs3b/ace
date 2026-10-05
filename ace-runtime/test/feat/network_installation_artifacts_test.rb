# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"
require_relative "../support/network_installation_fixture"

class NetworkInstallationArtifactsTest < AceRuntimeTestCase
  Set = Ace::Runtime::Molecules::ProtectedArtifactSet
  Evidence = Ace::Runtime::Molecules::NetworkInstallationEvidence
  Unavailable = Ace::Runtime::RuntimeUnavailableError

  # SOURCE fixture boundary: files are owned by this test process. Ancestors
  # above the private disposable root and mount type are synthetic trust inputs.
  # File reads, NOFOLLOW, descriptor identity, modes and byte/digest checks are real.
  class FixtureProtection < Set::Protection
    attr_reader :checked
    def initialize(root)
      @root, @checked = root, []
      mounts = Object.new
      def mounts.mount_identity(_handle) = {"filesystem_type" => "ext4"}
      super(mounts: mounts)
    end
    def root_path!(_path); end
    def verify!(path, handle, directory:)
      @checked << [path, handle]
      super if path == @root || path.start_with?(@root + "/")
    end
    private
    def trusted_owner?(stat) = stat.uid == Process.uid
  end

  def setup
    @root = File.realpath(Dir.mktmpdir("network-evidence-source-"))
    File.chmod(0o700, @root)
    @protection = FixtureProtection.new(@root)
    @reader = Set.new(protection: @protection)
  end

  def teardown
    FileUtils.remove_entry(@root) if File.exist?(@root)
  end

  def artifact(name, bytes)
    path = File.join(@root, name)
    File.binwrite(path, bytes)
    File.chmod(0o600, path)
    {"path" => path, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
  end

  def test_actual_content_descriptors_are_held_until_complete_validation_and_closed_afterwards
    ref = artifact("evidence", "protected source content")
    @reader.with do
      assert_equal "protected source content", @reader.read!(ref)
      held = @protection.checked.map(&:last)
      assert held.all? { |handle| !handle.closed? }
      assert_equal "protected source content", @reader.read!(ref.dup)
      assert @reader.verify_unchanged!
    end
    assert @protection.checked.all? { |_path, handle| handle.closed? }
  end

  def test_read_length_digest_kind_symlink_and_writable_modes_refuse
    ref = artifact("evidence", "protected source content")
    [ref.merge("bytes" => 1), ref.merge("sha256" => "a" * 64), ref.merge("bytes" => Set::LIMIT + 1)].each do |bad|
      assert_raises(Unavailable) { @reader.with { @reader.read!(bad) } }
    end
    File.chmod(0o622, ref.fetch("path"))
    assert_raises(Unavailable) { @reader.with { @reader.read!(ref) } }
    File.chmod(0o600, ref.fetch("path"))
    File.symlink(ref.fetch("path"), File.join(@root, "linked"))
    assert_raises(Unavailable) { @reader.with { @reader.read!(ref.merge("path" => File.join(@root, "linked"))) } }
    assert_raises(Unavailable) { @reader.with { @reader.read!(ref.merge("path" => @root)) } }
    File.mkfifo(File.join(@root, "fifo"), 0o600)
    assert_raises(Unavailable) { @reader.with { @reader.read!(ref.merge("path" => File.join(@root, "fifo"))) } }
  end

  def test_writable_or_symlink_ancestor_refuses
    FileUtils.mkdir_p(File.join(@root, "nested"))
    ref = artifact("nested/evidence", "source content")
    File.chmod(0o777, File.join(@root, "nested"))
    assert_raises(Unavailable) { @reader.with { @reader.read!(ref) } }
    File.chmod(0o700, File.join(@root, "nested"))
    File.symlink(File.join(@root, "nested"), File.join(@root, "alias"))
    assert_raises(Unavailable) { @reader.with { @reader.read!(ref.merge("path" => File.join(@root, "alias/evidence"))) } }
  end

  def test_path_replacement_and_content_or_ancestor_mutation_refuse_while_pinned
    ref = artifact("evidence", "source content")
    assert_raises(Unavailable) do
      @reader.with do
        @reader.read!(ref)
        File.rename(ref.fetch("path"), File.join(@root, "original"))
        artifact("evidence", "source content")
        @reader.verify_unchanged!
      end
    end
    assert @protection.checked.all? { |_path, handle| handle.closed? }
    ref = artifact("second", "source content")
    assert_raises(Unavailable) do
      @reader.with do
        @reader.read!(ref)
        File.chmod(0o666, ref.fetch("path"))
        @reader.verify_unchanged!
      end
    end
    ref = artifact("third", "source content")
    assert_raises(Unavailable) do
      @reader.with do
        @reader.read!(ref)
        File.chmod(0o777, @root)
        @reader.verify_unchanged!
      end
    end
  end

  def test_unique_graph_count_and_aggregate_bytes_limits_and_consistent_sharing
    ref = artifact("evidence", "s" * Set::LIMIT)
    @reader.with do
      20.times { assert_equal Set::LIMIT, @reader.read!(ref.dup).bytesize }
      assert @reader.verify_unchanged!
    end
    refs = Array.new(17) { |index| artifact("large-#{index}", "s" * Set::LIMIT) }
    assert_raises(Unavailable) { @reader.with { refs.each { |item| @reader.read!(item) } } }
    refs = Array.new(257) { |index| artifact("small-#{index}", "s") }
    assert_raises(Unavailable) { @reader.with { refs.each { |item| @reader.read!(item) } } }
    assert_raises(Unavailable) do
      @reader.with do
        @reader.read!(ref)
        @reader.read!(ref.merge("sha256" => "a" * 64))
      end
    end
  end
  def test_eof_after_size_inspection_is_a_typed_content_refusal_and_closes_handles
    ref = artifact("eof", "source content")
    original = @protection.method(:verify!)
    @protection.stub(:verify!, lambda { |path, handle, directory:|
      original.call(path, handle, directory: directory)
      if path == ref.fetch("path")
        # Deterministic fault at the actual held IO read, after regular-file
        # pinning/size inspection. A truncation can produce nil at this seam.
        def handle.read(_length) = nil
      end
    }) do
      assert_raises(Unavailable) { @reader.with { @reader.read!(ref) } }
    end
    assert @protection.checked.all? { |_path, handle| handle.closed? }
  end

  class DiskFixture < NetworkInstallationFixture
    def initialize(root)
      super()
      @root = root
    end

    def store(path, bytes)
      target = File.join(@root, File.basename(path))
      File.binwrite(target, bytes)
      File.chmod(0o600, target)
      super(target, bytes)
    end
  end

  def test_complete_closed_verifier_uses_real_graph_bytes_and_holds_all_source_artifacts
    fixture = DiskFixture.new(@root)
    selection = fixture.build
    result = Evidence.new(artifacts: @reader).verify!(selection: selection, expected: fixture.expected)
    assert_equal selection.fetch("report").fetch("sha256"), result.fetch("report_sha256")
    assert_equal fixture.expected.fetch("namespace_identity"), result.fetch("namespace_identity")
    assert @protection.checked.all? { |_path, handle| handle.closed? }
    assert_equal fixture.files.keys.sort,
      @protection.checked.map(&:first).select { |path| fixture.files.key?(path) }.uniq.sort
    File.binwrite(File.join(@root, "raw"), "tampered observation content")
    assert_raises(Unavailable) do
      Evidence.new(artifacts: @reader).verify!(selection: selection, expected: fixture.expected)
    end
  end

end
