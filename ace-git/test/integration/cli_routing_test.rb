# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/cli"
require "ace/test_support/cli_helpers"

class CliRoutingTest < AceGitTestCase
  include Ace::TestSupport::CliHelpers

  def test_cli_routes_version_command
    result = invoke_cli(Ace::Git::CLI, ["version"])
    assert_match(/ace-git \d+\.\d+\.\d+/, result[:stdout])
  end

  def test_cli_routes_version_with_long_flag
    result = invoke_cli(Ace::Git::CLI, ["--version"])
    assert_match(/ace-git \d+\.\d+\.\d+/, result[:stdout])
  end

  def test_cli_routes_help_command
    result = invoke_cli(Ace::Git::CLI, ["help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  def test_cli_routes_help_with_long_flag
    result = invoke_cli(Ace::Git::CLI, ["--help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  def test_cli_routes_help_with_short_flag
    result = invoke_cli(Ace::Git::CLI, ["-h"])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  def test_cli_shows_help_when_no_args
    result = invoke_cli(Ace::Git::CLI, [])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  def test_cli_routes_explicit_diff_range
    stub_diff_orchestrator do
      result = invoke_cli(Ace::Git::CLI, ["diff", "HEAD~1..HEAD"])
      # Routing succeeds — no unknown command error
      output = result[:stdout] + result[:stderr]
      refute_match(/unknown command/i, output)
    end
  end

  def test_cli_routes_range_shorthand_to_diff
    stub_diff_orchestrator do
      result = invoke_cli(Ace::Git::CLI, ["HEAD~1..HEAD"])
      output = result[:stdout] + result[:stderr]
      refute_match(/unknown command/i, output)
    end
  end

  def test_cli_routes_head_shorthand_to_diff
    stub_diff_orchestrator do
      result = invoke_cli(Ace::Git::CLI, ["HEAD"])
      output = result[:stdout] + result[:stderr]
      refute_match(/unknown command/i, output)
    end
  end

  def test_cli_unknown_command_returns_error
    result = invoke_cli(Ace::Git::CLI, ["log"])
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:|unknown command/i, output)
  end

  def test_cli_passes_range_to_orchestrator
    captured_options = nil
    mock_result = build_mock_result
    spy = ->(opts) { captured_options = opts; mock_result }

    Ace::Git::Organisms::DiffOrchestrator.stub(:generate, spy) do
      Ace::Git::Organisms::DiffOrchestrator.stub(:raw, mock_result) do
        invoke_cli(Ace::Git::CLI, ["diff", "origin/main..HEAD"])
      end
    end

    assert_equal ["origin/main..HEAD"], captured_options[:ranges]
  end

  private

  # Stub the diff orchestrator to avoid actual git operations
  def stub_diff_orchestrator(&block)
    mock_result = build_mock_result

    Ace::Git::Organisms::DiffOrchestrator.stub(:generate, mock_result) do
      Ace::Git::Organisms::DiffOrchestrator.stub(:raw, mock_result, &block)
    end
  end

  def build_mock_result
    result = Object.new
    result.define_singleton_method(:content) { "mock diff" }
    result.define_singleton_method(:summary) { "1 file changed" }
    result.define_singleton_method(:files) { ["test.rb"] }
    result.define_singleton_method(:empty?) { false }
    result.define_singleton_method(:to_s) { "mock diff" }
    result
  end
end
