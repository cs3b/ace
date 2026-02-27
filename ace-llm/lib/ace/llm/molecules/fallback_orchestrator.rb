# frozen_string_literal: true

require_relative "../atoms/error_classifier"
require_relative "../models/fallback_config"

module Ace
  module LLM
    module Molecules
      # FallbackOrchestrator manages provider fallback chain execution
      # This is a molecule - it coordinates between atoms and handles complex logic
      class FallbackOrchestrator
        attr_reader :config, :status_callback

        # @param config [Models::FallbackConfig] Fallback configuration
        # @param status_callback [Proc, nil] Optional callback for status messages
        def initialize(config:, status_callback: nil)
          @config = config
          @status_callback = status_callback
          @visited_providers = Set.new
          @start_time = nil
        end

        # Execute a block with fallback support
        # @param primary_provider [String] Primary provider name
        # @param registry [Molecules::ClientRegistry] Client registry for getting fallback providers
        # @yield Block to execute with current provider
        # @yieldparam client [Object] Provider client
        # @return [Object] Result from successful execution
        # @raise [Error] If all providers and retries exhausted
        def execute(primary_provider:, registry:)
          @start_time = Time.now
          @visited_providers.clear

          # If fallback disabled, just execute with primary
          return yield get_client(primary_provider, registry) if @config.disabled?

          # Try primary provider with retries
          result = try_provider_with_retry(primary_provider, registry) { |client| yield client }
          return result if result

          # Try fallback providers in order (per-provider chain or default)
          @config.providers_for(primary_provider).each do |fallback_provider|
            # Skip if we've already tried this provider
            next if @visited_providers.include?(fallback_provider)

            # Check total timeout
            if timeout_exceeded?
              report_status("⚠ Total timeout exceeded (#{@config.max_total_timeout}s)")
              break
            end

            report_status("ℹ Trying fallback provider #{fallback_provider}...")

            result = try_provider_with_retry(fallback_provider, registry) { |client| yield client }
            return result if result
          end

          # All providers exhausted
          raise Ace::LLM::ProviderError, build_exhaustion_error_message
        end

        private

        # Try a provider with retry logic
        # @param provider_name [String] Provider name
        # @param registry [Molecules::ClientRegistry] Client registry
        # @yield Block to execute with client
        # @return [Object, nil] Result if successful, nil if all retries failed
        def try_provider_with_retry(provider_name, registry)
          @visited_providers << provider_name
          attempts = 0
          last_error = nil

          loop do
            begin
              client = get_client(provider_name, registry)
              return yield client
            rescue => error
              last_error = error

              # Handle the error - returns :retry or :stop_and_fallback
              action = handle_error(error, provider_name, attempts)

              if action == :retry
                attempts += 1
                next
              else # :stop_and_fallback
                return nil
              end
            end
          end
        end

        # Handle error and determine retry/fallback strategy
        # @param error [Exception] The error that occurred
        # @param provider_name [String] Provider name
        # @param attempts [Integer] Current attempt number
        # @return [Symbol] :retry to retry, :stop_and_fallback to move to next provider
        def handle_error(error, provider_name, attempts)
          classification = Atoms::ErrorClassifier.classify(error)

          case classification
          when Atoms::ErrorClassifier::SKIP_TO_NEXT
            report_status("⚠ #{provider_name} authentication failed, skipping...")
            :stop_and_fallback
          when Atoms::ErrorClassifier::FALLBACK_IMMEDIATELY
            reason = if Atoms::ErrorClassifier.quota_or_credit_limited?(error)
                       "quota/credit/window limit reached"
                     else
                       "timeout"
                     end
            report_status("⚠ #{provider_name} #{reason}, trying next provider...")
            :stop_and_fallback
          when Atoms::ErrorClassifier::RETRYABLE_WITH_BACKOFF
            if attempts < @config.retry_count && !timeout_exceeded?
              delay = Atoms::ErrorClassifier.retry_delay(
                error,
                attempt: attempts + 1,
                base_delay: @config.retry_delay
              )
              report_status("⚠ #{provider_name} unavailable (#{extract_error_code(error)}), retrying... (attempt #{attempts + 2}/#{@config.retry_count + 1})")
              wait(delay)
              :retry
            else
              report_status("⚠ #{provider_name} unavailable after #{attempts + 1} retries")
              :stop_and_fallback
            end
          when Atoms::ErrorClassifier::TERMINAL
            report_status("⚠ #{provider_name} error: #{error.message}")
            :stop_and_fallback
          end
        end

        # Get a client from the registry
        # @param provider_name [String] Provider name
        # @param registry [Molecules::ClientRegistry] Client registry
        # @return [Object] Provider client
        def get_client(provider_name, registry)
          # Parse provider:model format if present
          if provider_name.include?(":")
            provider, model = provider_name.split(":", 2)
            registry.get_client(provider, model: model)
          else
            registry.get_client(provider_name)
          end
        end

        # Check if total timeout exceeded
        # @return [Boolean]
        def timeout_exceeded?
          return false unless @start_time

          elapsed = Time.now - @start_time
          elapsed >= @config.max_total_timeout
        end

        # Extract error code from error message
        # @param error [Exception] Error
        # @return [String] Error code or type
        def extract_error_code(error)
          status = Atoms::ErrorClassifier.extract_status_code(error)
          return status.to_s if status

          # Try to identify error type
          case error
          when Faraday::TimeoutError
            "timeout"
          when Faraday::ConnectionFailed
            "connection failed"
          when Ace::LLM::ProviderError
            "provider error"
          else
            "error"
          end
        end

        # Build error message for when all providers are exhausted
        # @return [String] Error message
        def build_exhaustion_error_message
          providers_tried = @visited_providers.to_a.join(", ")

          msg = "All configured providers unavailable. "
          msg += "Tried: #{providers_tried}. "
          msg += "\nTry:\n"
          msg += "  - Check provider status pages\n"
          msg += "  - Configure additional providers\n"
          msg += "  - Retry in a few minutes\n"
          msg += "  - Run with --debug for detailed errors"
          msg
        end

        # Report status message via callback
        # @param message [String] Status message
        def report_status(message)
          return unless @status_callback

          @status_callback.call(message)
        end

        # Wait for specified duration
        # Extracted to protected method for easier testing without actual sleep
        # @param duration [Float] Duration in seconds
        def wait(duration)
          sleep(duration)
        end
      end
    end
  end
end
