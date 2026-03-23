# frozen_string_literal: true

require "test_helper"
require "ace/llm/atoms/error_classifier"

module Ace
  module LLM
    module Atoms
      class ErrorClassifierTest < AceLlmTestCase
        def test_classify_authentication_error
          error = Ace::LLM::AuthenticationError.new("Invalid API key")
          assert_equal ErrorClassifier::SKIP_TO_NEXT, ErrorClassifier.classify(error)
        end

        def test_classify_timeout_error
          error = Faraday::TimeoutError.new("Request timeout")
          assert_equal ErrorClassifier::FALLBACK_IMMEDIATELY, ErrorClassifier.classify(error)
        end

        def test_classify_connection_failed
          error = Faraday::ConnectionFailed.new("Connection failed")
          assert_equal ErrorClassifier::RETRYABLE_WITH_BACKOFF, ErrorClassifier.classify(error)
        end

        def test_classify_503_error
          error = mock_faraday_error(status: 503)
          assert_equal ErrorClassifier::RETRYABLE_WITH_BACKOFF, ErrorClassifier.classify(error)
        end

        def test_classify_429_error
          error = mock_faraday_error(status: 429)
          assert_equal ErrorClassifier::RETRYABLE_WITH_BACKOFF, ErrorClassifier.classify(error)
        end

        def test_classify_401_error
          error = mock_faraday_error(status: 401)
          assert_equal ErrorClassifier::SKIP_TO_NEXT, ErrorClassifier.classify(error)
        end

        def test_classify_403_error
          error = mock_faraday_error(status: 403)
          assert_equal ErrorClassifier::SKIP_TO_NEXT, ErrorClassifier.classify(error)
        end

        def test_classify_404_error
          error = mock_faraday_error(status: 404)
          assert_equal ErrorClassifier::SKIP_TO_NEXT, ErrorClassifier.classify(error)
        end

        def test_classify_500_error
          error = mock_faraday_error(status: 500)
          assert_equal ErrorClassifier::RETRYABLE_WITH_BACKOFF, ErrorClassifier.classify(error)
        end

        def test_classify_provider_error_with_status
          error = Ace::LLM::ProviderError.new("Provider error (503): Service unavailable")
          assert_equal ErrorClassifier::RETRYABLE_WITH_BACKOFF, ErrorClassifier.classify(error)
        end

        def test_classify_provider_error_timeout_message
          error = Ace::LLM::ProviderError.new("Request timeout for provider")
          assert_equal ErrorClassifier::FALLBACK_IMMEDIATELY, ErrorClassifier.classify(error)
        end

        def test_classify_provider_error_rate_limit_message
          error = Ace::LLM::ProviderError.new("Rate limit exceeded")
          assert_equal ErrorClassifier::RETRYABLE_WITH_BACKOFF, ErrorClassifier.classify(error)
        end

        def test_classify_provider_error_quota_message_as_immediate_fallback
          error = Ace::LLM::ProviderError.new("insufficient_quota: You exceeded your current quota")
          assert_equal ErrorClassifier::FALLBACK_IMMEDIATELY, ErrorClassifier.classify(error)
        end

        def test_classify_provider_error_credit_message_as_immediate_fallback
          error = Ace::LLM::ProviderError.new("Out of credits for this billing period")
          assert_equal ErrorClassifier::FALLBACK_IMMEDIATELY, ErrorClassifier.classify(error)
        end

        def test_classify_provider_error_unavailable_message
          error = Ace::LLM::ProviderError.new("Service unavailable")
          assert_equal ErrorClassifier::RETRYABLE_WITH_BACKOFF, ErrorClassifier.classify(error)
        end

        def test_classify_unknown_error
          error = StandardError.new("Unknown error")
          assert_equal ErrorClassifier::TERMINAL, ErrorClassifier.classify(error)
        end

        def test_retryable_true_for_503
          error = mock_faraday_error(status: 503)
          assert ErrorClassifier.retryable?(error)
        end

        def test_retryable_false_for_401
          error = mock_faraday_error(status: 401)
          refute ErrorClassifier.retryable?(error)
        end

        def test_fallback_immediately_true_for_timeout
          error = Faraday::TimeoutError.new("Timeout")
          assert ErrorClassifier.fallback_immediately?(error)
        end

        def test_fallback_immediately_false_for_503
          error = mock_faraday_error(status: 503)
          refute ErrorClassifier.fallback_immediately?(error)
        end

        def test_quota_or_credit_limited_detects_quota_strings
          error = Ace::LLM::ProviderError.new("insufficient quota")
          assert ErrorClassifier.quota_or_credit_limited?(error)
        end

        def test_quota_or_credit_limited_false_for_generic_rate_limit
          error = Ace::LLM::ProviderError.new("rate limit exceeded")
          refute ErrorClassifier.quota_or_credit_limited?(error)
        end

        def test_skip_to_next_true_for_auth_error
          error = Ace::LLM::AuthenticationError.new("Invalid key")
          assert ErrorClassifier.skip_to_next?(error)
        end

        def test_skip_to_next_false_for_503
          error = mock_faraday_error(status: 503)
          refute ErrorClassifier.skip_to_next?(error)
        end

        def test_extract_status_code_from_faraday_error
          error = mock_faraday_error(status: 503)
          assert_equal 503, ErrorClassifier.extract_status_code(error)
        end

        def test_extract_status_code_from_provider_error
          error = Ace::LLM::ProviderError.new("Error (429): Rate limited")
          assert_equal 429, ErrorClassifier.extract_status_code(error)
        end

        def test_extract_status_code_returns_nil_when_not_available
          error = StandardError.new("Generic error")
          assert_nil ErrorClassifier.extract_status_code(error)
        end

        def test_retry_delay_exponential_backoff
          error = mock_faraday_error(status: 503)

          # Attempt 1: 1.0 * 2^0 * (1 + jitter) where jitter is 0.1-0.3
          # Expected range: 1.0 * 1.1 to 1.0 * 1.3 = 1.1 to 1.3
          delay1 = ErrorClassifier.retry_delay(error, attempt: 1, base_delay: 1.0)
          assert_operator delay1, :>=, 1.1
          assert_operator delay1, :<=, 1.3

          # Attempt 2: 2.0 * (1 + jitter) = 2.2 to 2.6
          delay2 = ErrorClassifier.retry_delay(error, attempt: 2, base_delay: 1.0)
          assert_operator delay2, :>=, 2.2
          assert_operator delay2, :<=, 2.6

          # Attempt 3: 4.0 * (1 + jitter) = 4.4 to 5.2
          delay3 = ErrorClassifier.retry_delay(error, attempt: 3, base_delay: 1.0)
          assert_operator delay3, :>=, 4.4
          assert_operator delay3, :<=, 5.2
        end

        def test_retry_delay_respects_retry_after_header_seconds
          error = mock_faraday_error(status: 429, headers: {"retry-after" => "5"})
          assert_equal 5.0, ErrorClassifier.retry_delay(error, attempt: 1, base_delay: 1.0)
        end

        def test_retry_delay_respects_retry_after_header_http_date
          future_time = Time.now + 10
          error = mock_faraday_error(
            status: 429,
            headers: {"retry-after" => future_time.httpdate}
          )
          delay = ErrorClassifier.retry_delay(error, attempt: 1, base_delay: 1.0)

          # Should be approximately 10 seconds (allow 1 second margin for test execution)
          assert_in_delta 10.0, delay, 1.0
        end

        def test_retry_delay_handles_invalid_retry_after
          error = mock_faraday_error(
            status: 429,
            headers: {"retry-after" => "invalid"}
          )
          # Should fallback to default 1.0 when parsing fails
          assert_equal 1.0, ErrorClassifier.retry_delay(error, attempt: 1, base_delay: 1.0)
        end

        def test_retry_delay_custom_base_delay
          error = mock_faraday_error(status: 503)

          # With base_delay 2.0: attempt 1 = 2.0 * 2^0 * (1 + jitter) = 2.2 to 2.6
          delay1 = ErrorClassifier.retry_delay(error, attempt: 1, base_delay: 2.0)
          assert_operator delay1, :>=, 2.2
          assert_operator delay1, :<=, 2.6

          # Attempt 2: 2.0 * 2^1 * (1 + jitter) = 4.4 to 5.2
          delay2 = ErrorClassifier.retry_delay(error, attempt: 2, base_delay: 2.0)
          assert_operator delay2, :>=, 4.4
          assert_operator delay2, :<=, 5.2
        end

        private

        # Create a mock Faraday::ClientError with response
        def mock_faraday_error(status:, headers: {})
          response = {
            status: status,
            headers: headers,
            body: {}
          }

          Faraday::ClientError.new("HTTP #{status}", response)
        end
      end
    end
  end
end
