# frozen_string_literal: true

require_relative "../../test_helper"
require "minitest/mock"

class GitignoreCheckerTest < TestCase
  def setup
    @checker = Ace::GitCommit::Atoms::GitignoreChecker.new
  end

  # Tests for ignored?
  def test_ignored_returns_true_for_gitignored_file
    mock_git = Minitest::Mock.new
    # git check-ignore -v returns output when file IS ignored
    mock_git.expect :execute, ".gitignore:3:.gitignore:pattern    path/to/file.txt", ["check-ignore", "-v", "path/to/file.txt"]

    result = @checker.ignored?("path/to/file.txt", mock_git)

    assert result, "Should return true for gitignored file"
    mock_git.verify
  end

  def test_ignored_returns_false_for_non_gitignored_file
    mock_git = Minitest::Mock.new
    # git check-ignore raises GitError (exit 1) when file is NOT ignored
    mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "exit 1"
    end

    result = @checker.ignored?("path/to/file.txt", mock_git)

    refute result, "Should return false for non-gitignored file"
    mock_git.verify
  end

  # Tests for tracked?
  def test_tracked_returns_true_for_tracked_file
    mock_git = Minitest::Mock.new
    mock_git.expect :execute, "path/to/file.txt\n", ["ls-files", "--error-unmatch", "path/to/file.txt"]

    result = @checker.tracked?("path/to/file.txt", mock_git)

    assert result, "Should return true for tracked file"
    mock_git.verify
  end

  def test_tracked_returns_false_for_untracked_file
    mock_git = Minitest::Mock.new
    mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "exit 1"
    end

    result = @checker.tracked?("path/to/file.txt", mock_git)

    refute result, "Should return false for untracked file"
    mock_git.verify
  end

  # Tests for categorize_paths
  def test_categorize_paths_separates_valid_force_add_and_skipped
    mock_git = Minitest::Mock.new

    # First file: NOT gitignored -> valid
    mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "exit 1"
    end

    # Second file: gitignored but TRACKED -> force_add
    mock_git.expect :execute, ".gitignore:1:.gitignore:*.log    tracked.log", ["check-ignore", "-v", "tracked.log"]
    mock_git.expect :execute, "tracked.log\n", ["ls-files", "--error-unmatch", "tracked.log"]

    # Third file: gitignored and NOT tracked -> skipped
    mock_git.expect :execute, ".gitignore:1:.gitignore:*.log    untracked.log", ["check-ignore", "-v", "untracked.log"]
    mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "exit 1"
    end

    result = @checker.categorize_paths(["src/main.rb", "tracked.log", "untracked.log"], mock_git)

    assert_equal ["src/main.rb"], result[:valid]
    assert_equal 1, result[:force_add].length
    assert_equal "tracked.log", result[:force_add][0][:path]
    assert_equal 1, result[:skipped].length
    assert_equal "untracked.log", result[:skipped][0][:path]
    mock_git.verify
  end

  def test_categorize_paths_returns_empty_for_nil_input
    result = @checker.categorize_paths(nil, nil)

    assert_equal [], result[:valid]
    assert_equal [], result[:force_add]
    assert_equal [], result[:skipped]
  end

  def test_categorize_paths_returns_empty_for_empty_input
    result = @checker.categorize_paths([], nil)

    assert_equal [], result[:valid]
    assert_equal [], result[:force_add]
    assert_equal [], result[:skipped]
  end

  def test_categorize_paths_all_files_valid
    mock_git = Minitest::Mock.new
    # All files are NOT ignored
    3.times do
      mock_git.expect :execute, nil do |*args|
        raise Ace::GitCommit::GitError, "exit 1"
      end
    end

    result = @checker.categorize_paths(["a.txt", "b.txt", "c.txt"], mock_git)

    assert_equal ["a.txt", "b.txt", "c.txt"], result[:valid]
    assert_equal [], result[:force_add]
    assert_equal [], result[:skipped]
    mock_git.verify
  end

  def test_categorize_paths_all_files_gitignored_and_untracked
    mock_git = Minitest::Mock.new
    # All files are ignored and untracked
    2.times do |i|
      file = "#{["a", "b"][i]}.log"
      mock_git.expect :execute, ".gitignore:1:.gitignore:*.log    #{file}", ["check-ignore", "-v", file]
      mock_git.expect :execute, nil do |*args|
        raise Ace::GitCommit::GitError, "exit 1"
      end
    end

    result = @checker.categorize_paths(["a.log", "b.log"], mock_git)

    assert_equal [], result[:valid]
    assert_equal [], result[:force_add]
    assert_equal 2, result[:skipped].length
    mock_git.verify
  end

  def test_categorize_paths_all_files_gitignored_but_tracked
    mock_git = Minitest::Mock.new
    # All files are ignored but tracked (force add)
    2.times do |i|
      file = "#{["a", "b"][i]}.log"
      mock_git.expect :execute, ".gitignore:1:.gitignore:*.log    #{file}", ["check-ignore", "-v", file]
      mock_git.expect :execute, "#{file}\n", ["ls-files", "--error-unmatch", file]
    end

    result = @checker.categorize_paths(["a.log", "b.log"], mock_git)

    assert_equal [], result[:valid]
    assert_equal 2, result[:force_add].length
    assert_equal [], result[:skipped]
    mock_git.verify
  end

  # Tests for filter_ignored (backward compatibility)
  def test_filter_ignored_includes_force_add_in_valid
    mock_git = Minitest::Mock.new

    # File is gitignored but tracked -> goes to force_add, but filter_ignored includes it in valid
    mock_git.expect :execute, ".gitignore:1:.gitignore:*.log    tracked.log", ["check-ignore", "-v", "tracked.log"]
    mock_git.expect :execute, "tracked.log\n", ["ls-files", "--error-unmatch", "tracked.log"]

    # File is gitignored and not tracked -> skipped
    mock_git.expect :execute, ".gitignore:1:.gitignore:*.log    untracked.log", ["check-ignore", "-v", "untracked.log"]
    mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "exit 1"
    end

    result = @checker.filter_ignored(["tracked.log", "untracked.log"], mock_git)

    assert_includes result[:valid], "tracked.log", "Force-add files should be in valid array"
    assert_equal 1, result[:ignored].length
    assert_equal "untracked.log", result[:ignored][0][:path]
    mock_git.verify
  end

  # Tests for extract_pattern
  def test_extract_pattern_parses_verbose_output
    output = ".gitignore:3:.ace-task/**/reviews/\t.ace-task/v.0.9.0/reviews/review-report-gpro.md"
    pattern = @checker.send(:extract_pattern, output)

    assert_equal ".ace-task/**/reviews/", pattern
  end

  def test_extract_pattern_returns_nil_for_empty_output
    pattern = @checker.send(:extract_pattern, "")

    assert_nil pattern
  end

  def test_extract_pattern_returns_nil_for_nil_output
    pattern = @checker.send(:extract_pattern, nil)

    assert_nil pattern
  end
end
