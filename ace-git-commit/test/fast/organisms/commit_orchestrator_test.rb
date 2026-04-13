# frozen_string_literal: true

require_relative "../../test_helper"
require "minitest/mock"

class CommitOrchestratorTest < TestCase
  PROJECT_ROOT = "/Users/test/project"

  def setup
    @mock_git = Minitest::Mock.new
    @mock_diff_analyzer = Minitest::Mock.new
    @mock_file_stager = Minitest::Mock.new
    @mock_message_generator = Minitest::Mock.new
    @mock_commit_grouper = Minitest::Mock.new
    @mock_split_executor = Minitest::Mock.new

    @orchestrator = Ace::GitCommit::Organisms::CommitOrchestrator.new

    # Inject mocks
    @orchestrator.instance_variable_set(:@git, @mock_git)
    @orchestrator.instance_variable_set(:@diff_analyzer, @mock_diff_analyzer)
    @orchestrator.instance_variable_set(:@file_stager, @mock_file_stager)
    @orchestrator.instance_variable_set(:@message_generator, @mock_message_generator)
    @orchestrator.instance_variable_set(:@commit_grouper, @mock_commit_grouper)
    @orchestrator.instance_variable_set(:@split_commit_executor, @mock_split_executor)

    # Add last_error method to mock_file_stager
    def @mock_file_stager.last_error
      nil
    end
  end

  def test_validates_git_repository
    @mock_git.expect :in_repository?, false

    error = assert_raises(Ace::GitCommit::GitError) do
      @orchestrator.execute(create_options(message: "test"))
    end

    assert_match(/not in a git repository/i, error.message)
    @mock_git.verify
  end

  def test_returns_true_when_no_changes
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, true
    @mock_git.expect :has_staged_changes?, false

    result = @orchestrator.execute(create_options(message: "test", quiet: true))

    assert result, "Should return true when no changes to commit"
    @mock_git.verify
    @mock_file_stager.verify
  end

  def test_no_change_output_omits_staging_messages
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, true
    @mock_git.expect :has_staged_changes?, false

    original_stdout = $stdout
    $stdout = StringIO.new

    result = @orchestrator.execute(create_options(message: "test", quiet: false))
    output = $stdout.string

    $stdout = original_stdout

    assert result, "No-op commit should be successful"
    assert_match(/No changes to commit/, output)
    refute_match(/Staging all changes\.\.\./, output)
    refute_match(/Changes staged successfully/, output)
    @mock_git.verify
    @mock_file_stager.verify
  end

  def test_commits_with_direct_message
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, true  # Now returns boolean
    @mock_git.expect :has_staged_changes?, true
    expect_single_group(["file.rb"])
    @mock_git.expect :execute, nil, ["commit", "-m", "feat: add test file"]
    @mock_git.expect :execute, "abc1234", ["rev-parse", "HEAD"]
    @mock_git.expect :execute, "abc1234 (HEAD -> main) feat: add test file", ["log", "--oneline", "abc1234", "-1"]
    @mock_git.expect :execute, " file.rb | 5 +++++\n 1 file changed, 5 insertions(+)", ["diff", "--stat", "abc1234~1", "abc1234"], capture_stderr: true

    # Suppress stdout for clean test output
    original_stdout = $stdout
    $stdout = StringIO.new

    result = @orchestrator.execute(create_options(message: "feat: add test file"))

    $stdout = original_stdout

    assert result, "Commit should succeed"
    @mock_git.verify
    @mock_file_stager.verify
  end

  def test_stages_specific_files
    @mock_git.expect :in_repository?, true

    # Add path_resolver mock for single file (no glob)
    mock_path_resolver = Minitest::Mock.new
    @orchestrator.instance_variable_set(:@path_resolver, mock_path_resolver)

    # Single file validation and path separation
    mock_path_resolver.expect :glob_pattern?, false, ["file1.txt"]  # In non_glob_paths check
    mock_path_resolver.expect :validate_paths, {valid: ["file1.txt"], invalid: []}, [["file1.txt"]]
    mock_path_resolver.expect :glob_pattern?, false, ["file1.txt"]  # In glob_patterns check

    # Single files now use stage_paths (same path as directories)
    @mock_file_stager.expect :stage_paths, true, [["file1.txt"]]
    @mock_file_stager.expect :staged_files, ["file1.txt"]
    @mock_git.expect :has_staged_changes?, true
    expect_single_group(["file1.txt"])
    @mock_git.expect :execute, nil, ["commit", "-m", "feat: add file1"]
    @mock_git.expect :execute, "def5678", ["rev-parse", "HEAD"]
    @mock_git.expect :execute, "def5678 feat: add file1", ["log", "--oneline", "def5678", "-1"]
    @mock_git.expect :execute, " file1.txt | 3 +++\n 1 file changed, 3 insertions(+)", ["diff", "--stat", "def5678~1", "def5678"], capture_stderr: true

    # Suppress stdout for clean test output
    original_stdout = $stdout
    $stdout = StringIO.new

    result = @orchestrator.execute(
      create_options(
        files: ["file1.txt"],
        message: "feat: add file1"
      )
    )

    $stdout = original_stdout

    assert result, "Commit should succeed"
    @mock_git.verify
    @mock_file_stager.verify
    mock_path_resolver.verify
  end

  def test_stages_all_changes
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, true  # Now returns boolean
    @mock_git.expect :has_staged_changes?, true
    expect_single_group(["file1.rb", "file2.rb"])
    @mock_git.expect :execute, nil, ["commit", "-m", "feat: add all files"]
    @mock_git.expect :execute, "ghi9012", ["rev-parse", "HEAD"]
    @mock_git.expect :execute, "ghi9012 feat: add all files", ["log", "--oneline", "ghi9012", "-1"]
    @mock_git.expect :execute, " file1.rb | 3 +++\n file2.rb | 2 ++\n 2 files changed, 5 insertions(+)", ["diff", "--stat", "ghi9012~1", "ghi9012"], capture_stderr: true

    # Suppress stdout for clean test output
    original_stdout = $stdout
    $stdout = StringIO.new

    result = @orchestrator.execute(
      create_options(
        only_staged: false,
        message: "feat: add all files"
      )
    )

    $stdout = original_stdout

    assert result, "Commit should succeed"
    @mock_git.verify
    @mock_file_stager.verify
  end

  def test_dry_run_does_not_commit
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, true  # Now returns boolean
    @mock_git.expect :has_staged_changes?, true
    expect_single_group(["test.txt"])
    @mock_file_stager.expect :staged_files, ["test.txt"]
    @mock_diff_analyzer.expect :get_staged_diff, "diff content"
    @mock_diff_analyzer.expect :analyze_diff, {insertions: 5, deletions: 2}, ["diff content"]

    # Suppress stdout during dry run
    original_stdout = $stdout
    $stdout = StringIO.new

    result = @orchestrator.execute(
      create_options(
        message: "feat: test",
        dry_run: true,
        debug: true,
        quiet: true
      )
    )

    $stdout = original_stdout

    assert result, "Dry run should succeed"
    @mock_git.verify
    @mock_file_stager.verify
    @mock_diff_analyzer.verify
  end

  def test_handles_commit_failure_gracefully
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, true  # Now returns boolean
    @mock_git.expect :has_staged_changes?, true
    expect_single_group(["file.rb"])
    @mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "pre-commit hook failed"
    end

    # Suppress stdout during test
    original_stdout = $stdout
    $stdout = StringIO.new

    result = @orchestrator.execute(create_options(message: "feat: test", quiet: true))

    $stdout = original_stdout

    refute result, "Should return false when commit fails"
    @mock_git.verify
    @mock_file_stager.verify
  end

  def test_generates_message_with_llm_when_intention_provided
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, true  # Now returns boolean
    @mock_git.expect :has_staged_changes?, true
    @mock_diff_analyzer.expect :get_staged_diff, "diff content"
    @mock_diff_analyzer.expect :changed_files, ["file.txt"] do |**kwargs|
      kwargs == {staged_only: true}
    end
    expect_single_group(["file.txt"], config: {"model" => "glite"})
    @mock_message_generator.expect :generate, "feat: generated message" do |diff, **kwargs|
      diff == "diff content" &&
        kwargs == {intention: "add feature", files: ["file.txt"], config: {"model" => "glite"}}
    end
    @mock_git.expect :execute, nil, ["commit", "-m", "feat: generated message"]
    @mock_git.expect :execute, "jkl3456", ["rev-parse", "HEAD"]
    @mock_git.expect :execute, "jkl3456 feat: generated message", ["log", "--oneline", "jkl3456", "-1"]
    @mock_git.expect :execute, " file.txt | 10 ++++++++++\n 1 file changed, 10 insertions(+)", ["diff", "--stat", "jkl3456~1", "jkl3456"], capture_stderr: true

    # Suppress stdout for clean test output
    original_stdout = $stdout
    $stdout = StringIO.new

    result = @orchestrator.execute(
      create_options(
        intention: "add feature"
      )
    )

    $stdout = original_stdout

    assert result, "Commit with LLM should succeed"
    @mock_git.verify
    @mock_file_stager.verify
    @mock_diff_analyzer.verify
    @mock_message_generator.verify
  end

  def test_split_commit_executes_split_executor
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, true
    @mock_git.expect :has_staged_changes?, true
    @mock_file_stager.expect :staged_files, ["a.md", "b.md"]
    @mock_git.expect :repository_root, PROJECT_ROOT

    groups = [
      Ace::GitCommit::Models::CommitGroup.new(
        scope_name: "docs",
        source: "#{PROJECT_ROOT}/.ace/git/commit.yml",
        config: {"model" => "glite"},
        files: ["a.md"]
      ),
      Ace::GitCommit::Models::CommitGroup.new(
        scope_name: "taskflow",
        source: "#{PROJECT_ROOT}/ace-task/.ace/git/commit.yml",
        config: {"model" => "gflash"},
        files: ["b.md"]
      )
    ]

    @mock_commit_grouper.expect :group, groups do |files, **kwargs|
      files == ["a.md", "b.md"] && kwargs[:project_root] == PROJECT_ROOT
    end

    split_result = Ace::GitCommit::Models::SplitCommitResult.new
    @mock_split_executor.expect :execute, split_result do |passed_groups, passed_options|
      passed_groups == groups && passed_options.is_a?(Ace::GitCommit::Models::CommitOptions)
    end

    result = @orchestrator.execute(create_options(message: "test", quiet: true))

    assert result, "Split commit should succeed"
    @mock_git.verify
    @mock_file_stager.verify
    @mock_commit_grouper.verify
    @mock_split_executor.verify
  end

  def test_no_split_ignores_split_executor
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, true
    @mock_git.expect :has_staged_changes?, true
    @mock_file_stager.expect :staged_files, ["a.md", "b.md"]
    @mock_git.expect :repository_root, PROJECT_ROOT

    groups = [
      Ace::GitCommit::Models::CommitGroup.new(
        scope_name: "docs",
        source: "#{PROJECT_ROOT}/.ace/git/commit.yml",
        config: {"model" => "glite"},
        files: ["a.md"]
      ),
      Ace::GitCommit::Models::CommitGroup.new(
        scope_name: "taskflow",
        source: "#{PROJECT_ROOT}/ace-task/.ace/git/commit.yml",
        config: {"model" => "gflash"},
        files: ["b.md"]
      )
    ]

    @mock_commit_grouper.expect :group, groups do |files, **kwargs|
      files == ["a.md", "b.md"] && kwargs[:project_root] == PROJECT_ROOT
    end

    @mock_git.expect :execute, nil, ["commit", "-m", "test"]
    @mock_git.expect :execute, "abc1234", ["rev-parse", "HEAD"]
    @mock_git.expect :execute, "abc1234 feat: test", ["log", "--oneline", "abc1234", "-1"]
    @mock_git.expect :execute, " a.md | 1 +\n b.md | 1 +\n 2 files changed, 2 insertions(+)", ["diff", "--stat", "abc1234~1", "abc1234"], capture_stderr: true

    original_stdout = $stdout
    $stdout = StringIO.new

    result = @orchestrator.execute(create_options(message: "test", no_split: true))

    $stdout = original_stdout

    assert result, "No-split should commit once"
    @mock_git.verify
    @mock_file_stager.verify
    @mock_commit_grouper.verify
  end

  # Integration tests for path validation and glob patterns
  def test_early_path_validation_rejects_invalid_paths
    @mock_git.expect :in_repository?, true

    # Add path_resolver mock
    mock_path_resolver = Minitest::Mock.new
    @orchestrator.instance_variable_set(:@path_resolver, mock_path_resolver)

    # Mock glob_pattern? to return false (non-glob paths)
    mock_path_resolver.expect :glob_pattern?, false, ["nonexistent/"]

    # Mock validate_paths to return invalid path
    mock_path_resolver.expect :validate_paths,
      {valid: [], invalid: ["nonexistent/"]},
      [["nonexistent/"]]

    # Mock last_error to return nil (no git error, just missing path)
    mock_path_resolver.expect :last_error, nil

    # Capture output
    original_stdout = $stdout
    $stdout = StringIO.new

    result = @orchestrator.execute(
      create_options(message: "test", files: ["nonexistent/"], quiet: false)
    )

    output = $stdout.string
    $stdout = original_stdout

    refute result, "Should return false for invalid paths"
    assert_match(/Invalid path\(s\)/, output)
    assert_match(/nonexistent/, output)

    @mock_git.verify
    mock_path_resolver.verify
  end

  def test_glob_pattern_staging_with_resolved_files
    @mock_git.expect :in_repository?, true

    # Add path_resolver mock
    mock_path_resolver = Minitest::Mock.new
    @orchestrator.instance_variable_set(:@path_resolver, mock_path_resolver)

    # Mock glob_pattern? - called for validation, then for separating paths
    mock_path_resolver.expect :glob_pattern?, true, ["**/*.rb"]  # In validation (reject from non_glob_paths)
    mock_path_resolver.expect :glob_pattern?, true, ["**/*.rb"]  # In glob pattern check

    # Mock resolve_paths to return file list
    mock_path_resolver.expect :resolve_paths,
      ["lib/file1.rb", "lib/file2.rb"],
      [["**/*.rb"]]

    # Mock stage_paths with resolved files
    @mock_file_stager.expect :stage_paths, true, [["lib/file1.rb", "lib/file2.rb"]]
    @mock_file_stager.expect :staged_files, ["lib/file1.rb", "lib/file2.rb"]

    @mock_git.expect :has_staged_changes?, true
    expect_single_group(["lib/file1.rb", "lib/file2.rb"])
    @mock_git.expect :execute, "abc123", ["commit", "-m", "test message"]
    @mock_git.expect :execute, "abc123", ["rev-parse", "HEAD"]

    # Mock commit summarizer
    mock_summarizer = Minitest::Mock.new
    mock_summarizer.expect :summarize, "Commit summary", ["abc123"]

    Ace::GitCommit::Molecules::CommitSummarizer.stub :new, mock_summarizer do
      result = @orchestrator.execute(
        create_options(message: "test message", files: ["**/*.rb"], quiet: true)
      )

      assert result, "Should successfully stage and commit with glob pattern"
    end

    @mock_git.verify
    @mock_file_stager.verify
    mock_path_resolver.verify
  end

  def test_multiple_paths_uses_path_restricted_staging
    @mock_git.expect :in_repository?, true

    # Add path_resolver mock
    mock_path_resolver = Minitest::Mock.new
    @orchestrator.instance_variable_set(:@path_resolver, mock_path_resolver)

    # Mock validation for non-glob paths (each path checked in validation)
    mock_path_resolver.expect :glob_pattern?, false, ["lib/"]   # In validation
    mock_path_resolver.expect :glob_pattern?, false, ["test/"]  # In validation
    mock_path_resolver.expect :validate_paths,
      {valid: ["lib/", "test/"], invalid: []},
      [["lib/", "test/"]]

    # Mock glob_pattern? for separating paths (directories, globs, single files)
    mock_path_resolver.expect :glob_pattern?, false, ["lib/"]   # Directory check
    mock_path_resolver.expect :glob_pattern?, false, ["test/"]  # Directory check

    # Directories are passed directly to stage_paths (no expansion)
    @mock_file_stager.expect :stage_paths, true, [["lib/", "test/"]]
    @mock_file_stager.expect :staged_files, ["lib/file1.rb", "test/file1_test.rb"]

    @mock_git.expect :has_staged_changes?, true
    expect_single_group(["lib/file1.rb", "test/file1_test.rb"])
    @mock_git.expect :execute, "abc123", ["commit", "-m", "test"]
    @mock_git.expect :execute, "abc123", ["rev-parse", "HEAD"]

    # Mock commit summarizer
    mock_summarizer = Minitest::Mock.new
    mock_summarizer.expect :summarize, "Commit summary", ["abc123"]

    Ace::GitCommit::Molecules::CommitSummarizer.stub :new, mock_summarizer do
      result = @orchestrator.execute(
        create_options(message: "test", files: ["lib/", "test/"], quiet: true)
      )

      assert result, "Should handle multiple paths"
    end

    @mock_git.verify
    @mock_file_stager.verify
    mock_path_resolver.verify
  end

  def test_empty_glob_pattern_results_shows_helpful_message
    @mock_git.expect :in_repository?, true

    # Add path_resolver mock
    mock_path_resolver = Minitest::Mock.new
    @orchestrator.instance_variable_set(:@path_resolver, mock_path_resolver)

    # Mock glob_pattern? - called for validation, then for separating paths
    mock_path_resolver.expect :glob_pattern?, true, ["**/*.xyz"]  # In validation (reject from non_glob_paths)
    mock_path_resolver.expect :glob_pattern?, true, ["**/*.xyz"]  # In glob pattern check

    # Mock resolve_paths to return empty (no matching files)
    mock_path_resolver.expect :resolve_paths, [], [["**/*.xyz"]]

    # Mock suggest_recursive_pattern (returns nil for already recursive pattern)
    mock_path_resolver.expect :suggest_recursive_pattern, nil, ["**/*.xyz"]

    # Capture output
    original_stdout = $stdout
    $stdout = StringIO.new

    result = @orchestrator.execute(
      create_options(message: "test", files: ["**/*.xyz"], quiet: false)
    )

    output = $stdout.string
    $stdout = original_stdout

    refute result, "Should return false when no files match pattern"
    assert_match(/No files found matching/, output)

    @mock_git.verify
    mock_path_resolver.verify
  end

  def test_simple_glob_pattern_shows_recursive_hint
    @mock_git.expect :in_repository?, true

    # Add path_resolver mock
    mock_path_resolver = Minitest::Mock.new
    @orchestrator.instance_variable_set(:@path_resolver, mock_path_resolver)

    # Mock glob_pattern? - called for validation, then for separating paths
    mock_path_resolver.expect :glob_pattern?, true, ["*.rb"]  # In validation (reject from non_glob_paths)
    mock_path_resolver.expect :glob_pattern?, true, ["*.rb"]  # In glob pattern check

    # Mock resolve_paths to return empty (no matching files at root level)
    mock_path_resolver.expect :resolve_paths, [], [["*.rb"]]

    # Mock suggest_recursive_pattern - returns recursive alternative for simple glob
    mock_path_resolver.expect :suggest_recursive_pattern, "**/*.rb", ["*.rb"]

    # Capture output
    original_stdout = $stdout
    $stdout = StringIO.new

    result = @orchestrator.execute(
      create_options(message: "test", files: ["*.rb"], quiet: false)
    )

    output = $stdout.string
    $stdout = original_stdout

    refute result, "Should return false when no files match pattern"
    assert_match(/No files found matching/, output)
    assert_match(/Hint:.*only match files at the current directory level/, output)
    assert_match(/try '\*\*\/\*\.rb' for recursive matching/, output)

    @mock_git.verify
    mock_path_resolver.verify
  end

  private

  def expect_single_group(files = ["file.rb"], config: {})
    @mock_file_stager.expect :staged_files, files
    @mock_git.expect :repository_root, PROJECT_ROOT

    group = Ace::GitCommit::Models::CommitGroup.new(
      scope_name: "project default",
      source: "#{PROJECT_ROOT}/.ace/git/commit.yml",
      config: config,
      files: files
    )

    @mock_commit_grouper.expect :group, [group] do |arg_files, **kwargs|
      arg_files == files && kwargs[:project_root] == PROJECT_ROOT
    end

    group
  end

  def create_options(**overrides)
    defaults = {
      message: nil,
      intention: nil,
      files: [],
      only_staged: false,
      dry_run: false,
      debug: false,
      model: nil,
      force: false,
      verbose: true,
      quiet: false,
      no_split: false
    }

    Ace::GitCommit::Models::CommitOptions.new(**defaults.merge(overrides))
  end
end
