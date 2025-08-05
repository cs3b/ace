# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/models/pricing'

RSpec.describe CodingAgentTools::Models::Pricing::PricingInfo do
  let(:pricing_info) do
    described_class.new(
      input_cost_per_token: 0.000003,
      output_cost_per_token: 0.000015,
      cache_creation_input_token_cost: 0.000001,
      cache_read_input_token_cost: 0.000001,
      max_tokens: 4096,
      mode: 'chat',
      supports_function_calling: true
    )
  end

  describe '#calculate_cost' do
    it 'calculates cost for basic token usage' do
      result = pricing_info.calculate_cost(
        input_tokens: 1000,
        output_tokens: 500
      )

      expect(result).to be_a(CodingAgentTools::Models::Pricing::CostCalculation)
      expect(result.input_cost).to eq(BigDecimal('0.003'))
      expect(result.output_cost).to eq(BigDecimal('0.0075'))
      expect(result.total_cost).to eq(BigDecimal('0.0105'))
      expect(result.currency).to eq('USD')
    end

    it 'calculates cost with cache tokens' do
      result = pricing_info.calculate_cost(
        input_tokens: 1000,
        output_tokens: 500,
        cache_creation_tokens: 200,
        cache_read_tokens: 100
      )

      expect(result.cache_creation_cost).to eq(BigDecimal('0.0002'))
      expect(result.cache_read_cost).to eq(BigDecimal('0.0001'))
      expect(result.total_cost).to eq(BigDecimal('0.0108'))
      expect(result.caching_used?).to be true
    end

    it 'handles zero token usage' do
      result = pricing_info.calculate_cost(
        input_tokens: 0,
        output_tokens: 0
      )

      expect(result.total_cost).to eq(BigDecimal(0))
      expect(result.caching_used?).to be false
    end
  end

  describe '#supports_caching?' do
    it 'returns true when cache pricing is available' do
      expect(pricing_info.supports_caching?).to be true
    end

    it 'returns false when no cache pricing' do
      no_cache_pricing = described_class.new(
        input_cost_per_token: 0.000003,
        output_cost_per_token: 0.000015
      )

      expect(no_cache_pricing.supports_caching?).to be false
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      hash = pricing_info.to_h

      expect(hash[:input_cost_per_token]).to eq(0.000003)
      expect(hash[:output_cost_per_token]).to eq(0.000015)
      expect(hash[:cache_creation_input_token_cost]).to eq(0.000001)
      expect(hash[:max_tokens]).to eq(4096)
      expect(hash[:mode]).to eq('chat')
    end
  end

  describe '.from_litellm' do
    let(:litellm_data) do
      {
        'input_cost_per_token' => 0.000003,
        'output_cost_per_token' => 0.000015,
        'max_tokens' => 4096,
        'mode' => 'chat',
        'supports_function_calling' => true
      }
    end

    it 'creates PricingInfo from LiteLLM data' do
      pricing = described_class.from_litellm(litellm_data)

      expect(pricing.input_cost_per_token).to eq(0.000003)
      expect(pricing.output_cost_per_token).to eq(0.000015)
      expect(pricing.max_tokens).to eq(4096)
      expect(pricing.mode).to eq('chat')
      expect(pricing.supports_function_calling).to be true
    end

    it 'handles missing fields with defaults' do
      minimal_data = {
        'input_cost_per_token' => 0.000003,
        'output_cost_per_token' => 0.000015
      }

      pricing = described_class.from_litellm(minimal_data)

      expect(pricing.input_cost_per_token).to eq(0.000003)
      expect(pricing.output_cost_per_token).to eq(0.000015)
      expect(pricing.mode).to eq('chat')
      expect(pricing.supports_function_calling).to be false
    end
  end
end

RSpec.describe CodingAgentTools::Models::Pricing::CostCalculation do
  let(:cost_calculation) do
    described_class.new(
      input_cost: BigDecimal('0.003'),
      output_cost: BigDecimal('0.0075'),
      cache_creation_cost: BigDecimal('0.0002'),
      cache_read_cost: BigDecimal('0.0001'),
      total_cost: BigDecimal('0.0108'),
      currency: 'USD'
    )
  end

  describe '#caching_used?' do
    it 'returns true when cache costs exist' do
      expect(cost_calculation.caching_used?).to be true
    end

    it 'returns false when no cache costs' do
      no_cache_calculation = described_class.new(
        input_cost: BigDecimal('0.003'),
        output_cost: BigDecimal('0.0075'),
        cache_creation_cost: BigDecimal(0),
        cache_read_cost: BigDecimal(0),
        total_cost: BigDecimal('0.0105'),
        currency: 'USD'
      )

      expect(no_cache_calculation.caching_used?).to be false
    end
  end

  describe '#format_cost' do
    it 'formats cost with 6 decimal places' do
      formatted = cost_calculation.format_cost(BigDecimal('0.123456789'))
      expect(formatted).to eq('$0.123457')
    end

    it 'handles zero cost' do
      formatted = cost_calculation.format_cost(BigDecimal(0))
      expect(formatted).to eq('$0.0')
    end
  end

  describe '#formatted_total' do
    it 'returns formatted total cost' do
      expect(cost_calculation.formatted_total).to eq('$0.0108')
    end
  end

  describe '#to_h' do
    it 'returns hash with rounded values' do
      hash = cost_calculation.to_h

      expect(hash[:input]).to eq(0.003)
      expect(hash[:output]).to eq(0.0075)
      expect(hash[:cache_creation]).to eq(0.0002)
      expect(hash[:cache_read]).to eq(0.0001)
      expect(hash[:total]).to eq(0.0108)
      expect(hash[:currency]).to eq('USD')
    end
  end

  describe '#to_json_hash' do
    it 'returns same as to_h' do
      expect(cost_calculation.to_json_hash).to eq(cost_calculation.to_h)
    end
  end
end
