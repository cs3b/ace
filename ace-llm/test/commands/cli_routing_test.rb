# frozen_string_literal: true

require_relative "../test_helper"
require "ace/llm/cli"
require "ace/test_support/config_helpers"
require "ace/test_support/cli_helpers"

class CliRoutingTest < AceLlmTestCase
  include Ace::TestSupport::ConfigHelpers
  include Ace::TestSupport::CliHelpers

  # Helper method to invoke CLI with routing logic
  # Uses CLI.start to ensure default task routing is tested
  def invoke_llm_cli(args)
    invoke_cli_stdout(Ace::LLM::CLI, args)
  end

  # --- Version Command Tests ---

  def test_cli_routes_version_command
    output = invoke_llm_cli(["version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  def test_cli_routes_version_with_long_flag
    output = invoke_llm_cli(["--version"])
    assert_match(/\d+\.\d+\.\d+/, output)
  end

  # --- Help Command Tests ---

  def test_cli_routes_help_command
    output = invoke_llm_cli(["help"])
    # Help should mention available commands
    assert_match(/query|list-providers/i, output)
  end

  def test_cli_routes_help_with_long_flag
    output = invoke_llm_cli(["--help"])
    assert_match(/Commands:/i, output)
  end

  # --- List Providers Command Tests ---

  def test_cli_routes_list_providers_command
    with_real_config do
      output = invoke_llm_cli(["list-providers"])
      # Should list at least some providers
      assert_match(/google|anthropic|openai/i, output)
    end
  end

  def test_cli_routes_list_providers_with_long_flag
    with_real_config do
      output = invoke_llm_cli(["--list-providers"])
      # Should list at least some providers
      assert_match(/google|anthropic|openai/i, output)
    end
  end

  # --- Default Task Routing Tests ---

  def test_cli_uses_query_as_default_task_with_unknown_command
    # Unknown commands should be treated as provider:model arguments
    # and invoke the query command, showing help when no prompt given
    output = invoke_llm_cli(["google:gemini-2.5-flash"])
    # Should show aliases/help for the provider since no prompt given
    assert_match(/alias|Usage/i, output)
  end

  # --- Query Command with Help ---

  def test_cli_query_empty_args_shows_help
    output = invoke_llm_cli(["query"])
    # Empty args should show query help
    assert_match(/Usage:|PROVIDER/i, output)
  end
end
