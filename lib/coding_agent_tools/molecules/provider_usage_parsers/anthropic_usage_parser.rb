# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module ProviderUsageParsers
      # AnthropicUsageParser extracts usage information from Anthropic Claude API responses
      # This is a molecule - it composes usage parsing logic for Anthropic-specific format
      class AnthropicUsageParser
        # Parse usage metadata from Anthropic API response
        # @param response [Hash] The raw API response
        # @return [Hash] Extracted usage information
        def self.parse(response)
          usage_metadata = response[:usage_metadata] || response['usage_metadata'] || {}

          {
            input_tokens: extract_input_tokens(usage_metadata),
            output_tokens: extract_output_tokens(usage_metadata),
            total_tokens: extract_total_tokens(usage_metadata),
            provider_specific: extract_provider_specific(response, usage_metadata),
            cached_tokens: extract_cached_tokens(usage_metadata)
          }.compact
        end

        # Extract input tokens from Anthropic usage metadata
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Number of input tokens
        def self.extract_input_tokens(usage)
          usage[:input_tokens] || usage['input_tokens'] || 0
        end

        # Extract output tokens from Anthropic usage metadata
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Number of output tokens
        def self.extract_output_tokens(usage)
          usage[:output_tokens] || usage['output_tokens'] || 0
        end

        # Calculate total tokens (Anthropic doesn't provide total, calculate it)
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Total token count
        def self.extract_total_tokens(usage)
          input_tokens = extract_input_tokens(usage)
          output_tokens = extract_output_tokens(usage)
          input_tokens + output_tokens
        end

        # Extract Anthropic-specific metadata
        # @param response [Hash] Full API response
        # @param usage [Hash] Usage metadata section
        # @return [Hash] Provider-specific data
        def self.extract_provider_specific(response, usage)
          specific_data = {}

          # Include cache-related token details
          cache_creation = usage[:cache_creation_input_tokens] || usage['cache_creation_input_tokens']
          specific_data[:cache_creation_input_tokens] = cache_creation if cache_creation && cache_creation > 0

          cache_read = usage[:cache_read_input_tokens] || usage['cache_read_input_tokens']
          specific_data[:cache_read_input_tokens] = cache_read if cache_read && cache_read > 0

          # Include service tier information
          service_tier = usage[:service_tier] || usage['service_tier']
          specific_data[:service_tier] = service_tier if service_tier

          # Include message metadata
          message_id = response[:id] || response['id']
          specific_data[:message_id] = message_id if message_id

          message_type = response[:type] || response['type']
          specific_data[:message_type] = message_type if message_type

          # Include stop sequence information
          stop_sequence = response[:stop_sequence] || response['stop_sequence']
          specific_data[:stop_sequence] = stop_sequence if stop_sequence

          specific_data.empty? ? nil : specific_data
        end

        # Extract cached tokens information (total cache usage)
        # @param usage [Hash] Usage metadata section
        # @return [Integer, nil] Number of cached tokens
        def self.extract_cached_tokens(usage)
          # Anthropic provides separate cache metrics, sum them for total cached tokens
          cache_creation = usage[:cache_creation_input_tokens] || usage['cache_creation_input_tokens'] || 0
          cache_read = usage[:cache_read_input_tokens] || usage['cache_read_input_tokens'] || 0

          total_cached = cache_creation + cache_read
          total_cached > 0 ? total_cached : nil
        end

        private_class_method :extract_input_tokens, :extract_output_tokens,
                             :extract_total_tokens, :extract_provider_specific, :extract_cached_tokens
      end
    end
  end
end
