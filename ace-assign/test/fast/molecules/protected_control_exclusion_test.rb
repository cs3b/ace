# frozen_string_literal: true
require_relative "../../test_helper"
require_relative "../../support/protected_control_fixture"
require "ace/assign/molecules/protected_control_exclusion"
require "etc"
require "tmpdir"

class ProtectedControlExclusionTest < AceAssignTestCase
  Owner = Ace::Assign::Molecules::LifecycleExclusion::ControlExclusion
  Errors = Ace::Assign::AttemptErrors

  Files = Ace::Assign::ProtectedControlFixture::Files
  Mounts = Ace::Assign::ProtectedControlFixture::Mounts

  def setup
    super
    @state = File.realpath(Dir.mktmpdir("control-exclusion-", Etc.getpwuid(Process.uid).dir))
    @root = File.join(@state, "lifecycle-exclusion", "project", "control")
    FileUtils.mkdir_p(@root, mode: 0o700)
    @authority = {"state_root" => @state, "uid" => 13003, "gid" => 13003}
    @files = Files.new(@state)
    @acl = Ace::Assign::ProtectedWorkspaceFixture::ACL.new
    @protection = Owner::Protection.new(authority_uid: 13003, acl: @acl, mounts: Mounts.new)
    @owner = owner
    @keys = [@owner.task_key("task"), @owner.assignment_key("assignment")]
  end

  def teardown
    FileUtils.rm_rf(@state)
    super
  end

  def owner(selection: nil)
    Owner.new(authority: @authority, project_id: "project", descriptor_sha256: "d" * 64,
      root_identity: selection&.fetch("root_identity"), files: @files, protection: @protection)
  end

  def path(key, suffix)
    File.join(@root, "#{Digest::SHA256.hexdigest(key)}.#{suffix}")
  end

  def test_original_selection_and_no_replace_provision_survive_restart
    selection = @owner.selection!
    assert selection.frozen?
    assert selection.fetch("root_identity").frozen?
    assert_equal "d" * 64, selection.fetch("descriptor_sha256")
    @owner.provision_keys!(keys: @keys.reverse)
    inodes = @keys.map { |key| File.stat(path(key, "lock")).ino }
    fresh = owner(selection: selection)
    fresh.provision_keys!(keys: @keys)
    assert_equal inodes, @keys.map { |key| File.stat(path(key, "lock")).ino }
    assert_equal :accepted, fresh.with_shared_multi(@keys) { :accepted }
    @keys.each do |key|
      assert_equal 0o600, File.stat(path(key, "lock")).mode & 0o7777
      assert_equal({"key" => key, "removed" => false, "removed_at" => nil}, JSON.parse(File.read(path(key, "state.json"))))
    end
    assert @files.opened.all?(&:closed?)
    assert_includes @acl.attributes, "system.posix_acl_default"
  end

  def test_shared_and_exclusive_admission_are_same_inode_and_unwind_partial_contention
    @owner.provision_keys!(keys: @keys)
    other = owner(selection: @owner.selection!)
    @owner.with_shared_multi(@keys) do
      assert_raises(Errors::MaintenanceBusy) { other.with_exclusive(@keys.last) { flunk "contended EX admitted" } }
    end
    other.with_exclusive(@keys.last) do
      assert_raises(Errors::MaintenanceBusy) { @owner.with_shared_multi(@keys) { flunk "partial SH admitted" } }
    end
    @keys.each do |key|
      File.open(path(key, "lock"), File::RDONLY) { |file| assert file.flock(File::LOCK_EX | File::LOCK_NB) }
    end
    assert @files.opened.all?(&:closed?)
  end

  def test_corrupt_missing_and_true_markers_never_reset
    @owner.provision_keys!(keys: @keys)
    marker = path(@keys.first, "state.json")
    File.write(marker, "not-json")
    assert_raises(Errors::EvidenceUnavailable) { @owner.provision_keys!(keys: @keys) }
    assert_raises(Errors::EvidenceUnavailable) { @owner.with_shared_multi(@keys) { flunk } }
    assert_equal "not-json", File.read(marker)
    File.unlink(marker)
    assert_raises(Errors::EvidenceUnavailable) { @owner.provision_keys!(keys: @keys) }
    refute File.exist?(marker)
    File.write(marker, JSON.generate("key" => @keys.first, "removed" => true, "removed_at" => "2026-10-08T00:00:00Z"), perm: 0o600)
    assert_raises(Errors::Conflict) { @owner.with_shared_multi(@keys) { flunk } }
    assert JSON.parse(File.read(marker)).fetch("removed")
  end

  def test_changed_original_root_and_protection_refuse_before_keys
    selection = @owner.selection!
    File.rename(@root, @root + "-old")
    Dir.mkdir(@root, 0o700)
    assert_raises(Errors::EvidenceUnavailable) { owner(selection: selection).provision_keys!(keys: @keys) }
    assert_empty Dir.children(@root)
    @acl.default = ["unsupported"]
    assert_raises(Errors::EvidenceUnavailable) { @owner.selection! }
  end

  def test_wrong_owner_false_and_marker_replacement_refuse_without_leaking_locks
    @owner.provision_keys!(keys: @keys)
    @files.bad_marker_owner = true
    assert_raises(Errors::EvidenceUnavailable) { @owner.with_shared_multi(@keys) { flunk } }
    @files.bad_marker_owner = false
    assert_raises(Errors::EvidenceUnavailable) do
      @owner.with_shared_multi(@keys) do
        marker = path(@keys.first, "state.json")
        bytes = File.read(marker)
        File.rename(marker, marker + "-old")
        File.write(marker, bytes, perm: 0o600)
      end
    end
    @keys.each do |key|
      File.open(path(key, "lock"), File::RDONLY) { |file| assert file.flock(File::LOCK_EX | File::LOCK_NB) }
    end
    assert @files.opened.all?(&:closed?)
  end

  def test_expired_deadline_and_unsupported_keys_admit_no_callback_or_file_write
    @owner.provision_keys!(keys: @keys)
    assert_raises(Errors::MaintenanceBusy) do
      @owner.with_exclusive(@keys.first, deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) - 1) { flunk }
    end
    before = Dir.children(@root).sort
    assert_raises(Errors::EvidenceUnavailable) { @owner.provision_keys!(keys: ["assignment:../../foreign"]) }
    assert_equal before, Dir.children(@root).sort
  end
  def test_owner_callback_failure_retains_original_exception_and_unwinds_all_guards
    @owner.provision_keys!(keys: @keys)
    [IOError.new("callback"), Errno::EPERM.new("callback"), Ace::Runtime::RuntimeUnavailableError.new("callback")].each do |failure|
      actual = assert_raises(failure.class) do
        @owner.with_shared_multi(@keys) { raise failure }
      end
      assert_same failure, actual
      @keys.each do |key|
        File.open(path(key, "lock"), File::RDONLY) { |file| assert file.flock(File::LOCK_EX | File::LOCK_NB) }
      end
      assert @files.opened.all?(&:closed?)
    end
  end

end
