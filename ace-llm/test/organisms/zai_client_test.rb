# frozen_string_literal: true

require_relative "../test_helper"

class ZaiClientTest < AceTestCase
  def setup
    @client = Ace::LLM::Organisms::ZaiClient.allocate
  end

  def test_api_base_url_constant
    assert_equal "https://api.z.ai/api/paas/v4", Ace::LLM::Organisms::ZaiClient::API_BASE_URL
  end

  def test_default_model_constant
    assert_equal "glm-4.7-flashx", Ace::LLM::Organisms::ZaiClient::DEFAULT_MODEL
  end

  def test_provider_name
    assert_equal "zai", Ace::LLM::Organisms::ZaiClient.provider_name
  end

  def test_class_inheritance
    assert_kind_of Class, Ace::LLM::Organisms::ZaiClient
    assert Ace::LLM::Organisms::ZaiClient < Ace::LLM::Organisms::BaseClient
  end

  def test_parse_response_extracts_text_and_metadata
    response = {
      "id" => "chatcmpl-zai123",
      "created" => 1_738_000_000,
      "model" => "glm-4.7-flashx",
      "choices" => [
        {
          "message" => {"content" => "Hello from Z.AI"},
          "finish_reason" => "stop"
        }
      ],
      "usage" => {
        "prompt_tokens" => 11,
        "completion_tokens" => 6,
        "total_tokens" => 17
      }
    }

    result = @client.send(:parse_response, response)

    assert_equal "Hello from Z.AI", result[:text]
    assert_equal "stop", result[:metadata][:finish_reason]
    assert_equal "chatcmpl-zai123", result[:metadata][:id]
    assert_equal 1_738_000_000, result[:metadata][:created]
    assert_equal 11, result[:metadata][:input_tokens]
    assert_equal 6, result[:metadata][:output_tokens]
    assert_equal 17, result[:metadata][:total_tokens]
    assert_equal "glm-4.7-flashx", result[:metadata][:model_used]
  end

  def test_parse_response_raises_on_missing_choice
    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:parse_response, {"choices" => []})
    end

    assert_match(/No choices in response/, error.message)
  end

  def test_parse_response_raises_on_missing_text
    response = {
      "choices" => [{"message" => {}, "finish_reason" => "stop"}]
    }

    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:parse_response, response)
    end

    assert_match(/No text in response/, error.message)
  end

  def test_build_request_body_preserves_zero_values
    @client.instance_variable_set(:@model, "glm-4.7-flashx")
    messages = [{role: "user", content: "hello"}]
    generation_params = {
      temperature: 0.7,
      frequency_penalty: 0,
      presence_penalty: 0
    }

    result = @client.send(:build_request_body, messages, generation_params)

    assert_equal "glm-4.7-flashx", result[:model]
    assert_equal false, result[:stream]
    assert result.key?(:frequency_penalty)
    assert result.key?(:presence_penalty)
    assert_equal 0, result[:frequency_penalty]
    assert_equal 0, result[:presence_penalty]
  end

  def test_make_api_request_json_error
    failed_response = Minitest::Mock.new
    failed_response.expect :success?, false
    failed_response.expect :status, 401
    failed_response.expect :body, {"error" => {"type" => "invalid_request", "message" => "Invalid API key"}}

    http_client_mock = Object.new
    http_client_mock.define_singleton_method(:post) do |_url, _body, **_kwargs|
      failed_response
    end

    @client.instance_variable_set(:@http_client, http_client_mock)
    @client.instance_variable_set(:@base_url, "https://api.z.ai/api/paas/v4")
    @client.instance_variable_set(:@api_key, "test-zai-key")

    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:make_api_request, {model: "glm-4.7-flashx", messages: []})
    end

    assert_match(/Z.AI API error \(401\)/, error.message)
    assert_match(/invalid_request/, error.message)
    assert_match(/Invalid API key/, error.message)

    failed_response.verify
  end

  def test_make_api_request_non_json_error
    failed_response = Minitest::Mock.new
    failed_response.expect :success?, false
    failed_response.expect :status, 502
    failed_response.expect :body, "<html><body>Bad Gateway</body></html>"

    http_client_mock = Object.new
    http_client_mock.define_singleton_method(:post) do |_url, _body, **_kwargs|
      failed_response
    end

    @client.instance_variable_set(:@http_client, http_client_mock)
    @client.instance_variable_set(:@base_url, "https://api.z.ai/api/paas/v4")
    @client.instance_variable_set(:@api_key, "test-zai-key")

    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:make_api_request, {model: "glm-4.7-flashx", messages: []})
    end

    assert_match(/Z.AI API error \(502\)/, error.message)
    assert_match(/Non-JSON response: <html><body>Bad Gateway<\/body><\/html>/, error.message)

    failed_response.verify
  end
end
