# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module ProviderUsageParsers
      # LMStudioUsageParser extracts usage information from LM Studio API responses
      # This is a molecule - it composes usage parsing logic for LM Studio OpenAI-compatible format
      class LMStudioUsageParser
        # Parse usage metadata from LM Studio API response
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

        # Extract input/prompt tokens from LM Studio usage metadata
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Number of input tokens
        def self.extract_input_tokens(usage)
          usage[:prompt_tokens] || usage['prompt_tokens'] || 0
        end

        # Extract output/completion tokens from LM Studio usage metadata
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Number of output tokens
        def self.extract_output_tokens(usage)
          usage[:completion_tokens] || usage['completion_tokens'] || 0
        end

        # Extract total tokens (LM Studio provides this, but we can calculate if missing)
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Total token count
        def self.extract_total_tokens(usage)
          # Use provided total if available, otherwise calculate
          provided_total = usage[:total_tokens] || usage['total_tokens']
          return provided_total if provided_total

          input_tokens = extract_input_tokens(usage)
          output_tokens = extract_output_tokens(usage)
          input_tokens + output_tokens
        end

        # Extract LM Studio-specific metadata
        # @param response [Hash] Full API response
        # @param usage [Hash] Usage metadata section
        # @return [Hash] Provider-specific data
        def self.extract_provider_specific(response, _usage)
          specific_data = {}

          # Include system fingerprint if available
          fingerprint = response[:system_fingerprint] || response['system_fingerprint']
          specific_data[:system_fingerprint] = fingerprint if fingerprint

          # Include model-specific stats if available
          stats = response[:stats] || response['stats']
          specific_data[:stats] = stats if stats && !stats.empty?

          # Include choice-level metadata
          first_choice = response.dig(:choices, 0) || response.dig('choices', 0)
          if first_choice
            # Log probabilities
            logprobs = first_choice[:logprobs] || first_choice['logprobs']
            specific_data[:logprobs] = logprobs if logprobs

            # Seed used for generation
            seed = first_choice[:seed] || first_choice['seed']
            specific_data[:seed] = seed if seed

            # Index
            index = first_choice[:index] || first_choice['index']
            specific_data[:choice_index] = index if index
          end

          specific_data.empty? ? nil : specific_data
        end

        # Extract cached tokens information
        # @param usage [Hash] Usage metadata section
        # @return [Integer, nil] Number of cached tokens
        def self.extract_cached_tokens(usage)
          usage[:cached_tokens] || usage['cached_tokens']
        end

        private_class_method :extract_input_tokens, :extract_output_tokens,
                             :extract_total_tokens, :extract_provider_specific, :extract_cached_tokens
      end
    end
  end
end
