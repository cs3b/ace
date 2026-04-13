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

  private

  def stub_commit_orchestrator(&block)
    mock_orchestrator = Minitest::Mock.new
    mock_orchestrator.expect(:execute, true, [Ace::GitCommit::Models::CommitOptions])
    Ace::GitCommit::Organisms::CommitOrchestrator.stub(:new, mock_orchestrator, &block)
  end
end
