# frozen_string_literal: true

require "test_helper"

module Ace
  module LLM
    class QueryInterfaceFallbackTest < AceLlmTestCase
      def test_query_executes_without_fallback_when_disabled
        # Set environment to disable fallback
        ENV["ACE_LLM_FALLBACK_ENABLED"] = "false"

        # This test is minimal since we don't have real API keys
        # Just verify the interface accepts the fallback parameter
        assert_raises(Ace::LLM::Error) do
          QueryInterface.query(
            "nonexistent:model",
            "test prompt",
            fallback: false
          )
        end
      ensure
        ENV.delete("ACE_LLM_FALLBACK_ENABLED")
      end

      def test_load_fallback_config_from_environment
        ENV["ACE_LLM_FALLBACK_ENABLED"] = "true"
        ENV["ACE_LLM_FALLBACK_PROVIDERS"] = "anthropic,openai"
        ENV["ACE_LLM_FALLBACK_RETRY_COUNT"] = "5"
        ENV["ACE_LLM_FALLBACK_RETRY_DELAY"] = "2.0"
        ENV["ACE_LLM_FALLBACK_MAX_TOTAL_TIMEOUT"] = "45.0"

        config = with_config_fallback(nil) do
          QueryInterface.send(:load_fallback_config, nil, nil)
        end

        assert_equal true, config.enabled
        assert_equal 2, config.providers.length
        assert_match(/\Aanthropic:/, config.providers[0])
        assert_match(/\Aopenai:/, config.providers[1])
        assert_equal 5, config.retry_count
        assert_equal 2.0, config.retry_delay
        assert_equal 45.0, config.max_total_timeout
      ensure
        ENV.delete("ACE_LLM_FALLBACK_ENABLED")
        ENV.delete("ACE_LLM_FALLBACK_PROVIDERS")
        ENV.delete("ACE_LLM_FALLBACK_RETRY_COUNT")
        ENV.delete("ACE_LLM_FALLBACK_RETRY_DELAY")
        ENV.delete("ACE_LLM_FALLBACK_MAX_TOTAL_TIMEOUT")
      end

      def test_load_fallback_config_with_explicit_parameters
        config = with_config_fallback({ "enabled" => true }) do
          QueryInterface.send(
            :load_fallback_config,
            false,
            ["claude", "gpt"]
          )
        end

        assert_equal false, config.enabled
        assert_equal 2, config.providers.length
        assert_match(/\A(anthropic|claude):/, config.providers[0])
        assert_match(/\A(openai:|gpt)\b/, config.providers[1])
      end

      def test_load_fallback_config_defaults
        config = with_config_fallback(nil) do
          QueryInterface.send(:load_fallback_config, nil, nil)
        end

        assert_equal true, config.enabled
        assert_equal 3, config.retry_count
        assert_equal 1.0, config.retry_delay
        assert_equal [], config.providers
        assert_equal 30.0, config.max_total_timeout
      end

      def test_normalizes_numeric_timeout_string_for_query
        captured_timeout = nil

        QueryInterface.stub(
          :execute_with_fallback,
          ->(**kwargs) do
            captured_timeout = kwargs[:timeout]
            {}
          end
        ) do
          Molecules::ConfigLoader.stub(:get, ->(path) { path == "llm.timeout" ? "600" : {} }) do
            QueryInterface.query("google:gemini-2.5-flash", "test prompt", timeout: "600")
          end
        end

        assert_equal 600.0, captured_timeout
      end

      def test_invalid_timeout_string_raises_argument_error
        assert_raises(ArgumentError) do
          with_config_fallback(nil) do
            QueryInterface.query(
              "google:gemini-2.5-flash",
              "test prompt",
              timeout: "invalid"
            )
          end
        end
      end

      def test_load_fallback_config_from_configuration
        config = with_config_fallback(
          "enabled" => false,
          "retry_count" => 2,
          "retry_delay" => 0.75,
          "max_total_timeout" => 15.0,
          "providers" => ["openai:gpt-5"]
        ) do
          QueryInterface.send(:load_fallback_config, nil, nil)
        end

        assert_equal false, config.enabled
        assert_equal 2, config.retry_count
        assert_equal 0.75, config.retry_delay
        assert_equal 15.0, config.max_total_timeout
        assert_equal ["openai:gpt-5"], config.providers
      end

      def test_fallback_providers_from_env_are_split_and_trimmed
        ENV["ACE_LLM_FALLBACK_PROVIDERS"] = " anthropic , openai , mistral "

        config = with_config_fallback(nil) do
          QueryInterface.send(:load_fallback_config, nil, nil)
        end

        assert_equal 3, config.providers.length
        assert_match(/\Aanthropic:/, config.providers[0])
        assert_match(/\Aopenai:/, config.providers[1])
        assert_match(/\Amistral:/, config.providers[2])
      ensure
        ENV.delete("ACE_LLM_FALLBACK_PROVIDERS")
      end

      def test_explicit_fallback_param_overrides_environment
        ENV["ACE_LLM_FALLBACK_ENABLED"] = "true"

        config = with_config_fallback({ "enabled" => true }) do
          QueryInterface.send(:load_fallback_config, false, nil)
        end

        assert_equal false, config.enabled
      ensure
        ENV.delete("ACE_LLM_FALLBACK_ENABLED")
      end

      def test_explicit_providers_override_environment
        ENV["ACE_LLM_FALLBACK_PROVIDERS"] = "anthropic,openai"

        config = with_config_fallback(nil) do
          QueryInterface.send(:load_fallback_config, nil, ["claude"])
        end

        assert_equal 1, config.providers.length
        assert_match(/\A(anthropic|claude):/, config.providers.first)
      ensure
        ENV.delete("ACE_LLM_FALLBACK_PROVIDERS")
      end

      def test_chains_loaded_from_config_and_aliases_normalized
        parser = FakeParser.new(
          "glite" => FakeParseResult.new("google", "gemini-2.0-flash-lite", true),
          "codex" => FakeParseResult.new("openai", "codex-mini", true),
          "zai:glm-4.7-flashx" => FakeParseResult.new("zai", "glm-4.7-flashx", true)
        )

        config = with_config_fallback(
          "chains" => {
            "glite" => ["zai:glm-4.7-flashx", "codex"],
            "zai" => ["glite", "codex"]
          },
          "providers" => ["glite", "codex"]
        ) do
          QueryInterface.send(:load_fallback_config, nil, nil, parser: parser)
        end

        # Chains should be normalized
        assert_equal ["zai:glm-4.7-flashx", "openai:codex-mini"], config.providers_for("glite")
        assert_equal ["google:gemini-2.0-flash-lite", "openai:codex-mini"], config.providers_for("zai")
        # Default providers also normalized
        assert_equal ["google:gemini-2.0-flash-lite", "openai:codex-mini"], config.providers
        # Unknown primary gets default providers
        assert_equal config.providers, config.providers_for("unknown")
      end

      def test_fallback_providers_are_deduplicated_preserving_order
        parser = FakeParser.new(
          "glite" => FakeParseResult.new("google", "gemini-2.0-flash-lite", true),
          "google:gemini-2.0-flash-lite" => FakeParseResult.new("google", "gemini-2.0-flash-lite", true),
          "openai:gpt-5" => FakeParseResult.new("openai", "gpt-5", true)
        )

        config = with_config_fallback(
          "providers" => [
            "glite",
            "google:gemini-2.0-flash-lite",
            "openai:gpt-5",
            "openai:gpt-5"
          ]
        ) do
          QueryInterface.send(:load_fallback_config, nil, nil, parser: parser)
        end

        assert_equal ["google:gemini-2.0-flash-lite", "openai:gpt-5"], config.providers
      end

      def test_query_applies_preset_defaults_from_model_suffix
        parse_result = Ace::LLM::Molecules::ProviderModelParser::ParseResult.new(
          "google", "gemini-2.5-flash", "ro", true, nil, "google:gemini-2.5-flash@ro"
        )
        parser = SingleParseParser.new(parse_result)
        captured = {}
        captured_preset_call = {}

        with_query_stubs(parser: parser, preset: {
                           "temperature" => 0.2,
                           "max_tokens" => 256,
                           "timeout" => 450,
                           "cli_args" => "--safe-mode",
                           "system_append" => "preset guidance",
                           "subprocess_env" => { "ACE_MODE" => "safe" }
                         }, captured: captured, captured_preset_call: captured_preset_call) do
          result = QueryInterface.query("google:gemini-2.5-flash@ro", "test prompt", fallback: false)

          assert_equal "ro", result[:preset]
        end

        assert_equal "ro", captured_preset_call[:name]
        assert_equal "google", captured_preset_call[:provider]
        assert_equal 450.0, captured[:timeout]
        assert_equal 0.2, captured[:generation_opts][:temperature]
        assert_equal 256, captured[:generation_opts][:max_tokens]
        assert_equal "--safe-mode", captured[:generation_opts][:cli_args]
        assert_equal "preset guidance", captured[:generation_opts][:system_append]
        assert_equal({ "ACE_MODE" => "safe" }, captured[:generation_opts][:subprocess_env])
      end

      def test_query_accepts_cli_args_array_from_provider_scoped_preset
        parse_result = Ace::LLM::Molecules::ProviderModelParser::ParseResult.new(
          "codex", "gpt-5.3-codex", "rw", true, nil, "codex:codex@rw"
        )
        parser = SingleParseParser.new(parse_result)
        captured = {}

        with_query_stubs(parser: parser, preset: {
                           "timeout" => 900,
                           "cli_args" => ["--full-auto", "-c", "sandbox_mode=\"read-only\"", "-c", "model_reasoning_effort=\"high\""]
                         }, captured: captured) do
          QueryInterface.query("codex:codex@rw", "test prompt", fallback: false)
        end

        assert_equal 900.0, captured[:timeout]
        assert_equal ["--full-auto", "-c", "sandbox_mode=\"read-only\"", "-c", "model_reasoning_effort=\"high\""], captured[:generation_opts][:cli_args]
      end

      def test_query_applies_claude_provider_scoped_cli_args
        parse_result = Ace::LLM::Molecules::ProviderModelParser::ParseResult.new(
          "claude", "claude-sonnet-4-6", "ro", true, nil, "claude:sonnet@ro"
        )
        parser = SingleParseParser.new(parse_result)
        captured = {}

        with_query_stubs(parser: parser, preset: {
                           "cli_args" => ["--effort", "medium"]
                         }, captured: captured) do
          QueryInterface.query("claude:sonnet@ro", "test prompt", fallback: false)
        end

        assert_equal ["--effort", "medium"], captured[:generation_opts][:cli_args]
      end

      def test_query_applies_gemini_provider_scoped_cli_args
        parse_result = Ace::LLM::Molecules::ProviderModelParser::ParseResult.new(
          "gemini", "gemini-2.5-pro", "rw", true, nil, "gemini:pro@rw"
        )
        parser = SingleParseParser.new(parse_result)
        captured = {}

        with_query_stubs(parser: parser, preset: {
                           "cli_args" => ["--approval-mode", "plan", "--sandbox"]
                         }, captured: captured) do
          QueryInterface.query("gemini:pro@rw", "test prompt", fallback: false)
        end

        assert_equal ["--approval-mode", "plan", "--sandbox"], captured[:generation_opts][:cli_args]
      end

      def test_explicit_query_options_override_preset_defaults
        parse_result = Ace::LLM::Molecules::ProviderModelParser::ParseResult.new(
          "google", "gemini-2.5-flash", "ro", true, nil, "google:gemini-2.5-flash@ro"
        )
        parser = SingleParseParser.new(parse_result)
        captured = {}

        with_query_stubs(parser: parser, preset: {
                           "temperature" => 0.2,
                           "max_tokens" => 256,
                           "timeout" => 450,
                           "cli_args" => "--safe-mode",
                           "system_append" => "preset guidance",
                           "subprocess_env" => { "ACE_MODE" => "safe" }
                         }, captured: captured) do
          QueryInterface.query(
            "google:gemini-2.5-flash@ro",
            "test prompt",
            temperature: 0.7,
            max_tokens: 42,
            timeout: 120,
            cli_args: "--explicit-arg",
            system_append: "explicit guidance",
            subprocess_env: { "ACE_MODE" => "explicit" },
            fallback: false
          )
        end

        assert_equal 120.0, captured[:timeout]
        assert_equal 0.7, captured[:generation_opts][:temperature]
        assert_equal 42, captured[:generation_opts][:max_tokens]
        assert_equal "--explicit-arg", captured[:generation_opts][:cli_args]
        assert_equal "explicit guidance", captured[:generation_opts][:system_append]
        assert_equal({ "ACE_MODE" => "explicit" }, captured[:generation_opts][:subprocess_env])
      end

      def test_query_rejects_suffix_and_flag_preset_combination
        parse_result = Ace::LLM::Molecules::ProviderModelParser::ParseResult.new(
          "google", "gemini-2.5-flash", "ro", true, nil, "google:gemini-2.5-flash@ro"
        )
        parser = SingleParseParser.new(parse_result)

        Molecules::ClientRegistry.stub(:new, Object.new) do
          Molecules::ProviderModelParser.stub(:new, parser) do
            assert_raises(Ace::LLM::Error) do
              QueryInterface.query(
                "google:gemini-2.5-flash@ro",
                "test prompt",
                preset: "rw",
                fallback: false
              )
            end
          end
        end
      end

      private

      FakeParseResult = Struct.new(:provider, :model, :valid) do
        def valid?
          valid
        end
      end

      class FakeParser
        def initialize(results)
          @results = results
        end

        def parse(input)
          @results.fetch(input.to_s.strip, FakeParseResult.new(nil, nil, false))
        end
      end

      class SingleParseParser
        def initialize(result)
          @result = result
        end

        def parse(_input)
          @result
        end
      end

      def with_config_fallback(config_hash)
        Ace::LLM::Molecules::ConfigLoader.stub(:get, ->(path) { path == "llm.fallback" ? config_hash : nil }) do
          yield
        end
      end

      def with_query_stubs(parser:, preset:, captured:, captured_preset_call: nil)
        Molecules::ClientRegistry.stub(:new, Object.new) do
          Molecules::ProviderModelParser.stub(:new, parser) do
            Ace::LLM.stub(:preset_for_provider, lambda { |name, provider|
              if captured_preset_call
                captured_preset_call[:name] = name
                captured_preset_call[:provider] = provider
              end
              preset
            }) do
              QueryInterface.stub(:execute_with_fallback, ->(**kwargs) do
                captured[:timeout] = kwargs[:timeout]
                captured[:generation_opts] = kwargs[:generation_opts]
                { text: "ok", usage: {}, metadata: {} }
              end) do
                Molecules::ConfigLoader.stub(:get, ->(path) { path == "llm.fallback" ? nil : nil }) do
                  yield
                end
              end
            end
          end
        end
      end
    end
  end
end
