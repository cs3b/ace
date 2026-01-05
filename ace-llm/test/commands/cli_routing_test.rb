# frozen_string_literal: true

require_relative "../test_helper"
require "ace/llm/cli"
require "ace/test_support/config_helpers"

class CliRoutingTest < AceLlmTestCase
  include Ace::TestSupport::ConfigHelpers
  # --- Version Command Tests ---

  def test_cli_routes_version_command
    output = capture_io do
      Ace::LLM::CLI.start(["version"])
    end
    assert_match(/\d+\.\d+\.\d+/, output.first)
  end

  def test_cli_routes_version_with_long_flag
    output = capture_io do
      Ace::LLM::CLI.start(["--version"])
    end
    assert_match(/\d+\.\d+\.\d+/, output.first)
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_command
    output = capture_io do
      Ace::LLM::CLI.start(["help"])
    end
    # Help should mention available commands
    assert_match(/query|list-providers/i, output.first)
  end

  def test_cli_routes_help_with_long_flag
    output = capture_io do
      Ace::LLM::CLI.start(["--help"])
    end
    assert_match(/Commands:/i, output.first)
  end

  # --- List Providers Command Tests ---

  def test_cli_routes_list_providers_command
    with_real_config do
      output = capture_io do
        Ace::LLM::CLI.start(["list-providers"])
      end
      # Should list at least some providers
      assert_match(/google|anthropic|openai/i, output.first)
    end
  end

  # --- Default Task Routing Tests ---

  def test_cli_uses_query_as_default_task_with_unknown_command
    # Unknown commands should be treated as provider:model arguments
    # and invoke the query command, showing help when no prompt given
    output = capture_io do
      Ace::LLM::CLI.start(["google:gemini-2.5-flash"])
    end
    # Should show aliases/help for the provider since no prompt given
    assert_match(/alias|Usage/i, output.first)
  end

  # --- Query Command with Help ---

  def test_cli_query_empty_args_shows_help
    output = capture_io do
      Ace::LLM::CLI.start(["query"])
    end
    # Empty args should show query help
    assert_match(/Usage:|PROVIDER/i, output.first)
  end
end
