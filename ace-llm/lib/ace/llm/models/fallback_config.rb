# frozen_string_literal: true

module Ace
  module LLM
    module Models
      # FallbackConfig represents fallback configuration settings
      # This is a model - pure data structure with validation
      class FallbackConfig
        attr_reader :enabled, :retry_count, :retry_delay, :providers, :max_total_timeout

        # Default configuration values
        DEFAULT_ENABLED = true
        DEFAULT_RETRY_COUNT = 3
        DEFAULT_RETRY_DELAY = 1.0
        DEFAULT_PROVIDERS = [].freeze
        DEFAULT_MAX_TOTAL_TIMEOUT = 30.0

        # @param enabled [Boolean] Whether fallback is enabled
        # @param retry_count [Integer] Number of retries before fallback
        # @param retry_delay [Float] Initial retry delay in seconds
        # @param providers [Array<String>] Fallback provider chain
        # @param max_total_timeout [Float] Maximum total time for all retries and fallbacks
        def initialize(enabled: DEFAULT_ENABLED,
                      retry_count: DEFAULT_RETRY_COUNT,
                      retry_delay: DEFAULT_RETRY_DELAY,
                      providers: DEFAULT_PROVIDERS,
                      max_total_timeout: DEFAULT_MAX_TOTAL_TIMEOUT)
          @enabled = enabled
          @retry_count = retry_count
          @retry_delay = retry_delay
          @providers = providers.freeze
          @max_total_timeout = max_total_timeout

          validate!
        end

        # Create FallbackConfig from a hash (e.g., from YAML)
        # @param hash [Hash] Configuration hash
        # @return [FallbackConfig] New instance
        def self.from_hash(hash)
          return new unless hash

          new(
            enabled: fetch_key(hash, :enabled, DEFAULT_ENABLED),
            retry_count: fetch_key(hash, :retry_count, DEFAULT_RETRY_COUNT),
            retry_delay: fetch_key(hash, :retry_delay, DEFAULT_RETRY_DELAY),
            providers: fetch_key(hash, :providers, DEFAULT_PROVIDERS),
            max_total_timeout: fetch_key(hash, :max_total_timeout, DEFAULT_MAX_TOTAL_TIMEOUT)
          )
        end

        # Convert to hash representation
        # @return [Hash] Configuration as hash
        def to_h
          {
            enabled: @enabled,
            retry_count: @retry_count,
            retry_delay: @retry_delay,
            providers: @providers.dup,
            max_total_timeout: @max_total_timeout
          }
        end

        # Check if fallback is enabled
        # @return [Boolean]
        def enabled?
          @enabled == true
        end

        # Check if fallback is disabled
        # @return [Boolean]
        def disabled?
          !enabled?
        end

        # Check if there are any fallback providers configured
        # @return [Boolean]
        def has_providers?
          @providers && !@providers.empty?
        end

        # Merge with another config (other takes precedence)
        # @param other [FallbackConfig, Hash] Config to merge
        # @return [FallbackConfig] New merged config
        def merge(other)
          other_hash = other.is_a?(Hash) ? other : other.to_h

          self.class.new(
            enabled: other_hash.fetch(:enabled, @enabled),
            retry_count: other_hash.fetch(:retry_count, @retry_count),
            retry_delay: other_hash.fetch(:retry_delay, @retry_delay),
            providers: other_hash.fetch(:providers, @providers),
            max_total_timeout: other_hash.fetch(:max_total_timeout, @max_total_timeout)
          )
        end

        private

        # Helper to fetch key from hash supporting both symbol and string keys
        # @param hash [Hash] Hash to fetch from
        # @param key [Symbol] Key to fetch
        # @param default [Object] Default value if key not found
        # @return [Object] Value from hash or default
        def self.fetch_key(hash, key, default)
          hash.fetch(key, hash.fetch(key.to_s, default))
        end

        # Validate configuration values
        # @raise [ConfigurationError] If configuration is invalid
        def validate!
          validate_retry_count!
          validate_retry_delay!
          validate_providers!
          validate_max_total_timeout!
        end

        def validate_retry_count!
          unless @retry_count.is_a?(Integer) && @retry_count >= 0
            raise Ace::LLM::ConfigurationError,
              "retry_count must be a non-negative integer, got: #{@retry_count.inspect}"
          end
        end

        def validate_retry_delay!
          unless @retry_delay.is_a?(Numeric) && @retry_delay > 0
            raise Ace::LLM::ConfigurationError,
              "retry_delay must be a positive number, got: #{@retry_delay.inspect}"
          end
        end

        def validate_providers!
          unless @providers.is_a?(Array)
            raise Ace::LLM::ConfigurationError,
              "providers must be an array, got: #{@providers.class}"
          end

          # Check for duplicates
          duplicates = @providers.group_by { |p| p }.select { |_, v| v.size > 1 }.keys
          unless duplicates.empty?
            raise Ace::LLM::ConfigurationError,
              "providers contains duplicates: #{duplicates.join(', ')}"
          end

          # Validate each provider string format
          @providers.each do |provider|
            unless provider.is_a?(String) && !provider.empty?
              raise Ace::LLM::ConfigurationError,
                "each provider must be a non-empty string, got: #{provider.inspect}"
            end
          end
        end

        def validate_max_total_timeout!
          unless @max_total_timeout.is_a?(Numeric) && @max_total_timeout > 0
            raise Ace::LLM::ConfigurationError,
              "max_total_timeout must be a positive number, got: #{@max_total_timeout.inspect}"
          end
        end
      end
    end
  end
end
