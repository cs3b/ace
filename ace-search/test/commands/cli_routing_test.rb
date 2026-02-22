# frozen_string_literal: true

require_relative "../test_helper"
require "ace/search/cli"

class CliRoutingTest < AceSearchTestCase
  include Ace::TestSupport::CliHelpers

  # Helper method to invoke CLI with routing logic
  # Uses CLI.start to ensure default task routing is tested
  def invoke_search_cli(args)
    invoke_cli_stdout(Ace::Search::CLI, args)
  end

  # --- Version Command Tests ---

  def test_cli_routes_version_command
    output = invoke_search_cli(["version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  def test_cli_routes_version_with_long_flag
    output = invoke_search_cli(["--version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_command
    result = invoke_cli(Ace::Search::CLI, ["help"])
    # Help goes to stderr in dry-cli
    output = result[:stdout] + result[:stderr]
    assert_match(/search|Commands/i, output)
  end

  def test_cli_routes_help_with_long_flag
    result = invoke_cli(Ace::Search::CLI, ["--help"])
    # Help goes to stderr in dry-cli
    output = result[:stdout] + result[:stderr]
    assert_match(/COMMANDS|Commands:/i, output)
  end

  # --- Search Command Tests ---

  def test_cli_routes_search_command_with_explicit_command
    skip_unless_rg_available

    output = invoke_search_cli(["search", "test", "--max-results", "1"])
    # Should attempt a search
    assert_match(/Found \d+ results?|mode:/i, output)
  end

  # --- Default Task Routing Tests ---

  def test_cli_uses_search_as_default_task
    skip_unless_rg_available

    # Unknown commands should be treated as patterns and invoke search
    output = invoke_search_cli(["TODO", "--max-results", "1"])
    # Should attempt a search (the pattern "TODO" should be treated as search pattern)
    assert_match(/Found \d+ results?|mode:/i, output)
  end

  def test_cli_shows_help_when_no_args
    result = invoke_cli(Ace::Search::CLI, [])
    # dry-cli shows help when no arguments provided
    # This is a UX improvement over showing an error
    assert_match(/COMMANDS|Commands:/i, result[:stdout] + result[:stderr])
  end
end
