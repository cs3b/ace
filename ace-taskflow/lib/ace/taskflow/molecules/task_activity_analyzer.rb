# frozen_string_literal: true

require_relative "task_filter"

module Ace
  module Taskflow
    module Molecules
      # Analyze and categorize task activity for status awareness
      # Provides visibility into what's recently done, in progress, and coming next
      #
      # Configuration (ADR-022):
      # Primary source of defaults is .ace-defaults/taskflow/config.yml via Configuration class.
      # This molecule receives settings from the caller (typically TaskflowContextLoader).
      # Fallback defaults exist for backward compatibility but callers should provide explicit values.
      class TaskActivityAnalyzer
        # Categorize tasks into activity buckets
        # @param tasks [Array<Hash>] All tasks to analyze
        # @param options [Hash] Configuration options
        #   Caller should provide values from Configuration class (ADR-022 compliant).
        #   Fallback defaults exist for backward compatibility but are not the primary source.
        # @option options [String] :current_task_id ID of current task to exclude from in_progress
        # @option options [Integer] :recently_done_limit Max recently done tasks (default: 3 for backward compat)
        # @option options [Integer] :up_next_limit Max up next tasks (default: 3 for backward compat)
        # @option options [Boolean] :include_drafts Include draft tasks in up_next (default: false)
        # @return [Hash] Activity data with :recently_done, :in_progress, :up_next arrays
        def self.categorize_activities(tasks, options = {})
          new.categorize_activities(tasks, options)
        end

        def categorize_activities(tasks, options = {})
          return empty_result if tasks.nil? || tasks.empty?

          # Extract options - caller provides values from Configuration (ADR-022)
          # Fallback defaults for backward compatibility (e.g., direct molecule usage in tests)
          current_task_id = options[:current_task_id]
          recently_done_limit = options.fetch(:recently_done_limit, 3)
          up_next_limit = options.fetch(:up_next_limit, 3)
          include_drafts = options.fetch(:include_drafts, false)

          # Validate limits are non-negative integers (0 is valid to disable sections)
          recently_done_limit = [recently_done_limit.to_i, 0].max
          up_next_limit = [up_next_limit.to_i, 0].max

          {
            recently_done: find_recently_done(tasks, recently_done_limit),
            in_progress: find_in_progress(tasks, current_task_id),
            up_next: find_up_next(tasks, up_next_limit, include_drafts: include_drafts)
          }
        end

        # Find recently completed tasks
        # Returns the most recently completed tasks by file modification time.
        # Enriches tasks with :completed_at for pure formatting in TaskDisplayFormatter.
        #
        # @note Filters by both "done" and "completed" statuses. Both are valid terminal
        #   states indicating task completion. Including both ensures comprehensive
        #   recent activity tracking for projects using either status convention.
        #
        # @param tasks [Array<Hash>] All tasks
        # @param limit [Integer] Maximum number of tasks to return (0 to disable)
        # @return [Array<Hash>] Recently done tasks with :completed_at, most recent first
        def find_recently_done(tasks, limit)
          # Short-circuit when limit is 0 (disables section entirely)
          return [] if limit.zero?

          # Filter to done and completed tasks (both are valid completion statuses)
          done_tasks = TaskFilter.filter_by_status(tasks, %w[done completed])
          return [] if done_tasks.empty?

          # Sort by modification time (most recent first) and limit
          sorted = TaskFilter.sort_tasks(done_tasks, :modified, false)

          # Enrich with completed_at for pure formatting (I/O happens here, not in formatter)
          sorted.first(limit).map { |task| enrich_with_completed_at(task) }
        end

        # Find tasks currently in progress (excluding current task)
        # @param tasks [Array<Hash>] All tasks
        # @param current_task_id [String, nil] ID of current task to exclude
        # @return [Array<Hash>] In-progress tasks excluding current, sorted by ID for deterministic output
        def find_in_progress(tasks, current_task_id = nil)
          in_progress = TaskFilter.filter_by_status(tasks, ["in-progress"])

          # Exclude current task if specified
          if current_task_id
            in_progress = in_progress.reject { |t| t[:id] == current_task_id }
          end

          # Sort by task ID for deterministic output across runs
          in_progress.sort_by { |t| t[:id].to_s }
        end

        # Find next pending tasks
        # @param tasks [Array<Hash>] All tasks
        # @param limit [Integer] Maximum number of tasks to return (0 to disable)
        # @param include_drafts [Boolean] Include draft status tasks (default: false)
        # @return [Array<Hash>] Next pending tasks in priority order
        def find_up_next(tasks, limit, include_drafts: false)
          # Short-circuit when limit is 0 (disables section entirely)
          return [] if limit.zero?

          # Filter to pending tasks (optionally include drafts for visibility)
          statuses = include_drafts ? %w[pending draft] : ["pending"]
          pending_tasks = TaskFilter.filter_by_status(tasks, statuses)

          # Sort using TaskFilter's sort logic (respects sort field, then ID)
          sorted = TaskFilter.sort_tasks(pending_tasks, :sort, true)

          sorted.first(limit)
        end

        private

        def empty_result
          {
            recently_done: [],
            in_progress: [],
            up_next: []
          }
        end

        # Enrich task with completed_at timestamp from file mtime
        # This moves I/O out of the formatter for ATOM purity (molecule performs data enrichment)
        # @param task [Hash] Task data with :path
        # @return [Hash] Task with :completed_at added if file exists
        def enrich_with_completed_at(task)
          return task unless task[:path]

          task.merge(completed_at: File.mtime(task[:path]))
        rescue Errno::ENOENT, Errno::EACCES => e
          # File was deleted or inaccessible - graceful fallback
          # Debug logging for troubleshooting (file missing or permission denied)
          warn("Task file inaccessible: #{task[:path]} (#{e.class})") if $VERBOSE
          if defined?(Ace::Core) && Ace::Core.respond_to?(:logger)
            Ace::Core.logger.debug("Task file inaccessible: #{task[:path]} (#{e.class})")
          end
          task
        end
      end
    end
  end
end
