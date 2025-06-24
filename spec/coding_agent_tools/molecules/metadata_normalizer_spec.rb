# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/metadata_normalizer"

RSpec.describe CodingAgentTools::Molecules::MetadataNormalizer do
  describe ".normalize" do
    let(:execution_time) { 2.45 }
    let(:model) { "test-model" }

    context "with Google provider" do
      let(:gemini_response) do
        {
          text: "Test response",
          finish_reason: "STOP",
          usage_metadata: {
            promptTokenCount: 123,
            candidatesTokenCount: 456,
            totalTokenCount: 579
          },
          safety_ratings: [
            {category: "HARM_CATEGORY_HARASSMENT", probability: "NEGLIGIBLE"}
          ]
        }
      end

      it "handles missing usage metadata" do
        response = {text: "Test", finish_reason: "STOP"}
        result = described_class.normalize(
          response,
          provider: "google",
          model: model,
          execution_time: execution_time
        )

        expect(result).to include(
          finish_reason: "stop",
          input_tokens: 0,
          output_tokens: 0,
          total_tokens: 0,
          took: 2.45,
          provider: "google",
          model: model
        )
      end

      it "normalizes Google metadata correctly" do
        result = described_class.normalize(
          gemini_response,
          provider: "google",
          model: model,
          execution_time: execution_time
        )

        expect(result).to include(
          finish_reason: "stop",
          input_tokens: 123,
          output_tokens: 456,
          total_tokens: 579,
          took: 2.45,
          provider: "google",
          model: model,
          safety_ratings: gemini_response[:safety_ratings]
        )
        expect(result[:timestamp]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
      end

      it "handles string keys in usage metadata" do
        response = {
          text: "Test",
          finish_reason: "STOP",
          usage_metadata: {
            "promptTokenCount" => 100,
            "candidatesTokenCount" => 200
          }
        }

        result = described_class.normalize(
          response,
          provider: "google",
          model: model,
          execution_time: execution_time
        )

        expect(result).to include(
          input_tokens: 100,
          output_tokens: 200,
          total_tokens: 300
        )
      end
    end

    context "with LMStudio provider" do
      let(:lmstudio_response) do
        {
          text: "Test response",
          finish_reason: "stop",
          usage_metadata: {
            prompt_tokens: 150,
            completion_tokens: 300,
            total_tokens: 450
          }
        }
      end

      it "normalizes LMStudio metadata correctly" do
        result = described_class.normalize(
          lmstudio_response,
          provider: "lmstudio",
          model: model,
          execution_time: execution_time
        )

        expect(result).to include(
          finish_reason: "stop",
          input_tokens: 150,
          output_tokens: 300,
          total_tokens: 450,
          took: 2.45,
          provider: "lmstudio",
          model: model
        )
        expect(result[:timestamp]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
        expect(result).not_to have_key(:safety_ratings)
      end

      it "handles missing usage metadata" do
        response = {text: "Test", finish_reason: "stop"}

        result = described_class.normalize(
          response,
          provider: "lmstudio",
          model: model,
          execution_time: execution_time
        )

        expect(result).to include(
          input_tokens: 0,
          output_tokens: 0,
          total_tokens: 0
        )
      end

      it "handles string keys in usage metadata" do
        response = {
          text: "Test",
          finish_reason: "stop",
          usage_metadata: {
            "prompt_tokens" => 75,
            "completion_tokens" => 125
          }
        }

        result = described_class.normalize(
          response,
          provider: "lmstudio",
          model: model,
          execution_time: execution_time
        )

        expect(result).to include(
          input_tokens: 75,
          output_tokens: 125,
          total_tokens: 200
        )
      end
    end

    context "with unknown provider" do
      let(:unknown_response) do
        {
          text: "Test response",
          finish_reason: "completed",
          usage_metadata: {custom_field: "value"}
        }
      end

      it "normalizes unknown provider metadata" do
        result = described_class.normalize(
          unknown_response,
          provider: "custom",
          model: model,
          execution_time: execution_time
        )

        expect(result).to include(
          finish_reason: "completed",
          input_tokens: 0,
          output_tokens: 0,
          total_tokens: 0,
          took: 2.45,
          provider: "custom",
          model: model,
          raw_usage: {custom_field: "value"}
        )
        expect(result[:timestamp]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
      end
    end

    context "finish reason normalization" do
      let(:base_response) { {text: "Test"} }

      it "normalizes various finish reasons" do
        test_cases = {
          "STOP" => "stop",
          "stop" => "stop",
          "finished" => "stop",
          "LENGTH" => "length",
          "length" => "length",
          "max_tokens" => "length",
          "ERROR" => "error",
          "error" => "error",
          "failed" => "error",
          "CANCELLED" => "cancelled",
          "cancelled" => "cancelled",
          "canceled" => "cancelled",
          "custom_reason" => "custom_reason",
          nil => "unknown"
        }

        test_cases.each do |input, expected|
          response = base_response.merge(finish_reason: input)
          result = described_class.normalize(
            response,
            provider: "test",
            model: model,
            execution_time: execution_time
          )

          expect(result[:finish_reason]).to eq(expected),
            "Expected '#{input}' to normalize to '#{expected}'"
        end
      end
    end

    context "execution time formatting" do
      it "rounds execution time to 3 decimal places" do
        result = described_class.normalize(
          {text: "Test"},
          provider: "test",
          model: model,
          execution_time: 1.23456789
        )

        expect(result[:took]).to eq(1.235)
      end

      it "handles integer execution times" do
        result = described_class.normalize(
          {text: "Test"},
          provider: "test",
          model: model,
          execution_time: 3
        )

        expect(result[:took]).to eq(3.0)
      end
    end
  end

  describe ".current_timestamp" do
    it "returns ISO 8601 formatted timestamp" do
      timestamp = described_class.current_timestamp
      expect(timestamp).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end

    it "returns UTC timezone" do
      timestamp = described_class.current_timestamp
      expect(timestamp).to end_with("Z")
    end

    it "returns current time" do
      freeze_time = Time.new(2024, 1, 1, 12, 0, 0, 0)
      allow(Time).to receive(:now).and_return(freeze_time)

      timestamp = described_class.current_timestamp
      expect(timestamp).to eq("2024-01-01T12:00:00Z")
    end
  end

  describe "private methods" do
    describe ".calculate_total_tokens" do
      it "calculates Gemini total tokens correctly" do
        usage = {promptTokenCount: 100, candidatesTokenCount: 200}
        total = described_class.send(:calculate_total_tokens, usage, :gemini)
        expect(total).to eq(300)
      end

      it "calculates LMStudio total tokens correctly" do
        usage = {prompt_tokens: 150, completion_tokens: 250}
        total = described_class.send(:calculate_total_tokens, usage, :lmstudio)
        expect(total).to eq(400)
      end

      it "handles missing token counts" do
        usage = {}
        total = described_class.send(:calculate_total_tokens, usage, :gemini)
        expect(total).to eq(0)
      end

      it "returns 0 for unknown providers" do
        usage = {some_tokens: 100}
        total = described_class.send(:calculate_total_tokens, usage, :unknown)
        expect(total).to eq(0)
      end
    end

    describe ".extract_finish_reason" do
      it "handles various input types" do
        expect(described_class.send(:extract_finish_reason, :stop)).to eq("stop")
        expect(described_class.send(:extract_finish_reason, "STOP")).to eq("stop")
        expect(described_class.send(:extract_finish_reason, nil)).to eq("unknown")
      end
    end
  end
end
