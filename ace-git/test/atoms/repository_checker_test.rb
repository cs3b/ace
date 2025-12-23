# frozen_string_literal: true

require_relative "../test_helper"

class RepositoryCheckerTest < AceGitTestCase
  def setup
    super
    @checker = Ace::Git::Atoms::RepositoryChecker
  end

  def test_in_git_repo_returns_boolean
    result = @checker.in_git_repo?
    assert [true, false].include?(result)
  end

  def test_detached_head_returns_boolean
    skip "Not in git repo" unless @checker.in_git_repo?

    result = @checker.detached_head?
    assert [true, false].include?(result)
  end

  def test_bare_repository_returns_boolean
    skip "Not in git repo" unless @checker.in_git_repo?

    result = @checker.bare_repository?
    assert [true, false].include?(result)
  end

  def test_in_worktree_returns_boolean
    skip "Not in git repo" unless @checker.in_git_repo?

    result = @checker.in_worktree?
    assert [true, false].include?(result)
  end

  def test_repository_type_returns_symbol
    result = @checker.repository_type

    assert %i[normal detached bare worktree not_git].include?(result)
  end

  def test_status_description_returns_string
    result = @checker.status_description

    assert_instance_of String, result
    refute_empty result
  end

  def test_usable_returns_boolean
    result = @checker.usable?
    assert [true, false].include?(result)
  end
end
