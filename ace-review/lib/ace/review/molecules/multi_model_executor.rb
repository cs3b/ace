# frozen_string_literal: true

require_relative "llm_executor"

module Ace
  module Review
    module Molecules
      # Executes LLM queries concurrently across reviewer lanes.
      # Uses Thread-based parallelism with configurable concurrency limit.
      class MultiModelExecutor
        attr_reader :max_concurrent

        # Warning threshold: 80% of typical 200K context window
        PROMPT_SIZE_WARNING_THRESHOLD = 160_000

        def initialize(max_concurrent: nil, llm_timeout: nil)
          # Read from config, fallback to default of 3, clamp to minimum 1
          @max_concurrent = [
            max_concurrent || Ace::Review.get("defaults", "max_concurrent_models") || 3,
            1
          ].max
          # llm_timeout is intentionally handled by provider/client config (ace-llm).
          _ = llm_timeout
          @llm_executor = LlmExecutor.new
          @mutex = Mutex.new
        end

        # Execute reviews concurrently across reviewer lanes.
        # @param models [Array<String>] array of model identifiers
        # @param reviewers [Array<Reviewer>, nil] optional reviewer objects; when provided,
        #   each result is keyed by a reviewer-run key and includes reviewer metadata.
        # @param system_prompt [String, Hash<String, String>] system prompt
        # @param user_prompt [String] user prompt
        # @param session_dir [String] session directory for output
        # @return [Hash] results hash with per-lane outcomes and summary
        def execute(models:, system_prompt:, user_prompt:, session_dir:, reviewers: nil)
          start_time = Time.now
          results = {}

          reviewer_lanes = build_reviewer_lanes(reviewers, system_prompt)
          effective_lanes = if reviewer_lanes.any?
                              reviewer_lanes
                            else
                              models.map do |model|
                                {
                                  run_key: model,
                                  model: model,
                                  reviewer: nil,
                                  system_prompt: system_prompt_for_model(system_prompt, model)
                                }
                              end
                            end

          # Legacy path can still execute model list directly.
          # Reviewer lane path executes one lane per reviewer run key.
          return { success: false, results: {}, summary: { total_models: 0, success_count: 0, failure_count: 0, total_duration: 0.0 } } if effective_lanes.empty?

          # Warn once before executing any lanes
          warn_if_prompt_large(system_prompt, user_prompt, effective_lanes.map { |lane| lane[:run_key] })

          # Display execution header
          display_header(effective_lanes)

          # Process lanes in batches to respect concurrency limit
          effective_lanes.each_slice(@max_concurrent) do |batch|
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
              total_models: effective_lanes.size,
              success_count: success_count,
              failure_count: failure_count,
              total_duration: total_duration.round(2)
            }
          }
        end

        private

        # Build execution lanes from a reviewers array.
        # @param reviewers [Array<Reviewer>, nil]
        # @return [Array<Hash>] lane descriptors
        def build_reviewer_lanes(reviewers, system_prompt)
          return [] unless reviewers.is_a?(Array) && reviewers.any?

          Ace::Review::Atoms::ReviewerRunKeyAllocator.allocate(reviewers).map do |reviewer_lane|
            model = reviewer_lane[:model]
            next if model.nil? || model.to_s.empty?
            {
              run_key: reviewer_lane[:run_key],
              model: model,
              reviewer: reviewer_lane[:reviewer],
              system_prompt: system_prompt_for_reviewer(system_prompt, reviewer_lane[:run_key], model)
            }
          end
            .compact
            .uniq { |lane| lane[:run_key] }
        end

        # Execute a batch of models concurrently
        def execute_batch(lanes, system_prompt, user_prompt, session_dir)
          batch_results = {}
          threads = []

          lanes.each do |lane|
            thread = Thread.new do
              # Suppress IOError noise from killed threads
              Thread.current.report_on_exception = false
              Thread.current[:run_key] = lane[:run_key] # Store lane key for warning display
              Thread.current[:lane] = lane
              execute_single_lane(lane, system_prompt, user_prompt, session_dir, batch_results)
            end
            threads << thread
          end

          # Wait for all threads to complete
          threads.each(&:join)

          batch_results
        end

        # Execute a single lane (runs in thread)
        def execute_single_lane(lane, _system_prompt, user_prompt, session_dir, results)
          run_key = lane[:run_key]
          model = lane[:model]
          reviewer = lane[:reviewer]

          start_time = Time.now
          display_progress(run_key, :querying)

          begin
            # Generate lane-specific output filename
            run_key_slug = generate_run_key_slug(run_key)
            model_output_file = File.join(session_dir, "review-#{run_key_slug}.md")
            model_slug = generate_model_slug(model)

            result = @llm_executor.execute(
              system_prompt: lane[:system_prompt],
              user_prompt: user_prompt,
              model: model,
              session_dir: session_dir,
              output_file: model_output_file,
              reviewer: reviewer
            )

            duration = Time.now - start_time

            # Add additional metadata (output_file is already set by executor)
            result[:run_key] = run_key
            result[:model] = model
            result[:reviewer] = reviewer
            result[:duration] = duration.round(2)
            result[:model_slug] = model_slug

            # Store result in thread-safe manner
            @mutex.synchronize do
              results[run_key] = result
            end

            # Display progress
            if result[:success]
              display_progress(run_key, :success, duration.round(1))
            else
              display_progress(run_key, :failure, nil, result[:error])
            end
          rescue => e
            duration = Time.now - start_time

            @mutex.synchronize do
              results[run_key] = {
                success: false,
                model: model,
                run_key: run_key,
                reviewer: reviewer,
                model_slug: generate_model_slug(model),
                error: e.message,
                duration: duration.round(2)
              }
            end

            display_progress(run_key, :failure, nil, e.message)
          end
        end

        # Generate model slug for filename (sanitize provider:model string)
        def generate_model_slug(model)
          Ace::Review::Atoms::SlugGenerator.generate(model)
        end

        def generate_run_key_slug(run_key)
          Ace::Review::Atoms::SlugGenerator.generate(run_key)
        end

        def reviewer_name(reviewer)
          return reviewer.name if reviewer.respond_to?(:name)

          reviewer[:name] || reviewer["name"] if reviewer.is_a?(Hash)
        end

        def reviewer_model(reviewer)
          return reviewer.model if reviewer.respond_to?(:model)

          reviewer[:model] || reviewer["model"] if reviewer.is_a?(Hash)
        end

        # Display execution header
        def display_header(lanes)
          $stderr.puts
          $stderr.puts "Executing reviews (#{lanes.size} lane#{'s' if lanes.size > 1}):"
          $stderr.flush
        end

        # Display progress for a lane
        # @param lane_id [String] lane identifier (run key or model)
        # @param status [Symbol] :querying, :success, or :failure
        # @param duration [Float, nil] execution duration in seconds
        # @param error [String, nil] error message if failed
        def display_progress(lane_id, status, duration = nil, error = nil)
          message = case status
                    when :querying
                      "  ⏳ #{lane_id}: querying..."
                    when :success
                      "  ✓ #{lane_id}: complete (#{duration}s)"
                    when :failure
                      error_msg = error ? " (#{error})" : ""
                      "  ✗ #{lane_id}: failed#{error_msg}"
                    end

          @mutex.synchronize do
            $stderr.puts message
            $stderr.flush
          end
        end

        # Warn if prompt size may exceed model context limits
        #
        # Uses rough estimate of 4 characters per token. Warns at 80% of
        # typical context window to give user advance notice before execution fails.
        #
        # @param system_prompt [String, Hash<String, String>, nil] system prompt
        # @param user_prompt [String, nil] user prompt
        # @param models [Array<String>] model identifiers
        def warn_if_prompt_large(system_prompt, user_prompt, models)
          system_prompt_chars = if system_prompt.is_a?(Hash)
                                 system_prompt.values.sum { |value| value.to_s.length }
                               else
                                 system_prompt.to_s.length
                               end
          total_chars = system_prompt_chars + (user_prompt&.length || 0)
          estimated_tokens = total_chars / 4  # Rough estimate: 4 chars per token

          return unless estimated_tokens > PROMPT_SIZE_WARNING_THRESHOLD

          model_list = models.join(", ")
          warn "Warning: Prompt size (~#{estimated_tokens.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')} tokens) " \
               "may exceed context limits for: #{model_list}"
        end

        def system_prompt_for_model(system_prompt, model)
          return system_prompt unless system_prompt.is_a?(Hash)

          system_prompt[model] || system_prompt[model.to_s] || system_prompt[model.to_sym] || system_prompt.values.first
        end

        def system_prompt_for_reviewer(system_prompt, run_key, model)
          return system_prompt unless system_prompt.is_a?(Hash)

          system_prompt[run_key] ||
            system_prompt[run_key.to_s] ||
            system_prompt[run_key.to_sym] ||
            system_prompt_for_model(system_prompt, model)
        end
      end
    end
  end
end
