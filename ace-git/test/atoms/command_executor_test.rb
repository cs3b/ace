# frozen_string_literal: true

require_relative "../test_helper"

class CommandExecutorTest < AceGitTestCase
  def setup
    super
    @executor = Ace::Git::Atoms::CommandExecutor
  end

  def test_execute_returns_hash_with_expected_keys
    result = @executor.execute("echo", "test")

    assert_instance_of Hash, result
    assert result.key?(:success)
    assert result.key?(:output)
    assert result.key?(:error)
    assert result.key?(:exit_code)
  end

  def test_execute_successful_command
    result = @executor.execute("echo", "hello")

    assert result[:success]
    assert_includes result[:output], "hello"
    assert_equal 0, result[:exit_code]
  end

  def test_execute_failed_command
    result = @executor.execute("false")

    refute result[:success]
    assert_equal 1, result[:exit_code]
  end

  def test_in_git_repo_returns_boolean
    result = @executor.in_git_repo?
    assert [true, false].include?(result)
  end

  def test_current_branch_returns_string_or_nil
    skip "Not in git repo" unless @executor.in_git_repo?

    result = @executor.current_branch
    assert result.nil? || result.is_a?(String)
  end

  def test_repo_root_returns_string_or_nil
    skip "Not in git repo" unless @executor.in_git_repo?

    result = @executor.repo_root
    assert result.nil? || result.is_a?(String)
    assert Dir.exist?(result) if result
  end

  def test_has_unstaged_changes_returns_boolean
    skip "Not in git repo" unless @executor.in_git_repo?

    result = @executor.has_unstaged_changes?
    assert [true, false].include?(result)
  end

  def test_has_staged_changes_returns_boolean
    skip "Not in git repo" unless @executor.in_git_repo?

    result = @executor.has_staged_changes?
    assert [true, false].include?(result)
  end

  def test_changed_files_returns_array
    skip "Not in git repo" unless @executor.in_git_repo?

    result = @executor.changed_files("HEAD~1..HEAD")
    assert_instance_of Array, result
  end

  def test_git_diff_returns_string
    skip "Not in git repo" unless @executor.in_git_repo?

    result = @executor.git_diff("HEAD~1..HEAD")
    assert_instance_of String, result
  end

  def test_execute_handles_errors_gracefully
    result = @executor.execute("nonexistent_command_xyz")

    refute result[:success]
    assert_equal(-1, result[:exit_code])
    assert_instance_of String, result[:error]
  end

  def test_execute_accepts_custom_timeout
    # Should complete quickly with short timeout
    result = @executor.execute("echo", "test", timeout: 5)

    assert result[:success]
    assert_includes result[:output], "test"
  end

  def test_execute_uses_config_default_timeout
    # git_timeout method reads from config (per ADR-022)
    assert_equal 30, Ace::Git.git_timeout
  end

  def test_execute_returns_timeout_error_with_custom_timeout_value
    # Use a very short timeout that will fail
    result = @executor.execute("sleep", "10", timeout: 1)

    refute result[:success]
    assert_includes result[:error], "1 seconds"
    assert_equal(-1, result[:exit_code])
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

  def test_repo_root_with_stubbed_response
    mock_result = { success: true, output: "/path/to/repo\n", error: "", exit_code: 0 }

    @executor.stub :execute, mock_result do
      result = @executor.repo_root
      assert_equal "/path/to/repo", result
    end
  end

  def test_repo_root_stubbed_failure
    mock_result = { success: false, output: "", error: "not a git repo", exit_code: 128 }

    @executor.stub :execute, mock_result do
      result = @executor.repo_root
      assert_nil result, "Should return nil on failure"
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

  def test_changed_files_stubbed_failure
    mock_result = { success: false, output: "", error: "error", exit_code: 1 }

    @executor.stub :execute, mock_result do
      result = @executor.changed_files("HEAD..HEAD")
      assert_equal [], result, "Should return empty array on failure"
    end
  end
end
