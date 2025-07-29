# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/models/usage_metadata_with_cost"
require "coding_agent_tools/models/pricing"

RSpec.describe CodingAgentTools::Models::UsageMetadataWithCost do
  let(:base_attributes) do
    {
      input_tokens: 100,
      output_tokens: 50,
      total_tokens: 150,
      took: 2.5,
      provider: "test_provider",
      model: "test_model",
      timestamp: "2024-01-01T12:00:00Z",
      finish_reason: "stop"
    }
  end

  let(:cost_calculation) do
    CodingAgentTools::Models::Pricing::CostCalculation.new(
      input_cost: BigDecimal("0.003"),
      output_cost: BigDecimal("0.0075"),
      cache_creation_cost: BigDecimal("0.0002"),
      cache_read_cost: BigDecimal("0.0001"),
      total_cost: BigDecimal("0.0108"),
      currency: "USD"
    )
  end

  let(:zero_cost_calculation) do
    CodingAgentTools::Models::Pricing::CostCalculation.new(
      input_cost: BigDecimal("0"),
      output_cost: BigDecimal("0"),
      cache_creation_cost: BigDecimal("0"),
      cache_read_cost: BigDecimal("0"),
      total_cost: BigDecimal("0"),
      currency: "USD"
    )
  end

  describe "#initialize" do
    context "with cost calculation" do
      it "creates a usage metadata with cost instance" do
        metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)

        expect(metadata.input_tokens).to eq(100)
        expect(metadata.output_tokens).to eq(50)
        expect(metadata.total_tokens).to eq(150)
        expect(metadata.took).to eq(2.5)
        expect(metadata.provider).to eq("test_provider")
        expect(metadata.model).to eq("test_model")
        expect(metadata.timestamp).to eq("2024-01-01T12:00:00Z")
        expect(metadata.finish_reason).to eq("stop")
        expect(metadata.cost_calculation).to eq(cost_calculation)
      end

      it "creates an immutable instance" do
        metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)
        expect(metadata).to be_frozen
      end
    end

    context "without cost calculation" do
      it "creates a usage metadata instance with nil cost" do
        metadata = described_class.new(**base_attributes)

        expect(metadata.cost_calculation).to be_nil
        expect(metadata.input_tokens).to eq(100)
        expect(metadata.output_tokens).to eq(50)
      end
    end

    context "with optional attributes" do
      it "includes provider_specific and cached_tokens" do
        full_attributes = base_attributes.merge(
          provider_specific: {custom_field: "value"},
          cached_tokens: 25,
          cost_calculation: cost_calculation
        )

        metadata = described_class.new(**full_attributes)

        expect(metadata.provider_specific).to eq({custom_field: "value"})
        expect(metadata.cached_tokens).to eq(25)
        expect(metadata.cost_calculation).to eq(cost_calculation)
      end
    end
  end

  describe "#has_cost_info?" do
    context "with cost calculation" do
      it "returns true" do
        metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)
        expect(metadata.has_cost_info?).to be true
      end
    end

    context "without cost calculation" do
      it "returns false" do
        metadata = described_class.new(**base_attributes)
        expect(metadata.has_cost_info?).to be false
      end
    end
  end

  describe "#total_cost" do
    context "with cost calculation" do
      it "returns the total cost as float" do
        metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)
        expect(metadata.total_cost).to eq(0.0108)
      end
    end

    context "without cost calculation" do
      it "returns 0.0" do
        metadata = described_class.new(**base_attributes)
        expect(metadata.total_cost).to eq(0.0)
      end
    end

    context "with zero cost calculation" do
      it "returns 0.0" do
        metadata = described_class.new(**base_attributes, cost_calculation: zero_cost_calculation)
        expect(metadata.total_cost).to eq(0.0)
      end
    end
  end

  describe "#input_cost" do
    context "with cost calculation" do
      it "returns the input cost as float" do
        metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)
        expect(metadata.input_cost).to eq(0.003)
      end
    end

    context "without cost calculation" do
      it "returns 0.0" do
        metadata = described_class.new(**base_attributes)
        expect(metadata.input_cost).to eq(0.0)
      end
    end
  end

  describe "#output_cost" do
    context "with cost calculation" do
      it "returns the output cost as float" do
        metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)
        expect(metadata.output_cost).to eq(0.0075)
      end
    end

    context "without cost calculation" do
      it "returns 0.0" do
        metadata = described_class.new(**base_attributes)
        expect(metadata.output_cost).to eq(0.0)
      end
    end
  end

  describe "#cache_cost" do
    context "with cost calculation that includes caching" do
      it "returns the sum of cache creation and read costs" do
        metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)
        expect(metadata.cache_cost).to eq(0.0003) # 0.0002 + 0.0001
      end
    end

    context "without cost calculation" do
      it "returns 0.0" do
        metadata = described_class.new(**base_attributes)
        expect(metadata.cache_cost).to eq(0.0)
      end
    end

    context "with cost calculation without caching" do
      let(:no_cache_cost_calculation) do
        CodingAgentTools::Models::Pricing::CostCalculation.new(
          input_cost: BigDecimal("0.003"),
          output_cost: BigDecimal("0.0075"),
          cache_creation_cost: BigDecimal("0"),
          cache_read_cost: BigDecimal("0"),
          total_cost: BigDecimal("0.0105"),
          currency: "USD"
        )
      end

      it "returns 0.0" do
        metadata = described_class.new(**base_attributes, cost_calculation: no_cache_cost_calculation)
        expect(metadata.cache_cost).to eq(0.0)
      end
    end
  end

  describe "#cost_per_token" do
    context "with cost calculation and tokens" do
      it "calculates cost per token correctly" do
        metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)
        # total_cost (0.0108) / total_tokens (150) = 0.000072
        expect(metadata.cost_per_token).to eq(0.000072)
      end
    end

    context "without cost calculation" do
      it "returns 0.0" do
        metadata = described_class.new(**base_attributes)
        expect(metadata.cost_per_token).to eq(0.0)
      end
    end

    context "with zero total tokens" do
      it "returns 0.0" do
        zero_tokens_attributes = base_attributes.merge(total_tokens: 0)
        metadata = described_class.new(**zero_tokens_attributes, cost_calculation: cost_calculation)
        expect(metadata.cost_per_token).to eq(0.0)
      end
    end

    context "with zero cost" do
      it "returns 0.0" do
        metadata = described_class.new(**base_attributes, cost_calculation: zero_cost_calculation)
        expect(metadata.cost_per_token).to eq(0.0)
      end
    end
  end

  describe "#cost_per_second" do
    context "with cost calculation and execution time" do
      it "calculates cost per second correctly" do
        metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)
        # total_cost (0.0108) / took (2.5) = 0.00432
        expect(metadata.cost_per_second).to eq(0.00432)
      end
    end

    context "without cost calculation" do
      it "returns 0.0" do
        metadata = described_class.new(**base_attributes)
        expect(metadata.cost_per_second).to eq(0.0)
      end
    end

    context "with zero execution time" do
      it "returns 0.0" do
        zero_time_attributes = base_attributes.merge(took: 0.0)
        metadata = described_class.new(**zero_time_attributes, cost_calculation: cost_calculation)
        expect(metadata.cost_per_second).to eq(0.0)
      end
    end

    context "with zero cost" do
      it "returns 0.0" do
        metadata = described_class.new(**base_attributes, cost_calculation: zero_cost_calculation)
        expect(metadata.cost_per_second).to eq(0.0)
      end
    end
  end

  describe "#to_h" do
    context "with cost calculation" do
      it "includes cost information in hash" do
        metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)
        hash = metadata.to_h

        expect(hash).to include(
          input_tokens: 100,
          output_tokens: 50,
          total_tokens: 150,
          took: 2.5,
          provider: "test_provider",
          model: "test_model",
          timestamp: "2024-01-01T12:00:00Z",
          finish_reason: "stop"
        )

        expect(hash[:cost]).to eq(cost_calculation.to_json_hash)
      end
    end

    context "without cost calculation" do
      it "excludes cost information from hash" do
        metadata = described_class.new(**base_attributes)
        hash = metadata.to_h

        expect(hash).not_to have_key(:cost)
        expect(hash).to include(
          input_tokens: 100,
          output_tokens: 50,
          total_tokens: 150
        )
      end
    end

    context "with optional attributes and cost" do
      it "includes all attributes including cost" do
        full_attributes = base_attributes.merge(
          provider_specific: {custom: "data"},
          cached_tokens: 10,
          cost_calculation: cost_calculation
        )
        metadata = described_class.new(**full_attributes)

        hash = metadata.to_h

        expect(hash).to include(
          provider_specific: {custom: "data"},
          cached_tokens: 10,
          cost: cost_calculation.to_json_hash
        )
      end
    end
  end

  describe "#to_json_hash" do
    it "returns the same as to_h" do
      metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)
      expect(metadata.to_json_hash).to eq(metadata.to_h)
    end
  end

  describe "#cost_summary" do
    context "with cost calculation" do
      it "returns formatted cost summary" do
        metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)
        summary = metadata.cost_summary

        expect(summary).to include("Cost Summary:")
        expect(summary).to include("Input: $0.003")
        expect(summary).to include("Output: $0.0075")
        expect(summary).to include("Cache Creation: $0.0002")
        expect(summary).to include("Cache Read: $0.0001")
        expect(summary).to include("Total: $0.0108 USD")
      end
    end

    context "with cost calculation without caching" do
      let(:no_cache_cost_calculation) do
        CodingAgentTools::Models::Pricing::CostCalculation.new(
          input_cost: BigDecimal("0.003"),
          output_cost: BigDecimal("0.0075"),
          cache_creation_cost: BigDecimal("0"),
          cache_read_cost: BigDecimal("0"),
          total_cost: BigDecimal("0.0105"),
          currency: "USD"
        )
      end

      it "excludes cache cost lines" do
        metadata = described_class.new(**base_attributes, cost_calculation: no_cache_cost_calculation)
        summary = metadata.cost_summary

        expect(summary).to include("Cost Summary:")
        expect(summary).to include("Input: $0.003")
        expect(summary).to include("Output: $0.0075")
        expect(summary).not_to include("Cache Creation:")
        expect(summary).not_to include("Cache Read:")
        expect(summary).to include("Total: $0.0105 USD")
      end
    end

    context "without cost calculation" do
      it "returns N/A message" do
        metadata = described_class.new(**base_attributes)
        expect(metadata.cost_summary).to eq("Cost: N/A")
      end
    end
  end

  describe ".from_usage_metadata" do
    let(:base_usage_metadata) do
      CodingAgentTools::Models::UsageMetadata.new(**base_attributes)
    end

    context "with cost calculation" do
      it "creates UsageMetadataWithCost from base metadata" do
        result = described_class.from_usage_metadata(base_usage_metadata, cost_calculation)

        expect(result).to be_a(described_class)
        expect(result.input_tokens).to eq(100)
        expect(result.output_tokens).to eq(50)
        expect(result.total_tokens).to eq(150)
        expect(result.took).to eq(2.5)
        expect(result.provider).to eq("test_provider")
        expect(result.model).to eq("test_model")
        expect(result.timestamp).to eq("2024-01-01T12:00:00Z")
        expect(result.finish_reason).to eq("stop")
        expect(result.cost_calculation).to eq(cost_calculation)
        expect(result.has_cost_info?).to be true
      end
    end

    context "without cost calculation" do
      it "creates UsageMetadataWithCost without cost info" do
        result = described_class.from_usage_metadata(base_usage_metadata)

        expect(result).to be_a(described_class)
        expect(result.input_tokens).to eq(100)
        expect(result.cost_calculation).to be_nil
        expect(result.has_cost_info?).to be false
        expect(result.total_cost).to eq(0.0)
      end
    end

    context "with nil cost calculation explicitly" do
      it "creates UsageMetadataWithCost without cost info" do
        result = described_class.from_usage_metadata(base_usage_metadata, nil)

        expect(result).to be_a(described_class)
        expect(result.cost_calculation).to be_nil
        expect(result.has_cost_info?).to be false
      end
    end

    context "with metadata including optional attributes" do
      let(:full_usage_metadata) do
        CodingAgentTools::Models::UsageMetadata.new(
          **base_attributes,
          provider_specific: {custom_field: "value"},
          safety_ratings: [{category: "HARM_CATEGORY_HARASSMENT", probability: "NEGLIGIBLE"}],
          cached_tokens: 25
        )
      end

      it "preserves all attributes" do
        result = described_class.from_usage_metadata(full_usage_metadata, cost_calculation)

        expect(result.provider_specific).to eq({custom_field: "value"})
        expect(result.safety_ratings).to eq([{category: "HARM_CATEGORY_HARASSMENT", probability: "NEGLIGIBLE"}])
        expect(result.cached_tokens).to eq(25)
        expect(result.cost_calculation).to eq(cost_calculation)
      end
    end
  end

  describe "inheritance behavior" do
    it "inherits all methods from UsageMetadata" do
      metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)

      # Test inherited status methods
      expect(metadata.successful?).to be true
      expect(metadata.truncated?).to be false
      expect(metadata.error?).to be false
      expect(metadata.cancelled?).to be false

      # Test inherited performance methods
      expect(metadata.tokens_per_second).to eq(20.0) # 50 output tokens / 2.5 seconds
      expect(metadata.efficiency_rate).to eq(60.0) # 150 total tokens / 2.5 seconds
    end

    it "inherits cached? method behavior" do
      metadata_with_cache = described_class.new(**base_attributes.merge(cached_tokens: 10), cost_calculation: cost_calculation)
      metadata_without_cache = described_class.new(**base_attributes, cost_calculation: cost_calculation)

      expect(metadata_with_cache.cached?).to be true
      expect(metadata_without_cache.cached?).to be false
    end

    it "can be used anywhere UsageMetadata is expected" do
      metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)
      
      # Should respond to all UsageMetadata methods
      expect(metadata).to respond_to(:input_tokens)
      expect(metadata).to respond_to(:output_tokens)
      expect(metadata).to respond_to(:total_tokens)
      expect(metadata).to respond_to(:took)
      expect(metadata).to respond_to(:provider)
      expect(metadata).to respond_to(:model)
      expect(metadata).to respond_to(:timestamp)
      expect(metadata).to respond_to(:finish_reason)
      expect(metadata).to respond_to(:to_json)
    end
  end

  describe "JSON serialization" do
    context "with cost calculation" do
      it "can be converted to JSON and back" do
        metadata = described_class.new(**base_attributes, cost_calculation: cost_calculation)
        json_string = metadata.to_json
        
        parsed = JSON.parse(json_string, symbolize_names: true)
        
        expect(parsed[:input_tokens]).to eq(100)
        expect(parsed[:output_tokens]).to eq(50)
        expect(parsed[:cost]).to be_a(Hash)
        expect(parsed[:cost][:total]).to eq(0.0108)
      end
    end

    context "without cost calculation" do
      it "can be converted to JSON without cost info" do
        metadata = described_class.new(**base_attributes)
        json_string = metadata.to_json
        
        parsed = JSON.parse(json_string, symbolize_names: true)
        
        expect(parsed[:input_tokens]).to eq(100)
        expect(parsed).not_to have_key(:cost)
      end
    end
  end

  describe "edge cases and error handling" do
    context "with very small costs" do
      let(:tiny_cost_calculation) do
        CodingAgentTools::Models::Pricing::CostCalculation.new(
          input_cost: BigDecimal("0.000001"),
          output_cost: BigDecimal("0.000001"),
          cache_creation_cost: BigDecimal("0"),
          cache_read_cost: BigDecimal("0"),
          total_cost: BigDecimal("0.000002"),
          currency: "USD"
        )
      end

      it "handles tiny costs correctly" do
        metadata = described_class.new(**base_attributes, cost_calculation: tiny_cost_calculation)
        
        expect(metadata.total_cost).to eq(0.000002)
        expect(metadata.cost_per_token).to eq(0.000002 / 150.0)
        expect(metadata.cost_summary).to include("Total: $2.0e-06 USD")
      end
    end

    context "with large costs" do
      let(:large_cost_calculation) do
        CodingAgentTools::Models::Pricing::CostCalculation.new(
          input_cost: BigDecimal("1.5"),
          output_cost: BigDecimal("2.75"),
          cache_creation_cost: BigDecimal("0.1"),
          cache_read_cost: BigDecimal("0.05"),
          total_cost: BigDecimal("4.4"),
          currency: "USD"
        )
      end

      it "handles large costs correctly" do
        metadata = described_class.new(**base_attributes, cost_calculation: large_cost_calculation)
        
        expect(metadata.total_cost).to eq(4.4)
        expect(metadata.input_cost).to eq(1.5)
        expect(metadata.output_cost).to eq(2.75)
        expect(metadata.cache_cost).to eq(0.15)
      end
    end

    context "with extreme token counts" do
      let(:extreme_attributes) do
        base_attributes.merge(
          input_tokens: 1_000_000,
          output_tokens: 500_000,
          total_tokens: 1_500_000
        )
      end

      it "handles large token counts correctly" do
        metadata = described_class.new(**extreme_attributes, cost_calculation: cost_calculation)
        
        expect(metadata.cost_per_token).to eq(0.0108 / 1_500_000.0)
        expect(metadata.total_tokens).to eq(1_500_000)
      end
    end
  end
end