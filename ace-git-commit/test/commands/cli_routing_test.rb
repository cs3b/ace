# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git_commit/cli"
require "ace/test_support/cli_helpers"

class GitCommitCliRoutingTest < TestCase
  include Ace::TestSupport::CliHelpers

  # --- Version Command Tests ---

  def test_cli_routes_version_command
    output = invoke_cli_stdout(Ace::GitCommit::CLI, ["version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  def test_cli_routes_version_with_long_flag
    output = invoke_cli_stdout(Ace::GitCommit::CLI, ["--version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_command
    result = invoke_cli(Ace::GitCommit::CLI, ["help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  def test_cli_routes_help_with_long_flag
    result = invoke_cli(Ace::GitCommit::CLI, ["--help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  def test_cli_routes_help_with_short_flag
    result = invoke_cli(Ace::GitCommit::CLI, ["-h"])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  # --- Default Task Routing Tests ---
  # Critical regression tests for Task 200 fix

  # Helper to create mock orchestrator
  def mock_orchestrator
    mock = Object.new
    mock.define_singleton_method(:execute) { |_opts| true }
    mock
  end

  def test_cli_routes_unknown_flag_to_default_command
    # Flags like --dry-run should route to the default 'commit' command
    # Previously, the hyphen check would reject flags as unknown commands
    #
    # We stub the orchestrator since --dry-run will actually try to run
    Ace::GitCommit::Organisms::CommitOrchestrator.stub(:new, ->(*) { mock_orchestrator }) do
      result = invoke_cli(Ace::GitCommit::CLI, ["--dry-run"])
      output = result[:stdout] + result[:stderr]

      # Should process the flag, not reject as "unknown command"
      refute_match(/unknown command/i, output)
    end
  end

  def test_cli_routes_staged_flag_to_default_command
    # The --staged flag should route to default command
    Ace::GitCommit::Organisms::CommitOrchestrator.stub(:new, ->(*) { mock_orchestrator }) do
      result = invoke_cli(Ace::GitCommit::CLI, ["--staged", "--dry-run"])
      output = result[:stdout] + result[:stderr]

      # Should process flags, not reject them
      refute_match(/unknown command/i, output)
    end
  end

  def test_cli_routes_message_flag_to_default_command
    # The -m flag should route to default command
    Ace::GitCommit::Organisms::CommitOrchestrator.stub(:new, ->(*) { mock_orchestrator }) do
      result = invoke_cli(Ace::GitCommit::CLI, ["-m", "test message", "--dry-run"])
      output = result[:stdout] + result[:stderr]

      # Should process the message flag
      refute_match(/unknown command/i, output)
    end
  end

  def test_cli_empty_args_routes_to_default_command
    # Empty args should invoke the default command
    Ace::GitCommit::Organisms::CommitOrchestrator.stub(:new, ->(*) { mock_orchestrator }) do
      result = invoke_cli(Ace::GitCommit::CLI, [])
      output = result[:stdout] + result[:stderr]

      # Should attempt to run commit, not show "unknown command"
      refute_match(/unknown command/i, output)
    end
  end

  def test_cli_known_command_routes_directly
    # Known commands should route directly
    result = invoke_cli(Ace::GitCommit::CLI, ["commit", "--help"])
    output = result[:stdout] + result[:stderr]

    # Should show commit command help
    assert_match(/commit|Usage/i, output)
  end

  def test_cli_builtin_flags_not_routed_to_default
    # Built-in flags like --help should NOT route to default command
    result = invoke_cli(Ace::GitCommit::CLI, ["--help"])
    output = result[:stdout] + result[:stderr]

    # Should show root help with Commands list
    assert_match(/COMMANDS|Commands:/i, output)
  end
end
