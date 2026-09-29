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

  def test_default_root_prefers_cache_base_sandbox
    ENV["CACHE_BASE"] = @tmp
    root = Ace::Assign::Molecules::LifecycleExclusion.default_root
    assert_equal File.join(@tmp, ".exclusion"), root
  ensure
    ENV.delete("CACHE_BASE")
  end
end
