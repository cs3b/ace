# frozen_string_literal: true

require "test_helper"

module Ace
  module Review
    module Atoms
      class RetryWithBackoffTest < Minitest::Test
        def setup
          @success_result = {success: true, stdout: "output"}
          @network_error = {success: false, stderr: "Network timeout occurred"}
          @connection_error = {success: false, stderr: "Connection refused"}
          @not_found_error = {success: false, stderr: "Could not resolve to a PullRequest"}
        end

        # Test: Successful execution on first attempt
        def test_execute_succeeds_on_first_try
          call_count = 0
          result = RetryWithBackoff.execute do
            call_count += 1
            @success_result
          end

          assert_equal @success_result, result
          assert_equal 1, call_count, "Should only attempt once on success"
        end

        # Test: Success after retries
        def test_execute_succeeds_after_retries
          call_count = 0

          RetryWithBackoff.stub :sleep, ->(_time) {} do
            result = RetryWithBackoff.execute do
              call_count += 1
              (call_count < 2) ? @network_error : @success_result
            end

            assert_equal @success_result, result
            assert_equal 2, call_count, "Should retry once before succeeding"
          end
        end

        # Test: Retry exhaustion raises error
        def test_execute_raises_error_after_max_retries
          call_count = 0

          RetryWithBackoff.stub :sleep, ->(_time) {} do
            error = assert_raises(Ace::Review::Errors::GhNetworkError) do
              RetryWithBackoff.execute(max_retries: 2) do
                call_count += 1
                @network_error
              end
            end

            assert_match(/Operation failed after 2 retries/, error.message)
            assert_match(/Network timeout/, error.message)
            assert_equal 2, call_count, "Should attempt max_retries times"
          end
        end

        # Test: Non-retryable error returns immediately
        def test_execute_returns_immediately_for_non_retryable_error
          call_count = 0
          result = RetryWithBackoff.execute do
            call_count += 1
            @not_found_error
          end

          assert_equal @not_found_error, result
          assert_equal 1, call_count, "Should not retry non-retryable errors"
        end

        # Test: Exponential backoff timing
        def test_execute_uses_exponential_backoff
          sleep_times = []
          call_count = 0

          # Stub sleep to capture backoff times
          RetryWithBackoff.stub :sleep, ->(time) { sleep_times << time } do
            RetryWithBackoff.execute(max_retries: 3, initial_backoff: 2, max_backoff: 10) do
              call_count += 1
              (call_count < 3) ? @network_error : @success_result
            end
          end

          # Backoff sequence: 2, 4 (succeeds on attempt 3)
          assert_equal [2, 4], sleep_times
          assert_equal 3, call_count
        end

        # Test: Max backoff cap
        def test_execute_caps_backoff_at_max_backoff
          sleep_times = []

          RetryWithBackoff.stub :sleep, ->(time) { sleep_times << time } do
            RetryWithBackoff.execute(max_retries: 4, initial_backoff: 10, max_backoff: 20) do
              (sleep_times.size < 3) ? @network_error : @success_result
            end
          end

          # Backoff sequence: 10, 20, 20 (capped at 20)
          assert_equal [10, 20, 20], sleep_times
        end

        # Test: Custom retryable check
        def test_execute_uses_custom_retryable_check
          custom_error = {success: false, stderr: "CUSTOM_RETRY_ME"}
          call_count = 0

          custom_check = lambda do |result|
            result[:stderr]&.include?("CUSTOM_RETRY_ME")
          end

          RetryWithBackoff.stub :sleep, ->(_time) {} do
            result = RetryWithBackoff.execute(
              max_retries: 2,
              retryable_check: custom_check
            ) do
              call_count += 1
              (call_count < 2) ? custom_error : @success_result
            end

            assert_equal @success_result, result
            assert_equal 2, call_count
          end
        end

        # Test: Custom error class
        def test_execute_raises_custom_error_class
          custom_error_class = Class.new(StandardError)

          RetryWithBackoff.stub :sleep, ->(_time) {} do
            error = assert_raises(custom_error_class) do
              RetryWithBackoff.execute(
                max_retries: 2,
                error_class: custom_error_class
              ) do
                @network_error
              end
            end

            assert_match(/Operation failed after 2 retries/, error.message)
          end
        end

        # Test: Default retryable check for timeout errors
        def test_default_retryable_check_detects_timeout
          timeout_error = {success: false, stderr: "Request timeout"}
          assert RetryWithBackoff.default_retryable_check(timeout_error)
        end

        # Test: Default retryable check for connection errors
        def test_default_retryable_check_detects_connection_errors
          connection_error = {success: false, stderr: "Connection failed"}
          assert RetryWithBackoff.default_retryable_check(connection_error)
        end

        # Test: Default retryable check for network errors
        def test_default_retryable_check_detects_network_errors
          network_error = {success: false, stderr: "Network error occurred"}
          assert RetryWithBackoff.default_retryable_check(network_error)
        end

        # Test: Default retryable check for temporary failures
        def test_default_retryable_check_detects_temporary_failures
          temp_error = {success: false, stderr: "Temporary failure in name resolution"}
          assert RetryWithBackoff.default_retryable_check(temp_error)
        end

        # Test: Default retryable check rejects non-retryable errors
        def test_default_retryable_check_rejects_non_retryable_errors
          not_found = {success: false, stderr: "Could not resolve to a PullRequest"}
          refute RetryWithBackoff.default_retryable_check(not_found)
        end

        # Test: Default retryable check handles :error key
        def test_default_retryable_check_handles_error_key
          error_with_error_key = {success: false, error: "Network timeout"}
          assert RetryWithBackoff.default_retryable_check(error_with_error_key)
        end

        # Test: Default retryable check handles missing error message
        def test_default_retryable_check_handles_missing_error
          no_error_msg = {success: false}
          refute RetryWithBackoff.default_retryable_check(no_error_msg)
        end

        # Test: Zero retries configuration
        def test_execute_with_zero_retries
          call_count = 0

          # With max_retries: 0, it should attempt once and raise immediately
          # without any retries (the initial attempt is made, then error is raised)
          error = assert_raises(Ace::Review::Errors::GhNetworkError) do
            RetryWithBackoff.execute(max_retries: 0) do
              call_count += 1
              @network_error
            end
          end

          assert_equal 1, call_count, "Should attempt once with max_retries: 0"
          assert_match(/Operation failed after 0 retries/, error.message)
        end

        # Test: Custom backoff values
        def test_execute_with_custom_backoff_values
          sleep_times = []

          RetryWithBackoff.stub :sleep, ->(time) { sleep_times << time } do
            RetryWithBackoff.execute(
              max_retries: 3,
              initial_backoff: 5,
              max_backoff: 15
            ) do
              (sleep_times.size < 2) ? @network_error : @success_result
            end
          end

          # Backoff: 5, 10, then success
          assert_equal [5, 10], sleep_times
        end
      end
    end
  end
end
