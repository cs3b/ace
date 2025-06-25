# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module ProviderUsageParsers
      # MistralUsageParser extracts usage information from Mistral AI API responses
      # This is a molecule - it composes usage parsing logic for Mistral OpenAI-compatible format
      class MistralUsageParser
        # Parse usage metadata from Mistral API response
        # @param response [Hash] The raw API response
        # @return [Hash] Extracted usage information
        def self.parse(response)
          usage_metadata = response[:usage_metadata] || response["usage_metadata"] || {}

          {
            input_tokens: extract_input_tokens(usage_metadata),
            output_tokens: extract_output_tokens(usage_metadata),
            total_tokens: extract_total_tokens(usage_metadata),
            provider_specific: extract_provider_specific(response, usage_metadata)
          }.compact
        end

        # Extract input/prompt tokens from Mistral usage metadata
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Number of input tokens
        def self.extract_input_tokens(usage)
          usage[:prompt_tokens] || usage["prompt_tokens"] || 0
        end

        # Extract output/completion tokens from Mistral usage metadata
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Number of output tokens
        def self.extract_output_tokens(usage)
          usage[:completion_tokens] || usage["completion_tokens"] || 0
        end

        # Extract total tokens (Mistral provides this)
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Total token count
        def self.extract_total_tokens(usage)
          # Use provided total if available, otherwise calculate
          provided_total = usage[:total_tokens] || usage["total_tokens"]
          return provided_total if provided_total

          input_tokens = extract_input_tokens(usage)
          output_tokens = extract_output_tokens(usage)
          input_tokens + output_tokens
        end

        # Extract Mistral-specific metadata
        # @param response [Hash] Full API response
        # @param usage [Hash] Usage metadata section
        # @return [Hash] Provider-specific data
        def self.extract_provider_specific(response, usage)
          specific_data = {}

          # Include choice-level metadata
          first_choice = response.dig(:choices, 0) || response.dig("choices", 0)
          if first_choice
            # Index
            index = first_choice[:index] || first_choice["index"]
            specific_data[:choice_index] = index if index

            # Tool calls information
            message = first_choice[:message] || first_choice["message"]
            if message
              tool_calls = message[:tool_calls] || message["tool_calls"]
              specific_data[:tool_calls] = tool_calls if tool_calls && !tool_calls.empty?
            end
          end

          # Include response metadata
          response_id = response[:id] || response["id"]
          specific_data[:response_id] = response_id if response_id

          object_type = response[:object] || response["object"]
          specific_data[:object_type] = object_type if object_type

          created_timestamp = response[:created] || response["created"]
          specific_data[:created_timestamp] = created_timestamp if created_timestamp

          specific_data.empty? ? nil : specific_data
        end

        private_class_method :extract_input_tokens, :extract_output_tokens,
          :extract_total_tokens, :extract_provider_specific
      end
    end
  end
end
