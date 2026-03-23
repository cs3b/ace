# frozen_string_literal: true

require_relative "../test_helper"

class GroqClientTest < AceTestCase
  def setup
    @mock_http_client = Ace::TestSupport::Fixtures::HTTPMocks::MockHTTPClient.new
  end

  # ============================================================
  # Constants and Provider Name Tests
  # ============================================================

  def test_provider_name
    assert_equal "groq", Ace::LLM::Organisms::GroqClient.provider_name
  end

  def test_api_base_url
    assert_equal "https://api.groq.com/openai/v1", Ace::LLM::Organisms::GroqClient::API_BASE_URL
  end

  def test_default_model
    assert_equal "openai/gpt-oss-120b", Ace::LLM::Organisms::GroqClient::DEFAULT_MODEL
  end

  # ============================================================
  # Initialization Tests (using EnvReader stub)
  # ============================================================

  def test_initialization_with_api_key
    Ace::LLM::Atoms::EnvReader.stub :get_api_key, "test-api-key" do
      client = Ace::LLM::Organisms::GroqClient.new(
        model: "openai/gpt-oss-120b"
      )

      assert_instance_of Ace::LLM::Organisms::GroqClient, client
    end
  end

  def test_initialization_with_explicit_api_key
    Ace::LLM::Atoms::EnvReader.stub :get_api_key, nil do
      client = Ace::LLM::Organisms::GroqClient.new(
        model: "openai/gpt-oss-120b",
        api_key: "explicit-key"
      )

      assert_instance_of Ace::LLM::Organisms::GroqClient, client
      assert_equal "explicit-key", client.api_key
    end
  end

  def test_initialization_raises_without_api_key
    Ace::LLM::Atoms::EnvReader.stub :get_api_key, nil do
      error = assert_raises(Ace::LLM::AuthenticationError) do
        Ace::LLM::Organisms::GroqClient.new(model: "openai/gpt-oss-120b")
      end

      assert_match(/No API key found for groq/, error.message)
    end
  end

  def test_initialization_uses_default_model
    Ace::LLM::Atoms::EnvReader.stub :get_api_key, "test-key" do
      client = Ace::LLM::Organisms::GroqClient.new

      assert_equal "openai/gpt-oss-120b", client.model
    end
  end

  # ============================================================
  # Generate Method Tests (with mocked HTTP client)
  # ============================================================

  def test_generate_with_simple_prompt
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    result = client.generate("Hello, world!")

    assert_equal "Hello! How can I assist you today?", result[:text]
    assert_equal "groq", result[:metadata][:provider]
    assert_equal "openai/gpt-oss-120b", result[:metadata][:model]
  end

  def test_generate_with_messages_array
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    result = client.generate([
      {role: "system", content: "You are helpful."},
      {role: "user", content: "Hi there!"}
    ])

    assert_equal "Hello! How can I assist you today?", result[:text]
  end

  def test_generate_includes_token_usage_in_metadata
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    result = client.generate("Test prompt")

    assert_equal 10, result[:metadata][:input_tokens]
    assert_equal 20, result[:metadata][:output_tokens]
    assert_equal 30, result[:metadata][:total_tokens]
  end

  def test_generate_includes_finish_reason
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    result = client.generate("Test prompt")

    assert_equal "stop", result[:metadata][:finish_reason]
  end

  def test_generate_includes_model_used
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    result = client.generate("Test prompt")

    assert_equal "openai/gpt-oss-120b", result[:metadata][:model_used]
  end

  def test_generate_with_temperature_option
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test", temperature: 0.5)

    request_body = @mock_http_client.last_request[:body]
    assert_equal 0.5, request_body[:temperature]
  end

  def test_generate_with_max_tokens_option
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test", max_tokens: 1000)

    request_body = @mock_http_client.last_request[:body]
    assert_equal 1000, request_body[:max_tokens]
  end

  def test_generate_with_top_p_option
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test", top_p: 0.9)

    request_body = @mock_http_client.last_request[:body]
    assert_equal 0.9, request_body[:top_p]
  end

  def test_generate_with_frequency_penalty_option
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test", frequency_penalty: 0.5)

    request_body = @mock_http_client.last_request[:body]
    assert_equal 0.5, request_body[:frequency_penalty]
  end

  def test_generate_with_presence_penalty_option
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test", presence_penalty: 0.3)

    request_body = @mock_http_client.last_request[:body]
    assert_equal 0.3, request_body[:presence_penalty]
  end

  # ============================================================
  # Zero-Valued Options Tests (regression coverage for nil-check fix)
  # ============================================================

  def test_generate_with_zero_temperature
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test", temperature: 0)

    request_body = @mock_http_client.last_request[:body]
    assert_equal 0, request_body[:temperature]
  end

  def test_generate_with_zero_frequency_penalty
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test", frequency_penalty: 0.0)

    request_body = @mock_http_client.last_request[:body]
    assert_equal 0.0, request_body[:frequency_penalty]
  end

  def test_generate_with_zero_presence_penalty
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test", presence_penalty: 0.0)

    request_body = @mock_http_client.last_request[:body]
    assert_equal 0.0, request_body[:presence_penalty]
  end

  def test_generate_sets_stream_to_false
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test")

    request_body = @mock_http_client.last_request[:body]
    assert_equal false, request_body[:stream]
  end

  def test_generate_with_system_append
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate(
      [{role: "system", content: "Base system"}, {role: "user", content: "Hello"}],
      system_append: "Additional context"
    )

    request_body = @mock_http_client.last_request[:body]
    messages = request_body[:messages]

    # System message should be concatenated
    system_msg = messages.find { |m| m[:role] == "system" }
    assert_includes system_msg[:content], "Base system"
    assert_includes system_msg[:content], "Additional context"
  end

  # ============================================================
  # Error Handling Tests
  # ============================================================

  def test_generate_raises_provider_error_on_401
    @mock_http_client.set_error_response(401, "Invalid API Key")

    client = create_client_with_mock_http

    error = assert_raises(Ace::LLM::ProviderError) do
      client.generate("Test")
    end

    assert_match(/401/, error.message)
    assert_match(/Invalid API Key/, error.message)
  end

  def test_generate_raises_provider_error_on_500
    @mock_http_client.set_error_response(500, "Internal server error")

    client = create_client_with_mock_http

    error = assert_raises(Ace::LLM::ProviderError) do
      client.generate("Test")
    end

    assert_match(/500/, error.message)
  end

  def test_generate_raises_provider_error_on_missing_text
    @mock_http_client.set_response({
      "id" => "chatcmpl-test",
      "choices" => [{"message" => {"content" => nil}, "finish_reason" => "stop"}],
      "model" => "openai/gpt-oss-120b"
    })

    client = create_client_with_mock_http

    error = assert_raises(Ace::LLM::ProviderError) do
      client.generate("Test")
    end

    assert_match(/No text in response/, error.message)
  end

  def test_generate_raises_provider_error_on_empty_choices
    @mock_http_client.set_response({
      "id" => "chatcmpl-test",
      "choices" => [],
      "model" => "openai/gpt-oss-120b"
    })

    client = create_client_with_mock_http

    error = assert_raises(Ace::LLM::ProviderError) do
      client.generate("Test")
    end

    assert_match(/No text in response/, error.message)
  end

  # ============================================================
  # Defensive Tests for Optional Response Fields
  # ============================================================

  def test_generate_succeeds_without_usage_field
    response_without_usage = {
      "id" => "chatcmpl-test",
      "model" => "openai/gpt-oss-120b",
      "choices" => [
        {
          "message" => {"role" => "assistant", "content" => "Response without usage"},
          "finish_reason" => "stop"
        }
      ]
    }
    @mock_http_client.set_response(response_without_usage)

    client = create_client_with_mock_http

    result = client.generate("Test")

    assert_equal "Response without usage", result[:text]
    assert_nil result[:metadata][:input_tokens]
    assert_nil result[:metadata][:output_tokens]
    assert_nil result[:metadata][:total_tokens]
  end

  def test_generate_succeeds_without_model_field
    response_without_model = {
      "id" => "chatcmpl-test",
      "choices" => [
        {
          "message" => {"role" => "assistant", "content" => "Response without model"},
          "finish_reason" => "stop"
        }
      ],
      "usage" => {"prompt_tokens" => 5, "completion_tokens" => 10, "total_tokens" => 15}
    }
    @mock_http_client.set_response(response_without_model)

    client = create_client_with_mock_http

    result = client.generate("Test")

    assert_equal "Response without model", result[:text]
    assert_nil result[:metadata][:model_used]
    # Token usage should still work
    assert_equal 5, result[:metadata][:input_tokens]
  end

  def test_generate_with_stop_param
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test", stop: ["\n", "END"])

    request_body = @mock_http_client.last_request[:body]
    assert_equal ["\n", "END"], request_body[:stop]
  end

  # ============================================================
  # Request Building Tests
  # ============================================================

  def test_build_request_body_includes_model
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test")

    request_body = @mock_http_client.last_request[:body]
    assert_equal "openai/gpt-oss-120b", request_body[:model]
  end

  def test_build_request_body_includes_messages
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Hello")

    request_body = @mock_http_client.last_request[:body]
    assert_equal 1, request_body[:messages].length
    assert_equal "user", request_body[:messages][0][:role]
    assert_equal "Hello", request_body[:messages][0][:content]
  end

  def test_request_includes_authorization_header
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test")

    headers = @mock_http_client.last_request[:headers]
    assert_equal "Bearer test-api-key", headers["Authorization"]
  end

  def test_request_includes_content_type_header
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test")

    headers = @mock_http_client.last_request[:headers]
    assert_equal "application/json", headers["Content-Type"]
  end

  def test_request_url_is_correct
    @mock_http_client.set_response(success_response)

    client = create_client_with_mock_http

    client.generate("Test")

    assert_equal "https://api.groq.com/openai/v1/chat/completions", @mock_http_client.last_request[:url]
  end

  private

  # Create a client with mocked HTTP client and EnvReader
  def create_client_with_mock_http
    Ace::LLM::Atoms::EnvReader.stub :get_api_key, "test-api-key" do
      client = Ace::LLM::Organisms::GroqClient.new(model: "openai/gpt-oss-120b")
      # Replace the http_client with our mock
      client.instance_variable_set(:@http_client, @mock_http_client)
      return client
    end
  end

  # Sample success response matching Groq API format
  def success_response
    {
      "id" => "chatcmpl-test123",
      "object" => "chat.completion",
      "created" => 1_234_567_890,
      "model" => "openai/gpt-oss-120b",
      "choices" => [
        {
          "index" => 0,
          "message" => {
            "role" => "assistant",
            "content" => "Hello! How can I assist you today?"
          },
          "finish_reason" => "stop"
        }
      ],
      "usage" => {
        "prompt_tokens" => 10,
        "completion_tokens" => 20,
        "total_tokens" => 30
      }
    }
  end
end
