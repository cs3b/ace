# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module ProviderUsageParsers
      # GoogleUsageParser extracts usage information from Google Gemini API responses
      # This is a molecule - it composes usage parsing logic for Google-specific format
      class GoogleUsageParser
        # Parse usage metadata from Google Gemini API response
        # @param response [Hash] The raw API response
        # @return [Hash] Extracted usage information
        def self.parse(response)
          usage_metadata = response[:usageMetadata] || response['usageMetadata'] ||
                           response[:usage_metadata] || response['usage_metadata'] || {}

          {
            input_tokens: extract_input_tokens(usage_metadata),
            output_tokens: extract_output_tokens(usage_metadata),
            total_tokens: extract_total_tokens(usage_metadata),
            provider_specific: extract_provider_specific(response, usage_metadata),
            safety_ratings: response[:safetyRatings] || response['safetyRatings'] ||
              response[:safety_ratings] || response['safety_ratings'],
            cached_tokens: extract_cached_tokens(usage_metadata)
          }.compact
        end

        # Extract input/prompt tokens from Google usage metadata
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Number of input tokens
        def self.extract_input_tokens(usage)
          usage[:promptTokenCount] || usage['promptTokenCount'] || 0
        end

        # Extract output/candidate tokens from Google usage metadata
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Number of output tokens
        def self.extract_output_tokens(usage)
          usage[:candidatesTokenCount] || usage['candidatesTokenCount'] || 0
        end

        # Extract total tokens (Google provides this, but we can calculate if missing)
        # @param usage [Hash] Usage metadata section
        # @return [Integer] Total token count
        def self.extract_total_tokens(usage)
          # Use provided total if available, otherwise calculate
          provided_total = usage[:totalTokenCount] || usage['totalTokenCount']
          return provided_total if provided_total

          input_tokens = extract_input_tokens(usage)
          output_tokens = extract_output_tokens(usage)
          input_tokens + output_tokens
        end

        # Extract Google-specific metadata that doesn't fit standard fields
        # @param response [Hash] Full API response
        # @param usage [Hash] Usage metadata section
        # @return [Hash] Provider-specific data
        def self.extract_provider_specific(response, usage)
          specific_data = {}

          # Include token details if available
          prompt_details = usage[:promptTokensDetails] || usage['promptTokensDetails']
          specific_data[:prompt_token_details] = prompt_details if prompt_details

          candidate_details = usage[:candidatesTokensDetails] || usage['candidatesTokensDetails']
          specific_data[:candidate_token_details] = candidate_details if candidate_details

          # Include model version if available
          model_version = response[:modelVersion] || response['modelVersion']
          specific_data[:model_version] = model_version if model_version

          # Include response ID for debugging
          response_id = response[:responseId] || response['responseId']
          specific_data[:response_id] = response_id if response_id

          # Include average log probabilities if available
          avg_logprobs = response.dig(:candidates, 0, :avgLogprobs) ||
                         response.dig('candidates', 0, 'avgLogprobs')
          specific_data[:avg_logprobs] = avg_logprobs if avg_logprobs

          specific_data.empty? ? nil : specific_data
        end

        # Extract cached tokens information (if Google adds this in future)
        # @param usage [Hash] Usage metadata section
        # @return [Integer, nil] Number of cached tokens
        def self.extract_cached_tokens(usage)
          # Google doesn't currently provide cached token info in standard format
          # This is future-proofing for when they might add it
          usage[:cachedTokenCount] || usage['cachedTokenCount']
        end

        private_class_method :extract_input_tokens, :extract_output_tokens,
          :extract_total_tokens, :extract_provider_specific, :extract_cached_tokens
      end
    end
  end
end
