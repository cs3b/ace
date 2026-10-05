# frozen_string_literal: true

require_relative "../test_helper"
require "ace/runtime/molecules/linux_mount_info"

class LinuxMountInfoTest < AceRuntimeTestCase
  MountInfo = Ace::Runtime::Molecules::LinuxMountInfo

  def test_bound_nsfs_roots_are_typed_namespace_objects_not_storage_paths
    table = MountInfo.new("40 1 0:4 net:[4026533001] /run/netns/slot rw - nsfs nsfs rw\n")
    assert_equal "nsfs", table.by_id(40).fetch("filesystem_type")
    assert_equal "net:[4026533001]", table.by_id(40).fetch("root")
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { table.filesystem_path(table.by_id(40), "/run/netns/slot") }
    ["net:[0]", "net:[1]/escape", "unknown:[1]", "relative"].each do |root|
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { MountInfo.new("40 1 0:4 #{root} /run/netns/slot rw - nsfs nsfs rw\n") }
    end
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { MountInfo.new("40 1 0:4 net:[1] /run/netns/slot rw - ext4 /dev/sda1 rw\n") }
  end

  Unavailable = Ace::Runtime::RuntimeUnavailableError

  def table
    "20 1 8:1 / / ro,nosuid - ext4 /dev/vda1 rw\n" \
      "21 20 8:1 /slots/a\\040b /scratch rw,nosuid,nodev shared:7 - ext4 /dev/vda1 rw\n" \
      "22 20 8:1 /readonly /scratch ro,nosuid,nodev - ext4 /dev/vda1 rw\n"
  end

  def test_descriptor_mount_id_selects_exact_bind_object_despite_same_path
    mounts = MountInfo.new(table)
    mutable = mounts.by_id(21)
    assert_equal "/slots/a b", mutable.fetch("root")
    assert_equal %w[rw nosuid nodev], mutable.fetch("options")
    assert_equal "/slots/a b/file", mounts.filesystem_path(mutable, "/scratch/file")
    assert_equal "/readonly/file", mounts.filesystem_path(mounts.by_id(22), "/scratch/file")
    assert_equal "/etc/config", mounts.filesystem_path(mounts.by_id(20), "/etc/config")
    assert_raises(Unavailable) { mounts.by_id(99) }
    assert_raises(Unavailable) { mounts.filesystem_path(mutable, "/scratch-other/file") }
  end

  def test_kernel_escapes_preserve_literal_backslashes_and_whitespace
    mounts = MountInfo.new("20 1 8:1 /a\\134b\\011c\\012d / ro - ext4 none rw\n")
    assert_equal "/a\\b\tc\nd", mounts.by_id(20).fetch("root")
  end

  def test_missing_duplicate_malformed_or_unresolved_mount_data_refuses
    ["", nil, "x" * (MountInfo::LIMIT + 1), table + table.lines.first,
     table.sub("8:1", "unknown"), table.sub("shared:7", "shared:bad"),
     table.sub("/slots/a\\040b") { "/slots/a\\999b" }, table.sub("ro,nosuid", "ro,,nosuid"),
     table.sub(" / / ", " /../wrong / "), table.sub(" - ext4 ", " ext4 ")].each do |bytes|
      assert_raises(Unavailable, bytes.inspect) { MountInfo.new(bytes) }
    end
  end
end
