# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    # MetadataNormalizer provides consistent metadata handling across LLM providers
    # This is a molecule - it transforms provider-specific metadata into normalized format
    class MetadataNormalizer
      # Normalize metadata from different LLM providers into consistent format
      # @param response [Hash] Raw response from LLM provider
      # @param provider [String] Provider name (google, lmstudio)
      # @param model [String] Model name used
      # @param execution_time [Float] Time taken for request in seconds
      # @return [Hash] Normalized metadata structure
      def self.normalize(response, provider:, model:, execution_time:)
        case provider.to_s.downcase
        when "google"
          normalize_google_metadata(response, model, execution_time)
        when "lmstudio"
          normalize_lmstudio_metadata(response, model, execution_time)
        else
          normalize_unknown_metadata(response, provider, model, execution_time)
        end
      end

      # Get current timestamp in ISO 8601 format
      # @return [String] Current timestamp
      def self.current_timestamp
        Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
      end

      # Normalize Google response metadata
      # @param response [Hash] Google response
      # @param model [String] Model name
      # @param execution_time [Float] Execution time in seconds
      # @return [Hash] Normalized metadata
      def self.normalize_google_metadata(response, model, execution_time)
        usage = response[:usage_metadata] || {}

        {
          finish_reason: extract_finish_reason(response[:finish_reason]),
          input_tokens: usage[:promptTokenCount] || usage["promptTokenCount"] || 0,
          output_tokens: usage[:candidatesTokenCount] || usage["candidatesTokenCount"] || 0,
          total_tokens: calculate_total_tokens(usage, :gemini),
          took: execution_time.round(3),
          provider: "google",
          model: model,
          timestamp: current_timestamp,
          safety_ratings: response[:safety_ratings]
        }.compact
      end

      # Normalize LMStudio response metadata
      # @param response [Hash] LMStudio response
      # @param model [String] Model name
      # @param execution_time [Float] Execution time in seconds
      # @return [Hash] Normalized metadata
      def self.normalize_lmstudio_metadata(response, model, execution_time)
        usage = response[:usage_metadata] || {}

        {
          finish_reason: extract_finish_reason(response[:finish_reason]),
          input_tokens: usage[:prompt_tokens] || usage["prompt_tokens"] || 0,
          output_tokens: usage[:completion_tokens] || usage["completion_tokens"] || 0,
          total_tokens: calculate_total_tokens(usage, :lmstudio),
          took: execution_time.round(3),
          provider: "lmstudio",
          model: model,
          timestamp: current_timestamp
        }.compact
      end

      # Normalize metadata from unknown provider
      # @param response [Hash] Provider response
      # @param provider [String] Provider name
      # @param model [String] Model name
      # @param execution_time [Float] Execution time in seconds
      # @return [Hash] Normalized metadata
      def self.normalize_unknown_metadata(response, provider, model, execution_time)
        {
          finish_reason: extract_finish_reason(response[:finish_reason]),
          input_tokens: 0,
          output_tokens: 0,
          total_tokens: 0,
          took: execution_time.round(3),
          provider: provider.to_s,
          model: model,
          timestamp: current_timestamp,
          raw_usage: response[:usage_metadata]
        }.compact
      end

      # Extract and normalize finish reason
      # @param finish_reason [String, Symbol, nil] Raw finish reason
      # @return [String] Normalized finish reason
      def self.extract_finish_reason(finish_reason)
        return "unknown" if finish_reason.nil?

        case finish_reason.to_s.downcase
        when "stop", "finished"
          "stop"
        when "length", "max_tokens"
          "length"
        when "error", "failed"
          "error"
        when "cancelled", "canceled"
          "cancelled"
        else
          finish_reason.to_s
        end
      end

      # Calculate total tokens based on provider
      # @param usage [Hash] Usage metadata
      # @param provider [Symbol] Provider type
      # @return [Integer] Total token count
      def self.calculate_total_tokens(usage, provider)
        case provider
        when :gemini
          prompt_tokens = usage[:promptTokenCount] || usage["promptTokenCount"] || 0
          candidate_tokens = usage[:candidatesTokenCount] || usage["candidatesTokenCount"] || 0
          prompt_tokens + candidate_tokens
        when :lmstudio
          prompt_tokens = usage[:prompt_tokens] || usage["prompt_tokens"] || 0
          completion_tokens = usage[:completion_tokens] || usage["completion_tokens"] || 0
          prompt_tokens + completion_tokens
        else
          0
        end
      end

      # Mark private class methods
      private_class_method :normalize_google_metadata, :normalize_lmstudio_metadata,
        :normalize_unknown_metadata, :extract_finish_reason,
        :calculate_total_tokens
    end
  end
end
