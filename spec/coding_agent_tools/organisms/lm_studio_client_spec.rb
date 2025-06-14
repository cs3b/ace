# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/organisms/lm_studio_client"

RSpec.describe CodingAgentTools::Organisms::LMStudioClient do
  let(:client) { described_class.new }
  let(:mock_request_builder) { instance_double(CodingAgentTools::Molecules::HTTPRequestBuilder) }
  let(:mock_response_parser) { instance_double(CodingAgentTools::Molecules::APIResponseParser) }

  before do
    allow(CodingAgentTools::Molecules::HTTPRequestBuilder).to receive(:new).and_return(mock_request_builder)
    allow(CodingAgentTools::Molecules::APIResponseParser).to receive(:new).and_return(mock_response_parser)
  end

  describe "#initialize" do
    it "initializes with default values" do
      expect(client.instance_variable_get(:@model)).to eq("mistralai/devstral-small-2505")
      expect(client.instance_variable_get(:@base_url)).to eq("http://localhost:1234")
    end

    it "accepts custom model" do
      custom_client = described_class.new(model: "custom-model")
      expect(custom_client.instance_variable_get(:@model)).to eq("custom-model")
    end

    it "accepts custom base URL" do
      custom_client = described_class.new(base_url: "http://custom:5678")
      expect(custom_client.instance_variable_get(:@base_url)).to eq("http://custom:5678")
    end

    it "merges custom generation config" do
      custom_client = described_class.new(generation_config: { temperature: 0.9 })
      config = custom_client.instance_variable_get(:@generation_config)
      expect(config[:temperature]).to eq(0.9)
      expect(config[:max_tokens]).to eq(-1) # Default value preserved
    end
  end

  describe "#server_available?" do
    context "when server is available" do
      it "returns true" do
        allow(mock_request_builder).to receive(:get_json)
          .with("http://localhost:1234/v1/models")
          .and_return({ success: true, status: 200 })

        expect(client.server_available?).to be true
      end
    end

    context "when server is not available" do
      it "returns false on connection error" do
        allow(mock_request_builder).to receive(:get_json)
          .and_raise(StandardError.new("Connection refused"))

        expect(client.server_available?).to be false
      end

      it "returns false on non-200 status" do
        allow(mock_request_builder).to receive(:get_json)
          .and_return({ success: false, status: 500 })

        expect(client.server_available?).to be false
      end
    end
  end

  describe "#generate_text" do
    let(:prompt) { "Hello, world!" }
    let(:successful_response) do
      {
        success: true,
        data: {
          choices: [
            {
              message: {
                content: "Hello! How can I help you today?"
              },
              finish_reason: "stop"
            }
          ],
          usage: {
            prompt_tokens: 10,
            completion_tokens: 20,
            total_tokens: 30
          }
        }
      }
    end

    context "when server is available" do
      before do
        allow(client).to receive(:server_available?).and_return(true)
      end

      it "generates text successfully" do
        expected_payload = {
          model: "mistralai/devstral-small-2505",
          messages: [
            { role: "user", content: prompt }
          ],
          temperature: 0.7,
          max_tokens: -1,
          stream: false
        }

        allow(mock_request_builder).to receive(:post_json)
          .with("http://localhost:1234/v1/chat/completions", expected_payload)
          .and_return({ success: true, status: 200, body: successful_response[:data] })

        allow(mock_response_parser).to receive(:parse_response)
          .and_return(successful_response)

        result = client.generate_text(prompt)

        expect(result[:text]).to eq("Hello! How can I help you today?")
        expect(result[:finish_reason]).to eq("stop")
        expect(result[:usage_metadata]).to eq(successful_response[:data][:usage])
      end

      it "includes system instruction when provided" do
        system_instruction = "You are a helpful assistant."
        expected_payload = {
          model: "mistralai/devstral-small-2505",
          messages: [
            { role: "system", content: system_instruction },
            { role: "user", content: prompt }
          ],
          temperature: 0.7,
          max_tokens: -1,
          stream: false
        }

        allow(mock_request_builder).to receive(:post_json)
          .with("http://localhost:1234/v1/chat/completions", expected_payload)
          .and_return({ success: true, status: 200, body: successful_response[:data] })

        allow(mock_response_parser).to receive(:parse_response)
          .and_return(successful_response)

        client.generate_text(prompt, system_instruction: system_instruction)
      end

      it "applies custom generation config" do
        expected_payload = {
          model: "mistralai/devstral-small-2505",
          messages: [
            { role: "user", content: prompt }
          ],
          temperature: 0.9,
          max_tokens: 1000,
          stream: false
        }

        allow(mock_request_builder).to receive(:post_json)
          .with("http://localhost:1234/v1/chat/completions", expected_payload)
          .and_return({ success: true, status: 200, body: successful_response[:data] })

        allow(mock_response_parser).to receive(:parse_response)
          .and_return(successful_response)

        client.generate_text(prompt, generation_config: { temperature: 0.9, max_tokens: 1000 })
      end
    end

    context "when server is not available" do
      before do
        allow(client).to receive(:server_available?).and_return(false)
      end

      it "raises an error" do
        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /LM Studio server is not available/)
      end
    end

    context "when API returns an error" do
      before do
        allow(client).to receive(:server_available?).and_return(true)
      end

      it "handles API errors" do
        error_response = {
          success: false,
          error: {
            status: 400,
            message: "Bad Request",
            details: { message: "Invalid model specified" }
          }
        }

        allow(mock_request_builder).to receive(:post_json)
          .and_return({ success: false, status: 400, body: { error: "Invalid model" } })

        allow(mock_response_parser).to receive(:parse_response)
          .and_return(error_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /LM Studio API Error.*Invalid model specified/)
      end
    end

    context "when response has invalid structure" do
      before do
        allow(client).to receive(:server_available?).and_return(true)
      end

      it "raises error when data is not a hash" do
        invalid_response = { success: true, data: "not a hash" }

        allow(mock_request_builder).to receive(:post_json).and_return({ success: true })
        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /Response data is not a Hash/)
      end

      it "raises error when choices is not an array" do
        invalid_response = { success: true, data: { choices: "not an array" } }

        allow(mock_request_builder).to receive(:post_json).and_return({ success: true })
        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /'choices' field is not an array/)
      end

      it "raises error when choices array is empty" do
        invalid_response = { success: true, data: { choices: [] } }

        allow(mock_request_builder).to receive(:post_json).and_return({ success: true })
        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /'choices' array is empty/)
      end

      it "raises error when first choice is not a hash" do
        invalid_response = { success: true, data: { choices: ["not a hash"] } }

        allow(mock_request_builder).to receive(:post_json).and_return({ success: true })
        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /No valid first choice found/)
      end

      it "raises error when message is not a hash" do
        invalid_response = { success: true, data: { choices: [{ message: "not a hash" }] } }

        allow(mock_request_builder).to receive(:post_json).and_return({ success: true })
        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /choice 'message' field is missing or not a Hash/)
      end

      it "raises error when content key is missing" do
        invalid_response = { success: true, data: { choices: [{ message: {} }] } }

        allow(mock_request_builder).to receive(:post_json).and_return({ success: true })
        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /message does not have a 'content' key/)
      end

      it "raises error when content is nil" do
        invalid_response = { success: true, data: { choices: [{ message: { content: nil } }] } }

        allow(mock_request_builder).to receive(:post_json).and_return({ success: true })
        allow(mock_response_parser).to receive(:parse_response).and_return(invalid_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /message content is nil/)
      end
    end
  end

  describe "#list_models" do
    context "when server is available" do
      before do
        allow(client).to receive(:server_available?).and_return(true)
      end

      it "returns list of models" do
        models_response = {
          success: true,
          data: {
            data: [
              { id: "model1", object: "model", owned_by: "local" },
              { id: "model2", object: "model", owned_by: "local" }
            ]
          }
        }

        allow(mock_request_builder).to receive(:get_json)
          .with("http://localhost:1234/v1/models")
          .and_return({ success: true, status: 200, body: models_response[:data] })

        allow(mock_response_parser).to receive(:parse_response)
          .and_return(models_response)

        result = client.list_models

        expect(result).to eq(models_response[:data][:data])
      end

      it "returns empty array when no models data" do
        models_response = { success: true, data: {} }

        allow(mock_request_builder).to receive(:get_json).and_return({ success: true })
        allow(mock_response_parser).to receive(:parse_response).and_return(models_response)

        result = client.list_models

        expect(result).to eq([])
      end
    end

    context "when server is not available" do
      before do
        allow(client).to receive(:server_available?).and_return(false)
      end

      it "raises an error" do
        expect { client.list_models }
          .to raise_error(CodingAgentTools::Error, /LM Studio server is not available/)
      end
    end
  end

  describe "#model_info" do
    it "returns model info from list when model exists" do
      models = [
        { id: "mistralai/devstral-small-2505", object: "model", owned_by: "local" },
        { id: "other-model", object: "model", owned_by: "local" }
      ]

      allow(client).to receive(:list_models).and_return(models)

      result = client.model_info

      expect(result[:id]).to eq("mistralai/devstral-small-2505")
      expect(result[:object]).to eq("model")
    end

    it "returns default info when model not found in list" do
      allow(client).to receive(:list_models).and_return([])

      result = client.model_info

      expect(result[:id]).to eq("mistralai/devstral-small-2505")
      expect(result[:object]).to eq("model")
      expect(result[:owned_by]).to eq("local")
    end
  end

  describe "private methods" do
    describe "#build_api_url" do
      it "builds correct API URL" do
        url = client.send(:build_api_url, "chat/completions")
        expect(url).to eq("http://localhost:1234/v1/chat/completions")
      end
    end

    describe "#build_generation_payload" do
      it "builds basic payload" do
        payload = client.send(:build_generation_payload, "Hello", {})

        expect(payload[:model]).to eq("mistralai/devstral-small-2505")
        expect(payload[:messages]).to eq([{ role: "user", content: "Hello" }])
        expect(payload[:temperature]).to eq(0.7)
        expect(payload[:max_tokens]).to eq(-1)
        expect(payload[:stream]).to be false
      end

      it "includes system instruction" do
        payload = client.send(:build_generation_payload, "Hello", { system_instruction: "Be helpful" })

        expect(payload[:messages]).to eq([
          { role: "system", content: "Be helpful" },
          { role: "user", content: "Hello" }
        ])
      end

      it "applies custom generation config" do
        payload = client.send(:build_generation_payload, "Hello", { generation_config: { temperature: 0.9 } })

        expect(payload[:temperature]).to eq(0.9)
      end
    end
  end
end
