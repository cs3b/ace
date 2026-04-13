# frozen_string_literal: true

require "test_helper"

class GitScopeFilterTest < AceGitTestCase
  def setup
    super
    @filter = Ace::Git::Atoms::GitScopeFilter
  end

  def test_in_git_repo_returns_boolean
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      result = @filter.in_git_repo?
      assert result, "Should return true when in git repo"
    end
  end

  def test_get_staged_files_stubbed
    mock_executor_result = {success: true, output: "lib/foo.rb\nlib/bar.rb\n", error: "", exit_code: 0}

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_staged_files
        assert_instance_of Array, result
      end
    end
  end

  def test_get_tracked_files_stubbed
    mock_executor_result = {success: true, output: "README.md\nlib/main.rb\ntest/test_helper.rb\n", error: "", exit_code: 0}

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_tracked_files
        assert_instance_of Array, result
      end
    end
  end

  def test_get_changed_files_stubbed
    mock_executor_result = {success: true, output: "lib/changed.rb\n", error: "", exit_code: 0}

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_changed_files
        assert_instance_of Array, result
      end
    end
  end

  def test_get_uncommitted_files_stubbed
    mock_executor_result = {success: true, output: "M lib/modified.rb\nA lib/added.rb\n", error: "", exit_code: 0}

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_uncommitted_files
        assert_instance_of Array, result
      end
    end
  end

  def test_get_files_with_staged_scope_stubbed
    mock_executor_result = {success: true, output: "staged_file.rb\n", error: "", exit_code: 0}

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_files(:staged)
        assert_instance_of Array, result
      end
    end
  end

  def test_get_files_with_tracked_scope_stubbed
    mock_executor_result = {success: true, output: "file1.rb\nfile2.rb\n", error: "", exit_code: 0}

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_files(:tracked)
        assert_instance_of Array, result
      end
    end
  end

  def test_get_files_with_changed_scope_stubbed
    mock_executor_result = {success: true, output: "changed.rb\n", error: "", exit_code: 0}

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_files(:changed)
        assert_instance_of Array, result
      end
    end
  end

  def test_get_files_with_unknown_scope
    result = @filter.get_files(:unknown)
    assert_equal [], result, "Should return empty array for unknown scope"
  end

  def test_get_files_between_stubbed
    mock_executor_result = {success: true, output: "lib/changed.rb\ntest/test.rb\n", error: "", exit_code: 0}

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_files_between("HEAD~1", "HEAD")
        assert_instance_of Array, result
      end
    end
  end

  def test_get_files_returns_empty_array_on_git_failure
    mock_executor_result = {success: false, output: "", error: "fatal: not a git repo", exit_code: 128}

    Ace::Git::Atoms::CommandExecutor.stub :execute, mock_executor_result do
      @filter.stub :in_git_repo?, true do
        result = @filter.get_files(:changed)
        assert_instance_of Array, result
        assert_empty result, "Should return empty array on git failure"
      end
    end
  end
end
