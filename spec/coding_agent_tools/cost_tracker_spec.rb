# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/cost_tracker'
require 'coding_agent_tools/pricing_fetcher'
require 'coding_agent_tools/models/pricing'

RSpec.describe CodingAgentTools::CostTracker do
  let(:mock_pricing_fetcher) { instance_double(CodingAgentTools::PricingFetcher) }
  let(:cost_tracker) { described_class.new(pricing_fetcher: mock_pricing_fetcher) }

  let(:sample_litellm_pricing_data) do
    {
      'input_cost_per_token' => 0.000003,
      'output_cost_per_token' => 0.000015,
      'cache_creation_input_token_cost' => 0.000001,
      'cache_read_input_token_cost' => 0.000001,
      'max_tokens' => 4096,
      'mode' => 'chat',
      'supports_function_calling' => true
    }
  end

  describe '#calculate_cost' do
    context 'when model pricing is available' do
      before do
        allow(mock_pricing_fetcher).to receive(:get_model_pricing)
          .with('gpt-4o-mini')
          .and_return(sample_litellm_pricing_data)
      end

      it 'calculates cost for basic token usage' do
        result = cost_tracker.calculate_cost(
          model_id: 'gpt-4o-mini',
          input_tokens: 1000,
          output_tokens: 500
        )

        expect(result).to be_a(CodingAgentTools::Models::Pricing::CostCalculation)
        expect(result.input_cost).to eq(BigDecimal('0.003')) # 1000 * 0.000003
        expect(result.output_cost).to eq(BigDecimal('0.0075')) # 500 * 0.000015
        expect(result.total_cost).to eq(BigDecimal('0.0105'))
        expect(result.currency).to eq('USD')
      end

      it 'calculates cost including cache tokens' do
        result = cost_tracker.calculate_cost(
          model_id: 'gpt-4o-mini',
          input_tokens: 1000,
          output_tokens: 500,
          cache_creation_tokens: 200,
          cache_read_tokens: 100
        )

        expect(result.cache_creation_cost).to eq(BigDecimal('0.0002')) # 200 * 0.000001
        expect(result.cache_read_cost).to eq(BigDecimal('0.0001')) # 100 * 0.000001
        expect(result.total_cost).to eq(BigDecimal('0.0108')) # 0.003 + 0.0075 + 0.0002 + 0.0001
        expect(result.caching_used?).to be true
      end

      it 'returns cost calculation with zero tokens' do
        result = cost_tracker.calculate_cost(
          model_id: 'gpt-4o-mini',
          input_tokens: 0,
          output_tokens: 0
        )

        expect(result.total_cost).to eq(BigDecimal(0))
        expect(result.caching_used?).to be false
      end
    end

    context 'when model pricing is not available' do
      before do
        allow(mock_pricing_fetcher).to receive(:get_model_pricing)
          .with('unknown-model')
          .and_return(nil)
      end

      it 'raises ModelNotFoundError' do
        expect do
          cost_tracker.calculate_cost(
            model_id: 'unknown-model',
            input_tokens: 1000,
            output_tokens: 500
          )
        end.to raise_error(CodingAgentTools::CostTracker::ModelNotFoundError, /Pricing data not found for model: unknown-model/)
      end
    end
  end

  describe '#calculate_cost_with_fallback' do
    context 'with free models' do
      it 'returns zero cost for LMStudio models' do
        result = cost_tracker.calculate_cost_with_fallback(
          model_id: 'lmstudio/model',
          input_tokens: 1000,
          output_tokens: 500
        )

        expect(result.total_cost).to eq(BigDecimal(0))
      end

      it 'returns zero cost for free Gemini models' do
        result = cost_tracker.calculate_cost_with_fallback(
          model_id: 'gemini-1.5-flash',
          input_tokens: 1000,
          output_tokens: 500
        )

        expect(result.total_cost).to eq(BigDecimal(0))
      end
    end

    context 'with priced models' do
      before do
        allow(mock_pricing_fetcher).to receive(:get_model_pricing)
          .with('gpt-4o-mini')
          .and_return(sample_litellm_pricing_data)
      end

      it 'calculates normal cost for non-free models' do
        result = cost_tracker.calculate_cost_with_fallback(
          model_id: 'gpt-4o-mini',
          input_tokens: 1000,
          output_tokens: 500
        )

        expect(result.total_cost).to eq(BigDecimal('0.0105'))
      end
    end

    context 'when pricing data is missing' do
      before do
        allow(mock_pricing_fetcher).to receive(:get_model_pricing)
          .with('unknown-model')
          .and_return(nil)
      end

      it 'returns zero cost as fallback' do
        result = cost_tracker.calculate_cost_with_fallback(
          model_id: 'unknown-model',
          input_tokens: 1000,
          output_tokens: 500
        )

        expect(result.total_cost).to eq(BigDecimal(0))
      end
    end
  end

  describe '#has_pricing_for_model?' do
    it 'returns true when pricing is available' do
      allow(mock_pricing_fetcher).to receive(:has_model_pricing?)
        .with('gpt-4o-mini')
        .and_return(true)

      expect(cost_tracker.has_pricing_for_model?('gpt-4o-mini')).to be true
    end

    it 'returns false when pricing is not available' do
      allow(mock_pricing_fetcher).to receive(:has_model_pricing?)
        .with('unknown-model')
        .and_return(false)

      expect(cost_tracker.has_pricing_for_model?('unknown-model')).to be false
    end
  end

  describe '#get_pricing_info' do
    context 'when pricing data exists' do
      before do
        allow(mock_pricing_fetcher).to receive(:get_model_pricing)
          .with('gpt-4o-mini')
          .and_return(sample_litellm_pricing_data)
      end

      it 'returns PricingInfo object' do
        result = cost_tracker.get_pricing_info('gpt-4o-mini')

        expect(result).to be_a(CodingAgentTools::Models::Pricing::PricingInfo)
        expect(result.input_cost_per_token).to eq(0.000003)
        expect(result.output_cost_per_token).to eq(0.000015)
        expect(result.supports_caching?).to be true
      end
    end

    context 'when pricing data does not exist' do
      before do
        allow(mock_pricing_fetcher).to receive(:get_model_pricing)
          .with('unknown-model')
          .and_return(nil)
      end

      it 'returns nil' do
        result = cost_tracker.get_pricing_info('unknown-model')
        expect(result).to be_nil
      end
    end
  end

  describe '#free_model?' do
    it 'identifies LMStudio models as free' do
      expect(cost_tracker.free_model?('lmstudio/model')).to be true
      expect(cost_tracker.free_model?('local/model')).to be true
    end

    it 'identifies free tier Gemini models as free' do
      expect(cost_tracker.free_model?('gemini-1.5-flash')).to be true
    end

    it 'identifies paid models as not free' do
      expect(cost_tracker.free_model?('gpt-4o-mini')).to be false
      expect(cost_tracker.free_model?('claude-3-5-sonnet')).to be false
    end
  end

  describe '#get_model_suggestions' do
    before do
      allow(mock_pricing_fetcher).to receive(:available_models)
        .and_return([
          'gpt-4o-mini',
          'gpt-4o',
          'claude-3-5-sonnet',
          'claude-3-haiku',
          'gemini-2.0-flash'
        ])
    end

    it 'returns similar model suggestions' do
      suggestions = cost_tracker.get_model_suggestions('gpt-4')
      expect(suggestions).to include('gpt-4o-mini', 'gpt-4o')
    end

    it 'returns claude suggestions for claude input' do
      suggestions = cost_tracker.get_model_suggestions('claude')
      expect(suggestions).to include('claude-3-5-sonnet', 'claude-3-haiku')
    end

    it 'limits suggestions to 5 items' do
      suggestions = cost_tracker.get_model_suggestions('model')
      expect(suggestions.length).to be <= 5
    end
  end

  describe 'integration with usage metadata' do
    let(:usage_metadata) do
      CodingAgentTools::Models::UsageMetadata.new(
        input_tokens: 1000,
        output_tokens: 500,
        total_tokens: 1500,
        took: 2.5,
        provider: 'openai',
        model: 'gpt-4o-mini',
        timestamp: '2024-01-01T12:00:00Z',
        finish_reason: 'stop',
        cached_tokens: 100
      )
    end

    before do
      allow(mock_pricing_fetcher).to receive(:get_model_pricing)
        .with('gpt-4o-mini')
        .and_return(sample_litellm_pricing_data)
    end

    it 'calculates cost from usage metadata' do
      result = cost_tracker.calculate_cost_from_metadata(usage_metadata)

      expect(result.input_cost).to eq(BigDecimal('0.003')) # 1000 * 0.000003
      expect(result.output_cost).to eq(BigDecimal('0.0075')) # 500 * 0.000015
      expect(result.cache_read_cost).to eq(BigDecimal('0.0001')) # 100 * 0.000001
      expect(result.total_cost).to eq(BigDecimal('0.0106'))
    end
  end
end
