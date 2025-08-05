# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/molecules/provider_usage_parsers/openai_usage_parser'

RSpec.describe CodingAgentTools::Molecules::ProviderUsageParsers::OpenaiUsageParser do
  describe '.parse' do
    let(:openai_response) do
      {
        id: 'test-id',
        object: 'chat.completion',
        created: 1_750_780_428,
        model: 'gpt-4o-mini-2024-07-18',
        choices: [
          {
            index: 0,
            message: {
              role: 'assistant',
              content: 'Hello! How can I assist you today?',
              refusal: nil,
              annotations: []
            },
            logprobs: nil,
            finish_reason: 'stop'
          }
        ],
        usage_metadata: {
          prompt_tokens: 9,
          completion_tokens: 9,
          total_tokens: 18,
          prompt_tokens_details: {
            cached_tokens: 0,
            audio_tokens: 0
          },
          completion_tokens_details: {
            reasoning_tokens: 0,
            audio_tokens: 0,
            accepted_prediction_tokens: 0,
            rejected_prediction_tokens: 0
          }
        },
        service_tier: 'default',
        system_fingerprint: 'fp_34a54ae93c'
      }
    end

    it 'extracts usage information from OpenAI response' do
      result = described_class.parse(openai_response)

      expect(result).to include(
        input_tokens: 9,
        output_tokens: 9,
        total_tokens: 18
      )
    end

    it 'extracts cached tokens when available' do
      response_with_cache = {
        usage_metadata: {
          prompt_tokens: 9,
          completion_tokens: 9,
          total_tokens: 18,
          prompt_tokens_details: {
            cached_tokens: 5
          }
        }
      }

      result = described_class.parse(response_with_cache)

      expect(result[:cached_tokens]).to eq(5)
    end

    it 'extracts provider-specific metadata' do
      result = described_class.parse(openai_response)

      expect(result[:provider_specific]).to include(
        service_tier: 'default',
        system_fingerprint: 'fp_34a54ae93c',
        choice_index: 0
      )
    end
  end
end
