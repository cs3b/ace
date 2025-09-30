# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

class FileStagerTest < TestCase
  def setup
    @temp_dir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)

    # Initialize git repo
    `git init -q`
    `git config user.name "Test User"`
    `git config user.email "test@example.com"`

    @git = Ace::GitCommit::Atoms::GitExecutor.new
    @stager = Ace::GitCommit::Molecules::FileStager.new(@git)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  def test_stages_specific_files
    File.write("file1.txt", "content1")
    File.write("file2.txt", "content2")

    result = @stager.stage_files(["file1.txt"])

    assert result, "Staging should succeed"
    assert_includes @stager.staged_files, "file1.txt"
    refute_includes @stager.staged_files, "file2.txt"
  end

  def test_stages_multiple_files
    File.write("file1.txt", "content1")
    File.write("file2.txt", "content2")
    File.write("file3.txt", "content3")

    result = @stager.stage_files(["file1.txt", "file2.txt"])

    assert result, "Staging should succeed"
    assert_includes @stager.staged_files, "file1.txt"
    assert_includes @stager.staged_files, "file2.txt"
    refute_includes @stager.staged_files, "file3.txt"
  end

  def test_stage_all_changes
    File.write("file1.txt", "content1")
    File.write("file2.txt", "content2")
    FileUtils.mkdir_p("subdir")
    File.write("subdir/file3.txt", "content3")

    result = @stager.stage_all

    assert result, "Stage all should succeed"
    staged = @stager.staged_files
    assert_includes staged, "file1.txt"
    assert_includes staged, "file2.txt"
    assert_includes staged, "subdir/file3.txt"
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
    File.write("file1.txt", "content1")
    File.write("file2.txt", "content2")

    @stager.stage_all

    result = @stager.unstage_files(["file1.txt"])

    assert result, "Unstaging should succeed"
    refute_includes @stager.staged_files, "file1.txt"
    assert_includes @stager.staged_files, "file2.txt"
  end

  def test_unstage_in_new_repo_without_head
    # New repo with no commits (no HEAD)
    File.write("test.txt", "content")
    @stager.stage_files(["test.txt"])

    result = @stager.unstage_files(["test.txt"])

    assert result, "Should unstage in new repo using rm --cached"
    refute_includes @stager.staged_files, "test.txt"
  end

  def test_checks_if_files_staged
    File.write("file1.txt", "content1")
    File.write("file2.txt", "content2")

    @stager.stage_files(["file1.txt"])

    assert @stager.files_staged?(["file1.txt"]), "Should detect staged file"
    refute @stager.files_staged?(["file2.txt"]), "Should detect unstaged file"
    refute @stager.files_staged?(["file1.txt", "file2.txt"]), "Should detect partially staged"
  end

  def test_staged_files_returns_empty_array_when_none
    assert_empty @stager.staged_files, "Should return empty array when no files staged"
  end

  def test_handles_unicode_filenames
    filename = "café_文件.txt"
    File.write(filename, "content")

    result = @stager.stage_files([filename])

    assert result, "Should stage unicode filename"
    assert_includes @stager.staged_files, filename
  end

  def test_handles_files_with_spaces
    filename = "file with spaces.txt"
    File.write(filename, "content")

    result = @stager.stage_files([filename])

    assert result, "Should stage file with spaces"
    assert_includes @stager.staged_files, filename
  end

  def test_handles_symlinks
    File.write("target.txt", "content")
    FileUtils.ln_s("target.txt", "link.txt")

    result = @stager.stage_files(["link.txt"])

    assert result, "Should stage symlink"
    # Git stages the symlink itself, not the target
    assert_includes @stager.staged_files, "link.txt"
  end

  def test_staging_from_deep_directory
    # Create deep directory structure (5 levels)
    deep_dir = File.join(@temp_dir, *Array.new(5) { "level" })
    FileUtils.mkdir_p(deep_dir)

    File.write("test.txt", "content")

    # Change to deep directory
    Dir.chdir(deep_dir)

    # Create stager from deep directory
    git = Ace::GitCommit::Atoms::GitExecutor.new
    stager = Ace::GitCommit::Molecules::FileStager.new(git)

    result = stager.stage_files(["../../../../../test.txt"])

    assert result, "Should stage from deep directory"
  end

  def test_handles_long_paths
    # Create deep directory structure with long paths (>200 chars)
    parts = Array.new(10) { "very_long_directory_name_that_contributes_to_path_length" }
    long_dir = File.join(@temp_dir, *parts)
    FileUtils.mkdir_p(long_dir)

    filename = File.join(long_dir.sub(@temp_dir + "/", ""), "file.txt")
    File.write(File.join(@temp_dir, filename), "content")

    result = @stager.stage_files([filename])

    assert result, "Should handle long paths"
    assert_includes @stager.staged_files, filename
  end

  def test_stages_deleted_files
    File.write("test.txt", "content")
    @stager.stage_files(["test.txt"])

    # Commit the file first
    `git commit -m "initial" -q`

    # Delete and stage deletion
    FileUtils.rm("test.txt")
    result = @stager.stage_all

    assert result, "Should stage deletion"
    # Staged files will show the deletion
    diff = `git diff --cached --name-status`.strip
    assert_match(/D\s+test\.txt/, diff, "Should show deletion in staged changes")
  end
end
