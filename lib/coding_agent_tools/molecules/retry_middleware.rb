# frozen_string_literal: true

require 'faraday'

module CodingAgentTools
  module Molecules
    # RetryMiddleware provides configurable retry logic with exponential back-off
    # This is a molecule - it composes retry logic for HTTP operations
    class RetryMiddleware
      # Default retry configuration
      DEFAULT_CONFIG = {
        max_attempts: 3,
        base_delay: 1.0,
        max_delay: 60.0,
        jitter: true,
        retryable_status_codes: [429, 500, 502, 503, 504],
        retryable_exceptions: [
          Faraday::TimeoutError,
          Faraday::ConnectionFailed,
          Faraday::SSLError
        ]
      }.freeze

      # @param config [Hash] Retry configuration
      # @option config [Integer] :max_attempts (3) Maximum number of retry attempts
      # @option config [Float] :base_delay (1.0) Base delay in seconds for exponential back-off
      # @option config [Float] :max_delay (60.0) Maximum delay in seconds
      # @option config [Boolean] :jitter (true) Whether to add jitter to prevent thundering herd
      # @option config [Array<Integer>] :retryable_status_codes HTTP status codes to retry
      # @option config [Array<Class>] :retryable_exceptions Exception classes to retry
      def initialize(config = {})
        @config = DEFAULT_CONFIG.merge(config)
        @max_attempts = @config[:max_attempts]
        @base_delay = @config[:base_delay]
        @max_delay = @config[:max_delay]
        @jitter = @config[:jitter]
        @retryable_status_codes = @config[:retryable_status_codes]
        @retryable_exceptions = @config[:retryable_exceptions]

        # Register events with the notifications system
        register_events
      end

      # Execute a block with retry logic
      # @param operation_name [String] Name of the operation for logging
      # @yield Block to execute with retry logic
      # @return [Object] Result of the block execution
      # @raise [StandardError] The last error if all retries are exhausted
      def execute(operation_name: 'HTTP request')
        attempt = 1

        begin
          log_attempt(operation_name, attempt)
          result = yield

          # Check if the result indicates a retryable failure
          raise RetryableError.new("Retryable response: #{result.status}", result) if retryable_response?(result)

          log_success(operation_name, attempt) if attempt > 1
          result
        rescue => e
          if should_retry?(e, attempt)
            delay = calculate_delay(attempt)
            log_retry(operation_name, attempt, e, delay)
            sleep(delay)
            attempt += 1
            retry
          else
            log_failure(operation_name, attempt, e)
            raise e
          end
        end
      end

      private

      # Register events with the notifications system to allow early subscription
      def register_events
        notifications = CodingAgentTools::Notifications.notifications

        # Guard against duplicate event registration across multiple instances
        begin
          notifications.register_event('retry_middleware.attempt.coding_agent_tools')
          notifications.register_event('retry_middleware.success.coding_agent_tools')
          notifications.register_event('retry_middleware.retry.coding_agent_tools')
          notifications.register_event('retry_middleware.failure.coding_agent_tools')
        rescue
          # Silently ignore registration errors for already registered events
        end
      end

      # Check if an error should trigger a retry
      # @param error [StandardError] The error that occurred
      # @param attempt [Integer] Current attempt number
      # @return [Boolean] Whether to retry
      def should_retry?(error, attempt)
        return false if attempt >= @max_attempts

        # Check for retryable exceptions
        return true if @retryable_exceptions.any? { |exception_class| error.is_a?(exception_class) }

        # Check for RetryableError (which wraps retryable responses)
        return true if error.is_a?(RetryableError)

        false
      end

      # Check if a response indicates a retryable failure
      # @param response [Object] The response object
      # @return [Boolean] Whether the response is retryable
      def retryable_response?(response)
        return false unless response.respond_to?(:status)

        @retryable_status_codes.include?(response.status)
      end

      # Calculate delay for exponential back-off with optional jitter
      # @param attempt [Integer] Current attempt number (1-based)
      # @return [Float] Delay in seconds
      def calculate_delay(attempt)
        # Exponential back-off: base_delay * 2^(attempt-1)
        delay = @base_delay * (2**(attempt - 1))
        delay = [@max_delay, delay].min

        if @jitter
          # Add jitter (±25% random variation)
          jitter_factor = 0.75 + (rand * 0.5) # 0.75 to 1.25
          delay *= jitter_factor
        end

        delay
      end

      # Log attempt information
      # @param operation_name [String] Name of the operation
      # @param attempt [Integer] Attempt number
      def log_attempt(operation_name, attempt)
        return unless attempt == 1

        CodingAgentTools::Notifications.publish(
          'retry_middleware.attempt.coding_agent_tools',
          operation: operation_name,
          attempt: attempt,
          message: "Starting #{operation_name}"
        )
      end

      # Log successful completion after retries
      # @param operation_name [String] Name of the operation
      # @param final_attempt [Integer] Final successful attempt number
      def log_success(operation_name, final_attempt)
        CodingAgentTools::Notifications.publish(
          'retry_middleware.success.coding_agent_tools',
          operation: operation_name,
          attempts: final_attempt,
          message: "#{operation_name} succeeded after #{final_attempt} attempts"
        )
      end

      # Log retry information
      # @param operation_name [String] Name of the operation
      # @param attempt [Integer] Current attempt number
      # @param error [StandardError] The error that triggered the retry
      # @param delay [Float] Delay before next attempt
      def log_retry(operation_name, attempt, error, delay)
        CodingAgentTools::Notifications.publish(
          'retry_middleware.retry.coding_agent_tools',
          operation: operation_name,
          attempt: attempt,
          max_attempts: @max_attempts,
          error: error.class.name,
          error_message: error.message,
          delay: delay,
          message: "#{operation_name} failed (attempt #{attempt}/#{@max_attempts}), retrying in #{delay.round(2)}s: #{error.message}"
        )
      end

      # Log final failure after all retries exhausted
      # @param operation_name [String] Name of the operation
      # @param final_attempt [Integer] Final failed attempt number
      # @param error [StandardError] The final error
      def log_failure(operation_name, final_attempt, error)
        CodingAgentTools::Notifications.publish(
          'retry_middleware.failure.coding_agent_tools',
          operation: operation_name,
          attempts: final_attempt,
          error: error.class.name,
          error_message: error.message,
          message: "#{operation_name} failed permanently after #{final_attempt} attempts: #{error.message}"
        )
      end

      # Custom error class for retryable responses
      class RetryableError < StandardError
        attr_reader :response

        def initialize(message, response = nil)
          super(message)
          @response = response
        end
      end
    end
  end
end
