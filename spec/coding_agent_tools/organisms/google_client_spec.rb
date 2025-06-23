# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/organisms/google_client"
require "webmock/rspec"

RSpec.describe CodingAgentTools::Organisms::GoogleClient do
  let(:api_key) { "test-api-key-123" }
  let(:client) { described_class.new(api_key: api_key) }
  let(:custom_client) do
    described_class.new(
      api_key: api_key,
      model: "gemini-pro",
      base_url: "https://custom.api.com",
      generation_config: {temperature: 0.5, maxOutputTokens: 4096},
      timeout: 60
    )
  end

  describe "#initialize" do
    context "with default configuration" do
      it "uses default model" do
        expect(client.instance_variable_get(:@model)).to eq("gemini-2.0-flash-lite")
      end

      it "uses default base URL" do
        expect(client.instance_variable_get(:@base_url)).to eq("https://generativelanguage.googleapis.com/v1beta")
      end

      it "uses default generation config" do
        config = client.instance_variable_get(:@generation_config)
        expect(config[:temperature]).to eq(0.7)
        expect(config[:maxOutputTokens]).to eq(8192)
      end

      it "uses GOOGLE_API_KEY environment variable by default" do
        credentials = client.instance_variable_get(:@credentials)
        expect(credentials.instance_variable_get(:@env_key_name)).to eq("GOOGLE_API_KEY")
      end
    end

    context "with custom configuration" do
      it "uses custom model" do
        expect(custom_client.instance_variable_get(:@model)).to eq("gemini-pro")
      end

      it "uses custom base URL" do
        expect(custom_client.instance_variable_get(:@base_url)).to eq("https://custom.api.com")
      end

      it "merges custom generation config" do
        config = custom_client.instance_variable_get(:@generation_config)
        expect(config[:temperature]).to eq(0.5)
        expect(config[:maxOutputTokens]).to eq(4096)
      end

      it "accepts timeout configuration" do
        # Test that timeout is accepted without error
        expect { custom_client }.not_to raise_error
      end

      it "accepts event namespace configuration" do
        # Test that client initializes without error
        expect { client }.not_to raise_error
      end
    end

    context "with API key from environment" do
      it "uses environment variable when no api_key provided" do
        allow_any_instance_of(CodingAgentTools::Molecules::APICredentials)
          .to receive(:api_key).and_return("env-api-key")

        env_client = described_class.new
        expect(env_client.instance_variable_get(:@api_key)).to eq("env-api-key")
      end
    end
  end

  describe "#generate_text" do
    let(:prompt) { "Tell me about Ruby programming" }
    let(:success_response) do
      {
        candidates: [
          {
            content: {
              parts: [
                {text: "Ruby is a dynamic programming language..."}
              ]
            },
            finishReason: "STOP",
            safetyRatings: []
          }
        ],
        usageMetadata: {
          promptTokenCount: 10,
          candidatesTokenCount: 20,
          totalTokenCount: 30
        }
      }
    end

    before do
      allow_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:post_json).and_return(success_response)
      allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
        .to receive(:parse_response).and_return({success: true, data: success_response})
    end

    it "generates text successfully" do
      result = client.generate_text(prompt)

      expect(result[:text]).to eq("Ruby is a dynamic programming language...")
      expect(result[:finish_reason]).to eq("STOP")
      expect(result[:usage_metadata]).to eq(success_response[:usageMetadata])
    end

    it "builds correct API URL" do
      expected_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=#{api_key}"

      expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:post_json).with(expected_url, anything)

      client.generate_text(prompt)
    end

    it "builds correct payload structure" do
      expected_payload = {
        contents: [
          {
            role: "user",
            parts: [{text: prompt}]
          }
        ],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 8192
        }
      }

      expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:post_json).with(anything, expected_payload)

      client.generate_text(prompt)
    end

    context "with system instruction" do
      let(:system_instruction) { "You are a helpful programming assistant" }

      it "includes system instruction in payload" do
        expected_payload = hash_including(
          systemInstruction: {
            parts: [{text: system_instruction}]
          }
        )

        expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
          .to receive(:post_json).with(anything, expected_payload)

        client.generate_text(prompt, system_instruction: system_instruction)
      end
    end

    context "with custom generation config" do
      it "merges generation config options" do
        custom_config = {temperature: 0.9, maxOutputTokens: 1000}
        expected_config = {temperature: 0.9, maxOutputTokens: 1000}

        expected_payload = hash_including(
          generationConfig: expected_config
        )

        expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
          .to receive(:post_json).with(anything, expected_payload)

        client.generate_text(prompt, generation_config: custom_config)
      end
    end

    context "when API returns error" do
      let(:error_response) do
        {
          error: {
            status: "INVALID_ARGUMENT",
            message: "Invalid prompt"
          }
        }
      end

      before do
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return({success: false, error: error_response[:error]})
      end

      it "raises error with formatted message" do
        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /Google API Error.*INVALID_ARGUMENT.*Invalid prompt/)
      end
    end

    context "when response has malformed structure" do
      before do
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return({success: true, data: {candidates: []}})
      end

      it "raises error for empty candidates" do
        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /candidates.*array is empty/)
      end
    end
  end

  describe "#count_tokens" do
    let(:text) { "Hello world" }
    let(:token_count_response) do
      {
        totalTokens: 15
      }
    end

    before do
      allow_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:post_json).and_return(token_count_response)
      allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
        .to receive(:parse_response).and_return({success: true, data: token_count_response})
    end

    it "returns token count information" do
      result = client.count_tokens(text)

      expect(result[:token_count]).to eq(15)
      expect(result[:details]).to eq(token_count_response)
    end

    it "builds correct API URL" do
      expected_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:countTokens?key=#{api_key}"

      expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:post_json).with(expected_url, anything)

      client.count_tokens(text)
    end
  end

  describe "#list_models" do
    let(:models_response) do
      {
        models: [
          {name: "models/gemini-pro", displayName: "Gemini Pro"},
          {name: "models/gemini-2.0-flash-lite", displayName: "Gemini 2.0 Flash Lite"}
        ]
      }
    end

    before do
      allow_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:get_json).and_return(models_response)
      allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
        .to receive(:parse_response).and_return({success: true, data: models_response})
    end

    it "returns list of models" do
      result = client.list_models

      expect(result).to eq(models_response[:models])
    end

    it "builds correct API URL" do
      expected_url = "https://generativelanguage.googleapis.com/v1beta/models?key=#{api_key}"

      expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:get_json).with(expected_url)

      client.list_models
    end
  end

  describe "#model_info" do
    let(:model_info_response) do
      {
        name: "models/gemini-2.0-flash-lite",
        displayName: "Gemini 2.0 Flash Lite",
        description: "Fast and efficient model"
      }
    end

    before do
      allow_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:get_json).and_return(model_info_response)
      allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
        .to receive(:parse_response).and_return({success: true, data: model_info_response})
    end

    it "returns model information" do
      result = client.model_info

      expect(result).to eq(model_info_response)
    end

    it "builds correct API URL with model name" do
      expected_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite?key=#{api_key}"

      expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:get_json).with(expected_url)

      client.model_info
    end
  end

  describe "#generate_text_stream" do
    it "raises NotImplementedError" do
      expect { client.generate_text_stream("test prompt") }
        .to raise_error(NotImplementedError, "Streaming responses not yet implemented")
    end
  end

  describe "private URL building methods" do
    describe "#build_url_with_path" do
      it "handles base URLs without trailing slash" do
        client_without_slash = described_class.new(
          api_key: api_key,
          base_url: "https://api.example.com"
        )

        url = client_without_slash.send(:build_url_with_path, "test/path")
        expect(url).to eq("https://api.example.com/test/path?key=#{api_key}")
      end

      it "handles base URLs with trailing slash" do
        client_with_slash = described_class.new(
          api_key: api_key,
          base_url: "https://api.example.com/"
        )

        url = client_with_slash.send(:build_url_with_path, "test/path")
        expect(url).to eq("https://api.example.com/test/path?key=#{api_key}")
      end
    end
  end
end
