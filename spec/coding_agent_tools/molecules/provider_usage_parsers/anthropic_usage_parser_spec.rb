# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/molecules/provider_usage_parsers/anthropic_usage_parser'

RSpec.describe CodingAgentTools::Molecules::ProviderUsageParsers::AnthropicUsageParser do
  describe '.parse' do
    let(:anthropic_response) do
      {
        id: 'test-id',
        type: 'message',
        role: 'assistant',
        model: 'claude-3-5-haiku-20241022',
        content: [{ type: 'text', text: 'Hello! How are you doing today?' }],
        stop_reason: 'end_turn',
        stop_sequence: nil,
        usage_metadata: {
          input_tokens: 9,
          cache_creation_input_tokens: 0,
          cache_read_input_tokens: 0,
          output_tokens: 11,
          service_tier: 'standard'
        }
      }
    end

    it 'extracts usage information from Anthropic response' do
      result = described_class.parse(anthropic_response)

      expect(result).to include(
        input_tokens: 9,
        output_tokens: 11,
        total_tokens: 20
      )
    end

    it 'handles string keys in usage metadata' do
      response_with_string_keys = {
        'usage_metadata' => {
          'input_tokens' => 5,
          'output_tokens' => 15
        }
      }

      result = described_class.parse(response_with_string_keys)

      expect(result).to include(
        input_tokens: 5,
        output_tokens: 15,
        total_tokens: 20
      )
    end

    it 'handles missing usage metadata' do
      minimal_response = {}

      result = described_class.parse(minimal_response)

      expect(result).to include(
        input_tokens: 0,
        output_tokens: 0,
        total_tokens: 0
      )
    end

    it 'extracts cached tokens when available' do
      response_with_cache = {
        usage_metadata: {
          input_tokens: 9,
          output_tokens: 11,
          cache_creation_input_tokens: 5,
          cache_read_input_tokens: 3
        }
      }

      result = described_class.parse(response_with_cache)

      expect(result[:cached_tokens]).to eq(8) # 5 + 3
    end

    it 'extracts provider-specific metadata' do
      result = described_class.parse(anthropic_response)

      expect(result[:provider_specific]).to include(
        service_tier: 'standard',
        message_id: 'test-id',
        message_type: 'message'
      )
    end
  end
end
