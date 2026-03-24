# frozen_string_literal: true

require "timeout"
require_relative "llm_executor"

module Ace
  module Review
    module Molecules
      # Executes LLM queries concurrently across multiple models
      # Uses Thread-based parallelism with configurable concurrency limit
      class MultiModelExecutor
        attr_reader :max_concurrent, :llm_timeout

        # Default timeout for LLM queries (5 minutes)
        DEFAULT_LLM_TIMEOUT = 300

        # Warning threshold: 80% of typical 1M context window
        PROMPT_SIZE_WARNING_THRESHOLD = 800_000

        def initialize(max_concurrent: nil, llm_timeout: nil)
          # Read from config, fallback to default of 3, clamp to minimum 1
          @max_concurrent = [
            max_concurrent || Ace::Review.get("defaults", "max_concurrent_models") || 3,
            1
          ].max
          # Timeout for LLM queries (in seconds)
          @llm_timeout = llm_timeout || Ace::Review.get("defaults", "llm_timeout") || DEFAULT_LLM_TIMEOUT
          @llm_executor = LlmExecutor.new
          @mutex = Mutex.new
        end

        # Execute reviews concurrently across multiple models
        # @param models [Array<String>] array of model identifiers
        # @param system_prompt [String] system prompt
        # @param user_prompt [String] user prompt
        # @param session_dir [String] session directory for output
        # @return [Hash] results hash with per-model outcomes and summary
        def execute(models:, system_prompt:, user_prompt:, session_dir:)
          start_time = Time.now
          results = {}

          # Warn once before executing any models
          warn_if_prompt_large(system_prompt, user_prompt, models)

          # Display execution header
          display_header(models)

          # Process models in batches to respect concurrency limit
          models.each_slice(@max_concurrent) do |batch|
            batch_results = execute_batch(batch, system_prompt, user_prompt, session_dir)
            results.merge!(batch_results)
          end

          # Compute summary metrics
          total_duration = Time.now - start_time
          success_count = results.values.count { |r| r[:success] }
          failure_count = results.values.count { |r| !r[:success] }

          {
            success: success_count > 0,
            results: results,
            summary: {
              total_models: models.size,
              success_count: success_count,
              failure_count: failure_count,
              total_duration: total_duration.round(2)
            }
          }
        end

        private

        # Grace period (seconds) added to llm_timeout for Thread.join deadline.
        # This allows the inner Timeout.timeout to fire first in normal cases,
        # while the outer Thread.join deadline acts as a safety net for threads
        # stuck in uninterruptible system calls (e.g., CLI providers).
        # @return [Integer] grace period in seconds
        JOIN_GRACE_PERIOD = 30

        # Execute a batch of models concurrently
        #
        # Two-tier timeout strategy:
        # 1. Timeout.timeout (inner): Catches most slow operations, can interrupt
        #    Ruby-level sleep and IO. Used in execute_single_model.
        # 2. Thread.join with deadline (outer): Safety net for when (1) cannot interrupt
        #    the thread (e.g., CLI provider stuck in uninterruptible system call).
        #
        # Uses deadline-based join to ensure total wait time is bounded regardless
        # of how many threads are stuck. Each subsequent join gets the remaining
        # time until the absolute deadline, not a fresh timeout.
        #
        # Note: Thread.kill may leave orphaned CLI subprocesses (from Open3.capture3).
        # These will complete naturally and exit. True subprocess cleanup would require
        # provider-level changes to track and terminate child processes.
        def execute_batch(models, system_prompt, user_prompt, session_dir)
          batch_results = {}
          threads = []

          models.each do |model|
            thread = Thread.new do
              # Suppress IOError noise from killed threads
              Thread.current.report_on_exception = false
              Thread.current[:model] = model  # Store model for warning display
              execute_single_model(model, system_prompt, user_prompt, session_dir, batch_results)
            end
            threads << thread
          end

          # Wait for all threads to complete with deadline-based timeout
          # Use absolute deadline to ensure total wait is bounded to llm_timeout + grace period
          # regardless of how many threads are stuck
          total_timeout = @llm_timeout + JOIN_GRACE_PERIOD
          deadline = monotonic_now + total_timeout
          threads.each do |thread|
            remaining = [deadline - monotonic_now, 0].max
            unless thread.join(remaining)
              # Thread didn't finish in time, kill it
              model = thread[:model]
              thread.kill

              # Only display/record if not already recorded (avoid duplicate messages)
              should_display = false
              @mutex.synchronize do
                unless batch_results.key?(model)
                  should_display = true
                  batch_results[model] = {
                    success: false,
                    error: "killed after #{total_timeout}s timeout",
                    duration: total_timeout.to_f
                  }
                end
              end
              display_progress_killed(model, total_timeout) if should_display
            end
          end

          batch_results
        end

        # Execute a single model (runs in thread)
        def execute_single_model(model, system_prompt, user_prompt, session_dir, results)
          start_time = Time.now
          display_progress(model, :querying)

          begin
            # Generate model-specific output filename
            model_slug = generate_model_slug(model)
            model_output_file = File.join(session_dir, "review-#{model_slug}.md")

            # Execute LLM query with timeout to prevent indefinite hangs
            result = Timeout.timeout(@llm_timeout) do
              @llm_executor.execute(
                system_prompt: system_prompt,
                user_prompt: user_prompt,
                model: model,
                session_dir: session_dir,
                output_file: model_output_file,
                timeout: @llm_timeout
              )
            end

            duration = Time.now - start_time

            # Add additional metadata (output_file is already set by executor)
            result[:duration] = duration.round(2)
            result[:model_slug] = model_slug

            # Store result in thread-safe manner
            @mutex.synchronize do
              results[model] = result
            end

            # Display progress
            if result[:success]
              display_progress(model, :success, duration.round(1))
            else
              display_progress(model, :failure, nil, result[:error])
            end
          rescue Timeout::Error
            duration = Time.now - start_time
            error_message = "timed out after #{@llm_timeout}s"

            @mutex.synchronize do
              results[model] = {
                success: false,
                error: error_message,
                duration: duration.round(2)
              }
            end

            display_progress(model, :failure, nil, error_message)
          rescue => e
            duration = Time.now - start_time

            @mutex.synchronize do
              results[model] = {
                success: false,
                error: e.message,
                duration: duration.round(2)
              }
            end

            display_progress(model, :failure, nil, e.message)
          end
        end

        # Generate model slug for filename (sanitize provider:model string)
        def generate_model_slug(model)
          Ace::Review::Atoms::SlugGenerator.generate(model)
        end

        # Display execution header
        def display_header(models)
          $stderr.puts
          warn "Executing reviews (#{models.size} model#{"s" if models.size > 1}):"
          $stderr.flush
        end

        # Display progress for a model
        # @param model [String] model identifier
        # @param status [Symbol] :querying, :success, or :failure
        # @param duration [Float, nil] execution duration in seconds
        # @param error [String, nil] error message if failed
        def display_progress(model, status, duration = nil, error = nil)
          message = case status
          when :querying
            "  ⏳ #{model}: querying..."
          when :success
            "  ✓ #{model}: complete (#{duration}s)"
          when :failure
            error_msg = error ? " (#{error})" : ""
            "  ✗ #{model}: failed#{error_msg}"
          end

          @mutex.synchronize do
            warn message
            $stderr.flush
          end
        end

        # Display warning for killed thread
        # @param model [String] model identifier
        # @param timeout [Integer] timeout duration in seconds
        def display_progress_killed(model, timeout)
          @mutex.synchronize do
            warn "  ⚠ #{model}: killed after #{timeout}s timeout"
            $stderr.flush
          end
        end

        # Returns monotonic time in seconds (immune to system clock changes)
        # @return [Float] monotonic time in seconds
        def monotonic_now
          Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end

        # Warn if prompt size may exceed model context limits
        #
        # Uses rough estimate of 4 characters per token. Warns at 80% of
        # typical context window to give user advance notice before execution fails.
        #
        # @param system_prompt [String, nil] system prompt
        # @param user_prompt [String, nil] user prompt
        # @param models [Array<String>] model identifiers
        def warn_if_prompt_large(system_prompt, user_prompt, models)
          total_chars = (system_prompt&.length || 0) + (user_prompt&.length || 0)
          estimated_tokens = total_chars / 4  # Rough estimate: 4 chars per token

          return unless estimated_tokens > PROMPT_SIZE_WARNING_THRESHOLD

          model_list = models.join(", ")
          warn "Warning: Prompt size (~#{estimated_tokens.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')} tokens) " \
               "may exceed context limits for: #{model_list}"
        end
      end
    end
  end
end
