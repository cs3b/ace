# frozen_string_literal: true
require_relative "../test_helper"
require "ace/runtime/molecules/kernel_view_topology"

class KernelViewTopologyTest < AceRuntimeTestCase
  Verifier = Ace::Runtime::Molecules::KernelViewTopology
  def setup
    paths = ["/"] + Verifier::VIEWS + ["/scratch"]
    text = paths.each_with_index.map do |path, index|
      filesystem = Verifier::APIS.fetch(path, path == "/dev" ? "tmpfs" : "ext4")
      flags = Verifier::APIS.key?(path) || path == "/scratch" ? "rw" : "ro"
      root = path == "/scratch" ? "/private/scratch" : "/"
      "#{index + 1} 0 8:1 #{root} #{path} #{flags} - #{filesystem} fixture #{flags}\n"
    end.join
    mounts = Ace::Runtime::Molecules::LinuxMountInfo.new(text).records.map { |row| row.slice(*Ace::Runtime::Molecules::ServerResourceObservation::MOUNT_FIELDS) }
    views = Verifier::VIEWS.map { |path| {"path" => path, "mount_id" => mounts.find { |row| row["mountpoint"] == path }.fetch("mount_id"),
      "device" => 8, "inode" => paths.index(path) + 100, "type" => "directory"} }
    @topology = {"ipc_namespace_identity" => {"device" => 4, "inode" => 20}, "hook_ipc_namespace_identity" => {"device" => 4, "inode" => 20},
      "mounts" => mounts, "views" => views, "authority_socket_identity" => [8, 90, 13000]}
    @writable = [{"view_path" => "/scratch", "major_minor" => "8:1", "filesystem_path" => "/private/scratch", "filesystem_type" => "ext4"}]
  end
  def verify(topology = @topology, writable = @writable)
    Verifier.new.verify!(topology: topology, host_ipc: {"device" => 4, "inode" => 10}, authority_socket: [8, 90, 13000], writable_resources: writable)
  end
  def changed
    Marshal.load(Marshal.dump(@topology))
  end
  def test_fixed_live_api_and_exact_original_writable_backing_accept
    assert verify
    topology = changed
    row = topology.fetch("mounts").find { |mount| mount["mountpoint"] == "/tmp" }
    row["options"] = ["rw"]
    row["root"] = "/private/tmp"
    writable = @writable + [{"view_path" => "/tmp", "major_minor" => "8:1", "filesystem_path" => "/private/tmp", "filesystem_type" => "ext4"}]
    assert verify(topology, writable)
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { verify(topology) }
  end
  def test_host_shared_or_different_hook_ipc_and_socket_substitution_refuse
    ["ipc_namespace_identity", "hook_ipc_namespace_identity"].each do |field|
      topology = changed
      topology[field] = {"device" => 4, "inode" => 10}
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { verify(topology) }
    end
    topology = changed
    topology["authority_socket_identity"] = [8, 91, 13000]
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { verify(topology) }
  end
  def test_missing_duplicate_non_directory_or_foreign_mount_views_refuse
    mutations = [->(t) { t["views"].pop }, ->(t) { t["views"][-1] = t["views"].first },
      ->(t) { t["views"].first["type"] = "socket" }, ->(t) { t["views"].first["mount_id"] = 999 },
      ->(t) { t["views"].first["mount_id"] = t["mounts"].last["mount_id"] }, ->(t) { t["views"].first["device"] = 8.0 }]
    mutations.each do |mutate|
      topology = changed
      mutate.call(topology)
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { verify(topology) }
    end
  end
  def test_writable_api_shadow_alias_unknown_mount_and_changed_backing_refuse
    Verifier::READONLY.each do |path|
      topology = changed
      topology["mounts"].find { |row| row["mountpoint"] == path }["options"] = ["rw"]
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { verify(topology) }
    end
    topology = changed
    topology["mounts"] << topology["mounts"].last.merge("mount_id" => 99, "mountpoint" => "/outside-alias")
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { verify(topology) }
    topology = changed
    topology["mounts"].last["root"] = "/foreign"
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { verify(topology) }
    topology = changed
    topology["mounts"] << topology["mounts"].find { |row| row["mountpoint"] == "/proc" }.merge("mount_id" => 99)
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { verify(topology) }
  end
  def test_closed_complete_mount_bounds_refuse
    [->(t) { t["mounts"].first["extra"] = true }, ->(t) { t["mounts"].first["mount_id"] = 1.0 },
      ->(t) { t["mounts"].shift }, ->(t) { t["mounts"].first["options"] = ["rw"] },
      ->(t) { t["mounts"] << t["mounts"].last.dup }, ->(t) { t["mounts"] = Array.new(257) { t["mounts"].first } }].each do |mutate|
      topology = changed
      mutate.call(topology)
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { verify(topology) }
    end
  end

  def test_declared_writable_api_descendants_never_gain_storage_authority
    %w[/sys/foreign /proc/storage /dev/shm/storage].each do |path|
      topology = changed
      row = topology["mounts"].last.merge("mount_id" => 99, "mountpoint" => path)
      topology["mounts"] << row
      declared = @writable + [{"view_path" => path, "major_minor" => "8:1", "filesystem_path" => row.fetch("root"), "filesystem_type" => "ext4"}]
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { verify(topology, declared) }
    end
  end
end
