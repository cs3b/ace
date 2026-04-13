# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/bundle/cli"
require "ace/test_support/cli_helpers"

class CliRoutingTest < AceTestCase
  include Ace::TestSupport::CliHelpers

  # --- Version Tests ---

  def test_cli_routes_version_with_long_flag
    result = invoke_cli(Ace::Bundle::CLI, ["--version"])
    assert_match(/ace-bundle \d+\.\d+\.\d+/, result[:stdout])
  end

  # --- Help Tests ---

  def test_cli_routes_help_with_long_flag
    result = invoke_cli(Ace::Bundle::CLI, ["--help"])
    output = result[:stdout] + result[:stderr]
    assert_match(/Load context|preset|protocol/i, output)
  end

  def test_cli_shows_help_when_no_args
    result = invoke_cli(Ace::Bundle::CLI, [])
    output = result[:stdout] + result[:stderr]
    assert_match(/Load context|preset|protocol/i, output)
  end

  # --- List Presets Flag Tests ---

  def test_cli_routes_list_presets_flag
    result = invoke_cli(Ace::Bundle::CLI, ["--list-presets"])
    refute_empty result[:stdout].strip
  end

  # --- Direct Invocation Tests (no subcommand needed) ---

  def test_cli_loads_project_preset_directly
    mock_context = Struct.new(:content, :metadata).new("mock content", {})
    Ace::Bundle.stub(:load_auto, mock_context) do
      result = invoke_cli(Ace::Bundle::CLI, ["project"])
      output = result[:stdout] + result[:stderr]
      refute_match(/unknown command/i, output)
    end
  end

  # --- Numeric Flag Conversion Tests ---

  def test_cli_converts_max_size_to_integer
    mock_context = Struct.new(:content, :metadata).new("mock content", {})
    Ace::Bundle.stub(:load_auto, mock_context) do
      result = invoke_cli(Ace::Bundle::CLI, ["project", "--max-size", "1024"])
      output = result[:stdout] + result[:stderr]
      refute_match(/ArgumentError.*String.*Integer/i, output)
      refute_match(/comparison.*failed/i, output)
    end
  end

  def test_cli_converts_timeout_to_integer
    mock_context = Struct.new(:content, :metadata).new("mock content", {})
    Ace::Bundle.stub(:load_auto, mock_context) do
      result = invoke_cli(Ace::Bundle::CLI, ["project", "--timeout", "60"])
      output = result[:stdout] + result[:stderr]
      refute_match(/ArgumentError.*String.*Integer/i, output)
      refute_match(/comparison.*failed/i, output)
    end
  end
end
