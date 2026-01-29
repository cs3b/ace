# frozen_string_literal: true

require "test_helper"
require "tempfile"

# Tests for MultiModelExecutor thread timeout handling
class MultiModelExecutorTimeoutTest < AceReviewTest
  # Original grace period for restoration
  ORIGINAL_GRACE_PERIOD = Ace::Review::Molecules::MultiModelExecutor::JOIN_GRACE_PERIOD

  def setup
    @tmpdir = Dir.mktmpdir
    # Use very short timeouts for fast tests
    @executor = Ace::Review::Molecules::MultiModelExecutor.new(
      max_concurrent: 2,
      llm_timeout: 1  # 1 second timeout
    )
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
    # Ensure grace period is restored even if test fails
    restore_grace_period
  end

  # Temporarily set a short grace period for fast Thread.kill path tests
  # @param seconds [Integer] grace period in seconds (default: 1)
  # @yield block to execute with short grace period
  def with_short_grace_period(seconds = 1)
    set_grace_period(seconds)
    yield
  ensure
    restore_grace_period
  end

  def set_grace_period(seconds)
    silence_warnings do
      Ace::Review::Molecules::MultiModelExecutor.send(:remove_const, :JOIN_GRACE_PERIOD)
      Ace::Review::Molecules::MultiModelExecutor.const_set(:JOIN_GRACE_PERIOD, seconds)
    end
  end

  def restore_grace_period
    silence_warnings do
      Ace::Review::Molecules::MultiModelExecutor.send(:remove_const, :JOIN_GRACE_PERIOD)
      Ace::Review::Molecules::MultiModelExecutor.const_set(:JOIN_GRACE_PERIOD, ORIGINAL_GRACE_PERIOD)
    end
  end

  def silence_warnings
    old_verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = old_verbose
  end

  # Test that thread join timeout is correctly calculated
  def test_join_timeout_includes_grace_period
    grace_period = Ace::Review::Molecules::MultiModelExecutor::JOIN_GRACE_PERIOD
    assert_equal 30, grace_period
  end

  # Test that threads report_on_exception is disabled
  def test_threads_have_report_on_exception_disabled
    executor = Ace::Review::Molecules::MultiModelExecutor.new(max_concurrent: 1, llm_timeout: 1)

    thread_report_on_exception = nil

    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      # Capture the thread's report_on_exception setting
      thread_report_on_exception = Thread.current.report_on_exception
      File.write(args[:output_file], "test")
      { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
    } do
      executor.execute(
        models: ["test-model"],
        system_prompt: "system",
        user_prompt: "user",
        session_dir: @tmpdir
      )
    end

    assert_equal false, thread_report_on_exception, "Thread should have report_on_exception disabled"
  end

  # Test that thread has model stored for warning display
  def test_threads_store_model_identifier
    executor = Ace::Review::Molecules::MultiModelExecutor.new(max_concurrent: 1, llm_timeout: 1)

    captured_model = nil

    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      # Capture the thread's model identifier
      captured_model = Thread.current[:model]
      File.write(args[:output_file], "test")
      { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
    } do
      executor.execute(
        models: ["google:gemini-flash"],
        system_prompt: "system",
        user_prompt: "user",
        session_dir: @tmpdir
      )
    end

    assert_equal "google:gemini-flash", captured_model, "Thread should store model identifier"
  end

  # Test that batch completes within bounded time with slow thread
  # NOTE: This test verifies the Timeout.timeout within execute_single_model works.
  # The thread join timeout is a fallback for when Timeout.timeout cannot interrupt
  # the thread (e.g., CLI provider stuck in system call that doesn't release GVL).
  def test_batch_completes_within_timeout_with_slow_thread
    executor = Ace::Review::Molecules::MultiModelExecutor.new(
      max_concurrent: 2,
      llm_timeout: 1  # 1 second timeout
    )

    # Create a scenario where one model hangs forever
    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      if args[:model] == "stuck-model"
        # Simulate a slow thread that will be caught by Timeout.timeout
        sleep 10  # Will be interrupted by 1s timeout
        { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
      else
        File.write(args[:output_file], "success")
        { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
      end
    } do
      start_time = Time.now

      # Capture stderr to suppress warning messages in test output
      original_stderr = $stderr
      $stderr = StringIO.new

      begin
        result = executor.execute(
          models: ["good-model", "stuck-model"],
          system_prompt: "system",
          user_prompt: "user",
          session_dir: @tmpdir
        )
      ensure
        $stderr = original_stderr
      end

      duration = Time.now - start_time

      # Should complete within llm_timeout + some margin, NOT the full join timeout
      assert duration < 5, "Batch should complete within bounded time, took #{duration}s"

      # Good model should succeed
      assert result[:results]["good-model"][:success], "Good model should succeed"

      # Stuck model should be marked as failed with timeout error
      refute result[:results]["stuck-model"][:success], "Stuck model should be marked as failed"
      assert_match(/timed out after 1s/, result[:results]["stuck-model"][:error])
    end
  end

  # Test that normal timeout error messages are displayed correctly
  def test_timeout_error_message_displayed
    executor = Ace::Review::Molecules::MultiModelExecutor.new(
      max_concurrent: 1,
      llm_timeout: 1  # 1 second timeout
    )

    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      # Simulate a slow operation that will be caught by Timeout.timeout
      sleep 10
      { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
    } do
      # Capture stderr
      original_stderr = $stderr
      captured_stderr = StringIO.new
      $stderr = captured_stderr

      begin
        result = executor.execute(
          models: ["slow-model"],
          system_prompt: "system",
          user_prompt: "user",
          session_dir: @tmpdir
        )
      ensure
        $stderr = original_stderr
      end

      stderr_output = captured_stderr.string

      # Verify the timeout message was displayed
      assert_match(/slow-model: failed \(timed out after 1s\)/, stderr_output)

      # Verify the result contains proper error info
      refute result[:results]["slow-model"][:success]
      assert_match(/timed out after 1s/, result[:results]["slow-model"][:error])
    end
  end

  # Test that Thread.kill path is exercised when Timeout.timeout cannot interrupt
  # This simulates CLI providers stuck in system calls that don't release the GVL
  def test_thread_kill_path_when_timeout_cannot_interrupt
    # Use short grace period (1s) to avoid 31s wait in CI
    with_short_grace_period(1) do
      executor = Ace::Review::Molecules::MultiModelExecutor.new(
        max_concurrent: 2,
        llm_timeout: 1  # 1 second timeout, join deadline = 2 seconds with short grace
      )

      # Stub Timeout.timeout to do nothing (simulates uninterruptible operation)
      # This forces the outer Thread.join timeout to fire

      executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
        if args[:model] == "stuck-model"
          # Sleep longer than join timeout to ensure Thread.kill is triggered
          sleep 60
          { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
        else
          File.write(args[:output_file], "success")
          { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
        end
      } do
        # Stub Timeout.timeout to pass through without timing out
        Timeout.stub :timeout, ->(_t, _klass = nil, _msg = nil, &block) { block.call } do
          start_time = Time.now

          # Capture stderr to verify killed message
          original_stderr = $stderr
          captured_stderr = StringIO.new
          $stderr = captured_stderr

          begin
            result = executor.execute(
              models: ["good-model", "stuck-model"],
              system_prompt: "system",
              user_prompt: "user",
              session_dir: @tmpdir
            )
          ensure
            $stderr = original_stderr
          end

          duration = Time.now - start_time
          stderr_output = captured_stderr.string

          # Should complete within ~2s (llm_timeout + 1s grace period)
          assert duration < 5, "Batch should complete within bounded time, took #{duration}s"

          # Good model should succeed
          assert result[:results]["good-model"][:success], "Good model should succeed"

          # Stuck model should be killed (not timed out via Timeout::Error)
          refute result[:results]["stuck-model"][:success], "Stuck model should be marked as failed"
          assert_match(/killed after.*timeout/, result[:results]["stuck-model"][:error])

          # Verify the killed message was displayed
          assert_match(/stuck-model: killed after/, stderr_output)
        end
      end
    end
  end

  # Test that normal timeouts still work (Timeout::Error)
  def test_normal_timeout_still_works
    executor = Ace::Review::Molecules::MultiModelExecutor.new(
      max_concurrent: 1,
      llm_timeout: 1  # 1 second timeout
    )

    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      # This will be caught by Timeout.timeout in execute_single_model
      sleep 5
      { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
    } do
      # Capture stderr
      original_stderr = $stderr
      $stderr = StringIO.new

      begin
        result = executor.execute(
          models: ["slow-model"],
          system_prompt: "system",
          user_prompt: "user",
          session_dir: @tmpdir
        )
      ensure
        $stderr = original_stderr
      end

      # Should be marked as timed out (not killed)
      refute result[:results]["slow-model"][:success]
      assert_match(/timed out after 1s/, result[:results]["slow-model"][:error])
    end
  end

  # Test that successful models still produce reports when others timeout
  def test_successful_models_produce_reports_when_others_timeout
    executor = Ace::Review::Molecules::MultiModelExecutor.new(
      max_concurrent: 2,
      llm_timeout: 1
    )

    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      if args[:model] == "slow-model"
        # Simulate a slow operation that will be caught by Timeout.timeout
        sleep 10
        { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
      else
        File.write(args[:output_file], "Review output for #{args[:model]}")
        { success: true, response: "Review output", output_file: args[:output_file], metadata: {} }
      end
    } do
      # Capture stderr
      original_stderr = $stderr
      $stderr = StringIO.new

      begin
        result = executor.execute(
          models: ["good-model", "slow-model"],
          system_prompt: "system",
          user_prompt: "user",
          session_dir: @tmpdir
        )
      ensure
        $stderr = original_stderr
      end

      # Verify partial success
      assert result[:success], "Overall result should be success (at least one model succeeded)"
      assert result[:results]["good-model"][:success]
      assert File.exist?(result[:results]["good-model"][:output_file])

      # Summary should reflect partial success
      assert_equal 2, result[:summary][:total_models]
      assert_equal 1, result[:summary][:success_count]
      assert_equal 1, result[:summary][:failure_count]
    end
  end

  # Test that deadline-based join ensures bounded total wait time
  # Even with multiple stuck threads, total wait should be llm_timeout + grace period
  def test_deadline_based_join_bounds_total_wait_time
    # Use short grace period (1s) to avoid 31s wait in CI
    with_short_grace_period(1) do
      executor = Ace::Review::Molecules::MultiModelExecutor.new(
        max_concurrent: 3,
        llm_timeout: 1  # 1 second timeout, join deadline = 2s with short grace
      )

      # Stub Timeout.timeout to do nothing (simulates uninterruptible operations)
      executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
        # All models are stuck
        sleep 60
        { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
      } do
        Timeout.stub :timeout, ->(_t, _klass = nil, _msg = nil, &block) { block.call } do
          start_time = Time.now

          # Capture stderr
          original_stderr = $stderr
          $stderr = StringIO.new

          begin
            result = executor.execute(
              models: ["stuck-1", "stuck-2", "stuck-3"],
              system_prompt: "system",
              user_prompt: "user",
              session_dir: @tmpdir
            )
          ensure
            $stderr = original_stderr
          end

          duration = Time.now - start_time

          # With deadline-based join, total wait should be ~2s (1s + 1s grace)
          # NOT 3 * 2s = 6s as would happen with per-thread timeout
          assert duration < 5, "Total wait should be bounded to ~2s, not #{duration}s"

          # All models should be killed
          assert_equal 3, result[:results].size
          result[:results].each do |model, model_result|
            refute model_result[:success], "#{model} should be killed"
            assert_match(/killed after/, model_result[:error])
          end
        end
      end
    end
  end
end

# Tests for MultiModelExecutor basic functionality
class MultiModelExecutorBasicTest < AceReviewTest
  def setup
    @tmpdir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_executor_passes_output_file_to_llm_executor
    executor = Ace::Review::Molecules::MultiModelExecutor.new(max_concurrent: 1)

    # Track what arguments are passed to LlmExecutor
    captured_calls = []

    # Stub the LlmExecutor#execute method
    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      captured_calls << args
      {
        success: true,
        response: "test response",
        output_file: args[:output_file],
        metadata: {}
      }
    } do
      result = executor.execute(
        models: ["test-model"],
        system_prompt: "system",
        user_prompt: "user",
        session_dir: @tmpdir
      )

      assert result[:success]
      assert_equal 1, captured_calls.size

      # Verify output_file was passed
      call = captured_calls.first
      assert call.key?(:output_file), "output_file should be passed to LlmExecutor"
      assert_match %r{review-test-model\.md$}, call[:output_file]
    end
  end

  def test_executor_returns_correct_output_files
    executor = Ace::Review::Molecules::MultiModelExecutor.new(max_concurrent: 2)

    # Stub to return success with the provided output_file
    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      # Actually create the file to simulate real behavior
      File.write(args[:output_file], "test content for #{args[:model]}")
      {
        success: true,
        response: "test response",
        output_file: args[:output_file],
        metadata: {}
      }
    } do
      result = executor.execute(
        models: ["google:gemini-2.5-flash", "openai:gpt-4"],
        system_prompt: "system",
        user_prompt: "user",
        session_dir: @tmpdir
      )

      assert result[:success]
      assert_equal 2, result[:results].size

      # Verify each model has correct output file that exists
      result[:results].each do |model, model_result|
        assert model_result[:success], "Model #{model} should succeed"
        assert model_result[:output_file], "Model #{model} should have output_file"
        assert File.exist?(model_result[:output_file]), "Output file should exist: #{model_result[:output_file]}"
      end
    end
  end

  def test_executor_handles_partial_failures
    executor = Ace::Review::Molecules::MultiModelExecutor.new(max_concurrent: 2)

    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      if args[:model] == "failing-model"
        { success: false, error: "API error", response: nil }
      else
        File.write(args[:output_file], "success")
        { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
      end
    } do
      result = executor.execute(
        models: ["good-model", "failing-model"],
        system_prompt: "system",
        user_prompt: "user",
        session_dir: @tmpdir
      )

      # Should still be considered success if at least one model succeeds
      assert result[:success]
      assert_equal 2, result[:summary][:total_models]
      assert_equal 1, result[:summary][:success_count]
      assert_equal 1, result[:summary][:failure_count]

      # Verify individual results
      assert result[:results]["good-model"][:success]
      refute result[:results]["failing-model"][:success]
    end
  end

  def test_executor_generates_correct_model_slugs
    executor = Ace::Review::Molecules::MultiModelExecutor.new(max_concurrent: 1)

    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      File.write(args[:output_file], "test")
      { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
    } do
      result = executor.execute(
        models: ["google:gemini-2.5-flash"],
        system_prompt: "system",
        user_prompt: "user",
        session_dir: @tmpdir
      )

      model_result = result[:results]["google:gemini-2.5-flash"]
      assert_equal "google-gemini-2-5-flash", model_result[:model_slug]
      assert_match %r{review-google-gemini-2-5-flash\.md$}, model_result[:output_file]
    end
  end
end
