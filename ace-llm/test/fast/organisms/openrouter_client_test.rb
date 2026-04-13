# frozen_string_literal: true

require_relative "../../test_helper"

class OpenRouterClientTest < AceTestCase
  # Alias for shorter reference
  LLMResponses = Ace::TestSupport::Fixtures::HTTPMocks::LLMResponses

  def setup
    @api_key = "test_openrouter_key"
    @client = Ace::LLM::Organisms::OpenRouterClient.new(api_key: @api_key)
  end

  # Helper methods for creating mock responses
  private

  def create_successful_response(content: "Hello", finish_reason: "stop", id: "test-id", model: nil)
    mock = Minitest::Mock.new
    mock.expect :success?, true
    # Use shared fixture for base body structure
    body = LLMResponses.chat_completion(content: content, model: model || "test-model")
    body["id"] = id
    body["choices"][0]["finish_reason"] = finish_reason
    mock.expect :body, body
    mock
  end

  def create_error_response(status:, message: nil, type: nil)
    mock = Minitest::Mock.new
    mock.expect :success?, false
    mock.expect :status, status
    body = {}
    if message || type
      body["error"] = {}
      body["error"]["message"] = message if message
      body["error"]["type"] = type if type
    end
    mock.expect :body, body
    mock
  end

  public

  # Test initialization
  def test_initialize_with_default_model
    assert_equal "openai/gpt-oss-120b:nitro", @client.instance_variable_get(:@model)
  end

  def test_initialize_with_custom_model
    client = Ace::LLM::Organisms::OpenRouterClient.new(
      api_key: @api_key,
      model: "anthropic/claude-3.5-sonnet"
    )
    assert_equal "anthropic/claude-3.5-sonnet", client.instance_variable_get(:@model)
  end

  def test_initialize_with_default_base_url
    assert_equal "https://openrouter.ai/api/v1", @client.instance_variable_get(:@base_url)
  end

  def test_initialize_stores_attribution_headers
    client = Ace::LLM::Organisms::OpenRouterClient.new(
      api_key: @api_key,
      referer: "https://example.com",
      title: "My App"
    )
    assert_equal "https://example.com", client.instance_variable_get(:@referer)
    assert_equal "My App", client.instance_variable_get(:@title)
  end

  # Test provider_name
  def test_provider_name
    assert_equal "openrouter", Ace::LLM::Organisms::OpenRouterClient.provider_name
  end

  # Test build_request_body
  def test_build_request_body_basic
    messages = [{role: "user", content: "Hello"}]
    body = @client.send(:build_request_body, messages, {})

    assert_equal "openai/gpt-oss-120b:nitro", body[:model]
    assert_equal messages, body[:messages]
    assert_equal false, body[:stream]
  end

  def test_build_request_body_with_temperature
    messages = [{role: "user", content: "Hello"}]
    body = @client.send(:build_request_body, messages, {temperature: 0.5})

    assert_equal 0.5, body[:temperature]
  end

  def test_build_request_body_with_max_tokens
    messages = [{role: "user", content: "Hello"}]
    body = @client.send(:build_request_body, messages, {max_tokens: 1000})

    assert_equal 1000, body[:max_tokens]
  end

  def test_build_request_body_with_system_append
    messages = [{role: "user", content: "Hello"}]
    body = @client.send(:build_request_body, messages, {system_append: "Be helpful"})

    # Should add system message
    assert_equal 2, body[:messages].length
    assert_equal "system", body[:messages][0][:role]
    assert_equal "Be helpful", body[:messages][0][:content]
  end

  # Test make_api_request headers
  def test_make_api_request_includes_authorization_header
    mock_response = create_successful_response
    captured_headers = nil

    http_client = @client.instance_variable_get(:@http_client)
    http_client.stub :post, ->(url, body, headers:) {
      captured_headers = headers
      mock_response
    } do
      body = {model: "openai/gpt-4o", messages: []}
      @client.send(:make_api_request, body)
    end

    assert_equal "Bearer test_openrouter_key", captured_headers["Authorization"]
  end

  def test_make_api_request_adds_referer_when_provided
    client = Ace::LLM::Organisms::OpenRouterClient.new(
      api_key: @api_key,
      referer: "https://example.com"
    )

    mock_response = create_successful_response
    captured_headers = nil

    http_client = client.instance_variable_get(:@http_client)
    http_client.stub :post, ->(url, body, headers:) {
      captured_headers = headers
      mock_response
    } do
      body = {model: "openai/gpt-4o", messages: []}
      client.send(:make_api_request, body)
    end

    assert_equal "https://example.com", captured_headers["HTTP-Referer"]
  end

  def test_make_api_request_adds_title_when_provided
    client = Ace::LLM::Organisms::OpenRouterClient.new(
      api_key: @api_key,
      title: "My App"
    )

    mock_response = create_successful_response
    captured_headers = nil

    http_client = client.instance_variable_get(:@http_client)
    http_client.stub :post, ->(url, body, headers:) {
      captured_headers = headers
      mock_response
    } do
      body = {model: "openai/gpt-4o", messages: []}
      client.send(:make_api_request, body)
    end

    assert_equal "My App", captured_headers["X-Title"]
  end

  def test_make_api_request_does_not_add_headers_when_not_provided
    mock_response = create_successful_response
    captured_headers = nil

    http_client = @client.instance_variable_get(:@http_client)
    http_client.stub :post, ->(url, body, headers:) {
      captured_headers = headers
      mock_response
    } do
      body = {model: "openai/gpt-4o", messages: []}
      @client.send(:make_api_request, body)
    end

    refute captured_headers.key?("HTTP-Referer")
    refute captured_headers.key?("X-Title")
  end

  # Test parse_response
  def test_parse_response_extracts_text
    response = {
      "choices" => [
        {
          "message" => {"content" => "Hello, world!"},
          "finish_reason" => "stop"
        }
      ],
      "id" => "test-123",
      "created" => 1234567890
    }

    result = @client.send(:parse_response, response)
    assert_equal "Hello, world!", result[:text]
  end

  def test_parse_response_extracts_metadata
    response = {
      "choices" => [
        {
          "message" => {"content" => "Hello"},
          "finish_reason" => "stop"
        }
      ],
      "id" => "test-123",
      "created" => 1234567890,
      "model" => "openai/gpt-4o"
    }

    result = @client.send(:parse_response, response)
    assert_equal "stop", result[:metadata][:finish_reason]
    assert_equal "test-123", result[:metadata][:id]
    assert_equal 1234567890, result[:metadata][:created]
    assert_equal "openai/gpt-4o", result[:metadata][:model_used]
  end

  def test_parse_response_extracts_token_usage
    response = {
      "choices" => [
        {
          "message" => {"content" => "Hello"},
          "finish_reason" => "stop"
        }
      ],
      "id" => "test-123",
      "usage" => {
        "prompt_tokens" => 10,
        "completion_tokens" => 20,
        "total_tokens" => 30
      }
    }

    result = @client.send(:parse_response, response)
    assert_equal 10, result[:metadata][:input_tokens]
    assert_equal 20, result[:metadata][:output_tokens]
    assert_equal 30, result[:metadata][:total_tokens]
  end

  def test_parse_response_preserves_native_finish_reason
    response = {
      "choices" => [
        {
          "message" => {"content" => "Hello"},
          "finish_reason" => "stop",
          "native_finish_reason" => "end_turn"
        }
      ],
      "id" => "test-123"
    }

    result = @client.send(:parse_response, response)
    assert_equal "stop", result[:metadata][:finish_reason]
    assert_equal "end_turn", result[:metadata][:native_finish_reason]
  end

  def test_parse_response_raises_on_missing_text
    response = {
      "choices" => [],
      "id" => "test-123"
    }

    assert_raises(Ace::LLM::ProviderError) do
      @client.send(:parse_response, response)
    end
  end

  # Test error handling
  def test_make_api_request_handles_api_error
    mock_response = create_error_response(
      status: 401,
      message: "Invalid API key",
      type: "authentication_error"
    )

    http_client = @client.instance_variable_get(:@http_client)
    http_client.stub :post, mock_response do
      error = assert_raises(Ace::LLM::ProviderError) do
        @client.send(:make_api_request, {})
      end
      assert_match(/OpenRouter API error.*authentication_error.*Invalid API key/, error.message)
    end
  end

  def test_make_api_request_handles_error_without_body
    # Use Object with methods instead of Mock to avoid expectation limits
    mock_response = Object.new
    def mock_response.success?
      false
    end

    def mock_response.status
      500
    end

    def mock_response.body
      {}
    end

    http_client = @client.instance_variable_get(:@http_client)
    http_client.stub :post, mock_response do
      error = assert_raises(Ace::LLM::ProviderError) do
        @client.send(:make_api_request, {})
      end
      assert_match(/OpenRouter API error.*500.*unknown.*Unknown error: 500/, error.message)
    end
  end

  def test_make_api_request_handles_non_hash_body
    # Simulate 502 Bad Gateway returning HTML instead of JSON
    mock_response = Object.new
    def mock_response.success?
      false
    end

    def mock_response.status
      502
    end

    def mock_response.body
      "<html>502 Bad Gateway</html>"
    end

    http_client = @client.instance_variable_get(:@http_client)
    http_client.stub :post, mock_response do
      error = assert_raises(Ace::LLM::ProviderError) do
        @client.send(:make_api_request, {})
      end
      assert_match(/OpenRouter API error.*502.*unknown.*Non-JSON response: <html>502 Bad Gateway<\/html>/, error.message)
    end
  end

  def test_make_api_request_handles_body_raising_exception
    # Simulate body accessor raising an exception
    mock_response = Object.new
    def mock_response.success?
      false
    end

    def mock_response.status
      500
    end

    def mock_response.body
      raise "Connection reset"
    end

    http_client = @client.instance_variable_get(:@http_client)
    http_client.stub :post, mock_response do
      error = assert_raises(Ace::LLM::ProviderError) do
        @client.send(:make_api_request, {})
      end
      assert_match(/OpenRouter API error.*500.*unknown.*Unknown error: 500/, error.message)
    end
  end

  # Test public generate method (integration-style tests)
  def test_generate_with_string_prompt
    mock_response = create_successful_response(content: "Hello, world!", model: "openai/gpt-4o")

    http_client = @client.instance_variable_get(:@http_client)
    http_client.stub :post, mock_response do
      result = @client.generate("Hello")
      assert_equal "Hello, world!", result[:text]
    end
  end

  def test_generate_with_messages_array
    mock_response = create_successful_response(content: "I'm doing well!", model: "openai/gpt-4o")

    http_client = @client.instance_variable_get(:@http_client)
    http_client.stub :post, mock_response do
      result = @client.generate([{role: "user", content: "How are you?"}])
      assert_equal "I'm doing well!", result[:text]
    end
  end

  def test_generate_with_temperature_zero
    mock_response = create_successful_response(content: "Deterministic output")
    captured_body = nil

    http_client = @client.instance_variable_get(:@http_client)
    http_client.stub :post, ->(url, body, headers:) {
      captured_body = body
      mock_response
    } do
      @client.generate("Test", temperature: 0)
    end

    assert_equal 0, captured_body[:temperature]
  end

  def test_generate_with_frequency_penalty_zero
    mock_response = create_successful_response(content: "Deterministic output")
    captured_body = nil

    http_client = @client.instance_variable_get(:@http_client)
    http_client.stub :post, ->(url, body, headers:) {
      captured_body = body
      mock_response
    } do
      @client.generate("Test", frequency_penalty: 0)
    end

    assert_equal 0, captured_body[:frequency_penalty]
  end

  def test_generate_with_presence_penalty_zero
    mock_response = create_successful_response(content: "Deterministic output")
    captured_body = nil

    http_client = @client.instance_variable_get(:@http_client)
    http_client.stub :post, ->(url, body, headers:) {
      captured_body = body
      mock_response
    } do
      @client.generate("Test", presence_penalty: 0)
    end

    assert_equal 0, captured_body[:presence_penalty]
  end

  def test_generate_wraps_errors_as_provider_error
    http_client = @client.instance_variable_get(:@http_client)
    http_client.stub :post, ->(*) { raise "Network error" } do
      error = assert_raises(Ace::LLM::ProviderError) do
        @client.generate("Test")
      end
      assert_match(/Network error/, error.message)
    end
  end
end
