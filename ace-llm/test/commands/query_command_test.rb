# frozen_string_literal: true

require_relative "../test_helper"
require "ace/llm/cli"
require "ace/llm/cli/commands/query"
require "ace/test_support/config_helpers"
require "ace/test_support/cli_helpers"
require "webmock/minitest"

class QueryCommandTest < AceLlmTestCase
  include Ace::TestSupport::ConfigHelpers
  include Ace::TestSupport::CliHelpers

  def setup
    super
    WebMock.disable_net_connect!
  end

  def teardown
    WebMock.reset!
    WebMock.allow_net_connect!
    super
  end

  # Stub Google LLM API for tests that verify CLI routing (not API functionality)
  def stub_llm_api_success
    stub_request(:post, /generativelanguage\.googleapis\.com/)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          "candidates" => [{
            "content" => { "parts" => [{ "text" => "Mock response" }] }
          }],
          "usageMetadata" => { "promptTokenCount" => 5, "candidatesTokenCount" => 10 }
        }.to_json
      )
  end

  # Helper method to invoke CLI
  def invoke_llm_cli(args)
    invoke_cli_stdout(Ace::LLM::CLI, args)
  end

  # Helper method to get full result (stdout + stderr)
  def invoke_llm_cli_result(args)
    result = invoke_cli(Ace::LLM::CLI, args)
    result[:stdout] + result[:stderr]
  end

  # --- Model Flag with Provider:Model Format Tests ---

  def test_model_flag_with_provider_model_format_works
    stub_llm_api_success
    with_real_config do
      # This should NOT show help, but should attempt to execute
      result = invoke_llm_cli_result(["--model", "google:gemini-2.5-flash", "What is Ruby?"])
      # Should show something other than just help/usage - either output or provider info
      # The output may include provider aliases or other info, but it shouldn't be the full help
      refute_match(/^Usage: ace-llm query/, result)
    end
  end

  def test_model_flag_with_provider_model_format_no_prompt_shows_help
    with_real_config do
      output = invoke_llm_cli(["--model", "google:gemini-2.5-flash"])
      # Should show provider help since no prompt
      assert_match(/alias|Usage:/i, output)
    end
  end

  def test_timeout_option_is_normalized_before_query
    captured_timeout = nil

    Ace::LLM::QueryInterface.stub(
      :query,
      ->(*_args, **kwargs) do
        captured_timeout = kwargs[:timeout]
        { text: "ok", usage: {}, metadata: {} }
      end
    ) do
      with_real_config do
        invoke_llm_cli_result(["google:gemini-2.5-flash", "What is Ruby?", "--timeout", "600"])
      end
    end

    assert_equal 600.0, captured_timeout
  end

  def test_model_flag_with_invalid_provider_shows_error
    with_real_config do
      # When positional arg "test" is present, it's interpreted as provider_model
      # and --model is used for model override. Without prompt, shows provider help.
      output = invoke_llm_cli_result(["--model", "invalid:provider", "test"])
      # Should show aliases for the "test" provider (provider help)
      assert_match(/Available aliases/i, output)
    end
  end

  def test_model_flag_with_model_only_needs_provider
    with_real_config do
      # When positional arg "test" is present, it's interpreted as provider_model
      # and --model is used for model override. Without prompt, shows provider help.
      output = invoke_llm_cli_result(["--model", "unknown-model", "test"])
      # Should show aliases for the "test" provider (provider help)
      assert_match(/Available aliases/i, output)
    end
  end

  # --- Positional Provider Tests ---

  def test_positional_provider_takes_precedence
    stub_llm_api_success
    with_real_config do
      output = invoke_llm_cli_result(["google", "test", "--model", "gemini-2.0-flash-lite"])
      # Should not show help - CLI routing should work and return API response (mocked)
      refute_match(/^Usage: ace-llm query/, output)
    end
  end

  def test_positional_provider_model_still_works
    stub_llm_api_success
    with_real_config do
      output = invoke_llm_cli_result(["google:gemini-2.5-flash", "What is Ruby?"])
      # Should not show help - CLI routing should work and return API response (mocked)
      refute_match(/^Usage: ace-llm query/, output)
    end
  end

  def test_positional_provider_only_shows_help
    with_real_config do
      output = invoke_llm_cli(["google"])
      # Should show aliases/help for the provider
      assert_match(/alias|Usage:/i, output)
    end
  end

  def test_list_providers_shows_filtered_header_and_inactive_section
    registry = Struct.new(:list).new(
      [
        {
          name: "google",
          models: ["gemini-2.5-flash"],
          gem: "ace-llm",
          available: true,
          api_key_required: false,
          api_key_present: false
        }
      ]
    )
    def registry.list_providers_with_status
      list
    end

    configuration = Struct.new(:applied, :configured, :inactive) do
      def provider_filter_applied?
        applied
      end

      def configured_provider_names
        configured
      end

      def inactive_provider_names
        inactive
      end
    end.new(true, %w[google anthropic], ["anthropic"])

    Ace::LLM::Molecules::ClientRegistry.stub(:new, registry) do
      Ace::LLM.stub(:configuration, configuration) do
        output, = capture_io { Ace::LLM::CLI::Commands::Query.new.send(:list_providers) }
        assert_match(/Available LLM Providers \(filtered - 1 of 2 active\):/, output)
        assert_match(/google.*1 models/, output)
        assert_match(/Inactive providers \(1\):/, output)
        assert_match(/anthropic/, output)
      end
    end
  end
end
