# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module ProviderUsageParsers
      # OpenaiUsageParser extracts usage information from OpenAI API responses
      # This is a molecule - it composes usage parsing logic for OpenAI-specific format
      class OpenaiUsageParser
        # Parse usage metadata from OpenAI API response
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

        # Extract input/prompt tokens from OpenAI usage metadata
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Number of input tokens
        def self.extract_input_tokens(usage)
          usage[:prompt_tokens] || usage['prompt_tokens'] || 0
        end

        # Extract output/completion tokens from OpenAI usage metadata
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Number of output tokens
        def self.extract_output_tokens(usage)
          usage[:completion_tokens] || usage['completion_tokens'] || 0
        end

        # Extract total tokens (OpenAI provides this)
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

        # Extract OpenAI-specific metadata
        # @param response [Hash] Full API response
        # @param usage [Hash] Usage metadata section
        # @return [Hash] Provider-specific data
        def self.extract_provider_specific(response, usage)
          specific_data = {}

          # Include detailed token breakdown
          prompt_details = usage[:prompt_tokens_details] || usage['prompt_tokens_details']
          specific_data[:prompt_tokens_details] = prompt_details if prompt_details

          completion_details = usage[:completion_tokens_details] || usage['completion_tokens_details']
          specific_data[:completion_tokens_details] = completion_details if completion_details

          # Include service tier information
          service_tier = response[:service_tier] || response['service_tier']
          specific_data[:service_tier] = service_tier if service_tier

          # Include system fingerprint
          fingerprint = response[:system_fingerprint] || response['system_fingerprint']
          specific_data[:system_fingerprint] = fingerprint if fingerprint

          # Include choice-level metadata
          first_choice = response.dig(:choices, 0) || response.dig('choices', 0)
          if first_choice
            # Log probabilities
            logprobs = first_choice[:logprobs] || first_choice['logprobs']
            specific_data[:logprobs] = logprobs if logprobs

            # Index
            index = first_choice[:index] || first_choice['index']
            specific_data[:choice_index] = index if index

            # Refusal information
            message = first_choice[:message] || first_choice['message']
            if message
              refusal = message[:refusal] || message['refusal']
              specific_data[:refusal] = refusal if refusal

              annotations = message[:annotations] || message['annotations']
              specific_data[:annotations] = annotations if annotations && !annotations.empty?
            end
          end

          specific_data.empty? ? nil : specific_data
        end

        # Extract cached tokens information
        # @param usage [Hash] Usage metadata section
        # @return [Integer, nil] Number of cached tokens
        def self.extract_cached_tokens(usage)
          # OpenAI provides cached tokens in prompt_tokens_details
          prompt_details = usage[:prompt_tokens_details] || usage['prompt_tokens_details']
          return nil unless prompt_details

          cached = prompt_details[:cached_tokens] || prompt_details['cached_tokens']
          cached && cached > 0 ? cached : nil
        end

        private_class_method :extract_input_tokens, :extract_output_tokens,
          :extract_total_tokens, :extract_provider_specific, :extract_cached_tokens
      end
    end
  end
end
