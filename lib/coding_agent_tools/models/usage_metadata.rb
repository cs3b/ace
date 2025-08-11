# frozen_string_literal: true

module CodingAgentTools
  module Models
    # UsageMetadata represents normalized token usage and metadata across all LLM providers
    # This is a model - a plain data structure with consistent fields
    class UsageMetadata
      # Define the structure for normalized usage metadata
      # @param input_tokens [Integer] Number of input/prompt tokens
      # @param output_tokens [Integer] Number of output/completion tokens
      # @param total_tokens [Integer] Total token count (input + output)
      # @param took [Float] Execution time in seconds
      # @param provider [String] Provider name (google, anthropic, openai, etc.)
      # @param model [String] Model identifier
      # @param timestamp [String] ISO 8601 UTC timestamp
      # @param finish_reason [String] Normalized completion reason
      # @param provider_specific [Hash, nil] Provider-specific additional data
      # @param safety_ratings [Array, nil] Google-specific safety ratings
      # @param cached_tokens [Integer, nil] Number of cached tokens (when available)
      def initialize(
        input_tokens:,
        output_tokens:,
        total_tokens:,
        took:,
        provider:,
        model:,
        timestamp:,
        finish_reason:,
        provider_specific: nil,
        safety_ratings: nil,
        cached_tokens: nil
      )
        @input_tokens = input_tokens
        @output_tokens = output_tokens
        @total_tokens = total_tokens
        @took = took
        @provider = provider
        @model = model
        @timestamp = timestamp
        @finish_reason = finish_reason
        @provider_specific = provider_specific
        @safety_ratings = safety_ratings
        @cached_tokens = cached_tokens

        freeze
      end

      attr_reader :input_tokens, :output_tokens, :total_tokens, :took,
        :provider, :model, :timestamp, :finish_reason,
        :provider_specific, :safety_ratings, :cached_tokens

      # Convert to hash representation
      # @return [Hash] Hash representation of usage metadata
      def to_h
        {
          input_tokens: input_tokens,
          output_tokens: output_tokens,
          total_tokens: total_tokens,
          took: took,
          provider: provider,
          model: model,
          timestamp: timestamp,
          finish_reason: finish_reason,
          provider_specific: provider_specific,
          safety_ratings: safety_ratings,
          cached_tokens: cached_tokens
        }.compact
      end

      # Convert to JSON
      # @return [String] JSON representation
      def to_json(*args)
        to_h.to_json(*args)
      end

      # Check if metadata indicates successful completion
      # @return [Boolean] True if request completed successfully
      def successful?
        finish_reason == "stop"
      end

      # Check if request was truncated due to length limits
      # @return [Boolean] True if truncated due to length
      def truncated?
        finish_reason == "length"
      end

      # Check if request had errors
      # @return [Boolean] True if request failed
      def error?
        finish_reason == "error"
      end

      # Check if request was cancelled
      # @return [Boolean] True if request was cancelled
      def cancelled?
        finish_reason == "cancelled"
      end

      # Calculate tokens per second rate
      # @return [Float] Output tokens per second
      def tokens_per_second
        return 0.0 if took.zero? || output_tokens.zero?

        output_tokens.to_f / took
      end

      # Calculate cost efficiency (tokens per unit time)
      # @return [Float] Total tokens per second
      def efficiency_rate
        return 0.0 if took.zero? || total_tokens.zero?

        total_tokens.to_f / took
      end

      # Check if cached tokens were used (optimization indicator)
      # @return [Boolean] True if caching was utilized
      def cached?
        !cached_tokens.nil? && cached_tokens > 0
      end
    end
  end
end
