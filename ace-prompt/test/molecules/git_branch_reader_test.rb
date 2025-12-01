# frozen_string_literal: true

require "test_helper"

class GitBranchReaderTest < Minitest::Test
  def test_current_branch_returns_branch_name
    # This test will work if we're in a git repo
    result = Ace::Prompt::Molecules::GitBranchReader.current_branch

    # Can't assert specific value, but should be string or nil
    assert(result.is_a?(String) || result.nil?)
  end

  def test_current_branch_returns_string_in_git_repo
    # We're running in a git repo, so should get a branch name
    result = Ace::Prompt::Molecules::GitBranchReader.current_branch

    # In this test environment, we should be in a git repo
    assert result.is_a?(String), "Expected string branch name when in git repo"
    refute result.empty?, "Branch name should not be empty"
  end
end
