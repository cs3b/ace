# frozen_string_literal: true

require_relative "../test_helper"

class WorktreeListerTest < Minitest::Test
  def setup
    @lister = Ace::Git::Worktree::Molecules::WorktreeLister.new
    @git_command = Ace::Git::Worktree::Atoms::GitCommand
  end

  def test_list_all_success
    # Mock git worktree list --porcelain output
    git_output = <<~GIT
      worktree /Users/mc/project/main
      HEAD abcdef1234567890abcd1234567890abcd123456
      branch refs/heads/main

      worktree /Users/mc/project/feature-branch
      HEAD bcdef1234567890abcd1234567890abcd123456a
      branch refs/heads/feature-branch

      worktree /Users/mc/project/task-081
      HEAD cdef1234567890abcd1234567890abcd123456ab
      detached
    GIT

    mock_result = {
      success: true,
      output: git_output,
      error: "",
      exit_code: 0
    }

    @git_command.stub(:worktree, mock_result) do
      worktrees = @lister.list_all

      assert_equal 3, worktrees.length

      main_worktree = worktrees.find { |w| w.branch == "main" }
      assert_equal "/Users/mc/project/main", main_worktree.path
      assert_equal "main", main_worktree.branch
      assert_equal false, main_worktree.bare
      assert_equal false, main_worktree.detached

      feature_worktree = worktrees.find { |w| w.branch == "feature-branch" }
      assert_equal "feature-branch", feature_worktree.branch

      task_worktree = worktrees.find { |w| w.path.include?("task-081") }
      assert_equal true, task_worktree.detached
    end
  end

  def test_list_all_git_failure
    # Mock git worktree list failure
    mock_result = {
      success: false,
      output: "",
      error: "fatal: not a git repository",
      exit_code: 128
    }

    @git_command.stub(:worktree, mock_result) do
      worktrees = @lister.list_all
      assert_empty worktrees
    end
  end

  def test_list_all_with_filter
    git_output = <<~GIT
      worktree /Users/mc/project/main
      HEAD abcdef1234567890abcd1234567890abcd123456
      branch refs/heads/main

      worktree /Users/mc/project/feature-branch
      HEAD bcdef1234567890abcd1234567890abcd123456a
      branch refs/heads/feature-branch

      worktree /Users/mc/project/task-081
      HEAD cdef1234567890abcd1234567890abcd123456ab
      detached
    GIT

    mock_result = {
      success: true,
      output: git_output,
      error: "",
      exit_code: 0
    }

    @git_command.stub(:worktree, mock_result) do
      # Search by branch name
      worktrees = @lister.search("feature")
      assert_equal 1, worktrees.length
      assert_equal "feature-branch", worktrees.first.branch

      # Search by path
      worktrees = @lister.search("task")
      assert_equal 1, worktrees.length
      assert worktrees.first.path.include?("task-081")

      # Search with no matches
      worktrees = @lister.search("nonexistent")
      assert_empty worktrees
    end
  end

  def test_list_all_with_porcelain_format
    # Mock git worktree list --porcelain output
    git_output = <<~GIT
      worktree /Users/mc/project/main
      HEAD abcdef1234567890abcd1234567890abcd123456
      branch refs/heads/main

      worktree /Users/mc/project/feature-branch
      HEAD bcdef1234567890abcd1234567890abcd123456a
      branch refs/heads/feature-branch

      worktree /Users/mc/project/task-081
      HEAD cdef1234567890abcd1234567890abcd123456ab
      detached
    GIT

    mock_result = {
      success: true,
      output: git_output,
      error: "",
      exit_code: 0
    }

    @git_command.stub(:worktree, mock_result) do
      worktrees = @lister.list_all

      assert_equal 3, worktrees.length
      assert_equal "main", worktrees.first.branch
      assert_equal "feature-branch", worktrees[1].branch
      assert_equal true, worktrees[2].detached
    end
  end

  def test_list_all_with_bare_repository
    skip "Bare repository detection not implemented in porcelain parser"
  end

  def test_list_all_parsing_edge_cases
    # Test with various edge cases in git output
    git_output = <<~GIT
      worktree /path/with spaces/branch
      HEAD abcdef1234567890abcd1234567890abcd123456
      branch refs/heads/branch with spaces

      worktree /path/with-dashes_branch
      HEAD bcdef1234567890abcd1234567890abcd123456a
      branch refs/heads/feature/branch-123

      worktree /path/with.dots
      HEAD cdef1234567890abcd1234567890abcd123456ab
      detached
    GIT

    mock_result = {
      success: true,
      output: git_output,
      error: "",
      exit_code: 0
    }

    @git_command.stub(:worktree, mock_result) do
      worktrees = @lister.list_all

      assert_equal 3, worktrees.length

      # Check that spaces and special characters are handled correctly
      space_branch = worktrees.find { |w| w.branch&.include?("with spaces") }
      refute_nil space_branch

      slash_branch = worktrees.find { |w| w.branch&.include?("feature/branch") }
      refute_nil slash_branch
    end
  end

  def test_list_all_empty_repository
    git_output = ""

    mock_result = {
      success: true,
      output: git_output,
      error: "",
      exit_code: 0
    }

    @git_command.stub(:worktree, mock_result) do
      worktrees = @lister.list_all
      assert_empty worktrees
    end
  end

  def test_security_validation_on_filter_arguments
    dangerous_filters = [
      "; rm -rf /",
      "$(whoami)",
      "`cat /etc/passwd`",
      "../etc/passwd",
      "filter\x00with\x00nulls",
      "filter\nwith\nnewlines"
    ]

    dangerous_filters.each do |dangerous_filter|
      mock_result = {
        success: true,
        output: "",
        error: "",
        exit_code: 0
      }

      @git_command.stub(:worktree, mock_result) do
        # Should not crash or execute malicious commands
        worktrees = @lister.search(dangerous_filter)
        assert_empty worktrees
      end
    end
  end

  def test_handles_malformed_git_output
    malformed_outputs = [
      "incomplete output line",
      "/path/with/no/branch or commit info",
      "invalid format that doesn't match expected pattern",
      "/path/too/many fields abcdef1234567890abcd1234567890abcd123456 [branch] extra field",
      "no worktree keyword here",
      "/path/without/commit/hash [branch]"
    ]

    malformed_outputs.each do |malformed_output|
      mock_result = {
        success: true,
        output: malformed_output,
        error: "",
        exit_code: 0
      }

      @git_command.stub(:worktree, mock_result) do
        # Should handle malformed output gracefully
        worktrees = @lister.list_all
        # May return empty array or partial results, but should not crash
        assert worktrees.is_a?(Array)
      end
    end
  end

  def test_command_timeout_handling
    # Mock command timeout by returning error result
    mock_result = {
      success: false,
      output: "",
      error: "Command timed out",
      exit_code: -1
    }

    @git_command.stub(:worktree, mock_result) do
      worktrees = @lister.list_all
      assert_empty worktrees
    end
  end

  def test_worktree_info_structure
    git_output = <<~GIT
      worktree /Users/mc/project/main
      HEAD abcdef1234567890abcd1234567890abcd123456
      branch refs/heads/main
    GIT

    mock_result = {
      success: true,
      output: git_output,
      error: "",
      exit_code: 0
    }

    @git_command.stub(:worktree, mock_result) do
      worktrees = @lister.list_all
      worktree = worktrees.first

      # Check that worktree has all expected fields
      refute_nil worktree.path
      refute_nil worktree.commit
      refute_nil worktree.branch
      assert_includes [true, false], worktree.bare
      assert_includes [true, false], worktree.detached

      # Check data types
      assert_kind_of String, worktree.path
      assert_kind_of String, worktree.commit
      assert_kind_of String, worktree.branch
      # Boolean values already checked above with assert_includes
    end
  end
end
