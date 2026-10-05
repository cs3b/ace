# frozen_string_literal: true

require_relative "../test_helper"

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
end
