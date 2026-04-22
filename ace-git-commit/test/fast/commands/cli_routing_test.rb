# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/git_commit/cli"
require "ace/test_support/cli_helpers"

class GitCommitCliRoutingTest < TestCase
  include Ace::TestSupport::CliHelpers

  # --- Version Command Tests ---

  def test_cli_routes_version_with_long_flag
    result = invoke_cli(Ace::GitCommit::CLI, ["--version"])
    assert_match(/ace-git-commit \d+\.\d+\.\d+/, result[:stdout])
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_with_long_flag
    result = invoke_cli(Ace::GitCommit::CLI, ["--help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/USAGE|Usage:/, output)
  end

  def test_cli_runs_commit_when_no_args
    stub_commit_orchestrator do
      result = invoke_cli(Ace::GitCommit::CLI, [])
      output = result[:stdout] + result[:stderr]
      refute_match(/unknown command/i, output)
      refute_match(/was called with arguments/i, output)
    end
  end

  # --- Commit Command Tests ---

  def test_cli_runs_commit_without_subcommand_for_dry_run
    stub_commit_orchestrator do
      result = invoke_cli(Ace::GitCommit::CLI, ["--dry-run"])
      output = result[:stdout] + result[:stderr]
      refute_match(/unknown command/i, output)
      refute_match(/was called with arguments/i, output)
    end
  end

  def test_cli_runs_commit_without_subcommand_for_staged_dry_run
    stub_commit_orchestrator do
      result = invoke_cli(Ace::GitCommit::CLI, ["--staged", "--dry-run"])
      output = result[:stdout] + result[:stderr]
      refute_match(/unknown command/i, output)
      refute_match(/was called with arguments/i, output)
    end
  end

  def test_cli_runs_commit_without_subcommand_for_message_dry_run
    stub_commit_orchestrator do
      result = invoke_cli(Ace::GitCommit::CLI, ["-m", "test message", "--dry-run"])
      output = result[:stdout] + result[:stderr]
      refute_match(/unknown command/i, output)
      refute_match(/was called with arguments/i, output)
    end
  end

  def test_cli_renders_git_commit_error_as_controlled_failure
    mock_orchestrator = Minitest::Mock.new
    mock_orchestrator.expect(:execute, nil) do |options|
      options.is_a?(Ace::GitCommit::Models::CommitOptions) ||
        raise("expected CommitOptions, got #{options.class}")
      raise Ace::GitCommit::Error, "Failed to generate commit message with ACE role 'role:commit': Provider unavailable\n\nLLM setup checks:\n  ace-llm --list-providers\n  ace-config doctor\n\nFallback commit command:\n  ace-git-commit --only-staged --no-split -m \"chore: set up ace tooling\""
    end

    result = Ace::GitCommit::Organisms::CommitOrchestrator.stub(:new, mock_orchestrator) do
      invoke_cli(Ace::GitCommit::CLI, ["-i", "set up ace tooling"])
    end

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Failed to generate commit message with ACE role 'role:commit'"
    assert_includes result[:stderr], "ace-llm --list-providers"
    assert_includes result[:stderr], "ace-config doctor"
    assert_includes result[:stderr], 'ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"'
    refute_match(/backtrace|traceback/i, result[:stderr])
    mock_orchestrator.verify
  end

  private

  def stub_commit_orchestrator(&block)
    mock_orchestrator = Minitest::Mock.new
    mock_orchestrator.expect(:execute, true, [Ace::GitCommit::Models::CommitOptions])
    Ace::GitCommit::Organisms::CommitOrchestrator.stub(:new, mock_orchestrator, &block)
  end
end
