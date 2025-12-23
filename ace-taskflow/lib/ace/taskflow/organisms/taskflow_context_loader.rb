# frozen_string_literal: true

require_relative "../molecules/task_loader"
require_relative "../molecules/release_resolver"
require_relative "../atoms/task_reference_parser"

module Ace
  module Taskflow
    module Organisms
      # Orchestrates loading taskflow context
      # Focuses on taskflow-specific information (release, task)
      # Git state is available via ace-git context command
      class TaskflowContextLoader
        # Load taskflow context
        # @since 0.24.0
        # @param options [Hash] Options (currently unused, kept for compatibility)
        # @return [Hash] Taskflow context with task and release info
        def self.load(options = {})
          new.load(options)
        end

        def initialize(root_path: nil)
          @root_path = root_path || default_root_path
        end

        # Load taskflow context (task and release information)
        # @since 0.24.0
        # @param options [Hash] Options (currently unused, kept for API compatibility)
        # @return [Hash] Taskflow context with task and release info
        def load(options = {})
          # Detect task pattern from current branch name
          task_pattern = detect_task_pattern_from_branch

          # Resolve task from pattern if found
          resolved_task = resolve_task(task_pattern) if task_pattern

          # Get current release info
          release_info = load_release_info

          {
            task: resolved_task,
            release: release_info
          }
        end

        private

        def resolve_task(task_pattern)
          return nil unless task_pattern

          loader = Molecules::TaskLoader.new(@root_path)
          task = loader.find_task_by_reference(task_pattern)

          return nil unless task

          {
            id: task[:id],
            title: task[:title],
            status: task[:status],
            path: task[:path],
            priority: task[:priority],
            estimate: task[:estimate],
            is_orchestrator: task[:is_orchestrator],
            subtask_ids: task[:subtask_ids],
            # Extract parent task number from parent_id for context display
            # parent_id is canonical (e.g., "v.0.9.0+task.140"), parent is extracted number (e.g., "140")
            parent: task[:parent_id] ? extract_parent_number(task[:parent_id]) : nil
          }
        end

        def load_release_info
          resolver = Molecules::ReleaseResolver.new(@root_path)
          primary = resolver.find_primary_active

          return nil unless primary

          # ReleaseResolver returns consistent symbol keys
          stats = primary[:statistics]
          total = stats[:total]
          statuses = stats[:statuses]
          done = (statuses[:done] || 0) + (statuses[:completed] || 0)
          progress = total > 0 ? ((done.to_f / total) * 100).round : 0

          {
            name: primary[:name],
            version: primary[:version],
            path: primary[:path],
            status: primary[:status],
            total_tasks: total,
            done_tasks: done,
            progress: progress
          }
        end

        def default_root_path
          # Use configuration to find taskflow root
          Ace::Taskflow.configuration.root_directory
        end

        # Detect task pattern from current git branch name
        # Extracts task number from branch names like "140.02-update-feature" or "140-feature"
        # @return [String, nil] Task pattern (e.g., "140.02", "140") or nil if not found
        def detect_task_pattern_from_branch
          # Get current branch name - minimal git operation
          branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
          return nil if branch.empty? || branch == "HEAD"

          # Extract task pattern: matches "140.02" or "140" at start of branch name
          # Pattern: starts with digits, optionally followed by .digits, before first hyphen
          branch[/^(\d+(?:\.\d+)?)-/, 1]
        end

        # Extract task number from parent_id (e.g., "v.0.9.0+task.140" -> "140")
        # Returns nil if parent_id is nil or format is invalid
        # Delegates to TaskReferenceParser for consistent parsing
        def extract_parent_number(parent_id)
          return nil unless parent_id
          Atoms::TaskReferenceParser.extract_number(parent_id)
        end
      end
    end
  end
end
