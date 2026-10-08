# frozen_string_literal: true

require "tmpdir"
require_relative "../../test_helper"

class LifecycleExclusionTest < AceAssignTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("lifecycle-exclusion")
    @root = File.join(@tmp, "exclusion")
    @exclusion = Ace::Assign::Molecules::LifecycleExclusion.new(root: @root)
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def test_bounded_exclusive_refuses_contention_and_releases_partial_inventory
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    held = Queue.new
    release = Queue.new
    holder = Thread.new do
      @exclusion.with_exclusive("slot:b") { held << true; release.pop(timeout: 5) }
    end
    assert held.pop(timeout: 2)
    assert_raises(Ace::Assign::AttemptErrors::MaintenanceBusy) do
      @exclusion.with_exclusive("slot:a", deadline: deadline) do
        @exclusion.with_exclusive("slot:b", deadline: deadline) { flunk "busy inventory entered" }
      end
    end
    @exclusion.with_exclusive("slot:a", deadline: deadline) { assert true }
    [false, Float::INFINITY, "5"].each do |invalid|
      assert_raises(ArgumentError) { @exclusion.with_exclusive("slot:a", deadline: invalid) {} }
    end
    assert_raises(Ace::Assign::AttemptErrors::MaintenanceBusy) do
      @exclusion.with_exclusive("slot:a", deadline: 0) {}
    end
  ensure
    release << true if release
    holder&.value
  end

  def test_assignment_and_worktree_keys_are_stable_and_canonical
    assert_equal "assignment:abc12", @exclusion.assignment_key("abc12")

    real = File.join(@tmp, "real-dir")
    FileUtils.mkdir_p(real)
    link = File.join(@tmp, "link-dir")
    File.symlink(real, link)

    assert_equal @exclusion.worktree_key(real), @exclusion.worktree_key(link)

    missing = File.join(@tmp, "not-yet", "task.230")
    assert_equal "worktree:#{File.expand_path(missing)}", @exclusion.worktree_key(missing)
  end

  def test_shared_allows_concurrent_holders
    entered = Queue.new
    thread = Thread.new do
      @exclusion.with_shared("assignment:abc12") { entered << true }
    end
    @exclusion.with_shared("assignment:abc12") do
      assert entered.pop(timeout: 2), "the other shared holder should have entered concurrently"
    end
    thread.join
  end

  def test_exclusive_blocks_shared_until_released
    held = Queue.new
    release = Queue.new
    holder = Thread.new do
      @exclusion.with_exclusive("assignment:abc12") do
        held << true
        release.pop(timeout: 5)
      end
    end
    assert_equal true, held.pop(timeout: 2)

    result = Queue.new
    contender = Thread.new do
      @exclusion.with_shared("assignment:abc12") { result << :entered }
    end
    sleep 0.2
    assert result.empty?, "shared must wait while exclusive is held"

    release << :done
    holder.join
    contender.join
    assert_equal :entered, result.pop(timeout: 2)
  end

  def test_removed_marker_blocks_shared_starts
    @exclusion.record_removed!("assignment:abc12")

    error = assert_raises(Ace::Assign::AttemptErrors::Conflict) do
      @exclusion.with_shared("assignment:abc12") { flake "must not yield" }
    end
    assert_includes error.message, "abc12"
    assert_includes error.message, "was pruned"

    assert @exclusion.removed?("assignment:abc12")
  end

  def test_reset_removed_clears_stale_marker_for_fresh_provisioning
    @exclusion.record_removed!("worktree:x")

    @exclusion.with_shared("worktree:x", reset_removed: true) do
      refute @exclusion.removed?("worktree:x")
    end

    @exclusion.with_shared("worktree:x") { }
  end

  def test_clear_removed_and_removed_roundtrip
    refute @exclusion.removed?("assignment:abc12")
    @exclusion.record_removed!("assignment:abc12")
    assert @exclusion.removed?("assignment:abc12")
    @exclusion.clear_removed!("assignment:abc12")
    refute @exclusion.removed?("assignment:abc12")
  end

  def test_shared_multi_acquires_all_identities_in_order
    acquired = []
    @exclusion.with_shared_multi(["task:230", "assignment:abc12"]) do
      acquired = [@exclusion.removed?("task:230"), @exclusion.removed?("assignment:abc12")]
    end
    assert_equal [false, false], acquired
  end

  def test_shared_multi_fails_when_any_identity_was_pruned
    @exclusion.record_removed!("assignment:abc12")

    error = assert_raises(Ace::Assign::AttemptErrors::Conflict) do
      @exclusion.with_shared_multi(["task:230", "assignment:abc12"]) { flake "must not yield" }
    end
    assert_includes error.message, "abc12"
    assert_includes error.message, "was pruned"
  end

  def test_shared_multi_reset_removed_clears_stale_markers
    @exclusion.record_removed!("task:230")

    @exclusion.with_shared_multi(["task:230", "assignment:abc12"], reset_removed: true) do
      refute @exclusion.removed?("task:230")
    end
  end

  def test_shared_multi_blocks_while_exclusive_held
    held = Queue.new
    release = Queue.new
    holder = Thread.new do
      @exclusion.with_exclusive("task:230") do
        held << true
        release.pop(timeout: 5)
      end
    end
    assert_equal true, held.pop(timeout: 2)

    result = Queue.new
    contender = Thread.new do
      @exclusion.with_shared_multi(["task:230", "assignment:abc12"]) { result << :entered }
    end
    sleep 0.2
    assert result.empty?, "shared multi must wait while exclusive is held"

    release << :done
    holder.join
    contender.join
    assert_equal :entered, result.pop(timeout: 2)
  end

  def test_explicit_repository_uses_its_actual_common_directory_despite_cache_and_current_project
    repo = File.join(@tmp, "selected")
    system("git", "init", "--quiet", repo, exception: true)
    previous = ENV["CACHE_BASE"]
    ENV["CACHE_BASE"] = File.join(@tmp, "unrelated-cache")
    assert_equal File.join(File.realpath(repo), ".git", "ace", "lifecycle-exclusion"),
      Ace::Assign::Molecules::LifecycleExclusion.default_root(repo)
    system("git", "-C", repo, "-c", "user.name=controlled", "-c", "user.email=controlled@example.test",
      "commit", "--allow-empty", "--quiet", "-m", "controlled", exception: true)
    linked = File.join(@tmp, "linked")
    system("git", "-C", repo, "worktree", "add", "--detach", "--quiet", linked, "HEAD", exception: true)
    assert_equal Ace::Assign::Molecules::LifecycleExclusion.default_root(repo),
      Ace::Assign::Molecules::LifecycleExclusion.default_root(linked)
    [repo, linked].each do |selected|
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub(:find_or_current, selected) do
        assert_equal Ace::Assign::Molecules::LifecycleExclusion.default_root(repo),
          Ace::Assign::Molecules::LifecycleExclusion.default_root
      end
    end
    assert_raises(Ace::Assign::AttemptErrors::Conflict) do
      Ace::Assign::Molecules::LifecycleExclusion.default_root(File.join(@tmp, "missing"))
    end
  ensure
    previous ? ENV["CACHE_BASE"] = previous : ENV.delete("CACHE_BASE")
  end

  def test_corrupt_misbound_duplicate_or_redirected_marker_never_permits_start_or_reset
    key = "assignment:abc12"
    @exclusion.record_removed!(key)
    path = File.join(@root, "#{Digest::SHA256.hexdigest(key)}.state.json")
    valid = File.binread(path)
    ["{", "[]", valid.sub('abc12', 'foreign'), valid.sub('true', 'false'),
      valid.sub('"removed":true', '"removed":true,"removed":true')].each do |bytes|
      File.binwrite(path, bytes)
      [false, true].each do |reset|
        assert_raises(Ace::Assign::AttemptErrors::Conflict) do
          @exclusion.with_shared(key, reset_removed: reset) { flunk "unsafe start" }
        end
      end
      assert_equal bytes, File.binread(path)
    end
    File.delete(path)
    target = File.join(@tmp, "marker")
    File.binwrite(target, valid)
    File.symlink(target, path)
    assert_raises(Ace::Assign::AttemptErrors::Conflict) { @exclusion.with_shared(key) {} }
    assert_equal valid, File.binread(target)
  end

  def test_restart_retains_fence_and_symlink_lock_cannot_admit_writer
    @exclusion.with_exclusive("worktree:original") { @exclusion.record_removed!("worktree:original") }
    restarted = Ace::Assign::Molecules::LifecycleExclusion.new(root: @root)
    assert_raises(Ace::Assign::AttemptErrors::Conflict) { restarted.with_shared("worktree:original") {} }
    path = File.join(@root, "#{Digest::SHA256.hexdigest('worktree:other')}.lock")
    File.symlink(File.join(@tmp, "foreign-lock"), path)
    assert_raises(Ace::Assign::AttemptErrors::Conflict) { restarted.with_shared("worktree:other") {} }
    refute File.exist?(File.join(@tmp, "foreign-lock"))
  end

  def test_failed_multi_open_closes_earlier_handles
    opened = []
    original = @exclusion.method(:open_lock)
    @exclusion.stub(:open_lock, ->(key) {
      raise IOError, "controlled later open" if key == "b"
      original.call(key).tap { |file| opened << file }
    }) do
      assert_raises(IOError) { @exclusion.with_shared_multi(%w[a b]) {} }
    end
    assert opened.all?(&:closed?)
  end

  def test_hardlinked_lock_refuses_with_typed_error_and_closes_once
    key = "worktree:hardlink"
    FileUtils.mkdir_p(@root)
    target = File.join(@tmp, "retained-lock")
    File.write(target, "", mode: "w", perm: 0600)
    path = File.join(@root, "#{Digest::SHA256.hexdigest(key)}.lock")
    File.link(target, path)
    assert_raises(Ace::Assign::AttemptErrors::MaintenanceBusy) { @exclusion.with_shared(key) {} }
    assert_equal 2, File.stat(target).nlink
  end

  def test_file_sync_failure_leaves_original_marker_and_removes_unpublished_temporary
    key = "assignment:durable"
    @exclusion.record_removed!(key)
    path = File.join(@root, "#{Digest::SHA256.hexdigest(key)}.state.json")
    before = File.binread(path)
    original_open = File.method(:open)
    failing_open = lambda do |name, *args, **options, &block|
      if File.basename(name.to_s).start_with?(".tmp-")
        original_open.call(name, *args, **options) do |file|
          file.define_singleton_method(:fsync) { raise IOError, "controlled file sync failure" }
          block.call(file)
        end
      else
        original_open.call(name, *args, **options, &block)
      end
    end
    File.stub(:open, failing_open) do
      assert_raises(IOError) { @exclusion.record_removed!(key) }
    end
    assert_equal before, File.binread(path)
    assert_empty Dir.children(@root).grep(/\A\.tmp-/)
    assert @exclusion.removed?(key)
  end

  def test_parent_sync_failure_is_reported_and_published_fence_remains_closed
    key = "assignment:parent-sync"
    @exclusion.stub(:sync_directory, ->(*) { raise IOError, "controlled directory sync failure" }) do
      assert_raises(IOError) { @exclusion.record_removed!(key) }
    end
    restarted = Ace::Assign::Molecules::LifecycleExclusion.new(root: @root)
    assert restarted.removed?(key)
    assert_raises(Ace::Assign::AttemptErrors::Conflict) { restarted.with_shared(key) {} }
  end

end
