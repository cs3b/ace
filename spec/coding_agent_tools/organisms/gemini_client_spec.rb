# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/organisms/gemini_client"
require "webmock/rspec"

RSpec.describe CodingAgentTools::Organisms::GeminiClient do
  let(:api_key) { "test-api-key-123" }
  let(:client) { described_class.new(api_key: api_key) }
  let(:custom_client) do
    described_class.new(
      api_key: api_key,
      model: "gemini-pro",
      base_url: "https://custom.api.com",
      generation_config: { temperature: 0.5, maxOutputTokens: 4096 },
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

      it "passes timeout to request builder" do
        request_builder = custom_client.instance_variable_get(:@request_builder)
        http_client = request_builder.instance_variable_get(:@client)
        expect(http_client.instance_variable_get(:@timeout)).to eq(60)
      end
    end

    context "without API key" do
      it "initializes credentials and attempts to get key from environment" do
        # Mock the environment to not have the API key
        allow(ENV).to receive(:fetch).with("GEMINI_API_KEY", nil).and_return(nil)

        expect {
          described_class.new
        }.to raise_error(KeyError)
      end
    end

    context "with API key from environment" do
      before do
        ENV["GEMINI_API_KEY"] = "env-api-key"
      end

      after do
        ENV.delete("GEMINI_API_KEY")
      end

      it "uses environment API key when not provided" do
        client = described_class.new
        expect(client.instance_variable_get(:@api_key)).to eq("env-api-key")
      end
    end
  end

  describe "#generate_text" do
    let(:prompt) { "What is the capital of France?" }
    let(:api_url) { "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=#{api_key}" }

    context "with successful response" do
      let(:successful_response) do
        {
          candidates: [
            {
              content: {
                parts: [{ text: "The capital of France is Paris." }]
              },
              finishReason: "STOP",
              safetyRatings: [
                { category: "HARM_CATEGORY_HATE_SPEECH", probability: "NEGLIGIBLE" }
              ]
            }
          ],
          usageMetadata: {
            promptTokenCount: 8,
            candidatesTokenCount: 10,
            totalTokenCount: 18
          }
        }
      end

      before do
        stub_request(:post, api_url)
          .with(
            body: {
              contents: [
                {
                  role: "user",
                  parts: [{ text: prompt }]
                }
              ],
              generationConfig: {
                temperature: 0.7,
                maxOutputTokens: 8192
              }
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
          .to_return(
            status: 200,
            body: successful_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns generated text with metadata" do
        result = client.generate_text(prompt)

        expect(result[:text]).to eq("The capital of France is Paris.")
        expect(result[:finish_reason]).to eq("STOP")
        expect(result[:safety_ratings]).to be_an(Array)
        expect(result[:usage_metadata]).to include(
          promptTokenCount: 8,
          candidatesTokenCount: 10,
          totalTokenCount: 18
        )
      end
    end

    context "with custom generation options" do
      let(:custom_prompt) { "Write a haiku" }
      let(:system_instruction) { "You are a poetry expert" }

      before do
        stub_request(:post, api_url)
          .with(
            body: {
              contents: [
                {
                  role: "user",
                  parts: [{ text: custom_prompt }]
                }
              ],
              generationConfig: {
                temperature: 0.9,
                maxOutputTokens: 100
              },
              systemInstruction: {
                parts: [{ text: system_instruction }]
              }
            }.to_json
          )
          .to_return(
            status: 200,
            body: {
              candidates: [{
                content: { parts: [{ text: "Cherry blossoms fall\nSoft petals on the spring breeze\nNature's gentle dance" }] },
                finishReason: "STOP",
                safetyRatings: []
              }],
              usageMetadata: {}
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "sends custom generation config and system instruction" do
        result = client.generate_text(
          custom_prompt,
          system_instruction: system_instruction,
          generation_config: { temperature: 0.9, maxOutputTokens: 100 }
        )

        expect(result[:text]).to include("Cherry blossoms")
      end
    end

    context "with API errors" do
      it "handles 400 Bad Request" do
        stub_request(:post, api_url)
          .to_return(
            status: 400,
            body: { error: { message: "Invalid request format" } }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Invalid request format/)
      end

      it "handles 401 Unauthorized" do
        stub_request(:post, api_url)
          .to_return(
            status: 401,
            body: { error: { message: "Invalid API key" } }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Invalid API key/)
      end

      it "handles 429 Rate Limit" do
        stub_request(:post, api_url)
          .to_return(
            status: 429,
            body: { error: { message: "Rate limit exceeded" } }.to_json,
            headers: { "Content-Type" => "application/json", "Retry-After" => "60" }
          )

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Rate limit exceeded/)
      end

      it "handles non-JSON error response" do
        stub_request(:post, api_url)
          .to_return(
            status: 500,
            body: "Internal Server Error",
            headers: { "Content-Type" => "text/plain" }
          )

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Internal Server Error/)
      end

      it "handles malformed response" do
        stub_request(:post, api_url)
          .to_return(
            status: 200,
            body: { unexpected: "format" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Failed to extract text from response/)
      end
    end

    context "with safety filters" do
      let(:blocked_response) do
        {
          candidates: [
            {
              content: {
                parts: [{ text: "" }]
              },
              finishReason: "SAFETY",
              safetyRatings: [
                { category: "HARM_CATEGORY_HATE_SPEECH", probability: "HIGH" }
              ]
            }
          ]
        }
      end

      before do
        stub_request(:post, api_url)
          .to_return(
            status: 200,
            body: blocked_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns response with SAFETY finish reason" do
        result = client.generate_text("Generate harmful content")

        expect(result[:text]).to eq("")
        expect(result[:finish_reason]).to eq("SAFETY")
        expect(result[:safety_ratings].first[:probability]).to eq("HIGH")
      end
    end
  end

  describe "#generate_text_stream" do
    it "raises NotImplementedError" do
      expect {
        client.generate_text_stream("Test prompt")
      }.to raise_error(NotImplementedError, "Streaming responses not yet implemented")
    end
  end

  describe "#count_tokens" do
    let(:text) { "This is a test text for token counting." }
    let(:api_url) { "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:countTokens?key=#{api_key}" }

    context "with successful response" do
      before do
        stub_request(:post, api_url)
          .with(
            body: {
              contents: [
                {
                  parts: [{ text: text }]
                }
              ]
            }.to_json
          )
          .to_return(
            status: 200,
            body: {
              totalTokens: 12,
              cachedContentTokens: 0
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns token count information" do
        result = client.count_tokens(text)

        expect(result[:token_count]).to eq(12)
        expect(result[:details]).to include(
          totalTokens: 12,
          cachedContentTokens: 0
        )
      end
    end

    context "with API error" do
      before do
        stub_request(:post, api_url)
          .to_return(
            status: 400,
            body: { error: { message: "Invalid input" } }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises error with message" do
        expect {
          client.count_tokens(text)
        }.to raise_error(CodingAgentTools::Error, /Invalid input/)
      end
    end
  end

  describe "#model_info" do
    let(:api_url) { "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite?key=#{api_key}" }

    context "with successful response" do
      let(:model_info_response) do
        {
          name: "models/gemini-2.0-flash-lite",
          displayName: "Gemini 2.0 Flash Lite",
          description: "Fast and efficient model",
          inputTokenLimit: 32768,
          outputTokenLimit: 8192,
          supportedGenerationMethods: ["generateContent", "countTokens"]
        }
      end

      before do
        stub_request(:get, api_url)
          .to_return(
            status: 200,
            body: model_info_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns model information" do
        result = client.model_info

        expect(result[:name]).to eq("models/gemini-2.0-flash-lite")
        expect(result[:displayName]).to eq("Gemini 2.0 Flash Lite")
        expect(result[:inputTokenLimit]).to eq(32768)
        expect(result[:outputTokenLimit]).to eq(8192)
        expect(result[:supportedGenerationMethods]).to include("generateContent", "countTokens")
      end
    end

    context "with API error" do
      before do
        stub_request(:get, api_url)
          .to_return(
            status: 404,
            body: { error: { message: "Model not found" } }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises error" do
        expect {
          client.model_info
        }.to raise_error(CodingAgentTools::Error, /Model not found/)
      end
    end
  end

  describe "error handling" do
    let(:api_url) { "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=#{api_key}" }

    it "handles connection errors" do
      stub_request(:post, api_url).to_timeout

      expect {
        client.generate_text("Test")
      }.to raise_error(Faraday::ConnectionFailed)
    end

    it "provides detailed error messages for nested error structures" do
      stub_request(:post, api_url)
        .to_return(
          status: 400,
          body: {
            error: {
              code: 400,
              message: "Invalid request",
              details: [
                {
                  type: "type.googleapis.com/google.rpc.BadRequest",
                  fieldViolations: [
                    {
                      field: "contents",
                      description: "Contents cannot be empty"
                    }
                  ]
                }
              ]
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect {
        client.generate_text("Test")
      }.to raise_error(CodingAgentTools::Error, /Invalid request/)
    end
  end

  describe "integration scenarios" do
    it "works with custom model and configuration" do
      custom_model_client = described_class.new(
        api_key: api_key,
        model: "gemini-pro",
        generation_config: { temperature: 0.2, maxOutputTokens: 1024 }
      )

      api_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=#{api_key}"

      stub_request(:post, api_url)
        .with(
          body: hash_including({
            generationConfig: {
              temperature: 0.2,
              maxOutputTokens: 1024
            }
          })
        )
        .to_return(
          status: 200,
          body: {
            candidates: [{
              content: { parts: [{ text: "Response from Gemini Pro" }] },
              finishReason: "STOP",
              safetyRatings: []
            }],
            usageMetadata: {}
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = custom_model_client.generate_text("Test prompt")
      expect(result[:text]).to eq("Response from Gemini Pro")
    end
  end
end
