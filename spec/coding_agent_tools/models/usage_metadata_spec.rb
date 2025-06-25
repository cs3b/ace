# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/models/usage_metadata"

RSpec.describe CodingAgentTools::Models::UsageMetadata do
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

  describe "#initialize" do
    it "creates a usage metadata instance with required attributes" do
      metadata = described_class.new(**base_attributes)

      expect(metadata.input_tokens).to eq(100)
      expect(metadata.output_tokens).to eq(50)
      expect(metadata.total_tokens).to eq(150)
      expect(metadata.took).to eq(2.5)
      expect(metadata.provider).to eq("test_provider")
      expect(metadata.model).to eq("test_model")
      expect(metadata.timestamp).to eq("2024-01-01T12:00:00Z")
      expect(metadata.finish_reason).to eq("stop")
    end

    it "creates a usage metadata instance with optional attributes" do
      full_attributes = base_attributes.merge(
        provider_specific: {custom_field: "value"},
        safety_ratings: [{category: "HARM_CATEGORY_HARASSMENT", probability: "NEGLIGIBLE"}],
        cached_tokens: 25
      )

      metadata = described_class.new(**full_attributes)

      expect(metadata.provider_specific).to eq({custom_field: "value"})
      expect(metadata.safety_ratings).to eq([{category: "HARM_CATEGORY_HARASSMENT", probability: "NEGLIGIBLE"}])
      expect(metadata.cached_tokens).to eq(25)
    end

    it "creates an immutable instance" do
      metadata = described_class.new(**base_attributes)
      expect(metadata).to be_frozen
    end
  end

  describe "#to_h" do
    it "converts to hash with all attributes" do
      full_attributes = base_attributes.merge(
        provider_specific: {custom: "data"},
        cached_tokens: 10
      )
      metadata = described_class.new(**full_attributes)

      hash = metadata.to_h

      expect(hash).to include(
        input_tokens: 100,
        output_tokens: 50,
        total_tokens: 150,
        took: 2.5,
        provider: "test_provider",
        model: "test_model",
        timestamp: "2024-01-01T12:00:00Z",
        finish_reason: "stop",
        provider_specific: {custom: "data"},
        cached_tokens: 10
      )
    end

    it "excludes nil values" do
      metadata = described_class.new(**base_attributes)
      hash = metadata.to_h

      expect(hash).not_to have_key(:provider_specific)
      expect(hash).not_to have_key(:safety_ratings)
      expect(hash).not_to have_key(:cached_tokens)
    end
  end

  describe "#to_json" do
    it "converts to JSON" do
      metadata = described_class.new(**base_attributes)
      json = metadata.to_json

      parsed = JSON.parse(json, symbolize_names: true)
      expect(parsed).to include(
        input_tokens: 100,
        output_tokens: 50,
        total_tokens: 150
      )
    end
  end

  describe "status methods" do
    describe "#successful?" do
      it "returns true when finish_reason is stop" do
        metadata = described_class.new(**base_attributes.merge(finish_reason: "stop"))
        expect(metadata).to be_successful
      end

      it "returns false when finish_reason is not stop" do
        metadata = described_class.new(**base_attributes.merge(finish_reason: "length"))
        expect(metadata).not_to be_successful
      end
    end

    describe "#truncated?" do
      it "returns true when finish_reason is length" do
        metadata = described_class.new(**base_attributes.merge(finish_reason: "length"))
        expect(metadata).to be_truncated
      end

      it "returns false when finish_reason is not length" do
        metadata = described_class.new(**base_attributes.merge(finish_reason: "stop"))
        expect(metadata).not_to be_truncated
      end
    end

    describe "#error?" do
      it "returns true when finish_reason is error" do
        metadata = described_class.new(**base_attributes.merge(finish_reason: "error"))
        expect(metadata).to be_error
      end

      it "returns false when finish_reason is not error" do
        metadata = described_class.new(**base_attributes.merge(finish_reason: "stop"))
        expect(metadata).not_to be_error
      end
    end

    describe "#cancelled?" do
      it "returns true when finish_reason is cancelled" do
        metadata = described_class.new(**base_attributes.merge(finish_reason: "cancelled"))
        expect(metadata).to be_cancelled
      end

      it "returns false when finish_reason is not cancelled" do
        metadata = described_class.new(**base_attributes.merge(finish_reason: "stop"))
        expect(metadata).not_to be_cancelled
      end
    end
  end

  describe "performance methods" do
    describe "#tokens_per_second" do
      it "calculates output tokens per second" do
        metadata = described_class.new(**base_attributes.merge(output_tokens: 100, took: 2.0))
        expect(metadata.tokens_per_second).to eq(50.0)
      end

      it "returns 0 when took is zero" do
        metadata = described_class.new(**base_attributes.merge(took: 0.0))
        expect(metadata.tokens_per_second).to eq(0.0)
      end

      it "returns 0 when output_tokens is zero" do
        metadata = described_class.new(**base_attributes.merge(output_tokens: 0))
        expect(metadata.tokens_per_second).to eq(0.0)
      end
    end

    describe "#efficiency_rate" do
      it "calculates total tokens per second" do
        metadata = described_class.new(**base_attributes.merge(total_tokens: 200, took: 4.0))
        expect(metadata.efficiency_rate).to eq(50.0)
      end

      it "returns 0 when took is zero" do
        metadata = described_class.new(**base_attributes.merge(took: 0.0))
        expect(metadata.efficiency_rate).to eq(0.0)
      end

      it "returns 0 when total_tokens is zero" do
        metadata = described_class.new(**base_attributes.merge(total_tokens: 0))
        expect(metadata.efficiency_rate).to eq(0.0)
      end
    end
  end

  describe "#cached?" do
    it "returns true when cached_tokens is present and greater than 0" do
      metadata = described_class.new(**base_attributes.merge(cached_tokens: 10))
      expect(metadata).to be_cached
    end

    it "returns false when cached_tokens is nil" do
      metadata = described_class.new(**base_attributes)
      expect(metadata).not_to be_cached
    end

    it "returns false when cached_tokens is 0" do
      metadata = described_class.new(**base_attributes.merge(cached_tokens: 0))
      expect(metadata).not_to be_cached
    end
  end
end
