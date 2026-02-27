# frozen_string_literal: true

module Ace
  module LLM
    module Atoms
      # ErrorClassifier categorizes errors to determine retry and fallback strategies
      # This is an atom - it has no dependencies on other parts of this gem
      class ErrorClassifier
        # Error classification types
        RETRYABLE_WITH_BACKOFF = :retryable_with_backoff
        FALLBACK_IMMEDIATELY = :fallback_immediately
        SKIP_TO_NEXT = :skip_to_next
        TERMINAL = :terminal

        # Map HTTP status codes to classification
        STATUS_CLASSIFICATIONS = {
          401 => SKIP_TO_NEXT,      # Unauthorized - skip to next provider
          403 => SKIP_TO_NEXT,      # Forbidden - skip to next provider
          404 => SKIP_TO_NEXT,      # Not Found - skip to next provider
          429 => RETRYABLE_WITH_BACKOFF, # Rate Limited - retry with backoff
          500 => RETRYABLE_WITH_BACKOFF, # Internal Server Error - retry
          502 => RETRYABLE_WITH_BACKOFF, # Bad Gateway - retry
          503 => RETRYABLE_WITH_BACKOFF, # Service Unavailable - retry
          504 => RETRYABLE_WITH_BACKOFF  # Gateway Timeout - retry
        }.freeze

        QUOTA_LIMIT_PATTERNS = [
          "insufficient_quota",
          "insufficient quota",
          "quota exceeded",
          "quota has been exceeded",
          "quota limit",
          "quota exhausted",
          "out of credit",
          "credits exhausted",
          "insufficient credit",
          "billing hard limit",
          "spending limit",
          "usage limit reached",
          "rate window limit",
          "window limit reached"
        ].freeze

        # Classify an error for retry/fallback decisions
        # @param error [Exception] The error to classify
        # @return [Symbol] Classification type (RETRYABLE_WITH_BACKOFF, FALLBACK_IMMEDIATELY, SKIP_TO_NEXT, TERMINAL)
        def self.classify(error)
          case error
          when Ace::LLM::AuthenticationError
            SKIP_TO_NEXT
          when Ace::LLM::ProviderError
            # Check if we can extract HTTP status from the error message
            classify_provider_error(error)
          when Faraday::TimeoutError
            FALLBACK_IMMEDIATELY
          when Faraday::ConnectionFailed
            RETRYABLE_WITH_BACKOFF
          when Faraday::ClientError
            classify_faraday_error(error)
          when Faraday::ServerError
            RETRYABLE_WITH_BACKOFF
          else
            TERMINAL
          end
        end

        # Determine if an error is retryable
        # @param error [Exception] The error to check
        # @return [Boolean] True if error should be retried
        def self.retryable?(error)
          classification = classify(error)
          classification == RETRYABLE_WITH_BACKOFF
        end

        # Determine if an error should trigger immediate fallback
        # @param error [Exception] The error to check
        # @return [Boolean] True if should fallback immediately
        def self.fallback_immediately?(error)
          classification = classify(error)
          classification == FALLBACK_IMMEDIATELY
        end

        # Determine if an error should skip to next provider without retry
        # @param error [Exception] The error to check
        # @return [Boolean] True if should skip to next provider
        def self.skip_to_next?(error)
          classification = classify(error)
          classification == SKIP_TO_NEXT
        end

        # Determine if an error indicates quota/credit/window exhaustion
        # and should move immediately to the next provider.
        # @param error [Exception] The error to check
        # @return [Boolean] True if this is a quota/credit/window-limit condition
        def self.quota_or_credit_limited?(error)
          quota_like_message?(error.message.to_s)
        end

        # Extract HTTP status code from various error types
        # @param error [Exception] The error
        # @return [Integer, nil] HTTP status code if available
        def self.extract_status_code(error)
          if error.respond_to?(:response) && error.response
            error.response[:status]
          elsif error.respond_to?(:http_status)
            error.http_status
          elsif error.is_a?(Ace::LLM::ProviderError)
            # Try to parse status from error message like "error (503):"
            match = error.message.match(/\((\d{3})\)/)
            match[1].to_i if match
          end
        end

        # Get retry delay for an error based on retry-after header or default
        # @param error [Exception] The error
        # @param attempt [Integer] Current retry attempt number
        # @param base_delay [Float] Base delay in seconds
        # @return [Float] Delay in seconds with jitter
        def self.retry_delay(error, attempt: 1, base_delay: 1.0)
          # Check for retry-after header (for 429 rate limits)
          if error.respond_to?(:response) && error.response
            headers = error.response[:headers]
            if headers && headers["retry-after"]
              return parse_retry_after(headers["retry-after"])
            end
          end

          # Exponential backoff with jitter: base_delay * 2^(attempt - 1) * (1 + jitter)
          # Jitter is 10-30% to prevent thundering herd
          exponential_delay = base_delay * (2 ** (attempt - 1))
          jitter = rand(0.1..0.3)
          exponential_delay * (1 + jitter)
        end

        # Classify a Faraday::ClientError based on status code
        # @param error [Faraday::ClientError] The error
        # @return [Symbol] Classification type
        def self.classify_faraday_error(error)
          status = extract_status_code(error)
          if status == 429 && quota_like_message?(error.message.to_s)
            return FALLBACK_IMMEDIATELY
          end

          STATUS_CLASSIFICATIONS.fetch(status, TERMINAL)
        end
        private_class_method :classify_faraday_error

        # Classify a ProviderError based on its message/attributes
        # @param error [Ace::LLM::ProviderError] The error
        # @return [Symbol] Classification type
        def self.classify_provider_error(error)
          message = error.message.downcase
          return FALLBACK_IMMEDIATELY if quota_like_message?(message)

          status = extract_status_code(error)
          return STATUS_CLASSIFICATIONS.fetch(status, TERMINAL) if status

          # Check error message patterns
          if message.include?("timeout")
            FALLBACK_IMMEDIATELY
          elsif message.include?("rate limit")
            RETRYABLE_WITH_BACKOFF
          elsif message.include?("connection failed")
            RETRYABLE_WITH_BACKOFF
          elsif message.include?("unavailable") || message.include?("overloaded")
            RETRYABLE_WITH_BACKOFF
          else
            TERMINAL
          end
        end
        private_class_method :classify_provider_error

        def self.quota_like_message?(message)
          normalized = message.to_s.downcase
          QUOTA_LIMIT_PATTERNS.any? { |pattern| normalized.include?(pattern) }
        end
        private_class_method :quota_like_message?

        # Parse retry-after header value
        # @param value [String] Header value (seconds or HTTP date)
        # @return [Float] Delay in seconds
        def self.parse_retry_after(value)
          # Try to parse as integer (seconds)
          Integer(value).to_f
        rescue ArgumentError
          # Try to parse as HTTP date
          begin
            retry_time = Time.httpdate(value)
            delay = retry_time - Time.now
            [delay, 0].max # Don't return negative delays
          rescue ArgumentError
            # Default fallback if parsing fails
            1.0
          end
        end
        private_class_method :parse_retry_after
      end
    end
  end
end
