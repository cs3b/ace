# frozen_string_literal: true

require_relative "../../test_helper"

class XAIClientTest < AceTestCase
  def setup
    @client = Ace::LLM::Organisms::XAIClient.allocate
  end

  # Helper: Create a mock failed response with specified status and body
  def create_failed_response_mock(status:, body:)
    mock = Minitest::Mock.new
    mock.expect :success?, false
    mock.expect :status, status
    mock.expect :body, body
    mock
  end

  # Helper: Configure client with mock HTTP client that returns the given response
  def setup_client_with_mock_response(response)
    http_client_mock = Object.new
    http_client_mock.define_singleton_method(:post) do |_url, _body, **_kwargs|
      response
    end

    @client.instance_variable_set(:@http_client, http_client_mock)
    @client.instance_variable_set(:@base_url, "https://api.x.ai")
    @client.instance_variable_set(:@api_key, "test-key")
  end

  # Test client constants
  def test_api_base_url_constant
    assert_equal "https://api.x.ai", Ace::LLM::Organisms::XAIClient::API_BASE_URL
  end

  def test_default_model_constant
    assert_equal "grok-4", Ace::LLM::Organisms::XAIClient::DEFAULT_MODEL
  end

  def test_default_generation_config_constant
    config = Ace::LLM::Organisms::XAIClient::DEFAULT_GENERATION_CONFIG
    assert_kind_of Hash, config
    assert config.frozen?
    assert_equal 0.7, config[:temperature]
    assert_equal 4096, config[:max_tokens]
  end

  def test_generation_keys_constant
    keys = Ace::LLM::Organisms::XAIClient::GENERATION_KEYS
    assert_kind_of Array, keys
    assert_includes keys, :temperature
    assert_includes keys, :max_tokens
    assert_includes keys, :top_p
    assert_includes keys, :frequency_penalty
    assert_includes keys, :presence_penalty
  end

  # Test provider name
  def test_provider_name
    assert_equal "xai", Ace::LLM::Organisms::XAIClient.provider_name
  end

  # Test class exists and inherits from BaseClient
  def test_class_inheritance
    assert_kind_of Class, Ace::LLM::Organisms::XAIClient
    assert Ace::LLM::Organisms::XAIClient < Ace::LLM::Organisms::BaseClient
  end

  # Test parse_response with valid response
  def test_parse_response_extracts_text_and_metadata
    response = {
      "id" => "chatcmpl-abc123",
      "created" => 1699000000,
      "model" => "grok-3",
      "choices" => [
        {
          "message" => {"content" => "Hello, I'm Grok!"},
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

    assert_equal "Hello, I'm Grok!", result[:text]
    assert_equal "stop", result[:metadata][:finish_reason]
    assert_equal "chatcmpl-abc123", result[:metadata][:id]
    assert_equal 1699000000, result[:metadata][:created]
    assert_equal 10, result[:metadata][:input_tokens]
    assert_equal 5, result[:metadata][:output_tokens]
    assert_equal 15, result[:metadata][:total_tokens]
    assert_equal "grok-3", result[:metadata][:model_used]
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
    assert_match(/No choices in response/, error.message)
  end

  def test_parse_response_raises_on_nil_choices
    response = {"choices" => nil}

    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:parse_response, response)
    end
    assert_match(/No choices in response/, error.message)
  end

  def test_parse_response_raises_on_missing_content
    response = {
      "choices" => [
        {"message" => {}, "finish_reason" => "stop"}
      ]
    }

    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:parse_response, response)
    end
    assert_match(/No text in response/, error.message)
  end

  # Test build_request_body
  def test_build_request_body_basic
    # Set instance variables needed by build_request_body
    @client.instance_variable_set(:@model, "grok-3")

    messages = [
      {role: "user", content: "Hello"}
    ]
    generation_params = {temperature: 0.8}

    result = @client.send(:build_request_body, messages, generation_params)

    assert_equal "grok-3", result[:model]
    assert_equal 1, result[:messages].length
    assert_equal 0.8, result[:temperature]
    assert_equal false, result[:stream]
  end

  def test_build_request_body_with_all_generation_params
    @client.instance_variable_set(:@model, "grok-4")

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

  def test_build_request_body_excludes_nil_params
    @client.instance_variable_set(:@model, "grok-3")

    messages = [{role: "user", content: "Test"}]
    generation_params = {temperature: 0.7, max_tokens: nil, top_p: nil}

    result = @client.send(:build_request_body, messages, generation_params)

    assert_equal 0.7, result[:temperature]
    refute result.key?(:max_tokens)
    refute result.key?(:top_p)
  end

  # Regression tests: zero values should be preserved (not filtered out)
  def test_build_request_body_preserves_zero_frequency_penalty
    @client.instance_variable_set(:@model, "grok-3")

    messages = [{role: "user", content: "Test"}]
    generation_params = {temperature: 0.7, frequency_penalty: 0}

    result = @client.send(:build_request_body, messages, generation_params)

    assert result.key?(:frequency_penalty), "frequency_penalty should be present with value 0"
    assert_equal 0, result[:frequency_penalty]
  end

  def test_build_request_body_preserves_zero_presence_penalty
    @client.instance_variable_set(:@model, "grok-3")

    messages = [{role: "user", content: "Test"}]
    generation_params = {temperature: 0.7, presence_penalty: 0}

    result = @client.send(:build_request_body, messages, generation_params)

    assert result.key?(:presence_penalty), "presence_penalty should be present with value 0"
    assert_equal 0, result[:presence_penalty]
  end

  def test_build_request_body_with_system_append
    @client.instance_variable_set(:@model, "grok-3")

    messages = [
      {role: "system", content: "You are helpful"},
      {role: "user", content: "Hello"}
    ]
    generation_params = {system_append: "Be concise"}

    result = @client.send(:build_request_body, messages, generation_params)

    # System prompt should be concatenated
    system_message = result[:messages].find { |m| m[:role] == "system" }
    assert_includes system_message[:content], "You are helpful"
    assert_includes system_message[:content], "Be concise"
  end

  # Test extract_generation_options
  def test_extract_generation_options_includes_xai_specific_options
    # Set up the generation_config that base_client expects
    @client.instance_variable_set(:@generation_config, {temperature: 0.7, max_tokens: 4096})

    options = {
      temperature: 0.8,
      frequency_penalty: 0.5,
      presence_penalty: 0.3
    }

    result = @client.send(:extract_generation_options, options)

    assert_equal 0.8, result[:temperature]
    assert_equal 0.5, result[:frequency_penalty]
    assert_equal 0.3, result[:presence_penalty]
  end

  def test_extract_generation_options_compacts_nil_values
    @client.instance_variable_set(:@generation_config, {temperature: 0.7, max_tokens: 4096})

    options = {
      temperature: 0.8,
      frequency_penalty: nil,
      presence_penalty: nil
    }

    result = @client.send(:extract_generation_options, options)

    refute result.key?(:frequency_penalty)
    refute result.key?(:presence_penalty)
  end

  # Test make_api_request error handling
  def test_make_api_request_raises_on_api_error
    # Create a mock failed response
    failed_response = Minitest::Mock.new
    failed_response.expect :success?, false
    failed_response.expect :status, 401
    failed_response.expect :body, {"error" => {"type" => "invalid_request", "message" => "Invalid API key"}}

    # Create mock http_client with block expectation to handle keyword args
    http_client_mock = Object.new
    http_client_mock.define_singleton_method(:post) do |_url, _body, **_kwargs|
      failed_response
    end

    @client.instance_variable_set(:@http_client, http_client_mock)
    @client.instance_variable_set(:@base_url, "https://api.x.ai")
    @client.instance_variable_set(:@api_key, "test-key")

    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:make_api_request, {model: "grok-3", messages: []})
    end

    assert_match(/x.ai API error \(401\)/, error.message)
    assert_match(/invalid_request/, error.message)
    assert_match(/Invalid API key/, error.message)

    failed_response.verify
  end

  def test_make_api_request_handles_malformed_error_body
    # Response with empty Hash body (missing error structure)
    failed_response = create_failed_response_mock(status: 500, body: {})
    setup_client_with_mock_response(failed_response)

    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:make_api_request, {model: "grok-3", messages: []})
    end

    assert_match(/x.ai API error \(500\)/, error.message)
    assert_match(/unknown - Unknown error: 500/, error.message)
  end

  def test_handles_non_json_error_response
    # Response with String body (e.g., HTML error page from 502 gateway error)
    failed_response = create_failed_response_mock(
      status: 502,
      body: "<html><body>Bad Gateway</body></html>"
    )
    setup_client_with_mock_response(failed_response)

    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:make_api_request, {model: "grok-3", messages: []})
    end

    assert_match(/x.ai API error \(502\)/, error.message)
    assert_match(/Non-JSON response: <html><body>Bad Gateway<\/body><\/html>/, error.message)

    failed_response.verify
  end

  def test_handles_empty_string_error_response
    # Response with empty String body (edge case)
    failed_response = create_failed_response_mock(status: 502, body: "")
    setup_client_with_mock_response(failed_response)

    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:make_api_request, {model: "grok-3", messages: []})
    end

    assert_match(/x.ai API error \(502\)/, error.message)
    assert_match(/Unknown error: 502/, error.message)

    failed_response.verify
  end
end
