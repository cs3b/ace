# frozen_string_literal: true

require_relative "../test_helper"
require "minitest/mock"

class FileStagerTest < TestCase
  def setup
    @mock_git = Minitest::Mock.new
    @stager = Ace::GitCommit::Molecules::FileStager.new(@mock_git)
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
    @mock_git.expect :execute, "file1.txt\n", ["diff", "--cached", "--name-only"]

    assert @stager.files_staged?(["file1.txt"]), "Should detect staged file"
    @mock_git.verify
  end

  def test_checks_files_not_staged
    @mock_git.expect :execute, "file1.txt\n", ["diff", "--cached", "--name-only"]

    refute @stager.files_staged?(["file2.txt"]), "Should detect unstaged file"
    @mock_git.verify
  end

  def test_checks_partially_staged_files
    @mock_git.expect :execute, "file1.txt\n", ["diff", "--cached", "--name-only"]

    refute @stager.files_staged?(["file1.txt", "file2.txt"]), "Should detect partially staged"
    @mock_git.verify
  end

  def test_staged_files_returns_empty_array_when_none
    @mock_git.expect :execute, "", ["diff", "--cached", "--name-only"]

    assert_empty @stager.staged_files, "Should return empty array when no files staged"
    @mock_git.verify
  end

  def test_staged_files_returns_list
    @mock_git.expect :execute, "file1.txt\nfile2.txt\n", ["diff", "--cached", "--name-only"]

    staged = @stager.staged_files
    assert_equal ["file1.txt", "file2.txt"], staged
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
end
