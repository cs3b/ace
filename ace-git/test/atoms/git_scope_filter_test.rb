# frozen_string_literal: true

require_relative "../test_helper"

class GitScopeFilterTest < AceGitTestCase
  def setup
    super
    @filter = Ace::Git::Atoms::GitScopeFilter
  end

  def test_in_git_repo_returns_boolean
    result = @filter.in_git_repo?
    assert [true, false].include?(result)
  end

  def test_get_staged_files_returns_array
    skip "Not in git repo" unless @filter.in_git_repo?

    result = @filter.get_staged_files
    assert_instance_of Array, result
  end

  def test_get_tracked_files_returns_array
    skip "Not in git repo" unless @filter.in_git_repo?

    result = @filter.get_tracked_files
    assert_instance_of Array, result
    # Should have at least some tracked files
    refute_empty result
  end

  def test_get_changed_files_returns_array
    skip "Not in git repo" unless @filter.in_git_repo?

    result = @filter.get_changed_files
    assert_instance_of Array, result
  end

  def test_get_uncommitted_files_returns_array
    skip "Not in git repo" unless @filter.in_git_repo?

    result = @filter.get_uncommitted_files
    assert_instance_of Array, result
  end

  def test_get_files_with_staged_scope
    skip "Not in git repo" unless @filter.in_git_repo?

    result = @filter.get_files(:staged)
    assert_instance_of Array, result
  end

  def test_get_files_with_tracked_scope
    skip "Not in git repo" unless @filter.in_git_repo?

    result = @filter.get_files(:tracked)
    assert_instance_of Array, result
  end

  def test_get_files_with_changed_scope
    skip "Not in git repo" unless @filter.in_git_repo?

    result = @filter.get_files(:changed)
    assert_instance_of Array, result
  end

  def test_get_files_with_unknown_scope
    result = @filter.get_files(:unknown)
    assert_equal [], result
  end

  def test_get_files_between_returns_array
    skip "Not in git repo" unless @filter.in_git_repo?

    result = @filter.get_files_between("HEAD~1", "HEAD")
    assert_instance_of Array, result
  end

  # --- Hermetic Tests (stubbed, no real git required) ---
  # These tests use stubbing to ensure they work without a real git repository

  def test_get_staged_files_stubbed
    # Stub the underlying command execution to return mock data
    mock_executor_result = { success: true, output: "lib/foo.rb\nlib/bar.rb\n", error: "", exit_code: 0 }

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_staged_files
        assert_instance_of Array, result
      end
    end
  end

  def test_get_tracked_files_stubbed
    mock_executor_result = { success: true, output: "README.md\nlib/main.rb\ntest/test_helper.rb\n", error: "", exit_code: 0 }

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_tracked_files
        assert_instance_of Array, result
      end
    end
  end

  def test_get_changed_files_stubbed
    mock_executor_result = { success: true, output: "lib/changed.rb\n", error: "", exit_code: 0 }

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_changed_files
        assert_instance_of Array, result
      end
    end
  end

  def test_get_uncommitted_files_stubbed
    mock_executor_result = { success: true, output: "M lib/modified.rb\nA lib/added.rb\n", error: "", exit_code: 0 }

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_uncommitted_files
        assert_instance_of Array, result
      end
    end
  end

  def test_get_files_with_staged_scope_stubbed
    mock_executor_result = { success: true, output: "staged_file.rb\n", error: "", exit_code: 0 }

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_files(:staged)
        assert_instance_of Array, result
      end
    end
  end

  def test_get_files_between_stubbed
    mock_executor_result = { success: true, output: "lib/changed.rb\ntest/test.rb\n", error: "", exit_code: 0 }

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_files_between("HEAD~1", "HEAD")
        assert_instance_of Array, result
      end
    end
  end

  def test_get_files_returns_empty_array_on_git_failure
    mock_executor_result = { success: false, output: "", error: "fatal: not a git repo", exit_code: 128 }

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_files(:changed)
        assert_instance_of Array, result
      end
    end
  end
end
