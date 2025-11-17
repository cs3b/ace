# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Pure function for retrying operations with exponential backoff
      #
      # This atom provides a reusable retry mechanism with exponential backoff
      # for operations that may experience transient failures (network issues,
      # timeouts, temporary unavailability).
      module RetryWithBackoff
        # Retry a block with exponential backoff
        #
        # @param options [Hash] Retry options
        # @option options [Integer] :max_retries Maximum retry attempts (default: 3)
        # @option options [Integer] :initial_backoff Initial backoff in seconds (default: 1)
        # @option options [Integer] :max_backoff Maximum backoff in seconds (default: 32)
        # @option options [Proc] :retryable_check Custom proc to check if error is retryable.
        #   Receives result hash, should return boolean. Defaults to network error check.
        # @option options [Class] :error_class Exception class to raise on retry exhaustion
        #   (default: Ace::Review::Errors::GhNetworkError)
        # @yield Block to retry - should return a hash with :success and :stderr keys
        # @return Result from successful execution
        # @raise [error_class] if all retries exhausted
        def self.execute(options = {})
          max_retries = options[:max_retries] || 3
          backoff = options[:initial_backoff] || 1
          max_backoff = options[:max_backoff] || 32
          retryable_check = options[:retryable_check] || method(:default_retryable_check)
          error_class = options[:error_class] || Ace::Review::Errors::GhNetworkError
          attempt = 0

          loop do
            result = yield

            # Success - return result
            return result if result[:success]

            # Check if error is retryable using provided check or default
            unless retryable_check.call(result)
              return result
            end

            # Increment attempt
            attempt += 1

            # Exhausted retries
            if attempt >= max_retries
              error_msg = result[:stderr] || result[:error] || "Unknown error"
              raise error_class, "Operation failed after #{max_retries} retries: #{error_msg}"
            end

            # Wait before retry with exponential backoff, capped at max_backoff
            sleep(backoff)
            backoff = [backoff * 2, max_backoff].min
          end
        end

        # Default check for retryable errors (network/timeout errors)
        #
        # @param result [Hash] Result from operation (should have :stderr or :error key)
        # @return [Boolean] true if error is retryable
        def self.default_retryable_check(result)
          error_msg = (result[:stderr] || result[:error]).to_s.downcase

          # Network-related errors are retryable
          error_msg.include?("timeout") ||
            error_msg.include?("connection") ||
            error_msg.include?("network") ||
            error_msg.include?("temporary failure")
        end
      end
    end
  end
end
