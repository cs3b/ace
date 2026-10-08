# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/protected_workspace_fixture"
require "tmpdir"
require "ace/assign/molecules/protected_workspace_exclusion"

class ProtectedWorkspaceExclusionTest < AceAssignTestCase
  include Ace::Assign::ProtectedWorkspaceFixture

  def test_malformed_projection_refuses_before_opening_any_reader_object
    [nil, [], "projection", 1, {}].each do |projection|
      assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
        owner::WorkspaceReader.new(projection: projection, files: @files)
      end
    end
    assert_empty @files.opened
  end

  def setup
    super
    @root = Dir.mktmpdir("protected-workspace-reader")
    File.chmod(0o755, @root)
    stat = File.stat(@root)
    authority = {"uid" => stat.uid, "gid" => stat.gid, "state_root" => "/protected/authority"}
    cwd = {"host_path" => "/protected/workspace", "view_path" => "/workspace", "device" => 8,
      "inode" => 42, "mount_id" => 10, "filesystem_type" => "ext4", "uid" => 13001, "gid" => 13001}
    selection = owner.workspace_selection(mapping_id: "mapping", project_id: "project", authority: authority, cwd_resource: cwd)
    @projection = {"key" => selection.fetch("key"), "authority_uid" => stat.uid, "authority_gid" => stat.gid,
      "worker_cwd_resource" => cwd, "root_resource" => selection.slice("host_path", "view_path").merge(
        "device" => stat.dev, "inode" => stat.ino, "uid" => stat.uid, "gid" => stat.gid,
        "mount_id" => 10, "filesystem_type" => "ext4")}
    @view = selection.fetch("view_path")
    @files = Files.new(@root, @view)
    @mounts = Mounts.new(@view, selection.fetch("host_path"))
    @acl = ACL.new
    File.write(lock_path, "", mode: "w", perm: 0o644)
    File.write(marker_path, owner.workspace_initial_marker(key: @projection.fetch("key")), mode: "w", perm: 0o644)
    File.chmod(0o644, lock_path)
    File.chmod(0o644, marker_path)
  end

  def teardown
    @reader&.close!
    FileUtils.rm_rf(@root)
    super
  end

  def owner = Ace::Assign::Molecules::LifecycleExclusion
  def lock_path = File.join(@root, "#{Digest::SHA256.hexdigest(@projection.fetch('key'))}.lock")
  def marker_path = File.join(@root, "#{Digest::SHA256.hexdigest(@projection.fetch('key'))}.state.json")

  def reader
    protection = owner::WorkspaceReader::Protection.new(projection: @projection, mounts: @mounts, acl: @acl)
    @reader = owner.workspace_reader(projection: @projection, protection: protection, files: @files)
  end

  def test_original_readonly_reader_holds_same_inode_shared_exclusion_without_writes
    assert_same reader, @reader.acquire!
    assert @reader.verify_unchanged!
    File.open(lock_path, File::RDWR) do |writer|
      refute writer.flock(File::LOCK_EX | File::LOCK_NB)
      @reader.close!
      assert writer.flock(File::LOCK_EX | File::LOCK_NB)
    end
    assert @files.opened.all?(&:closed?)
    assert_includes @acl.attributes, "system.posix_acl_default"
  end

  def test_native_host_lease_has_no_provider_lifetime_deadline_and_holds_original_inode
    host = @projection.fetch("root_resource").fetch("host_path")
    files = WriterFiles.new(@root, @view, host)
    protection = owner::WorkspaceHostReader::Protection.new(projection: @projection, mounts: @mounts, acl: @acl)
    @reader = owner::WorkspaceNativeReader.new(projection: @projection, files: files, protection: protection)
    @reader.acquire!
    assert @reader.verify_unchanged!
    File.open(lock_path, File::RDWR) do |writer|
      refute writer.flock(File::LOCK_EX | File::LOCK_NB)
      assert_nil @reader.instance_variable_get(:@deadline)
      @reader.close!
      assert writer.flock(File::LOCK_EX | File::LOCK_NB)
    end
    assert files.opened.all?(&:closed?)
  end

  def test_close_error_still_releases_every_other_retained_descriptor
    reader.acquire!
    handle = @files.opened.last
    handle.define_singleton_method(:close) do
      __getobj__.close
      raise IOError, "controlled close failure"
    end
    assert_raises(IOError) { @reader.close! }
    assert @files.opened.all?(&:closed?)
    File.open(lock_path, File::RDWR) do |writer|
      assert writer.flock(File::LOCK_EX | File::LOCK_NB)
    end
  end

  def writer
    files = WriterFiles.new(@root, @view, @projection.fetch("root_resource").fetch("host_path"))
    protection = owner::WorkspaceWriter::Protection.new(projection: @projection, mounts: @mounts, acl: @acl)
    @writer = owner.workspace_writer(projection: @projection, protection: protection, files: files)
  end

  def test_original_writer_refuses_live_reader_then_durably_publishes_refusal_fence
    reader.acquire!
    assert_raises(Ace::Assign::AttemptErrors::MaintenanceBusy) do
      writer.acquire!(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5)
    end
    @reader.close!
    writer.acquire!(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5)
    evidence = @writer.publish_removed!(removed_at: "2026-10-08T00:00:00Z")
    assert_equal File.binread(marker_path), evidence.fetch("bytes")
    assert_equal Digest::SHA256.file(marker_path).hexdigest, evidence.fetch("reference").fetch("sha256")
    assert evidence.frozen?
    assert evidence.fetch("reference").frozen?
    @writer.close!
    @files.marker_owner = [0, 0]
    assert_raises(Ace::Assign::AttemptErrors::Conflict) { reader.acquire! }
  ensure
    @writer&.close!
  end

  def test_replacement_inspection_reads_retained_fence_without_publication_capability
    writer.acquire!(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5)
    original = @writer.publish_removed!(removed_at: "2026-10-08T00:00:00Z")
    @writer.close!
    files = WriterFiles.new(@root, @view, @projection.fetch("root_resource").fetch("host_path"))
    files.marker_owner = [0, 0]
    protection = owner::WorkspaceFenceReader::Protection.new(projection: @projection, mounts: @mounts, acl: @acl)
    inspection = owner.workspace_fence_reader(projection: @projection, protection: protection, files: files)
    inspection.acquire!(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5)
    assert_equal original, inspection.fence_evidence!
    refute_respond_to inspection, :publish_removed!
  ensure
    inspection&.close!
    @writer&.close!
  end

  def test_expired_original_deadline_cannot_publish_fence_after_admission
    writer.acquire!(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5)
    @writer.instance_variable_set(:@deadline, Process.clock_gettime(Process::CLOCK_MONOTONIC) - 1)
    original = File.binread(marker_path)
    assert_raises(Ace::Assign::AttemptErrors::MaintenanceBusy) do
      @writer.publish_removed!(removed_at: "2026-10-08T00:00:00Z")
    end
    assert_equal original, File.binread(marker_path)
  ensure
    @writer&.close!
  end

  def provisioner
    authority = {"state_root" => "/protected/authority", "uid" => Process.uid, "gid" => Process.gid}
    files = ProvisionFiles.new(@root, authority.fetch("state_root"))
    directories = Object.new
    directories.define_singleton_method(:mkdir) { |path, mode| Dir.mkdir(files.actual(path), mode) }
    protection = owner::WorkspaceProvisioner::Protection.new(projection: @projection, mounts: @mounts, acl: @acl)
    @provision_files = files
    @provision_selection = owner.workspace_selection(mapping_id: "mapping", project_id: "project", authority: authority,
      cwd_resource: @projection.fetch("worker_cwd_resource"))
    owner::WorkspaceProvisioner.new(mapping_id: "mapping", project_id: "project", authority: authority,
      cwd_resource: @projection.fetch("worker_cwd_resource"), files: files, directories: directories, protection: protection)
  end

  def test_provisioning_is_no_replace_and_never_clears_retained_fence
    File.chmod(0o700, @root)
    initial = provisioner.provision!
    assert @provision_files.opened.all?(&:closed?)
    selected = @provision_files.actual(@provision_selection.fetch("host_path"))
    key = @provision_selection.fetch("key")
    lock = File.join(selected, "#{Digest::SHA256.hexdigest(key)}.lock")
    marker = File.join(selected, "#{Digest::SHA256.hexdigest(key)}.state.json")
    inode = File.stat(lock).ino
    control = File.join(File.dirname(File.dirname(File.dirname(selected))), "control")
    assert_equal 0o700, File.stat(control).mode & 0o7777
    assert_equal 0o755, File.stat(selected).mode & 0o7777
    assert_equal 0o644, File.stat(lock).mode & 0o7777
    assert_equal owner.workspace_initial_marker(key: key), File.binread(marker)
    assert_equal initial, provisioner.provision!
    assert_equal inode, File.stat(lock).ino
    bytes = JSON.generate({"key" => key, "removed" => true, "removed_at" => "2026-10-08T00:00:00Z"})
    File.write(marker, bytes)
    assert_raises(Ace::Assign::AttemptErrors::Conflict) { provisioner.provision! }
    assert_equal bytes, File.binread(marker)
    assert @provision_files.opened.all?(&:closed?)
  end

  def test_provisioning_rejects_writable_state_root_before_creation
    File.chmod(0o777, @root)
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { provisioner.provision! }
    refute File.exist?(File.join(@root, "lifecycle-exclusion"))
    assert @provision_files.opened.all?(&:closed?)
  ensure
    File.chmod(0o755, @root)
  end

  def test_failed_parent_fsync_preserves_refusal_fence_without_positive_evidence
    writer.acquire!(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5)
    host = @projection.fetch("root_resource").fetch("host_path")
    handle = @writer.instance_variable_get(:@handles).fetch(host).fetch(:handle)
    handle.define_singleton_method(:fsync) { raise IOError, "controlled parent sync failure" }
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
      @writer.publish_removed!(removed_at: "2026-10-08T00:00:00Z")
    end
    assert_equal true, JSON.parse(File.binread(marker_path)).fetch("removed")
    @writer.close!
    @files.marker_owner = [0, 0]
    assert_raises(Ace::Assign::AttemptErrors::Conflict) { reader.acquire! }
    assert_empty Dir.glob(File.join(@root, ".*.fence"))
  ensure
    @writer&.close!
  end

  def test_provisioning_rejects_corrupt_marker_and_symlink_lock_without_repair
    File.chmod(0o700, @root)
    provisioner.provision!
    selected = @provision_files.actual(@provision_selection.fetch("host_path"))
    hash = Digest::SHA256.hexdigest(@provision_selection.fetch("key"))
    marker = File.join(selected, "#{hash}.state.json")
    lock = File.join(selected, "#{hash}.lock")
    File.write(marker, "{broken")
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { provisioner.provision! }
    assert_equal "{broken", File.binread(marker)
    File.delete(lock)
    File.symlink(marker, lock)
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { provisioner.provision! }
    assert File.symlink?(lock)
    assert @provision_files.opened.all?(&:closed?)
  end

  def test_busy_maintenance_refuses_reader_and_unwinds_all_descriptors
    File.open(lock_path, File::RDWR) do |writer|
      assert writer.flock(File::LOCK_EX | File::LOCK_NB)
      assert_raises(Ace::Assign::AttemptErrors::MaintenanceBusy) { reader.acquire! }
    end
    assert @files.opened.all?(&:closed?)
  end

  def test_missing_corrupt_or_symlink_marker_never_grants_reader
    File.delete(marker_path)
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { reader.acquire! }
    assert @files.opened.all?(&:closed?)
    File.write(marker_path, "{broken", mode: "w", perm: 0o644)
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { reader.acquire! }
    File.delete(marker_path)
    File.symlink(lock_path, marker_path)
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { reader.acquire! }
    assert @files.opened.all?(&:closed?)
  end

  def test_root_owned_true_fence_only_refuses_and_root_owned_false_cannot_admit
    @files.marker_owner = [0, 0]
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { reader.acquire! }
    File.write(marker_path, JSON.generate({"key" => @projection.fetch("key"), "removed" => true,
      "removed_at" => "2026-10-08T00:00:00Z"}))
    assert_raises(Ace::Assign::AttemptErrors::Conflict) { reader.acquire! }
    assert @files.opened.all?(&:closed?)
  end

  def test_writable_mount_default_acl_or_replaced_root_refuses_before_lock
    @mounts.flags = "rw"
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { reader.acquire! }
    @mounts.flags = "ro"
    @acl.default = [[1, 7, 0xffffffff]]
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { reader.acquire! }
    @acl.default = nil
    @projection.fetch("root_resource")["inode"] += 1
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { reader.acquire! }
    assert @files.opened.all?(&:closed?)
  end
end
