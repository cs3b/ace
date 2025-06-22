# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/organisms/together_ai_client"
require "webmock/rspec"

RSpec.describe CodingAgentTools::Organisms::TogetherAIClient do
  let(:api_key) { "test-api-key-123" }
  let(:client) { described_class.new(api_key: api_key) }
  let(:custom_client) do
    described_class.new(
      api_key: api_key,
      model: "meta-llama/Llama-2-70b-chat-hf",
      base_url: "https://custom.api.com",
      generation_config: {temperature: 0.5, max_tokens: 2048},
      timeout: 60
    )
  end

  describe "#initialize" do
    context "with default configuration" do
      it "uses default model" do
        expect(client.instance_variable_get(:@model)).to eq("deepseek-ai/DeepSeek-V3")
      end

      it "uses default base URL" do
        expect(client.instance_variable_get(:@base_url)).to eq("https://api.together.xyz/v1")
      end

      it "uses default generation config" do
        config = client.instance_variable_get(:@generation_config)
        expect(config[:temperature]).to eq(0.7)
        expect(config[:max_tokens]).to eq(4096)
      end
    end

    context "with custom configuration" do
      it "uses custom model" do
        expect(custom_client.instance_variable_get(:@model)).to eq("meta-llama/Llama-2-70b-chat-hf")
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
        allow(ENV).to receive(:fetch).with("TOGETHER_API_KEY", nil).and_return(nil)

        expect {
          described_class.new
        }.to raise_error(KeyError)
      end
    end

    context "with API key from environment" do
      before do
        ENV["TOGETHER_API_KEY"] = "env-api-key"
      end

      after do
        ENV.delete("TOGETHER_API_KEY")
      end

      it "uses environment API key when not provided" do
        client = described_class.new
        expect(client.instance_variable_get(:@api_key)).to eq("env-api-key")
      end
    end
  end

  describe "#generate_text" do
    let(:prompt) { "What is 2+2?" }
    let(:api_url) { "https://api.together.xyz/v1/chat/completions" }

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
          model: "deepseek-ai/DeepSeek-V3",
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

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Together AI API Error \(400\): Bad request/)
      end

      it "handles 401 Unauthorized" do
        error_response = {error: {message: "Invalid API key"}}
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 401, body: error_response.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 401, message: "Invalid API key"}})

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Together AI API Error \(401\): Invalid API key/)
      end

      it "handles 429 Rate Limit" do
        error_response = {error: {message: "Rate limit exceeded"}}
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 429, body: error_response.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 429, message: "Rate limit exceeded"}})

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Together AI API Error \(429\): Rate limit exceeded/)
      end

      it "handles malformed response" do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 200, body: "invalid json"})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 200, message: "Invalid JSON"}})

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Together AI API Error/)
      end

      it "handles response where data is not a Hash" do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 200, body: "[]"})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: true, data: []})

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Response data is not a Hash/)
      end

      it "handles response where 'choices' field is missing" do
        response_data = {}
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 200, body: response_data.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: true, data: response_data})

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /'choices' field is not an array/)
      end

      it "handles response where 'choices' array is empty" do
        response_data = {choices: []}
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 200, body: response_data.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: true, data: response_data})

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /'choices' array is empty/)
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

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /message content is nil/)
      end
    end
  end

  describe "#generate_text_stream" do
    it "raises NotImplementedError" do
      expect {
        client.generate_text_stream("test prompt")
      }.to raise_error(NotImplementedError, "Streaming responses not yet implemented")
    end
  end

  describe "#count_tokens" do
    it "raises NotImplementedError" do
      expect {
        client.count_tokens("test text")
      }.to raise_error(NotImplementedError, "Token counting not directly supported by Together AI API")
    end
  end

  describe "#list_models" do
    let(:api_url) { "https://api.together.xyz/v1/models" }

    context "with successful response" do
      let(:mock_response) do
        [
          {id: "deepseek-ai/DeepSeek-V3", object: "model", created: 1687882411},
          {id: "meta-llama/Llama-2-70b-chat-hf", object: "model", created: 1677610602},
          {id: "some-other-model", object: "model", created: 1677610603},
          {id: "gpt-3.5-turbo-instruct", object: "model", created: 1677610604}
        ]
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

      it "returns list of models filtered to chat/instruct models" do
        result = client.list_models

        expect(result.length).to eq(2)
        expect(result.map { |m| m[:id] }).to contain_exactly(
          "meta-llama/Llama-2-70b-chat-hf",
          "gpt-3.5-turbo-instruct"
        )
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

        expect {
          client.list_models
        }.to raise_error(CodingAgentTools::Error, /Together AI API Error \(401\): Unauthorized/)
      end
    end
  end

  describe "#model_info" do
    context "with successful response" do
      let(:models_response) do
        [
          {id: "deepseek-ai/DeepSeek-V3", object: "model", created: 1687882411, owned_by: "together"},
          {id: "meta-llama/Llama-2-70b-chat-hf", object: "model", created: 1677610602},
          {id: "gpt-3.5-turbo-instruct", object: "model", created: 1677610604}
        ]
      end

      before do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:get_json)
          .with("https://api.together.xyz/v1/models", headers: anything)
          .and_return({status: 200, body: models_response.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .with({status: 200, body: models_response.to_json})
          .and_return({success: true, data: models_response})
      end

      it "returns model information from list_models" do
        result = client.model_info

        # Since DeepSeek-V3 doesn't have "chat" or "instruct" in its name,
        # it won't be in the filtered list, so model_info will return default info
        expect(result[:id]).to eq("deepseek-ai/DeepSeek-V3")
        expect(result[:name]).to eq("deepseek-ai/DeepSeek-V3")
        expect(result[:owned_by]).to eq("together")
        expect(result[:created]).to be_a(Integer)
      end
    end

    context "when model is found in filtered list" do
      let(:custom_model_client) do
        described_class.new(
          api_key: api_key,
          model: "meta-llama/Llama-2-70b-chat-hf"
        )
      end

      let(:models_response) do
        [
          {id: "deepseek-ai/DeepSeek-V3", object: "model", created: 1687882411},
          {id: "meta-llama/Llama-2-70b-chat-hf", object: "model", created: 1677610602, owned_by: "meta"},
          {id: "gpt-3.5-turbo-instruct", object: "model", created: 1677610604}
        ]
      end

      before do
        allow(custom_model_client.instance_variable_get(:@request_builder))
          .to receive(:get_json)
          .with("https://api.together.xyz/v1/models", headers: anything)
          .and_return({status: 200, body: models_response.to_json})

        allow(custom_model_client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .with({status: 200, body: models_response.to_json})
          .and_return({success: true, data: models_response})
      end

      it "returns model info from filtered list" do
        result = custom_model_client.model_info

        expect(result[:id]).to eq("meta-llama/Llama-2-70b-chat-hf")
        expect(result[:object]).to eq("model")
        expect(result[:created]).to eq(1677610602)
        expect(result[:owned_by]).to eq("meta")
      end
    end

    context "with API error" do
      it "raises error" do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:get_json)
          .with("https://api.together.xyz/v1/models", headers: anything)
          .and_return({status: 404, body: {error: {message: "Models endpoint not found"}}.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 404, message: "Models endpoint not found"}})

        expect {
          client.model_info
        }.to raise_error(CodingAgentTools::Error, /Together AI API Error \(404\): Models endpoint not found/)
      end
    end
  end

  describe "error handling" do
    it "handles connection errors" do
      allow(client.instance_variable_get(:@request_builder))
        .to receive(:post_json)
        .and_raise(StandardError.new("Connection failed"))

      expect {
        client.generate_text("test prompt")
      }.to raise_error(StandardError, "Connection failed")
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

      expect {
        client.generate_text("test prompt")
      }.to raise_error(CodingAgentTools::Error, /Together AI API Error \(400\): The model 'invalid-model' does not exist/)
    end
  end

  describe "integration scenarios" do
    it "works with custom model and configuration" do
      custom_client = described_class.new(
        api_key: api_key,
        model: "meta-llama/Llama-2-70b-chat-hf",
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
        model: "meta-llama/Llama-2-70b-chat-hf",
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
