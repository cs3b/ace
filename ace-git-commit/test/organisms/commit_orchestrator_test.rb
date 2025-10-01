# frozen_string_literal: true

require_relative "../test_helper"
require "minitest/mock"

class CommitOrchestratorTest < TestCase
  def setup
    @mock_git = Minitest::Mock.new
    @mock_diff_analyzer = Minitest::Mock.new
    @mock_file_stager = Minitest::Mock.new
    @mock_message_generator = Minitest::Mock.new

    @orchestrator = Ace::GitCommit::Organisms::CommitOrchestrator.new

    # Inject mocks
    @orchestrator.instance_variable_set(:@git, @mock_git)
    @orchestrator.instance_variable_set(:@diff_analyzer, @mock_diff_analyzer)
    @orchestrator.instance_variable_set(:@file_stager, @mock_file_stager)
    @orchestrator.instance_variable_set(:@message_generator, @mock_message_generator)
  end

  def test_validates_git_repository
    @mock_git.expect :in_repository?, false

    error = assert_raises(Ace::GitCommit::GitError) do
      @orchestrator.execute(create_options(message: "test"))
    end

    assert_match(/not in a git repository/i, error.message)
    @mock_git.verify
  end

  def test_returns_false_when_no_changes
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, nil  # Default behavior stages all
    @mock_git.expect :has_staged_changes?, false

    result = @orchestrator.execute(create_options(message: "test"))

    refute result, "Should return false when no changes to commit"
    @mock_git.verify
    @mock_file_stager.verify
  end

  def test_commits_with_direct_message
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, nil  # Default behavior stages all
    @mock_git.expect :has_staged_changes?, true
    @mock_git.expect :execute, nil, ["commit", "-m", "feat: add test file"]
    @mock_git.expect :execute, "abc1234", ["rev-parse", "HEAD"]
    @mock_git.expect :execute, "abc1234 (HEAD -> main) feat: add test file", ["log", "--oneline", "abc1234", "-1"]
    @mock_git.expect :execute, " file.rb | 5 +++++\n 1 file changed, 5 insertions(+)", ["diff", "--stat", "abc1234~1", "abc1234"], capture_stderr: true

    result = @orchestrator.execute(create_options(message: "feat: add test file"))

    assert result, "Commit should succeed"
    @mock_git.verify
    @mock_file_stager.verify
  end

  def test_stages_specific_files
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_files, nil, [["file1.txt"]]
    @mock_git.expect :has_staged_changes?, true
    @mock_git.expect :execute, nil, ["commit", "-m", "feat: add file1"]
    @mock_git.expect :execute, "def5678", ["rev-parse", "HEAD"]
    @mock_git.expect :execute, "def5678 feat: add file1", ["log", "--oneline", "def5678", "-1"]
    @mock_git.expect :execute, " file1.txt | 3 +++\n 1 file changed, 3 insertions(+)", ["diff", "--stat", "def5678~1", "def5678"], capture_stderr: true

    result = @orchestrator.execute(
      create_options(
        files: ["file1.txt"],
        message: "feat: add file1"
      )
    )

    assert result, "Commit should succeed"
    @mock_git.verify
    @mock_file_stager.verify
  end

  def test_stages_all_changes
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, nil
    @mock_git.expect :has_staged_changes?, true
    @mock_git.expect :execute, nil, ["commit", "-m", "feat: add all files"]
    @mock_git.expect :execute, "ghi9012", ["rev-parse", "HEAD"]
    @mock_git.expect :execute, "ghi9012 feat: add all files", ["log", "--oneline", "ghi9012", "-1"]
    @mock_git.expect :execute, " file1.rb | 3 +++\n file2.rb | 2 ++\n 2 files changed, 5 insertions(+)", ["diff", "--stat", "ghi9012~1", "ghi9012"], capture_stderr: true

    result = @orchestrator.execute(
      create_options(
        only_staged: false,
        message: "feat: add all files"
      )
    )

    assert result, "Commit should succeed"
    @mock_git.verify
    @mock_file_stager.verify
  end

  def test_dry_run_does_not_commit
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, nil  # Default behavior stages all
    @mock_git.expect :has_staged_changes?, true
    @mock_file_stager.expect :staged_files, ["test.txt"]
    @mock_diff_analyzer.expect :get_staged_diff, "diff content"
    @mock_diff_analyzer.expect :analyze_diff, { insertions: 5, deletions: 2 }, ["diff content"]

    # Suppress stdout during dry run
    original_stdout = $stdout
    $stdout = StringIO.new

    result = @orchestrator.execute(
      create_options(
        message: "feat: test",
        dry_run: true,
        debug: true
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
    @mock_file_stager.expect :stage_all, nil  # Default behavior stages all
    @mock_git.expect :has_staged_changes?, true
    @mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "pre-commit hook failed"
    end

    # Suppress stdout during test
    original_stdout = $stdout
    $stdout = StringIO.new

    result = @orchestrator.execute(create_options(message: "feat: test"))

    $stdout = original_stdout

    refute result, "Should return false when commit fails"
    @mock_git.verify
    @mock_file_stager.verify
  end

  def test_generates_message_with_llm_when_intention_provided
    @mock_git.expect :in_repository?, true
    @mock_file_stager.expect :stage_all, nil  # Default behavior stages all
    @mock_git.expect :has_staged_changes?, true
    @mock_diff_analyzer.expect :get_staged_diff, "diff content"
    @mock_diff_analyzer.expect :changed_files, ["file.txt"] do |**kwargs|
      kwargs == { staged_only: true }
    end
    @mock_message_generator.expect :generate, "feat: generated message" do |diff, **kwargs|
      diff == "diff content" && kwargs == { intention: "add feature", files: ["file.txt"] }
    end
    @mock_git.expect :execute, nil, ["commit", "-m", "feat: generated message"]
    @mock_git.expect :execute, "jkl3456", ["rev-parse", "HEAD"]
    @mock_git.expect :execute, "jkl3456 feat: generated message", ["log", "--oneline", "jkl3456", "-1"]
    @mock_git.expect :execute, " file.txt | 10 ++++++++++\n 1 file changed, 10 insertions(+)", ["diff", "--stat", "jkl3456~1", "jkl3456"], capture_stderr: true

    result = @orchestrator.execute(
      create_options(
        intention: "add feature"
      )
    )

    assert result, "Commit with LLM should succeed"
    @mock_git.verify
    @mock_file_stager.verify
    @mock_diff_analyzer.verify
    @mock_message_generator.verify
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
