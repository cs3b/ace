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

        # Execute a batch of models concurrently
        def execute_batch(models, system_prompt, user_prompt, session_dir)
          batch_results = {}
          threads = []

          models.each do |model|
            thread = Thread.new do
              execute_single_model(model, system_prompt, user_prompt, session_dir, batch_results)
            end
            threads << thread
          end

          # Wait for all threads to complete
          threads.each(&:join)

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
                output_file: model_output_file
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
          $stderr.puts "Executing reviews (#{models.size} model#{'s' if models.size > 1}):"
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
            $stderr.puts message
            $stderr.flush
          end
        end
      end
    end
  end
end
