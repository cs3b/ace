# frozen_string_literal: true

require_relative "../test_helper"
require "ace/search/cli"

class CliRoutingTest < AceSearchTestCase
  # --- Version Command Tests ---

  def test_cli_routes_version_command
    output = capture_io do
      Ace::Search::CLI.start(["version"])
    end
    assert_match(/\d+\.\d+\.\d+/, output.first)
  end

  def test_cli_routes_version_with_long_flag
    output = capture_io do
      Ace::Search::CLI.start(["--version"])
    end
    assert_match(/\d+\.\d+\.\d+/, output.first)
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_command
    output = capture_io do
      Ace::Search::CLI.start(["help"])
    end
    # Help should mention available commands
    assert_match(/search|Commands/i, output.first)
  end

  def test_cli_routes_help_with_long_flag
    output = capture_io do
      Ace::Search::CLI.start(["--help"])
    end
    assert_match(/Commands:/i, output.first)
  end

  # --- Search Command Tests ---

  def test_cli_routes_search_command_with_explicit_command
    skip_unless_rg_available

    output, err = capture_io do
      Ace::Search::CLI.start(["search", "test", "--max-results", "1"])
    end
    # Should attempt a search
    assert_match(/Found \d+ results?|mode:/i, output)
  end

  # --- Default Task Routing Tests ---

  def test_cli_uses_search_as_default_task
    skip_unless_rg_available

    output, err = capture_io do
      # Unknown commands should be treated as patterns and invoke search
      Ace::Search::CLI.start(["TODO", "--max-results", "1"])
    end
    # Should attempt a search (the pattern "TODO" should be treated as search pattern)
    assert_match(/Found \d+ results?|mode:/i, output)
  end

  def test_cli_error_when_no_pattern
    output, err = capture_io do
      Ace::Search::CLI.start([])
    end
    # Should show error about missing pattern
    assert_match(/No search pattern provided/i, output + err)
  end
end
