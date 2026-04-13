# frozen_string_literal: true

require_relative "../../test_helper"
require "minitest/mock"

class FileStagerTest < TestCase
  def setup
    @mock_git = Minitest::Mock.new
    @mock_checker = Minitest::Mock.new
    @stager = Ace::GitCommit::Molecules::FileStager.new(@mock_git, gitignore_checker: @mock_checker)
  end

  def test_stages_specific_files
    @mock_git.expect :execute, nil, ["add", "file1.txt"]

    result = @stager.stage_files(["file1.txt"])

    assert result, "Staging should succeed"
    @mock_git.verify
  end

  def test_stages_multiple_files
    @mock_git.expect :execute, nil, ["add", "file1.txt", "file2.txt"]

    result = @stager.stage_files(["file1.txt", "file2.txt"])

    assert result, "Staging should succeed"
    @mock_git.verify
  end

  def test_stage_all_changes
    @mock_git.expect :execute, nil, ["add", "-A"]

    result = @stager.stage_all

    assert result, "Stage all should succeed"
    @mock_git.verify
  end

  def test_returns_false_for_empty_file_list
    result = @stager.stage_files([])

    refute result, "Should return false for empty list"
  end

  def test_returns_false_for_nil_file_list
    result = @stager.stage_files(nil)

    refute result, "Should return false for nil"
  end

  def test_unstages_specific_files
    @mock_git.expect :execute, nil, ["reset", "HEAD", "file1.txt"]

    result = @stager.unstage_files(["file1.txt"])

    assert result, "Unstaging should succeed"
    @mock_git.verify
  end

  def test_unstage_in_new_repo_without_head
    # First attempt fails (no HEAD), second succeeds with rm --cached
    @mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "fatal: ambiguous argument 'HEAD'"
    end
    @mock_git.expect :execute, nil, ["rm", "--cached", "test.txt"]

    result = @stager.unstage_files(["test.txt"])

    assert result, "Should unstage in new repo using rm --cached"
    @mock_git.verify
  end

  def test_checks_if_files_staged
    @mock_git.expect :execute, "file1.txt\n", ["diff", "--cached", "--name-only", "--no-renames"]

    assert @stager.files_staged?(["file1.txt"]), "Should detect staged file"
    @mock_git.verify
  end

  def test_checks_files_not_staged
    @mock_git.expect :execute, "file1.txt\n", ["diff", "--cached", "--name-only", "--no-renames"]

    refute @stager.files_staged?(["file2.txt"]), "Should detect unstaged file"
    @mock_git.verify
  end

  def test_checks_partially_staged_files
    @mock_git.expect :execute, "file1.txt\n", ["diff", "--cached", "--name-only", "--no-renames"]

    refute @stager.files_staged?(["file1.txt", "file2.txt"]), "Should detect partially staged"
    @mock_git.verify
  end

  def test_staged_files_returns_empty_array_when_none
    @mock_git.expect :execute, "", ["diff", "--cached", "--name-only", "--no-renames"]

    assert_empty @stager.staged_files, "Should return empty array when no files staged"
    @mock_git.verify
  end

  def test_staged_files_returns_list
    @mock_git.expect :execute, "file1.txt\nfile2.txt\n", ["diff", "--cached", "--name-only", "--no-renames"]

    staged = @stager.staged_files
    assert_equal ["file1.txt", "file2.txt"], staged
    @mock_git.verify
  end

  # Regression: Without --no-renames, git collapses rename pairs into single entries,
  # causing deleted files from directory renames to be missing from staged_files.
  # Example: mv old_dir/ new_dir/ would only show new_dir/file.txt, not old_dir/file.txt deletion.
  def test_staged_files_uses_no_renames_flag_for_directory_renames
    # Simulates output when a directory is renamed: both old (deleted) and new paths appear
    @mock_git.expect :execute, "new_dir/file.txt\nold_dir/file.txt\n",
      ["diff", "--cached", "--name-only", "--no-renames"]

    staged = @stager.staged_files

    assert_includes staged, "new_dir/file.txt", "Should include new path"
    assert_includes staged, "old_dir/file.txt", "Should include deleted old path"
    @mock_git.verify
  end

  def test_handles_unicode_filenames
    @mock_git.expect :execute, nil, ["add", "café_文件.txt"]

    result = @stager.stage_files(["café_文件.txt"])

    assert result, "Should stage unicode filename"
    @mock_git.verify
  end

  def test_handles_files_with_spaces
    @mock_git.expect :execute, nil, ["add", "file with spaces.txt"]

    result = @stager.stage_files(["file with spaces.txt"])

    assert result, "Should stage file with spaces"
    @mock_git.verify
  end

  def test_stage_files_handles_errors
    @mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "Permission denied"
    end

    result = @stager.stage_files(["protected.txt"])

    refute result, "Should return false on error"
    assert_match(/Permission denied/, @stager.last_error)
    @mock_git.verify
  end

  def test_stage_all_handles_errors
    @mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "fatal: not a git repository"
    end

    result = @stager.stage_all

    refute result, "Should return false on error"
    assert_match(/not a git repository/, @stager.last_error)
    @mock_git.verify
  end

  def test_clears_last_error_on_success
    # First fail
    @mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "Error"
    end
    @stager.stage_files(["bad.txt"])
    assert @stager.last_error

    # Then succeed
    @mock_git.expect :execute, nil, ["add", "good.txt"]
    @stager.stage_files(["good.txt"])

    assert_nil @stager.last_error, "Should clear last_error on success"
    @mock_git.verify
  end

  # Tests for stage_paths
  def test_stage_paths_resets_and_stages_paths
    @mock_checker.expect :categorize_paths, {valid: ["lib/", "test/"], force_add: [], skipped: []}, [["lib/", "test/"], @mock_git]
    @mock_git.expect :execute, nil, ["reset", "--quiet"]
    @mock_git.expect :execute, nil, ["add", "lib/"]
    @mock_git.expect :execute, nil, ["add", "test/"]

    result = @stager.stage_paths(["lib/", "test/"])

    assert result, "Stage paths should succeed"
    @mock_git.verify
    @mock_checker.verify
  end

  def test_stage_paths_returns_false_for_empty_list
    result = @stager.stage_paths([])

    refute result, "Should return false for empty list"
  end

  def test_stage_paths_returns_false_for_nil
    result = @stager.stage_paths(nil)

    refute result, "Should return false for nil"
  end

  def test_stage_paths_handles_invalid_paths_via_git
    @mock_checker.expect :categorize_paths, {valid: ["nonexistent/"], force_add: [], skipped: []}, [["nonexistent/"], @mock_git]
    @mock_git.expect :execute, nil, ["reset", "--quiet"]
    @mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "pathspec 'nonexistent/' did not match any files"
    end

    result = @stager.stage_paths(["nonexistent/"])

    refute result, "Should return false when git add fails"
    assert_match(/did not match any files/, @stager.last_error)
    @mock_git.verify
    @mock_checker.verify
  end

  def test_stage_paths_handles_git_errors
    @mock_checker.expect :categorize_paths, {valid: ["lib/"], force_add: [], skipped: []}, [["lib/"], @mock_git]
    @mock_git.expect :execute, nil, ["reset", "--quiet"]
    @mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "Permission denied"
    end

    result = @stager.stage_paths(["lib/"])

    refute result, "Should return false on git error"
    assert_match(/Permission denied/, @stager.last_error)
    @mock_git.verify
    @mock_checker.verify
  end

  def test_stage_paths_clears_last_error_on_success
    # First fail with git error (all files pass gitignore check)
    @mock_checker.expect :categorize_paths, {valid: ["bad/"], force_add: [], skipped: []}, [["bad/"], @mock_git]
    @mock_git.expect :execute, nil, ["reset", "--quiet"]
    @mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "error"
    end
    @stager.stage_paths(["bad/"])
    assert @stager.last_error

    # Then succeed
    @mock_checker.expect :categorize_paths, {valid: ["good/"], force_add: [], skipped: []}, [["good/"], @mock_git]
    @mock_git.expect :execute, nil, ["reset", "--quiet"]
    @mock_git.expect :execute, nil, ["add", "good/"]
    @stager.stage_paths(["good/"])

    assert_nil @stager.last_error, "Should clear last_error on success"
    @mock_git.verify
  end

  # Tests for gitignore handling
  def test_stage_paths_skips_untracked_gitignored_files
    # Set up mock to return some skipped files (gitignored and untracked)
    @mock_checker.expect :categorize_paths,
      {valid: ["lib/main.rb"], force_add: [], skipped: [{path: "debug.log", pattern: "*.log"}]},
      [["lib/main.rb", "debug.log"], @mock_git]
    @mock_git.expect :execute, nil, ["reset", "--quiet"]
    @mock_git.expect :execute, nil, ["add", "lib/main.rb"]

    result = @stager.stage_paths(["lib/main.rb", "debug.log"], quiet: true)

    assert result, "Should succeed when some files are gitignored"
    assert_equal 1, @stager.last_skipped_files.length
    assert_equal "debug.log", @stager.last_skipped_files[0][:path]
    refute @stager.all_files_skipped?, "Should not be all skipped when some files are valid"
    @mock_git.verify
    @mock_checker.verify
  end

  def test_stage_paths_force_adds_tracked_gitignored_files
    # Set up mock with force_add files (gitignored but tracked)
    @mock_checker.expect :categorize_paths,
      {valid: [], force_add: [{path: "tracked.log", pattern: "*.log"}], skipped: []},
      [["tracked.log"], @mock_git]
    @mock_git.expect :execute, nil, ["reset", "--quiet"]
    @mock_git.expect :execute, nil, ["add", "-f", "tracked.log"]

    result = @stager.stage_paths(["tracked.log"], quiet: true)

    assert result, "Should succeed when force adding tracked gitignored files"
    assert_empty @stager.last_skipped_files, "Should have no skipped files"
    refute @stager.all_files_skipped?, "Should not be all skipped when force adding"
    @mock_git.verify
    @mock_checker.verify
  end

  def test_stage_paths_returns_success_when_all_files_skipped
    # All files are gitignored and untracked
    @mock_checker.expect :categorize_paths,
      {valid: [], force_add: [], skipped: [{path: "debug.log", pattern: "*.log"}, {path: "temp.txt", pattern: "temp/"}]},
      [["debug.log", "temp.txt"], @mock_git]

    result = @stager.stage_paths(["debug.log", "temp.txt"], quiet: true)

    assert result, "Should succeed when all files are gitignored"
    assert @stager.all_files_skipped?, "Should indicate all files were skipped"
    assert_equal 2, @stager.last_skipped_files.length
    @mock_checker.verify
  end

  def test_stage_paths_outputs_skipped_files_when_not_quiet
    @mock_checker.expect :categorize_paths,
      {valid: ["lib/main.rb"], force_add: [], skipped: [{path: "debug.log", pattern: "*.log"}]},
      [["lib/main.rb", "debug.log"], @mock_git]
    @mock_git.expect :execute, nil, ["reset", "--quiet"]
    @mock_git.expect :execute, nil, ["add", "lib/main.rb"]

    output = capture_io do
      @stager.stage_paths(["lib/main.rb", "debug.log"], quiet: false)
    end

    assert_match(/Skipping gitignored files/, output.last)
    assert_match(/debug.log/, output.last)
    assert_match(/\*\.log/, output.last)
    @mock_git.verify
    @mock_checker.verify
  end

  def test_stage_paths_no_output_when_quiet
    @mock_checker.expect :categorize_paths,
      {valid: ["lib/main.rb"], force_add: [], skipped: [{path: "debug.log", pattern: "*.log"}]},
      [["lib/main.rb", "debug.log"], @mock_git]
    @mock_git.expect :execute, nil, ["reset", "--quiet"]
    @mock_git.expect :execute, nil, ["add", "lib/main.rb"]

    output = capture_io do
      @stager.stage_paths(["lib/main.rb", "debug.log"], quiet: true)
    end

    refute_match(/Skipping gitignored files/, output.last)
    @mock_git.verify
    @mock_checker.verify
  end

  def test_all_files_skipped_returns_false_when_no_files_skipped
    @mock_checker.expect :categorize_paths,
      {valid: ["lib/main.rb"], force_add: [], skipped: []},
      [["lib/main.rb"], @mock_git]
    @mock_git.expect :execute, nil, ["reset", "--quiet"]
    @mock_git.expect :execute, nil, ["add", "lib/main.rb"]

    @stager.stage_paths(["lib/main.rb"], quiet: true)

    refute @stager.all_files_skipped?, "Should be false when no files were skipped"
    @mock_git.verify
    @mock_checker.verify
  end

  def test_stage_paths_handles_mixed_valid_force_add_and_skipped
    @mock_checker.expect :categorize_paths,
      {valid: ["lib/main.rb"], force_add: [{path: "tracked.log", pattern: "*.log"}], skipped: [{path: "untracked.log", pattern: "*.log"}]},
      [["lib/main.rb", "tracked.log", "untracked.log"], @mock_git]
    @mock_git.expect :execute, nil, ["reset", "--quiet"]
    @mock_git.expect :execute, nil, ["add", "lib/main.rb"]
    @mock_git.expect :execute, nil, ["add", "-f", "tracked.log"]

    result = @stager.stage_paths(["lib/main.rb", "tracked.log", "untracked.log"], quiet: true)

    assert result, "Should succeed with mixed files"
    assert_equal 1, @stager.last_skipped_files.length
    assert_equal "untracked.log", @stager.last_skipped_files[0][:path]
    refute @stager.all_files_skipped?, "Should not be all skipped when some files are valid"
    @mock_git.verify
    @mock_checker.verify
  end
end
