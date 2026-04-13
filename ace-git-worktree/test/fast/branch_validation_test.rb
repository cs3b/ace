# frozen_string_literal: true

require_relative "../test_helper"

class BranchValidationTest < Minitest::Test
  def setup
    @creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new
  end

  def test_branch_validation_allows_slash_characters
    # Test that branch validation properly allows / characters (critical for review feedback)
    slash_branches = [
      "feature/login",
      "feature/auth/oauth-flow",
      "bugfix/issue-123/security-patch",
      "hotfix/v1.0.0/patch",
      "hotfix/critical/security-update",
      "epic/user-management/permissions",
      "team/frontend/component-library"
    ]

    slash_branches.each do |slash_branch|
      # Use reflection to test private method
      result = @creator.send(:valid_branch_name?, slash_branch)
      assert result, "Should accept branch with slash: #{slash_branch}"
    end
  end

  def test_branch_validation_allows_main_and_master
    # Test that branch validation allows main and master (critical for review feedback)
    mainline_branches = ["main", "master"]

    mainline_branches.each do |mainline_branch|
      result = @creator.send(:valid_branch_name?, mainline_branch)
      assert result, "Should accept mainline branch: #{mainline_branch}"
    end
  end

  def test_branch_validation_still_blocks_truly_invalid_patterns
    # Test that branch validation still blocks actually invalid patterns
    invalid_branches = [
      "",                    # Empty
      "branch..name",        # Double dots
      "@{ref}",              # Starts with @{
      "branch name",         # Contains whitespace
      "branch~name",         # Contains ~
      "branch^name",         # Contains ^
      "branch:name",         # Contains :
      "branch?name",         # Contains ?
      "branch*name",         # Contains *
      "branch[name",         # Contains [
      "branch]name",         # Contains ]
      "branch.name.",        # Ends with .
      "branch.lock",         # Ends with .lock
      ".git/refs/heads"      # Contains .git
    ]

    invalid_branches.each do |invalid_branch|
      result = @creator.send(:valid_branch_name?, invalid_branch)
      refute result, "Should reject invalid branch: #{invalid_branch}"
    end
  end
end
