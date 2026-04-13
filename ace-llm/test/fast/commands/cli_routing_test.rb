# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/llm/cli"
require "ace/test_support/config_helpers"
require "ace/test_support/cli_helpers"

class CliRoutingTest < AceLlmTestCase
  include Ace::TestSupport::ConfigHelpers
  include Ace::TestSupport::CliHelpers

  # Helper method to invoke CLI
  def invoke_llm_cli(args)
    invoke_cli_stdout(Ace::LLM::CLI, args)
  end

  # --- Version Tests ---

  def test_cli_routes_version_with_long_flag
    output = invoke_llm_cli(["--version"])
    assert_match(/ace-llm \d+\.\d+\.\d+/, output)
  end

  # --- Help Tests ---

  def test_cli_routes_help_with_long_flag
    result = invoke_cli(Ace::LLM::CLI, ["--help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/PROVIDER|Query|LLM/i, output)
  end

  # --- List Providers Flag Tests ---

  def test_cli_routes_list_providers_flag
    with_real_config do
      output = invoke_llm_cli(["--list-providers"])
      assert_match(/google|anthropic|openai/i, output)
    end
  end

  # --- Query with No Args Shows Help ---

  def test_cli_no_args_shows_help
    output = invoke_llm_cli([])
    # Empty args should show query help (via --help default in exe)
    # But through CLI.start, empty args = no provider/prompt = show help
    assert_match(/Usage:|PROVIDER/i, output)
  end
end
