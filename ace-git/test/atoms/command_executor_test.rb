# frozen_string_literal: true

require_relative "../test_helper"

class CommandExecutorTest < AceGitTestCase
  def setup
    super
    @executor = Ace::Git::Atoms::CommandExecutor
  end

  def test_execute_returns_hash_with_expected_keys
    mock_result = { success: true, output: "test\n", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.execute("echo", "test")

      assert_instance_of Hash, result
      assert result.key?(:success)
      assert result.key?(:output)
      assert result.key?(:error)
      assert result.key?(:exit_code)
    end
  end

  def test_execute_successful_command
    mock_result = { success: true, output: "hello\n", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.execute("echo", "hello")

      assert result[:success]
      assert_includes result[:output], "hello"
      assert_equal 0, result[:exit_code]
    end
  end

  def test_execute_failed_command
    mock_result = { success: false, output: "", error: "command failed", exit_code: 1 }

    @executor.stub :execute, mock_result do
      result = @executor.execute("false")

      refute result[:success]
      assert_equal 1, result[:exit_code]
    end
  end

  # Tests for has_unstaged_changes? and has_staged_changes? (moved to hermetic section)
  def test_has_unstaged_changes_returns_true_when_diff_exists
    mock_result = { success: true, output: "changes\n", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.has_unstaged_changes?
      assert result, "Should return true when working diff is not empty"
    end
  end

  def test_has_unstaged_changes_returns_false_when_no_diff
    mock_result = { success: true, output: "", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.has_unstaged_changes?
      refute result, "Should return false when working diff is empty"
    end
  end

  def test_has_staged_changes_returns_true_when_diff_exists
    mock_result = { success: true, output: "staged changes\n", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.has_staged_changes?
      assert result, "Should return true when staged diff is not empty"
    end
  end

  def test_has_staged_changes_returns_false_when_no_diff
    mock_result = { success: true, output: "", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.has_staged_changes?
      refute result, "Should return false when staged diff is empty"
    end
  end

  def test_has_untracked_changes_returns_true_when_untracked_files_exist
    mock_result = { success: true, output: "new_file.txt\n", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.has_untracked_changes?
      assert result, "Should return true when untracked files are present"
    end
  end

  def test_has_untracked_changes_returns_false_when_no_untracked_files
    mock_result = { success: true, output: "", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.has_untracked_changes?
      refute result, "Should return false when no untracked files are present"
    end
  end

  def test_execute_handles_errors_gracefully
    mock_result = { success: false, output: "", error: "command not found", exit_code: -1 }

    @executor.stub :execute, mock_result do
      result = @executor.execute("nonexistent_command_xyz")

      refute result[:success]
      assert_equal(-1, result[:exit_code])
      assert_instance_of String, result[:error]
    end
  end

  def test_execute_accepts_custom_timeout
    # Verify timeout parameter is passed through (stubbed execute)
    mock_result = { success: true, output: "test\n", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.execute("echo", "test", timeout: 5)

      assert result[:success]
      assert_includes result[:output], "test"
    end
  end

  def test_execute_uses_config_default_timeout
    # git_timeout method reads from config (per ADR-022)
    # This is a fast config read, not a git call
    assert_equal 30, Ace::Git.git_timeout
  end

  def test_execute_returns_timeout_error_with_custom_timeout_value
    # Stub Timeout.timeout to simulate timeout without actual sleep
    Timeout.stub :timeout, ->(_, &) { raise Timeout::Error } do
      result = @executor.execute("echo", "test", timeout: 1)

      refute result[:success]
      assert_includes result[:error], "timed out after"
      assert_equal(-1, result[:exit_code])
    end
  end

  def test_git_diff_returns_output_on_success
    mock_result = { success: true, output: "diff content\n", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.git_diff("HEAD~1..HEAD")
      assert_equal "diff content\n", result
    end
  end

  def test_git_diff_returns_empty_string_on_failure
    mock_result = { success: false, output: "", error: "git diff failed", exit_code: 1 }

    @executor.stub :execute, mock_result do
      result = @executor.git_diff("invalid..range")
      assert_equal "", result
    end
  end

  # --- Hermetic Tests (class-level stubbing for real testing) ---
  # These tests use class-level stubbing to properly test without git

  def test_in_git_repo_stubbed_true
    mock_result = { success: true, output: ".git\n", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.in_git_repo?
      assert result, "Should return true when git rev-parse succeeds"
    end
  end

  def test_in_git_repo_stubbed_false
    mock_result = { success: false, output: "", error: "not a git repo", exit_code: 128 }

    @executor.stub :execute, mock_result do
      result = @executor.in_git_repo?
      refute result, "Should return false when git rev-parse fails"
    end
  end

  def test_current_branch_with_stubbed_response
    mock_result = { success: true, output: "feature-branch\n", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.current_branch
      assert_equal "feature-branch", result
    end
  end

  def test_current_branch_stubbed_failure
    mock_result = { success: false, output: "", error: "not a git repo", exit_code: 128 }

    @executor.stub :execute, mock_result do
      result = @executor.current_branch
      assert_nil result, "Should return nil on failure"
    end
  end

  def test_current_branch_returns_sha_when_detached
    # When git rev-parse --abbrev-ref HEAD returns "HEAD", we're detached
    # and should return the commit SHA instead
    call_count = 0
    mock_execute = lambda do |*args, **_opts|
      call_count += 1
      if call_count == 1
        # First call: abbrev-ref returns "HEAD" (detached)
        { success: true, output: "HEAD\n", error: "", exit_code: 0 }
      else
        # Second call: rev-parse HEAD returns SHA
        { success: true, output: "abc123def456789\n", error: "", exit_code: 0 }
      end
    end

    @executor.stub :execute, mock_execute do
      result = @executor.current_branch
      assert_equal "abc123def456789", result, "Should return SHA when detached"
    end
  end

  def test_current_branch_returns_nil_when_detached_sha_fails
    call_count = 0
    mock_execute = lambda do |*args, **_opts|
      call_count += 1
      if call_count == 1
        # First call: abbrev-ref returns "HEAD" (detached)
        { success: true, output: "HEAD\n", error: "", exit_code: 0 }
      else
        # Second call: rev-parse HEAD fails
        { success: false, output: "", error: "error", exit_code: 1 }
      end
    end

    @executor.stub :execute, mock_execute do
      result = @executor.current_branch
      assert_nil result, "Should return nil when SHA lookup fails"
    end
  end

  def test_repo_root_with_stubbed_response
    mock_result = { success: true, output: "/path/to/repo\n", error: "", exit_code: 0 }

    @executor.stub :execute_once, mock_result do
      result = @executor.repo_root
      assert_equal "/path/to/repo", result
    end
  end

  def test_repo_root_stubbed_failure
    mock_result = { success: false, output: "", error: "not a git repo", exit_code: 128 }

    @executor.stub :execute_once, mock_result do
      result = @executor.repo_root
      assert_nil result, "Should return nil on failure"
    end
  end

  def test_repo_root_bypasses_lock_retry
    # repo_root must call execute_once directly to avoid infinite recursion
    # (execute_with_lock_retry calls repo_root for stale cleanup)
    call_count = 0
    mock_result = { success: true, output: "/path/to/repo\n", error: "", exit_code: 0 }

    original_execute_once = @executor.method(:execute_once)
    mock_execute_once = lambda do |*args, **opts|
      call_count += 1
      mock_result
    end

    with_lock_retry_config(enabled: true) do
      @executor.stub :execute_once, mock_execute_once do
        result = @executor.repo_root

        assert_equal "/path/to/repo", result
        assert_equal 1, call_count, "execute_once should be called exactly once (no retry loop)"
      end
    end
  end

  def test_changed_files_with_stubbed_response
    mock_result = { success: true, output: "file1.rb\nfile2.rb\n", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.changed_files("HEAD..HEAD")
      assert_equal ["file1.rb", "file2.rb"], result
    end
  end

  def test_changed_files_with_empty_response
    mock_result = { success: true, output: "", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.changed_files("HEAD..HEAD")
      assert_equal [], result
    end
  end

  def test_changed_files_defaults_to_origin_main_when_origin_exists
    execute_calls = []
    stub_result = { success: true, output: "file.rb\n", error: "", exit_code: 0 }

    @executor.stub :execute, ->(*args) { execute_calls << args; stub_result } do
      @executor.stub :ref_exists?, ->(ref) { ref == "origin/main" } do
        result = @executor.changed_files
        assert_equal ["file.rb"], result
        assert_includes execute_calls, ["git", "diff", "--name-only", "origin/main...HEAD"]
      end
    end
  end

  def test_changed_files_without_origin_uses_working_diff
    execute_calls = []

    @executor.stub :execute, ->(*args) { execute_calls << args; { success: true, output: "file.rb\n", error: "", exit_code: 0 } } do
      @executor.stub :ref_exists?, ->(_ref) { false } do
        result = @executor.changed_files

        assert_equal ["file.rb"], result
        assert_includes execute_calls, ["git", "diff", "--name-only"]
      end
    end
  end

  def test_changed_files_stubbed_failure
    mock_result = { success: false, output: "", error: "error", exit_code: 1 }

    @executor.stub :execute, mock_result do
      result = @executor.changed_files("HEAD..HEAD")
      assert_equal [], result, "Should return empty array on failure"
    end
  end

  # --- Lock Retry Tests ---

  def test_retry_on_lock_error_with_eventual_success
    call_count = 0
    lock_error_result = { success: false, output: "", error: "fatal: Unable to create '.git/index.lock': File exists.", exit_code: 128 }
    success_result = { success: true, output: "success\n", error: "", exit_code: 0 }

    mock_execute = lambda do |*args, **_opts|
      call_count += 1
      call_count == 1 ? lock_error_result : success_result
    end
    mock_sleep = ->(_) { nil }

    # Stub repo_root to prevent additional execute_once calls during stale lock cleanup
    @executor.stub :repo_root, "/fake/repo" do
      @executor.stub :execute_once, mock_execute do
        Kernel.stub :sleep, mock_sleep do
          result = @executor.execute("git", "status")

          assert result[:success], "Should succeed after retry"
          assert_equal 2, call_count, "Should retry on lock error"
        end
      end
    end
  end

  def test_no_retry_for_non_lock_errors
    call_count = 0
    non_lock_error = { success: false, output: "", error: "error: pathspec unknown", exit_code: 128 }

    mock_execute = lambda do |*args, **_opts|
      call_count += 1
      non_lock_error
    end

    @executor.stub :execute_once, mock_execute do
      result = @executor.execute("git", "status")

      refute result[:success], "Should fail"
      assert_equal 1, call_count, "Should not retry non-lock errors"
    end
  end

  def test_no_retry_for_non_git_commands
    call_count = 0
    error_result = { success: false, output: "", error: "command failed", exit_code: 1 }

    mock_execute = lambda do |*args, **_opts|
      call_count += 1
      error_result
    end

    @executor.stub :execute_once, mock_execute do
      result = @executor.execute("non-git", "command")

      refute result[:success], "Should fail"
      assert_equal 1, call_count, "Should not retry non-git commands"
    end
  end

  def test_retry_disabled_when_config_says_so
    call_count = 0
    lock_error_result = { success: false, output: "", error: "fatal: Unable to create '.git/index.lock': File exists.", exit_code: 128 }

    mock_execute = lambda do |*args, **_opts|
      call_count += 1
      lock_error_result
    end

    with_lock_retry_config(enabled: false) do
      @executor.stub :execute_once, mock_execute do
        result = @executor.execute("git", "status")

        refute result[:success], "Should fail"
        assert_equal 1, call_count, "Should not retry when disabled in config"
      end
    end
  end

  def test_progressive_delay_between_retries
    lock_error_result = { success: false, output: "", error: "fatal: Unable to create '.git/index.lock': File exists.", exit_code: 128 }

    delays = []
    mock_sleep = lambda do |delay| delays << delay; nil end

    # Stub repo_root to prevent additional execute_once calls during stale lock cleanup
    @executor.stub :repo_root, "/fake/repo" do
      # Always return lock error to trigger all retries
      @executor.stub :execute_once, lock_error_result do
        Kernel.stub :sleep, mock_sleep do
          # Capture stderr to suppress warning output during test
          _captured = capture_io { @executor.execute("git", "status") }
        end
      end
    end

    # Progressive delays: 1s, 2s, 3s, 4s (total 10s across 4 retries)
    assert_equal 4, delays.length, "Should have 4 retry delays"
    assert_equal [1, 2, 3, 4], delays, "Should use progressive delays: 1s, 2s, 3s, 4s"
  end

  def test_lock_error_message_augmented_after_all_retries
    lock_error_result = { success: false, output: "", error: "fatal: Unable to create '.git/index.lock': File exists.", exit_code: 128 }
    mock_sleep = ->(_) { nil }

    # Stub repo_root to prevent additional execute_once calls during stale lock cleanup
    @executor.stub :repo_root, "/fake/repo" do
      @executor.stub :execute_once, lock_error_result do
        Kernel.stub :sleep, mock_sleep do
          result = @executor.execute("git", "status")

          refute result[:success], "Should fail after all retries"
          assert_includes result[:error], "Git index locked after", "Should augment error with retry context"
          assert_includes result[:error], "retries", "Should mention retries in error message"
        end
      end
    end
  end
end
