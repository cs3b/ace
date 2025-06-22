# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/organisms/anthropic_client"
require "webmock/rspec"

RSpec.describe CodingAgentTools::Organisms::AnthropicClient do
  let(:api_key) { "test-api-key-123" }
  let(:client) { described_class.new(api_key: api_key) }
  let(:custom_client) do
    described_class.new(
      api_key: api_key,
      model: "claude-3-haiku-20240307",
      base_url: "https://custom.api.com",
      generation_config: {temperature: 0.5, max_tokens: 2048},
      timeout: 60
    )
  end

  describe "#initialize" do
    context "with default configuration" do
      it "uses default model" do
        expect(client.instance_variable_get(:@model)).to eq("claude-3-5-haiku-20241022")
      end

      it "uses default base URL" do
        expect(client.instance_variable_get(:@base_url)).to eq("https://api.anthropic.com/v1")
      end

      it "uses default generation config" do
        config = client.instance_variable_get(:@generation_config)
        expect(config[:temperature]).to eq(0.7)
        expect(config[:max_tokens]).to eq(4096)
      end
    end

    context "with custom configuration" do
      it "uses custom model" do
        expect(custom_client.instance_variable_get(:@model)).to eq("claude-3-haiku-20240307")
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
        allow(ENV).to receive(:fetch).with("ANTHROPIC_API_KEY", nil).and_return(nil)

        expect {
          described_class.new
        }.to raise_error(KeyError)
      end
    end

    context "with API key from environment" do
      before do
        ENV["ANTHROPIC_API_KEY"] = "env-api-key"
      end

      after do
        ENV.delete("ANTHROPIC_API_KEY")
      end

      it "uses environment API key when not provided" do
        client = described_class.new
        expect(client.instance_variable_get(:@api_key)).to eq("env-api-key")
      end
    end
  end

  describe "#generate_text" do
    let(:prompt) { "What is 2+2?" }
    let(:api_url) { "https://api.anthropic.com/v1/messages" }

    context "with successful response" do
      let(:mock_response) do
        {
          content: [
            {
              type: "text",
              text: "2+2 equals 4"
            }
          ],
          stop_reason: "end_turn",
          usage: {
            input_tokens: 10,
            output_tokens: 8
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
        expect(result[:finish_reason]).to eq("end_turn")
        expect(result[:usage_metadata]).to eq({
          input_tokens: 10,
          output_tokens: 8
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
          model: "claude-3-5-haiku-20241022",
          messages: [
            {role: "user", content: prompt}
          ],
          system: "You are a math tutor",
          temperature: 0.3,
          max_tokens: 1024
        }
      end

      it "sends custom generation config and system instruction" do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .with(api_url, expected_payload, headers: anything)
          .and_return({status: 200, body: {content: [{text: "Response"}]}.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: true, data: {content: [{type: "text", text: "Response"}]}})

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
          .and_return({success: false, error: {status: 400, error: {message: "Bad request"}}})

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Anthropic API Error \(400\): Bad request/)
      end

      it "handles 401 Unauthorized" do
        error_response = {error: {message: "Invalid API key"}}
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 401, body: error_response.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 401, error: {message: "Invalid API key"}}})

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Anthropic API Error \(401\): Invalid API key/)
      end

      it "handles 429 Rate Limit" do
        error_response = {error: {message: "Rate limit exceeded"}}
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 429, body: error_response.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 429, error: {message: "Rate limit exceeded"}}})

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Anthropic API Error \(429\): Rate limit exceeded/)
      end

      it "handles malformed response" do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 200, body: "invalid json"})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 200, error: {message: "Invalid JSON"}}})

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /Anthropic API Error/)
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

      it "handles response where 'content' field is missing" do
        response_data = {}
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 200, body: response_data.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: true, data: response_data})

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /'content' field is not an array/)
      end

      it "handles response where 'content' array is empty" do
        response_data = {content: []}
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 200, body: response_data.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: true, data: response_data})

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /'content' array is empty/)
      end

      it "handles response where text content is nil" do
        response_data = {
          content: [
            {
              type: "text",
              text: nil
            }
          ],
          stop_reason: "end_turn"
        }
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:post_json)
          .and_return({status: 200, body: response_data.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: true, data: response_data})

        expect {
          client.generate_text(prompt)
        }.to raise_error(CodingAgentTools::Error, /No text blocks found in content/)
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
      }.to raise_error(NotImplementedError, "Token counting not directly supported by Anthropic API")
    end
  end

  describe "#list_models" do
    let(:api_models_url) { "https://api.anthropic.com/v1/models" }

    context "with successful API response" do
      let(:mock_api_response) do
        {
          data: [
            {
              id: "claude-3-5-sonnet-20241022",
              display_name: "Claude 3.5 Sonnet",
              created_at: "2024-10-22T00:00:00Z",
              type: "model"
            },
            {
              id: "claude-3-5-haiku-20241022",
              display_name: "Claude 3.5 Haiku",
              created_at: "2024-10-22T00:00:00Z",
              type: "model"
            }
          ],
          has_more: false,
          first_id: "claude-3-5-sonnet-20241022",
          last_id: "claude-3-5-haiku-20241022"
        }
      end

      before do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:get_json)
          .with("#{api_models_url}?limit=100", headers: anything)
          .and_return({status: 200, body: mock_api_response.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .with({status: 200, body: mock_api_response.to_json})
          .and_return({success: true, data: mock_api_response})
      end

      it "returns list of models from API" do
        result = client.list_models

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)

        claude_sonnet = result.find { |m| m[:id] == "claude-3-5-sonnet-20241022" }
        expect(claude_sonnet).not_to be_nil
        expect(claude_sonnet[:name]).to eq("Claude 3.5 Sonnet")
        expect(claude_sonnet[:description]).to eq("Balanced intelligence and speed")
        expect(claude_sonnet[:created]).to be_a(Integer)

        claude_haiku = result.find { |m| m[:id] == "claude-3-5-haiku-20241022" }
        expect(claude_haiku).not_to be_nil
        expect(claude_haiku[:name]).to eq("Claude 3.5 Haiku")
        expect(claude_haiku[:description]).to eq("Fast and cost-effective")
      end
    end

    context "with paginated API response" do
      let(:first_page_response) do
        {
          data: [
            {
              id: "claude-3-5-sonnet-20241022",
              display_name: "Claude 3.5 Sonnet",
              created_at: "2024-10-22T00:00:00Z",
              type: "model"
            }
          ],
          has_more: true,
          first_id: "claude-3-5-sonnet-20241022",
          last_id: "claude-3-5-sonnet-20241022"
        }
      end

      let(:second_page_response) do
        {
          data: [
            {
              id: "claude-3-5-haiku-20241022",
              display_name: "Claude 3.5 Haiku",
              created_at: "2024-10-22T00:00:00Z",
              type: "model"
            }
          ],
          has_more: false,
          first_id: "claude-3-5-haiku-20241022",
          last_id: "claude-3-5-haiku-20241022"
        }
      end

      before do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:get_json)
          .with("#{api_models_url}?limit=100", headers: anything)
          .and_return({status: 200, body: first_page_response.to_json})

        allow(client.instance_variable_get(:@request_builder))
          .to receive(:get_json)
          .with("#{api_models_url}?after_id=claude-3-5-sonnet-20241022&limit=100", headers: anything)
          .and_return({status: 200, body: second_page_response.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .with({status: 200, body: first_page_response.to_json})
          .and_return({success: true, data: first_page_response})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .with({status: 200, body: second_page_response.to_json})
          .and_return({success: true, data: second_page_response})
      end

      it "handles pagination and returns all models" do
        result = client.list_models

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.map { |m| m[:id] }).to contain_exactly(
          "claude-3-5-sonnet-20241022",
          "claude-3-5-haiku-20241022"
        )
      end
    end

    context "when API call fails" do
      before do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:get_json)
          .and_return({status: 401, body: {error: {message: "Unauthorized"}}.to_json})

        allow(client.instance_variable_get(:@response_parser))
          .to receive(:parse_response)
          .and_return({success: false, error: {status: 401, error: {message: "Unauthorized"}}})
      end

      it "falls back to static list" do
        result = client.list_models

        expect(result).to be_an(Array)
        expect(result.length).to be > 0

        # Should contain fallback models
        claude_haiku = result.find { |m| m[:id] == "claude-3-5-haiku-20241022" }
        expect(claude_haiku).not_to be_nil
        expect(claude_haiku[:name]).to eq("Claude 3.5 Haiku")
      end
    end

    context "when API call raises exception" do
      before do
        allow(client.instance_variable_get(:@request_builder))
          .to receive(:get_json)
          .and_raise(StandardError.new("Network error"))
      end

      it "falls back to static list" do
        result = client.list_models

        expect(result).to be_an(Array)
        expect(result.length).to be > 0

        # Should contain fallback models
        claude_haiku = result.find { |m| m[:id] == "claude-3-5-haiku-20241022" }
        expect(claude_haiku).not_to be_nil
      end
    end
  end

  describe "#model_info" do
    it "returns basic model information" do
      result = client.model_info

      expect(result[:id]).to eq("claude-3-5-haiku-20241022")
      expect(result[:name]).to eq("Claude 3.5 Haiku")
      expect(result[:description]).to eq("Fast and cost-effective")
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
      }.to raise_error(CodingAgentTools::Error, /Anthropic API Error \(400\): The model 'invalid-model' does not exist/)
    end
  end

  describe "integration scenarios" do
    it "works with custom model and configuration" do
      custom_client = described_class.new(
        api_key: api_key,
        model: "claude-3-haiku-20240307",
        generation_config: {temperature: 0.2, max_tokens: 1024}
      )

      mock_response = {
        content: [{
          type: "text",
          text: "Custom response"
        }],
        stop_reason: "end_turn",
        usage: {input_tokens: 5, output_tokens: 10}
      }

      expected_payload = {
        model: "claude-3-haiku-20240307",
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
      expect(result[:finish_reason]).to eq("end_turn")
    end
  end
end
