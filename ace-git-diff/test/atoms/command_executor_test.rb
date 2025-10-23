# frozen_string_literal: true

require "test_helper"

class CommandExecutorTest < AceGitDiffTestCase
  def setup
    super
    @executor = Ace::GitDiff::Atoms::CommandExecutor
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
end
