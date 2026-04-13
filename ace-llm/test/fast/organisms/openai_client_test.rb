# frozen_string_literal: true

require_relative "../../test_helper"

class OpenAIClientTest < AceTestCase
  def setup
    @client = Ace::LLM::Organisms::OpenAIClient.allocate
  end

  # Test client constants
  def test_api_base_url_constant
    assert_equal "https://api.openai.com", Ace::LLM::Organisms::OpenAIClient::API_BASE_URL
  end

  def test_default_model_constant
    assert_equal "gpt-4o", Ace::LLM::Organisms::OpenAIClient::DEFAULT_MODEL
  end

  def test_default_generation_config_constant
    config = Ace::LLM::Organisms::OpenAIClient::DEFAULT_GENERATION_CONFIG
    assert_kind_of Hash, config
    assert config.frozen?
    assert_equal 0.7, config[:temperature]
  end

  # Test provider name
  def test_provider_name
    assert_equal "openai", Ace::LLM::Organisms::OpenAIClient.provider_name
  end

  # Test class exists and inherits from BaseClient
  def test_class_inheritance
    assert_kind_of Class, Ace::LLM::Organisms::OpenAIClient
    assert Ace::LLM::Organisms::OpenAIClient < Ace::LLM::Organisms::BaseClient
  end

  # Test build_request_body preserves zero values (regression test)
  def test_build_request_body_preserves_zero_frequency_penalty
    @client.instance_variable_set(:@model, "gpt-4o")

    messages = [{role: "user", content: "Test"}]
    generation_params = {
      temperature: 0.5,
      frequency_penalty: 0
    }

    result = @client.send(:build_request_body, messages, generation_params)

    assert result.key?(:frequency_penalty), "frequency_penalty should be present with value 0"
    assert_equal 0, result[:frequency_penalty]
  end

  def test_build_request_body_preserves_zero_presence_penalty
    @client.instance_variable_set(:@model, "gpt-4o")

    messages = [{role: "user", content: "Test"}]
    generation_params = {
      temperature: 0.5,
      presence_penalty: 0
    }

    result = @client.send(:build_request_body, messages, generation_params)

    assert result.key?(:presence_penalty), "presence_penalty should be present with value 0"
    assert_equal 0, result[:presence_penalty]
  end

  def test_build_request_body_excludes_nil_params
    @client.instance_variable_set(:@model, "gpt-4o")

    messages = [{role: "user", content: "Test"}]
    generation_params = {temperature: 0.7, max_tokens: nil, frequency_penalty: nil}

    result = @client.send(:build_request_body, messages, generation_params)

    assert_equal 0.7, result[:temperature]
    refute result.key?(:max_tokens)
    refute result.key?(:frequency_penalty)
  end

  def test_build_request_body_with_all_generation_params
    @client.instance_variable_set(:@model, "gpt-4o")

    messages = [{role: "user", content: "Test"}]
    generation_params = {
      temperature: 0.5,
      max_tokens: 2048,
      top_p: 0.9,
      frequency_penalty: 0.5,
      presence_penalty: 0.3
    }

    result = @client.send(:build_request_body, messages, generation_params)

    assert_equal 0.5, result[:temperature]
    assert_equal 2048, result[:max_tokens]
    assert_equal 0.9, result[:top_p]
    assert_equal 0.5, result[:frequency_penalty]
    assert_equal 0.3, result[:presence_penalty]
  end

  # Test full chain: extract_generation_options -> build_request_body preserves zero values
  def test_full_chain_preserves_zero_penalties
    @client.instance_variable_set(:@model, "gpt-4o")
    @client.instance_variable_set(:@generation_config, {temperature: 0.7, max_tokens: nil})

    options = {
      temperature: 0.8,
      frequency_penalty: 0,
      presence_penalty: 0
    }

    # Step 1: Extract generation options (this uses the OpenAICompatibleParams concern)
    generation_params = @client.send(:extract_generation_options, options)

    assert generation_params.key?(:frequency_penalty), "extract_generation_options should preserve zero frequency_penalty"
    assert generation_params.key?(:presence_penalty), "extract_generation_options should preserve zero presence_penalty"
    assert_equal 0, generation_params[:frequency_penalty]
    assert_equal 0, generation_params[:presence_penalty]

    # Step 2: Build request body (this should also preserve zero values)
    messages = [{role: "user", content: "Test"}]
    request_body = @client.send(:build_request_body, messages, generation_params)

    assert request_body.key?(:frequency_penalty), "build_request_body should preserve zero frequency_penalty"
    assert request_body.key?(:presence_penalty), "build_request_body should preserve zero presence_penalty"
    assert_equal 0, request_body[:frequency_penalty]
    assert_equal 0, request_body[:presence_penalty]
  end

  # Test parse_response with valid response
  def test_parse_response_extracts_text_and_metadata
    response = {
      "id" => "chatcmpl-abc123",
      "created" => 1699000000,
      "model" => "gpt-4o",
      "choices" => [
        {
          "message" => {"content" => "Hello from OpenAI!"},
          "finish_reason" => "stop"
        }
      ],
      "usage" => {
        "prompt_tokens" => 10,
        "completion_tokens" => 5,
        "total_tokens" => 15
      }
    }

    result = @client.send(:parse_response, response)

    assert_equal "Hello from OpenAI!", result[:text]
    assert_equal "stop", result[:metadata][:finish_reason]
    assert_equal "chatcmpl-abc123", result[:metadata][:id]
    assert_equal 1699000000, result[:metadata][:created]
    assert_equal 10, result[:metadata][:input_tokens]
    assert_equal 5, result[:metadata][:output_tokens]
    assert_equal 15, result[:metadata][:total_tokens]
    assert_equal "gpt-4o", result[:metadata][:model_used]
  end

  def test_parse_response_handles_missing_usage
    response = {
      "id" => "chatcmpl-abc123",
      "choices" => [
        {
          "message" => {"content" => "Response without usage"},
          "finish_reason" => "stop"
        }
      ]
    }

    result = @client.send(:parse_response, response)

    assert_equal "Response without usage", result[:text]
    assert_nil result[:metadata][:input_tokens]
    assert_nil result[:metadata][:output_tokens]
  end

  def test_parse_response_raises_on_empty_choices
    response = {"choices" => []}

    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:parse_response, response)
    end
    assert_match(/No text in response/, error.message)
  end
end
