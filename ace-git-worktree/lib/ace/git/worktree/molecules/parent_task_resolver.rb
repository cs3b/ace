# frozen_string_literal: true

require_relative "../atoms/task_id_extractor"
require_relative "task_fetcher"

module Ace
  module Git
    module Worktree
      module Molecules
        # Parent task resolver molecule
        #
        # Determines the target branch for a task's PR by resolving the parent task's
        # worktree branch. This enables subtasks to target their orchestrator branch
        # instead of defaulting to main.
        #
        # @example Resolve target branch for a subtask
        #   resolver = ParentTaskResolver.new
        #   target = resolver.resolve_target_branch(subtask_data)
        #   target # => "202-rename-support-gems" or "main"
        class ParentTaskResolver
          # Default fallback target branch when no parent is found
          DEFAULT_TARGET = "main"

          # Regex pattern for extracting task number from full task ID
          # Pattern: v.0.9.0+task.202.01 -> captures "202.01"
          TASK_ID_PATTERN = /task\.(\d+(?:\.\d+)?)\z/.freeze

          # Initialize a new ParentTaskResolver
          #
          # @param project_root [String] Project root directory
          # @param task_fetcher [TaskFetcher] Optional TaskFetcher instance (for testing)
          def initialize(project_root: Dir.pwd, task_fetcher: nil)
            @project_root = project_root
            @task_fetcher = task_fetcher || TaskFetcher.new
          end

          # Resolve target branch for a task
          #
          # @param task_data [Hash] Task data hash from ace-taskflow
          # @return [String] Parent's worktree branch or DEFAULT_TARGET
          #
          # @example Subtask with parent
          #   resolve_target_branch(subtask_data) # => "202-orchestrator-branch"
          #
          # @example Orchestrator task (no parent)
          #   resolve_target_branch(orchestrator_data) # => "main"
          def resolve_target_branch(task_data)
            return DEFAULT_TARGET unless task_data

            # Extract parent task ID from task ID
            parent_id = extract_parent_id(task_data[:id])
            return DEFAULT_TARGET unless parent_id

            # Load parent task data
            parent_task = load_parent_task(parent_id)
            return DEFAULT_TARGET unless parent_task

            # Extract parent's worktree branch
            extract_parent_branch(parent_task)
          rescue StandardError => e
            # Silently fall back to default - debugging info available via --verbose flag on CLI
            DEFAULT_TARGET
          end

          # Load parent task data
          #
          # @param parent_id [String] Parent task ID (e.g., "202")
          # @return [Hash, nil] Parent task data or nil
          def load_parent_task(parent_id)
            return nil unless parent_id

            @task_fetcher.fetch(parent_id)
          end

          # Extract parent's worktree branch from task data
          #
          # @param parent_data [Hash] Parent task data hash
          # @return [String] Parent's worktree branch or DEFAULT_TARGET
          def extract_parent_branch(parent_data)
            return DEFAULT_TARGET unless parent_data

            # Support both symbol and string keys for compatibility
            worktree_data = parent_data[:worktree] || parent_data["worktree"]
            return DEFAULT_TARGET unless worktree_data.is_a?(Hash)

            # Return parent's worktree branch (support both key types)
            parent_branch = worktree_data[:branch] || worktree_data["branch"]
            parent_branch || DEFAULT_TARGET
          end

          private

          # Extract parent task ID from task ID
          #
          # @param task_id [String] Full task ID (e.g., "v.0.9.0+task.202.01")
          # @return [String, nil] Parent task ID (e.g., "202") or nil
          #
          # @example Subtask
          #   extract_parent_id("v.0.9.0+task.202.01") # => "202"
          #
          # @example Orchestrator task
          #   extract_parent_id("v.0.9.0+task.202") # => nil
          def extract_parent_id(task_id)
            return nil unless task_id

            # Extract task number from full ID using TASK_ID_PATTERN
            # Pattern: v.0.9.0+task.202.01 -> 202.01
            match = task_id.match(TASK_ID_PATTERN)
            return nil unless match

            task_number = match[1]

            # Check if this is a subtask (contains dot)
            return nil unless task_number.include?(".")

            # Extract parent number: 202.01 -> 202
            task_number.split(".").first
          end
        end
      end
    end
  end
end
