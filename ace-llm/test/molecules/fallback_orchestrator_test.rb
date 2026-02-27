# frozen_string_literal: true

require "test_helper"
require "ace/llm/molecules/fallback_orchestrator"
require "ace/llm/models/fallback_config"
require "ace/llm/atoms/error_classifier"

module Ace
  module LLM
    module Molecules
      class FallbackOrchestratorTest < AceLlmTestCase
        def setup
          @status_messages = []
          @status_callback = ->(msg) { @status_messages << msg }
        end

        def test_executes_with_primary_when_successful
          config = Models::FallbackConfig.new
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          registry.add_client("google", MockClient.new(response: "success"))

          result = orchestrator.execute(primary_provider: "google", registry: registry) do |client|
            client.call
          end

          assert_equal "success", result
          assert_empty @status_messages
        end

        def test_executes_without_fallback_when_disabled
          config = Models::FallbackConfig.new(enabled: false)
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          registry.add_client("google", MockClient.new(response: "success"))

          result = orchestrator.execute(primary_provider: "google", registry: registry) do |client|
            client.call
          end

          assert_equal "success", result
          assert_empty @status_messages
        end

        def test_retries_on_retryable_error
          config = Models::FallbackConfig.new(retry_count: 2, retry_delay: 1.0)
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          # Fail twice, then succeed
          client = MockClient.new(
            errors: [
              mock_server_error(503),
              mock_server_error(503)
            ],
            response: "success"
          )
          registry.add_client("google", client)

          # Stub wait method to avoid actual sleep delays
          orchestrator.stub :wait, nil do
            result = orchestrator.execute(primary_provider: "google", registry: registry) do |c|
              c.call
            end

            assert_equal "success", result
            assert_includes @status_messages.join, "retrying"
          end
        end

        def test_falls_back_after_retry_exhaustion
          config = Models::FallbackConfig.new(
            retry_count: 1,
            retry_delay: 1.0,
            providers: ["anthropic"]
          )
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          # Primary fails all retries
          registry.add_client("google", MockClient.new(errors: [mock_server_error(503), mock_server_error(503), mock_server_error(503)]))
          # Fallback succeeds
          registry.add_client("anthropic", MockClient.new(response: "fallback success"))

          # Stub wait method to avoid actual sleep delays
          orchestrator.stub :wait, nil do
            result = orchestrator.execute(primary_provider: "google", registry: registry) do |client|
              client.call
            end

            assert_equal "fallback success", result
            assert_includes @status_messages.join, "Trying fallback provider anthropic"
          end
        end

        def test_skips_to_next_on_auth_error
          config = Models::FallbackConfig.new(
            retry_count: 3,
            providers: ["anthropic"]
          )
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          # Primary fails with auth error (should skip immediately)
          registry.add_client("google", MockClient.new(errors: [Ace::LLM::AuthenticationError.new("Invalid API key")]))
          # Fallback succeeds
          registry.add_client("anthropic", MockClient.new(response: "fallback success"))

          result = orchestrator.execute(primary_provider: "google", registry: registry) do |client|
            client.call
          end

          assert_equal "fallback success", result
          assert_includes @status_messages.join, "authentication failed"
          # Should not retry on auth error
          refute_includes @status_messages.join, "retrying"
        end

        def test_skips_to_next_on_timeout
          config = Models::FallbackConfig.new(
            retry_count: 3,
            providers: ["anthropic"]
          )
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          # Primary fails with timeout (should skip immediately)
          registry.add_client("google", MockClient.new(errors: [Faraday::TimeoutError.new("Timeout")]))
          # Fallback succeeds
          registry.add_client("anthropic", MockClient.new(response: "fallback success"))

          result = orchestrator.execute(primary_provider: "google", registry: registry) do |client|
            client.call
          end

          assert_equal "fallback success", result
          assert_includes @status_messages.join, "timeout"
        end

        def test_skips_to_next_immediately_on_quota_error
          config = Models::FallbackConfig.new(
            retry_count: 3,
            providers: ["anthropic"]
          )
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          quota_error = Ace::LLM::ProviderError.new("insufficient_quota: exhausted credits")
          registry.add_client("google", MockClient.new(errors: [quota_error]))
          registry.add_client("anthropic", MockClient.new(response: "fallback success"))

          result = orchestrator.execute(primary_provider: "google", registry: registry) do |client|
            client.call
          end

          assert_equal "fallback success", result
          assert_includes @status_messages.join, "quota/credit/window limit reached"
          refute_includes @status_messages.join, "retrying"
        end

        def test_tries_multiple_fallback_providers
          config = Models::FallbackConfig.new(
            retry_count: 0,
            providers: ["anthropic", "openai"]
          )
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          registry.add_client("google", MockClient.new(errors: [mock_server_error(503)]))
          registry.add_client("anthropic", MockClient.new(errors: [mock_server_error(503)]))
          registry.add_client("openai", MockClient.new(response: "openai success"))

          result = orchestrator.execute(primary_provider: "google", registry: registry) do |client|
            client.call
          end

          assert_equal "openai success", result
          assert_includes @status_messages.join, "Trying fallback provider anthropic"
          assert_includes @status_messages.join, "Trying fallback provider openai"
        end

        def test_raises_error_when_all_providers_exhausted
          config = Models::FallbackConfig.new(
            retry_count: 0,
            providers: ["anthropic"]
          )
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          registry.add_client("google", MockClient.new(errors: [mock_server_error(503)]))
          registry.add_client("anthropic", MockClient.new(errors: [mock_server_error(503)]))

          error = assert_raises(Ace::LLM::ProviderError) do
            orchestrator.execute(primary_provider: "google", registry: registry) do |client|
              client.call
            end
          end

          assert_match(/All configured providers unavailable/, error.message)
          assert_match(/google, anthropic/, error.message)
        end

        def test_skips_duplicate_providers_in_fallback_chain
          config = Models::FallbackConfig.new(
            retry_count: 0,
            providers: ["google", "anthropic"] # google is also primary
          )
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          google_client = MockClient.new(errors: [mock_server_error(503)])
          registry.add_client("google", google_client)
          registry.add_client("anthropic", MockClient.new(response: "anthropic success"))

          result = orchestrator.execute(primary_provider: "google", registry: registry) do |client|
            client.call
          end

          assert_equal "anthropic success", result
          # Should only try google once (as primary), not again in fallback
          assert_equal 1, google_client.call_count
        end

        def test_handles_provider_with_model_format
          config = Models::FallbackConfig.new(
            providers: ["anthropic:claude-3.5-sonnet"]
          )
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          registry.add_client("google", MockClient.new(errors: [mock_server_error(503)]))
          registry.add_client("anthropic", MockClient.new(response: "claude success"), model: "claude-3.5-sonnet")

          result = orchestrator.execute(primary_provider: "google", registry: registry) do |client|
            client.call
          end

          assert_equal "claude success", result
        end

        def test_respects_max_total_timeout
          config = Models::FallbackConfig.new(
            retry_count: 5,
            retry_delay: 1.0,
            max_total_timeout: 0.2,
            providers: ["anthropic", "openai"]
          )
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          registry.add_client("google", MockClient.new(errors: [mock_server_error(503)] * 10))
          registry.add_client("anthropic", MockClient.new(errors: [mock_server_error(503)] * 10))
          registry.add_client("openai", MockClient.new(errors: [mock_server_error(503)] * 10))

          # Stub wait to track calls and simulate time passing
          wait_calls = []
          orchestrator.stub :wait, ->(duration) { wait_calls << duration } do
            # Stub Time.now to simulate elapsed time exceeding timeout
            start_time = Time.now
            orchestrator.stub :timeout_exceeded?, -> { wait_calls.size > 1 } do
              error = assert_raises(Ace::LLM::ProviderError) do
                orchestrator.execute(primary_provider: "google", registry: registry) do |client|
                  client.call
                end
              end

              assert_match(/All configured providers unavailable/, error.message)
              assert_includes @status_messages.join, "Total timeout exceeded"
            end
          end
        end

        def test_uses_per_provider_chain_for_matching_primary
          config = Models::FallbackConfig.new(
            retry_count: 0,
            chains: { "google" => ["anthropic"] },
            providers: ["openai"]
          )
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          registry.add_client("google", MockClient.new(errors: [mock_server_error(503)]))
          registry.add_client("anthropic", MockClient.new(response: "chain success"))
          registry.add_client("openai", MockClient.new(response: "default success"))

          result = orchestrator.execute(primary_provider: "google", registry: registry) do |client|
            client.call
          end

          assert_equal "chain success", result
          assert_includes @status_messages.join, "Trying fallback provider anthropic"
          refute_includes @status_messages.join, "openai"
        end

        def test_uses_default_providers_when_primary_not_in_chains
          config = Models::FallbackConfig.new(
            retry_count: 0,
            chains: { "google" => ["anthropic"] },
            providers: ["openai"]
          )
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          registry.add_client("mistral", MockClient.new(errors: [mock_server_error(503)]))
          registry.add_client("openai", MockClient.new(response: "default success"))

          result = orchestrator.execute(primary_provider: "mistral", registry: registry) do |client|
            client.call
          end

          assert_equal "default success", result
          assert_includes @status_messages.join, "Trying fallback provider openai"
        end

        def test_reports_status_for_different_error_types
          config = Models::FallbackConfig.new(
            retry_count: 1,
            retry_delay: 1.0,
            providers: []
          )
          orchestrator = FallbackOrchestrator.new(
            config: config,
            status_callback: @status_callback
          )

          registry = MockRegistry.new
          registry.add_client("google", MockClient.new(errors: [mock_server_error(503), mock_server_error(503)]))

          # Stub wait method to avoid actual sleep delays
          orchestrator.stub :wait, nil do
            assert_raises(Ace::LLM::ProviderError) do
              orchestrator.execute(primary_provider: "google", registry: registry) do |client|
                client.call
              end
            end

            assert_includes @status_messages.join, "503"
          end
        end

        private

        # Mock client for testing
        class MockClient
          attr_reader :call_count

          def initialize(response: nil, errors: [])
            @response = response
            @errors = errors.dup
            @call_count = 0
          end

          def call
            @call_count += 1
            if @errors.any?
              raise @errors.shift
            else
              @response
            end
          end
        end

        # Mock registry for testing
        class MockRegistry
          def initialize
            @clients = {}
          end

          def add_client(provider, client, model: nil)
            key = model ? "#{provider}:#{model}" : provider
            @clients[key] = client
          end

          def get_client(provider, model: nil)
            key = model ? "#{provider}:#{model}" : provider
            @clients[key] || raise("No client for #{key}")
          end
        end

        def mock_server_error(status)
          response = { status: status, body: "Error" }
          Faraday::ServerError.new("Server error", response)
        end
      end
    end
  end
end
