# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/organisms/openai_client"
require "webmock/rspec"

RSpec.describe CodingAgentTools::Organisms::OpenaiClient do
  let(:api_key) { "test-api-key-123" }
  let(:client) { described_class.new(api_key: api_key) }
  let(:custom_client) do
    described_class.new(
      api_key: api_key,
      model: "gpt-3.5-turbo",
      base_url: "https://custom.api.com",
      generation_config: {temperature: 0.5, max_tokens: 2048},
      timeout: 60
    )
  end

  describe "#initialize" do
    context "with default configuration" do
      it "uses default model" do
        expect(client.instance_variable_get(:@model)).to eq("gpt-4o-mini")
      end

      it "uses default base URL" do
        expect(client.instance_variable_get(:@base_url)).to eq("https://api.openai.com/v1")
      end

      it "uses default generation config" do
        config = client.instance_variable_get(:@generation_config)
        expect(config[:temperature]).to eq(0.7)
        expect(config[:max_tokens]).to eq(4096)
      end
    end

    context "with custom configuration" do
      it "uses custom model" do
        expect(custom_client.instance_variable_get(:@model)).to eq("gpt-3.5-turbo")
      end

      it "uses custom base URL" do
        expect(custom_client.instance_variable_get(:@base_url)).to eq("https://custom.api.com")
      end

      it "merges custom generation config" do
        config = custom_client.instance_variable_get(:@generation_config)
        expect(config[:temperature]).to eq(0.5)
        expect(config[:max_tokens]).to eq(2048)
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
        allow(ENV).to receive(:fetch).with("OPENAI_API_KEY", nil).and_return(nil)

        expect do
          described_class.new
        end.to raise_error(KeyError)
      end
    end

    context "with API key from environment" do
      before do
        ENV["OPENAI_API_KEY"] = "env-api-key"
      end

      after do
        ENV.delete("OPENAI_API_KEY")
      end

      it "uses environment API key when not provided" do
        client = described_class.new
        expect(client.instance_variable_get(:@api_key)).to eq("env-api-key")
      end
    end
  end

  describe "#generate_text" do
    let(:prompt) { "What is 2+2?" }
    let(:api_url) { "https://api.openai.com/v1/chat/completions" }

    context "with successful response" do
      let(:mock_response) do
        {
          choices: [
            {
              message: {
                content: "2+2 equals 4"
              },
              finish_reason: "stop"
            }
          ],
          usage: {
            prompt_tokens: 10,
            completion_tokens: 8,
            total_tokens: 18
          }
        }
      end

      before do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .with(api_url, anything, headers: anything)
          .and_return({status: 200, body: mock_response.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .with({status: 200, body: mock_response.to_json})
          .and_return({success: true, data: mock_response})
      end

      it "returns generated text with metadata" do
        result = client.generate_text(prompt)

        expect(result[:text]).to eq("2+2 equals 4")
        expect(result[:finish_reason]).to eq("stop")
        expect(result[:usage_metadata]).to eq({
          prompt_tokens: 10,
          completion_tokens: 8,
          total_tokens: 18
        })
      end
    end

    context "with custom generation options" do
      let(:options) do
        {
          system_instruction: "You are a math tutor",
          generation_config: {temperature: 0.3, max_tokens: 1024}
        }
      end

      let(:expected_payload) do
        {
          model: "gpt-4o-mini",
          messages: [
            {role: "system", content: "You are a math tutor"},
            {role: "user", content: prompt}
          ],
          temperature: 0.3,
          max_tokens: 1024
        }
      end

      it "sends custom generation config and system instruction" do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .with(api_url, expected_payload, headers: anything)
          .and_return({status: 200, body: {choices: [{message: {content: "Response"}}]}.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: true, data: {choices: [{message: {content: "Response"}}]}})

        client.generate_text(prompt, **options)

        expect(client.instance_variable_get(:@request_builder))
          .to have_received(:post_json)
          .with(api_url, expected_payload, headers: anything)
      end
    end

    context "with API errors" do
      it "handles 400 Bad Request" do
        error_response = {error: {message: "Bad request"}}
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 400, body: error_response.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 400, message: "Bad request"}})

        expect do
          client.generate_text(prompt)
        end.to raise_error(CodingAgentTools::Error, /OpenAI API Error \(400\): Bad request/)
      end

      it "handles 401 Unauthorized" do
        error_response = {error: {message: "Invalid API key"}}
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 401, body: error_response.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 401, message: "Invalid API key"}})

        expect do
          client.generate_text(prompt)
        end.to raise_error(CodingAgentTools::Error, /OpenAI API Error \(401\): Invalid API key/)
      end

      it "handles 429 Rate Limit" do
        error_response = {error: {message: "Rate limit exceeded"}}
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 429, body: error_response.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 429, message: "Rate limit exceeded"}})

        expect do
          client.generate_text(prompt)
        end.to raise_error(CodingAgentTools::Error, /OpenAI API Error \(429\): Rate limit exceeded/)
      end

      it "handles malformed response" do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 200, body: "invalid json"})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 200, message: "Invalid JSON"}})

        expect do
          client.generate_text(prompt)
        end.to raise_error(CodingAgentTools::Error, /OpenAI API Error/)
      end

      it "handles response where data is not a Hash" do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 200, body: "[]"})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: true, data: []})

        expect do
          client.generate_text(prompt)
        end.to raise_error(CodingAgentTools::Error, /Response data is not a Hash/)
      end

      it "handles response where 'choices' field is missing" do
        response_data = {}
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 200, body: response_data.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: true, data: response_data})

        expect do
          client.generate_text(prompt)
        end.to raise_error(CodingAgentTools::Error, /'choices' field is not an array/)
      end

      it "handles response where 'choices' array is empty" do
        response_data = {choices: []}
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 200, body: response_data.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: true, data: response_data})

        expect do
          client.generate_text(prompt)
        end.to raise_error(CodingAgentTools::Error, /'choices' array is empty/)
      end

      it "handles response where message content is nil" do
        response_data = {
          choices: [
            {
              message: {
                content: nil
              },
              finish_reason: "stop"
            }
          ]
        }
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 200, body: response_data.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: true, data: response_data})

        expect do
          client.generate_text(prompt)
        end.to raise_error(CodingAgentTools::Error, /message content is nil/)
      end
    end
  end

  describe "#generate_text_stream" do
    it "raises NotImplementedError" do
      expect do
        client.generate_text_stream("test prompt")
      end.to raise_error(NotImplementedError, "Streaming responses not yet implemented")
    end
  end

  describe "#count_tokens" do
    it "raises NotImplementedError" do
      expect do
        client.count_tokens("test text")
      end.to raise_error(NotImplementedError, "Token counting not directly supported by OpenAI API")
    end
  end

  describe "#list_models" do
    let(:api_url) { "https://api.openai.com/v1/models" }

    context "with successful response" do
      let(:mock_response) do
        {
          data: [
            {id: "gpt-4", object: "model", created: 1_687_882_411},
            {id: "gpt-3.5-turbo", object: "model", created: 1_677_610_602}
          ]
        }
      end

      before do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:get_json)
          .with(api_url, headers: anything)
          .and_return({status: 200, body: mock_response.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .with({status: 200, body: mock_response.to_json})
          .and_return({success: true, data: mock_response})
      end

      it "returns list of models" do
        result = client.list_models

        expect(result.length).to eq(2)
        expect(result.first[:id]).to eq("gpt-4")
        expect(result.last[:id]).to eq("gpt-3.5-turbo")
      end
    end

    context "with API error" do
      it "raises error" do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:get_json)
          .and_return({status: 401, body: {error: {message: "Unauthorized"}}.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 401, message: "Unauthorized"}})

        expect do
          client.list_models
        end.to raise_error(CodingAgentTools::Error, /OpenAI API Error \(401\): Unauthorized/)
      end
    end
  end

  describe "#model_info" do
    let(:api_url) { "https://api.openai.com/v1/models/gpt-4o-mini" }

    context "with successful response" do
      let(:mock_response) do
        {
          id: "gpt-4o-mini",
          object: "model",
          created: 1_687_882_411,
          owned_by: "openai"
        }
      end

      before do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:get_json)
          .with(api_url, headers: anything)
          .and_return({status: 200, body: mock_response.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .with({status: 200, body: mock_response.to_json})
          .and_return({success: true, data: mock_response})
      end

      it "returns model information" do
        result = client.model_info

        expect(result[:id]).to eq("gpt-4o-mini")
        expect(result[:object]).to eq("model")
        expect(result[:owned_by]).to eq("openai")
      end
    end

    context "with API error" do
      it "raises error" do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:get_json)
          .and_return({status: 404, body: {error: {message: "Model not found"}}.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 404, message: "Model not found"}})

        expect do
          client.model_info
        end.to raise_error(CodingAgentTools::Error, /OpenAI API Error \(404\): Model not found/)
      end
    end
  end

  describe "error handling" do
    it "handles connection errors" do
      allow(client.instance_variable_get(:@request_builder))
        .to receive(:post_json)
        .and_raise(StandardError.new("Connection failed"))

      expect do
        client.generate_text("test prompt")
      end.to raise_error(StandardError, "Connection failed")
    end

    it "provides detailed error messages for nested error structures" do
      parsed_response = {
        success: false,
        error: {
          status: 400,
          error: {
            message: "The model 'invalid-model' does not exist"
          }
        }
      }

      allow(client.instance_variable_get(:@request_builder))
        .to receive(:post_json)
        .and_return({status: 400, body: "error"})

      allow(client.instance_variable_get(:@response_parser))
        .to receive(:parse_response)
        .and_return(parsed_response)

      expect do
        client.generate_text("test prompt")
      end.to raise_error(CodingAgentTools::Error, /OpenAI API Error \(400\): The model 'invalid-model' does not exist/)
    end
  end

  describe "integration scenarios" do
    it "works with custom model and configuration" do
      custom_client = described_class.new(
        api_key: api_key,
        model: "gpt-3.5-turbo",
        generation_config: {temperature: 0.2, max_tokens: 1024}
      )

      mock_response = {
        choices: [{
          message: {content: "Custom response"},
          finish_reason: "stop"
        }],
        usage: {total_tokens: 15}
      }

      expected_payload = {
        model: "gpt-3.5-turbo",
        messages: [{role: "user", content: "test"}],
        temperature: 0.2,
        max_tokens: 1024
      }

      allow(custom_client.instance_variable_get(:@request_builder))
        .to receive(:post_json)
        .with(anything, expected_payload, headers: anything)
        .and_return({status: 200, body: mock_response.to_json})

      allow(custom_client.instance_variable_get(:@response_parser))
        .to receive(:parse_response)
        .and_return({success: true, data: mock_response})

      result = custom_client.generate_text("test")

      expect(result[:text]).to eq("Custom response")
      expect(result[:finish_reason]).to eq("stop")
    end
  end
end
