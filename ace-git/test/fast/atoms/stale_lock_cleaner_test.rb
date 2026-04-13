# frozen_string_literal: true

require "test_helper"

class StaleLockCleanerTest < AceGitTestCase
  def setup
    super
    @cleaner = Ace::Git::Atoms::StaleLockCleaner
    @temp_dir = Dir.mktmpdir
    @git_dir = File.join(@temp_dir, ".git")
    FileUtils.mkdir_p(@git_dir)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
    super
  end

  def test_stale_returns_false_for_non_existent_file
    lock_path = File.join(@git_dir, "index.lock")
    refute @cleaner.stale?(lock_path, 60), "Should return false for non-existent file"
  end

  def test_stale_returns_false_for_fresh_lock
    lock_path = File.join(@git_dir, "index.lock")
    File.write(lock_path, "lock content")
    # Lock was just created, so it's fresh
    refute @cleaner.stale?(lock_path, 60), "Should return false for fresh lock (< 60s old)"
  end

  def test_stale_returns_true_for_old_lock
    lock_path = File.join(@git_dir, "index.lock")
    File.write(lock_path, "lock content")
    # Set mtime to 120 seconds ago (older than 60s threshold)
    old_time = Time.now - 120
    File.utime(old_time, old_time, lock_path)
    assert @cleaner.stale?(lock_path, 60), "Should return true for stale lock (> 60s old)"
  end

  def test_stale_respects_custom_threshold
    lock_path = File.join(@git_dir, "index.lock")
    File.write(lock_path, "lock content")
    # Set mtime to 90 seconds ago
    old_time = Time.now - 90
    File.utime(old_time, old_time, lock_path)

    # With 100s threshold, 90s old is not stale
    refute @cleaner.stale?(lock_path, 100), "Should return false with 100s threshold"

    # With 60s threshold, 90s old is stale
    assert @cleaner.stale?(lock_path, 60), "Should return true with 60s threshold"
  end

  # --- orphaned? tests ---

  def test_orphaned_returns_true_for_non_existent_pid
    lock_path = File.join(@git_dir, "index.lock")
    # Use a PID that definitely doesn't exist (very high number)
    File.write(lock_path, "999999999")

    assert @cleaner.orphaned?(lock_path), "Should return true for non-existent PID"
  end

  def test_orphaned_returns_false_for_current_process_pid
    lock_path = File.join(@git_dir, "index.lock")
    # Use current process PID (definitely exists)
    File.write(lock_path, Process.pid.to_s)

    refute @cleaner.orphaned?(lock_path), "Should return false for running PID"
  end

  def test_orphaned_returns_false_for_invalid_pid
    lock_path = File.join(@git_dir, "index.lock")
    # Invalid PID (zero or negative)
    File.write(lock_path, "0")
    refute @cleaner.orphaned?(lock_path), "Should return false for zero PID"

    File.write(lock_path, "-1")
    refute @cleaner.orphaned?(lock_path), "Should return false for negative PID"
  end

  def test_orphaned_returns_false_for_non_numeric_content
    lock_path = File.join(@git_dir, "index.lock")
    File.write(lock_path, "not a pid")

    refute @cleaner.orphaned?(lock_path), "Should return false for non-numeric content"
  end

  def test_orphaned_handles_pid_with_hostname
    lock_path = File.join(@git_dir, "index.lock")
    # Git lock files may contain "PID hostname" format
    File.write(lock_path, "999999999 hostname.local")

    assert @cleaner.orphaned?(lock_path), "Should parse PID from 'PID hostname' format"
  end

  def test_orphaned_returns_false_for_non_existent_file
    lock_path = File.join(@git_dir, "index.lock")
    # File doesn't exist

    refute @cleaner.orphaned?(lock_path), "Should return false for non-existent file"
  end

  def test_find_lock_file_returns_path_when_exists
    lock_path = File.join(@git_dir, "index.lock")
    File.write(lock_path, "lock content")

    result = @cleaner.find_lock_file(@temp_dir)
    assert_equal lock_path, result, "Should return lock file path"
  end

  def test_find_lock_file_returns_nil_when_not_exists
    result = @cleaner.find_lock_file(@temp_dir)
    assert_nil result, "Should return nil when lock file doesn't exist"
  end

  def test_find_lock_file_returns_nil_for_nil_path
    assert_nil @cleaner.find_lock_file(nil), "Should return nil for nil path"
  end

  def test_find_lock_file_returns_nil_for_empty_path
    assert_nil @cleaner.find_lock_file(""), "Should return nil for empty path"
  end

  def test_clean_returns_success_when_no_lock_exists
    result = @cleaner.clean(@temp_dir, 60)

    assert result[:success], "Should succeed when no lock exists"
    refute result[:cleaned], "Should indicate no lock was cleaned"
    assert_includes result[:message], "No lock file found", "Should explain no lock found"
  end

  def test_clean_removes_stale_lock
    lock_path = File.join(@git_dir, "index.lock")
    File.write(lock_path, "lock content")
    # Make lock stale
    old_time = Time.now - 120
    File.utime(old_time, old_time, lock_path)

    result = @cleaner.clean(@temp_dir, 60)

    assert result[:success], "Should succeed"
    assert result[:cleaned], "Should indicate lock was cleaned"
    assert_includes result[:message], "Removed stale lock", "Should explain lock was removed"
    refute File.exist?(lock_path), "Lock file should be deleted"
  end

  def test_clean_does_not_remove_fresh_lock_with_running_pid
    lock_path = File.join(@git_dir, "index.lock")
    # Use current process PID so it's not orphaned
    File.write(lock_path, Process.pid.to_s)

    result = @cleaner.clean(@temp_dir, 60)

    assert result[:success], "Should succeed"
    refute result[:cleaned], "Should indicate no lock was cleaned"
    assert_includes result[:message], "active", "Should explain lock is active"
    assert File.exist?(lock_path), "Lock file should still exist"
  end

  def test_clean_removes_orphaned_lock_even_if_fresh
    lock_path = File.join(@git_dir, "index.lock")
    # Use a non-existent PID - lock is orphaned even though fresh
    File.write(lock_path, "999999999")

    result = @cleaner.clean(@temp_dir, 60)

    assert result[:success], "Should succeed"
    assert result[:cleaned], "Should indicate lock was cleaned"
    assert_includes result[:message], "orphaned", "Should explain lock was orphaned"
    refute File.exist?(lock_path), "Orphaned lock file should be deleted"
  end

  def test_clean_uses_custom_threshold
    lock_path = File.join(@git_dir, "index.lock")
    File.write(lock_path, "lock content")
    # Make lock 90 seconds old
    old_time = Time.now - 90
    File.utime(old_time, old_time, lock_path)

    # With 100s threshold, should not clean
    result = @cleaner.clean(@temp_dir, 100)
    assert result[:success], "Should succeed"
    refute result[:cleaned], "Should not clean with 100s threshold"
    assert File.exist?(lock_path), "Lock should still exist"

    # With 60s threshold, should clean
    result = @cleaner.clean(@temp_dir, 60)
    assert result[:cleaned], "Should clean with 60s threshold"
    refute File.exist?(lock_path), "Lock should be removed"
  end

  def test_clean_handles_worktree_git_file
    # Create a separate temp directory for worktree test
    worktree_dir = Dir.mktmpdir

    begin
      # Simulate worktree where .git is a file pointing to gitdir
      main_git_dir = File.join(worktree_dir, "main.git")
      worktree_git_dir = File.join(main_git_dir, "worktrees", "test-worktree")
      FileUtils.mkdir_p(worktree_git_dir)

      # Create worktree .git file
      git_file = File.join(worktree_dir, ".git")
      File.write(git_file, "gitdir: #{worktree_git_dir}")

      # Create lock in worktree gitdir
      lock_path = File.join(worktree_git_dir, "index.lock")
      File.write(lock_path, "lock content")
      # Make it stale
      old_time = Time.now - 120
      File.utime(old_time, old_time, lock_path)

      result = @cleaner.clean(worktree_dir, 60)

      assert result[:success], "Should succeed for worktree"
      assert result[:cleaned], "Should clean worktree lock"
      refute File.exist?(lock_path), "Worktree lock should be removed"
    ensure
      FileUtils.rm_rf(worktree_dir) if worktree_dir && File.exist?(worktree_dir)
    end
  end

  def test_clean_returns_error_on_exception
    # Use a directory we can't write to (simulated by stubbing File.delete)
    lock_path = File.join(@git_dir, "index.lock")
    File.write(lock_path, "lock content")
    old_time = Time.now - 120
    File.utime(old_time, old_time, lock_path)

    # Stub File.delete to raise an error
    File.stub :delete, ->(path) { raise Errno::EACCES, "Permission denied" } do
      result = @cleaner.clean(@temp_dir, 60)

      refute result[:success], "Should fail on exception"
      refute result[:cleaned], "Should indicate no lock was cleaned"
      assert_includes result[:message], "Failed to clean", "Should explain failure"
    end
  end

  def test_clean_handles_malformed_worktree_git_file
    # Create a separate temp directory for malformed git file test
    malformed_dir = Dir.mktmpdir

    begin
      # Create .git file with malformed content (not a directory)
      git_file = File.join(malformed_dir, ".git")
      File.write(git_file, "not a valid gitdir format")

      result = @cleaner.clean(malformed_dir, 60)

      assert result[:success], "Should succeed gracefully"
      refute result[:cleaned], "Should not clean anything"
    ensure
      FileUtils.rm_rf(malformed_dir) if malformed_dir && File.exist?(malformed_dir)
    end
  end

  def test_clean_handles_relative_gitdir_path
    # Create a worktree with a relative gitdir path
    # This is how git creates worktrees when the main repo and worktree
    # are on the same filesystem
    worktree_dir = Dir.mktmpdir

    begin
      # Simulate worktree where .git file contains relative path
      main_git_dir = File.join(worktree_dir, "main.git")
      worktree_git_dir = File.join(main_git_dir, "worktrees", "test-wt")
      FileUtils.mkdir_p(worktree_git_dir)

      # Create worktree .git file with RELATIVE path
      # Path is relative to the .git file's directory
      git_file = File.join(worktree_dir, ".git")
      File.write(git_file, "gitdir: main.git/worktrees/test-wt")

      # Create lock in worktree gitdir
      lock_path = File.join(worktree_git_dir, "index.lock")
      File.write(lock_path, "lock content")
      # Make it stale
      old_time = Time.now - 120
      File.utime(old_time, old_time, lock_path)

      result = @cleaner.clean(worktree_dir, 60)

      assert result[:success], "Should succeed for worktree with relative path"
      assert result[:cleaned], "Should clean worktree lock"
      refute File.exist?(lock_path), "Worktree lock should be removed"
    ensure
      FileUtils.rm_rf(worktree_dir) if worktree_dir && File.exist?(worktree_dir)
    end
  end

  def test_clean_refuses_to_delete_symlink
    # Create a real target file
    target_path = File.join(@temp_dir, "target_file")
    File.write(target_path, "target content")

    # Create a symlink named index.lock pointing to it
    lock_path = File.join(@git_dir, "index.lock")
    File.symlink(target_path, lock_path)

    # Make it look stale by modifying the target's mtime
    old_time = Time.now - 120
    File.utime(old_time, old_time, target_path)

    result = @cleaner.clean(@temp_dir, 60)

    refute result[:success], "Should fail for symlink"
    refute result[:cleaned], "Should not clean symlinks"
    assert_includes result[:message], "symlink", "Should mention symlink in message"
    assert File.exist?(lock_path), "Symlink should still exist"
    assert File.exist?(target_path), "Target file should still exist"
  end

  def test_clean_handles_race_condition_when_lock_deleted_externally
    lock_path = File.join(@git_dir, "index.lock")
    File.write(lock_path, "lock content")
    # Make lock stale
    old_time = Time.now - 120
    File.utime(old_time, old_time, lock_path)

    # Stub File.delete to simulate race condition where file was already deleted
    File.stub :delete, ->(path) { raise Errno::ENOENT, "No such file" } do
      result = @cleaner.clean(@temp_dir, 60)

      assert result[:success], "Should succeed when lock already removed"
      refute result[:cleaned], "Should indicate no lock was cleaned"
      assert_includes result[:message], "already removed", "Should explain lock was already removed"
    end
  end
end
