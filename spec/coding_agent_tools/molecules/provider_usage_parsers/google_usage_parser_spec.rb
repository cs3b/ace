# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/provider_usage_parsers/google_usage_parser"

RSpec.describe CodingAgentTools::Molecules::ProviderUsageParsers::GoogleUsageParser do
  describe ".parse" do
    let(:google_response) do
      {
        candidates: [
          {
            content: {
              parts: [{text: "Hello! How can I help you today?\n"}],
              role: "model"
            },
            finishReason: "STOP",
            avgLogprobs: -0.040499213337898257
          }
        ],
        usageMetadata: {
          promptTokenCount: 2,
          candidatesTokenCount: 10,
          totalTokenCount: 12,
          promptTokensDetails: [
            {modality: "TEXT", tokenCount: 2}
          ],
          candidatesTokensDetails: [
            {modality: "TEXT", tokenCount: 10}
          ]
        },
        modelVersion: "gemini-2.0-flash-lite",
        responseId: "SsVaaJKhOeaam9IP1fXesAg"
      }
    end

    it "extracts usage information from Google response" do
      result = described_class.parse(google_response)

      expect(result).to include(
        input_tokens: 2,
        output_tokens: 10,
        total_tokens: 12
      )
    end

    it "handles string keys in usage metadata" do
      response_with_string_keys = {
        "usage_metadata" => {
          "promptTokenCount" => 5,
          "candidatesTokenCount" => 15,
          "totalTokenCount" => 20
        }
      }

      result = described_class.parse(response_with_string_keys)

      expect(result).to include(
        input_tokens: 5,
        output_tokens: 15,
        total_tokens: 20
      )
    end

    it "calculates total tokens when not provided" do
      response_without_total = {
        usage_metadata: {
          promptTokenCount: 8,
          candidatesTokenCount: 12
        }
      }

      result = described_class.parse(response_without_total)

      expect(result).to include(
        input_tokens: 8,
        output_tokens: 12,
        total_tokens: 20
      )
    end

    it "handles missing usage metadata" do
      minimal_response = {}

      result = described_class.parse(minimal_response)

      expect(result).to include(
        input_tokens: 0,
        output_tokens: 0,
        total_tokens: 0
      )
    end

    it "extracts safety ratings" do
      response_with_safety = {
        usage_metadata: {promptTokenCount: 2, candidatesTokenCount: 3},
        safety_ratings: [
          {category: "HARM_CATEGORY_HARASSMENT", probability: "NEGLIGIBLE"}
        ]
      }

      result = described_class.parse(response_with_safety)

      expect(result[:safety_ratings]).to eq([
        {category: "HARM_CATEGORY_HARASSMENT", probability: "NEGLIGIBLE"}
      ])
    end

    it "extracts provider-specific metadata" do
      result = described_class.parse(google_response)

      expect(result[:provider_specific]).to include(
        prompt_token_details: google_response[:usageMetadata][:promptTokensDetails],
        candidate_token_details: google_response[:usageMetadata][:candidatesTokensDetails],
        model_version: "gemini-2.0-flash-lite",
        response_id: "SsVaaJKhOeaam9IP1fXesAg",
        avg_logprobs: -0.040499213337898257
      )
    end

    it "returns nil for provider_specific when no additional data" do
      minimal_response = {
        usage_metadata: {
          promptTokenCount: 2,
          candidatesTokenCount: 3
        }
      }

      result = described_class.parse(minimal_response)

      expect(result[:provider_specific]).to be_nil
    end

    it "handles cached tokens (future-proofing)" do
      response_with_cache = {
        usage_metadata: {
          promptTokenCount: 2,
          candidatesTokenCount: 3,
          cachedTokenCount: 5
        }
      }

      result = described_class.parse(response_with_cache)

      expect(result[:cached_tokens]).to eq(5)
    end
  end
end
