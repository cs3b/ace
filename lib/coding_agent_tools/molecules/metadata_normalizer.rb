# frozen_string_literal: true

require_relative 'provider_usage_parsers/google_usage_parser'
require_relative 'provider_usage_parsers/lmstudio_usage_parser'
require_relative 'provider_usage_parsers/anthropic_usage_parser'
require_relative 'provider_usage_parsers/openai_usage_parser'
require_relative 'provider_usage_parsers/mistral_usage_parser'
require_relative 'provider_usage_parsers/togetherai_usage_parser'
require_relative '../cost_tracker'
require_relative '../models/usage_metadata_with_cost'

module CodingAgentTools
  module Molecules
    # MetadataNormalizer provides consistent metadata handling across LLM providers
    # This is a molecule - it transforms provider-specific metadata into normalized format
    class MetadataNormalizer
      # Normalize metadata from different LLM providers into consistent format
      # @param response [Hash] Raw response from LLM provider
      # @param provider [String] Provider name (google, lmstudio, anthropic, openai, mistral, together_ai)
      # @param model [String] Model name used
      # @param execution_time [Float] Time taken for request in seconds
      # @return [Hash] Normalized metadata structure
      def self.normalize(response, provider:, model:, execution_time:)
        normalized_provider = normalize_provider_name(provider)
        usage_data = parse_usage_metadata(response, normalized_provider)

        build_normalized_metadata(
          response: response,
          provider: normalized_provider,
          model: model,
          execution_time: execution_time,
          usage_data: usage_data
        )
      end

      # Normalize metadata with cost calculation included
      # @param response [Hash] Raw response from LLM provider
      # @param provider [String] Provider name
      # @param model [String] Model name used
      # @param execution_time [Float] Time taken for request in seconds
      # @param cost_tracker [CostTracker, nil] Cost tracker instance (optional)
      # @return [Models::UsageMetadataWithCost] Enhanced metadata with cost info
      def self.normalize_with_cost(response, provider:, model:, execution_time:, cost_tracker: nil)
        # Get basic normalized metadata
        normalized_metadata = normalize(response, provider: provider, model: model, execution_time: execution_time)

        # Create base UsageMetadata object
        usage_metadata = Models::UsageMetadata.new(**normalized_metadata)

        # Calculate cost if tracker is provided
        cost_calculation = if cost_tracker
          begin
            cost_tracker.calculate_cost_with_fallback(
              model_id: model,
              input_tokens: usage_metadata.input_tokens,
              output_tokens: usage_metadata.output_tokens,
              cache_creation_tokens: 0,
              cache_read_tokens: usage_metadata.cached_tokens || 0
            )
          rescue
            # If cost calculation fails, continue without cost info
            nil
          end
        end

        # Return enhanced metadata with cost information
        Models::UsageMetadataWithCost.from_usage_metadata(usage_metadata, cost_calculation)
      end

      # Parse usage metadata using provider-specific parsers
      # @param response [Hash] Raw response from LLM provider
      # @param provider [String] Normalized provider name
      # @return [Hash] Parsed usage information
      def self.parse_usage_metadata(response, provider)
        case provider
        when 'google'
          ProviderUsageParsers::GoogleUsageParser.parse(response)
        when 'lmstudio'
          ProviderUsageParsers::LMStudioUsageParser.parse(response)
        when 'anthropic'
          ProviderUsageParsers::AnthropicUsageParser.parse(response)
        when 'openai'
          ProviderUsageParsers::OpenaiUsageParser.parse(response)
        when 'mistral'
          ProviderUsageParsers::MistralUsageParser.parse(response)
        when 'together_ai', 'togetherai'
          ProviderUsageParsers::TogetheraiUsageParser.parse(response)
        else
          # Fallback for unknown providers
          {
            input_tokens: 0,
            output_tokens: 0,
            total_tokens: 0,
            provider_specific: response[:usage_metadata] || response['usage_metadata']
          }
        end
      end

      # Build the final normalized metadata structure
      # @param response [Hash] Raw response
      # @param provider [String] Normalized provider name
      # @param model [String] Model name
      # @param execution_time [Float] Execution time in seconds
      # @param usage_data [Hash] Parsed usage information
      # @return [Hash] Complete normalized metadata
      def self.build_normalized_metadata(response:, provider:, model:, execution_time:, usage_data:)
        {
          finish_reason: extract_finish_reason(response[:finish_reason]),
          input_tokens: usage_data[:input_tokens] || 0,
          output_tokens: usage_data[:output_tokens] || 0,
          total_tokens: usage_data[:total_tokens] || 0,
          took: execution_time.round(3),
          provider: provider,
          model: model,
          timestamp: current_timestamp,
          safety_ratings: usage_data[:safety_ratings],
          cached_tokens: usage_data[:cached_tokens],
          provider_specific: usage_data[:provider_specific]
        }.compact
      end

      # Normalize provider name to consistent format
      # @param provider [String] Raw provider name
      # @return [String] Normalized provider name
      def self.normalize_provider_name(provider)
        case provider.to_s.downcase
        when 'together_ai', 'togetherai'
          'together_ai'
        else
          provider.to_s.downcase
        end
      end

      # Get current timestamp in ISO 8601 format
      # @return [String] Current timestamp
      def self.current_timestamp
        Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
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
          input_tokens: usage[:promptTokenCount] || usage['promptTokenCount'] || 0,
          output_tokens: usage[:candidatesTokenCount] || usage['candidatesTokenCount'] || 0,
          total_tokens: calculate_total_tokens(usage, :gemini),
          took: execution_time.round(3),
          provider: 'google',
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
          input_tokens: usage[:prompt_tokens] || usage['prompt_tokens'] || 0,
          output_tokens: usage[:completion_tokens] || usage['completion_tokens'] || 0,
          total_tokens: calculate_total_tokens(usage, :lmstudio),
          took: execution_time.round(3),
          provider: 'lmstudio',
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
        return 'unknown' if finish_reason.nil?

        case finish_reason.to_s.downcase
        when 'stop', 'finished'
          'stop'
        when 'length', 'max_tokens'
          'length'
        when 'error', 'failed'
          'error'
        when 'cancelled', 'canceled'
          'cancelled'
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
          prompt_tokens = usage[:promptTokenCount] || usage['promptTokenCount'] || 0
          candidate_tokens = usage[:candidatesTokenCount] || usage['candidatesTokenCount'] || 0
          prompt_tokens + candidate_tokens
        when :lmstudio
          prompt_tokens = usage[:prompt_tokens] || usage['prompt_tokens'] || 0
          completion_tokens = usage[:completion_tokens] || usage['completion_tokens'] || 0
          prompt_tokens + completion_tokens
        else
          0
        end
      end

      # Mark private class methods
      private_class_method :parse_usage_metadata, :build_normalized_metadata,
        :normalize_provider_name, :normalize_google_metadata, :normalize_lmstudio_metadata,
        :normalize_unknown_metadata, :extract_finish_reason,
        :calculate_total_tokens
    end
  end
end
