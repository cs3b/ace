# frozen_string_literal: true

require "test_helper"

class RepositoryCheckerTest < AceGitTestCase
  def setup
    super
    @checker = Ace::Git::Atoms::RepositoryChecker
    @executor = Ace::Git::Atoms::CommandExecutor
  end

  def test_in_git_repo_returns_true
    @executor.stub :in_git_repo?, true do
      result = @checker.in_git_repo?
      assert result, "Should return true when in git repo"
    end
  end

  def test_in_git_repo_returns_false
    @executor.stub :in_git_repo?, false do
      result = @checker.in_git_repo?
      refute result, "Should return false when not in git repo"
    end
  end

  def test_detached_head_returns_true
    # symbolic-ref fails when HEAD is detached
    mock_result = {success: false, output: "", error: "", exit_code: 1}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        result = @checker.detached_head?
        assert result, "Should return true when symbolic-ref fails (detached HEAD)"
      end
    end
  end

  def test_detached_head_returns_false
    # symbolic-ref succeeds when HEAD is not detached
    mock_result = {success: true, output: "", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        result = @checker.detached_head?
        refute result, "Should return false when symbolic-ref succeeds"
      end
    end
  end

  def test_bare_repository_returns_true
    mock_result = {success: true, output: "true\n", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        result = @checker.bare_repository?
        assert result, "Should return true when --is-bare-repository returns true"
      end
    end
  end

  def test_bare_repository_returns_false
    mock_result = {success: true, output: "false\n", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        result = @checker.bare_repository?
        refute result, "Should return false when --is-bare-repository returns false"
      end
    end
  end

  def test_in_worktree_returns_true
    mock_result = {success: true, output: "/path/to/.git/worktrees/my-worktree\n", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        result = @checker.in_worktree?
        assert result, "Should return true when git-dir contains /worktrees/"
      end
    end
  end

  def test_in_worktree_returns_false
    mock_result = {success: true, output: "/path/to/.git\n", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        result = @checker.in_worktree?
        refute result, "Should return false when git-dir does not contain /worktrees/"
      end
    end
  end

  def test_repository_type_returns_normal
    mock_result = {success: true, output: "", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        result = @checker.repository_type
        assert_equal :normal, result, "Should return :normal for normal repository"
      end
    end
  end

  def test_repository_type_returns_detached
    # symbolic-ref fails (detached)
    mock_result = {success: false, output: "", error: "", exit_code: 1}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        result = @checker.repository_type
        assert_equal :detached, result, "Should return :detached when HEAD is detached"
      end
    end
  end

  def test_repository_type_returns_bare
    # Stub based on command arguments
    mock_proc = ->(*args) {
      if args.include?("--is-bare-repository")
        {success: true, output: "true\n", error: "", exit_code: 0}
      else
        {success: true, output: "", error: "", exit_code: 0}
      end
    }

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_proc do
        result = @checker.repository_type
        assert_equal :bare, result, "Should return :bare for bare repository"
      end
    end
  end

  def test_repository_type_returns_worktree
    # Stub based on command arguments
    call_count = 0
    mock_proc = ->(*args) {
      call_count += 1
      if args.include?("--is-bare-repository")
        {success: true, output: "false\n", error: "", exit_code: 0}
      elsif args.include?("--git-dir")
        {success: true, output: "/path/to/.git/worktrees/my-worktree\n", error: "", exit_code: 0}
      else
        {success: true, output: "", error: "", exit_code: 0}
      end
    }

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_proc do
        result = @checker.repository_type
        assert_equal :worktree, result, "Should return :worktree for worktree"
      end
    end
  end

  def test_repository_type_returns_not_git
    @executor.stub :in_git_repo?, false do
      result = @checker.repository_type
      assert_equal :not_git, result, "Should return :not_git when not in git repo"
    end
  end

  def test_status_description_returns_string_for_normal
    mock_result = {success: true, output: "", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        result = @checker.status_description
        assert_equal "normal repository", result
      end
    end
  end

  def test_status_description_returns_string_for_detached
    mock_result = {success: false, output: "", error: "", exit_code: 1}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        result = @checker.status_description
        assert_equal "detached HEAD state", result
      end
    end
  end

  def test_status_description_returns_string_for_bare
    mock_proc = ->(*args) {
      if args.include?("--is-bare-repository")
        {success: true, output: "true\n", error: "", exit_code: 0}
      else
        {success: true, output: "", error: "", exit_code: 0}
      end
    }

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_proc do
        result = @checker.status_description
        assert_equal "bare repository", result
      end
    end
  end

  def test_status_description_returns_string_for_not_git
    @executor.stub :in_git_repo?, false do
      result = @checker.status_description
      assert_equal "not a git repository", result
    end
  end

  def test_usable_returns_true_for_normal_repo
    mock_result = {success: true, output: "false\n", error: "", exit_code: 0}

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_result do
        result = @checker.usable?
        assert result, "Should return true for normal repository"
      end
    end
  end

  def test_usable_returns_false_for_bare_repo
    mock_proc = ->(*args) {
      if args.include?("--is-bare-repository")
        {success: true, output: "true\n", error: "", exit_code: 0}
      else
        {success: true, output: "", error: "", exit_code: 0}
      end
    }

    @executor.stub :in_git_repo?, true do
      @executor.stub :execute, mock_proc do
        result = @checker.usable?
        refute result, "Should return false for bare repository"
      end
    end
  end

  def test_usable_returns_false_when_not_in_git
    @executor.stub :in_git_repo?, false do
      result = @checker.usable?
      refute result, "Should return false when not in git repo"
    end
  end
end
