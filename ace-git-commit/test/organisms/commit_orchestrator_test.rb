# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

class CommitOrchestratorTest < TestCase
  def setup
    @temp_dir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)

    # Initialize git repo
    `git init -q`
    `git config user.name "Test User"`
    `git config user.email "test@example.com"`

    @orchestrator = Ace::GitCommit::Organisms::CommitOrchestrator.new
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  def test_validates_git_repository
    Dir.chdir(@original_dir)

    error = assert_raises(Ace::GitCommit::GitError) do
      @orchestrator.execute(create_options)
    end

    assert_match(/not in a git repository/i, error.message)
  end

  def test_returns_false_when_no_changes
    Dir.chdir(@temp_dir)

    result = @orchestrator.execute(create_options(message: "test"))

    refute result, "Should return false when no changes to commit"
  end

  def test_commits_with_direct_message
    Dir.chdir(@temp_dir)

    File.write("test.txt", "content")
    `git add test.txt`

    result = @orchestrator.execute(create_options(message: "feat: add test file"))

    assert result, "Commit should succeed"
    assert_equal "feat: add test file", `git log -1 --pretty=%B`.strip
  end

  def test_stages_specific_files
    Dir.chdir(@temp_dir)

    File.write("file1.txt", "content1")
    File.write("file2.txt", "content2")

    result = @orchestrator.execute(
      create_options(
        files: ["file1.txt"],
        message: "feat: add file1"
      )
    )

    assert result, "Commit should succeed"
    committed_files = `git diff-tree --no-commit-id --name-only -r HEAD`.strip.split("\n")
    assert_includes committed_files, "file1.txt"
    refute_includes committed_files, "file2.txt"
  end

  def test_stages_all_changes
    Dir.chdir(@temp_dir)

    File.write("file1.txt", "content1")
    File.write("file2.txt", "content2")

    # stage_all happens when only_staged=false and files=[]
    result = @orchestrator.execute(
      create_options(
        only_staged: false,
        message: "feat: add all files"
      )
    )

    assert result, "Commit should succeed"
    committed_files = `git diff-tree --no-commit-id --name-only -r HEAD`.strip.split("\n")
    assert_includes committed_files, "file1.txt"
    assert_includes committed_files, "file2.txt"
  end

  def test_dry_run_does_not_commit
    Dir.chdir(@temp_dir)

    File.write("test.txt", "content")
    `git add test.txt`

    result = @orchestrator.execute(
      create_options(
        message: "feat: test",
        dry_run: true
      )
    )

    assert result, "Dry run should succeed"
    assert_empty `git log --oneline`.strip, "Should not create commit in dry run"
  end

  def test_handles_commit_failure_gracefully
    Dir.chdir(@temp_dir)

    File.write("test.txt", "content")
    `git add test.txt`

    # Make git commit fail by removing git config
    `git config --unset user.name`
    `git config --unset user.email`

    result = @orchestrator.execute(create_options(message: "feat: test"))

    refute result, "Should return false when commit fails"
  end

  def test_execution_from_deep_directory
    Dir.chdir(@temp_dir)

    # Create deep directory structure (5 levels)
    deep_dir = File.join(@temp_dir, *Array.new(5) { "level" })
    FileUtils.mkdir_p(deep_dir)

    File.write(File.join(@temp_dir, "test.txt"), "content")

    # Change to deep directory
    Dir.chdir(deep_dir)

    # Stage from deep directory
    `git add ../../../../../test.txt`

    result = @orchestrator.execute(create_options(message: "feat: test from deep"))

    assert result, "Should commit from deep directory"
  end

  def test_handles_unicode_filenames
    Dir.chdir(@temp_dir)

    filename = "café_文件.txt"
    File.write(filename, "content")

    result = @orchestrator.execute(
      create_options(
        files: [filename],
        message: "feat: add unicode file"
      )
    )

    assert result, "Should handle unicode filenames"
    committed_files = `git diff-tree --no-commit-id --name-only -r HEAD`.strip
    assert_includes committed_files, filename
  end

  def test_handles_files_with_spaces
    Dir.chdir(@temp_dir)

    filename = "file with spaces.txt"
    File.write(filename, "content")

    result = @orchestrator.execute(
      create_options(
        files: [filename],
        message: "feat: add file with spaces"
      )
    )

    assert result, "Should handle files with spaces"
  end

  private

  def create_options(**overrides)
    defaults = {
      message: nil,
      intention: nil,
      files: [],
      only_staged: false,
      dry_run: false,
      debug: false,
      model: nil,
      force: false
    }

    Ace::GitCommit::Models::CommitOptions.new(**defaults.merge(overrides))
  end
end
