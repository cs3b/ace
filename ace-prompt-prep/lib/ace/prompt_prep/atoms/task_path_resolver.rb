# frozen_string_literal: true

require "ace/task"
require "ace/task/organisms/task_manager"

module Ace
  module PromptPrep
    module Atoms
      # Resolves task directory path from task ID and extracts task IDs from branch names
      # Delegates to ace-task for task resolution to avoid duplicating logic
      #
      # Pure functions only - git I/O is handled by Molecules::GitBranchReader
      class TaskPathResolver
        # Find task directory by ID using ace-task API
        # @param task_id [String] e.g., "117", "121.01", "v.0.9.0+task.121"
        # @return [Hash] { path: String, prompts_path: String, found: Boolean, error: String|nil }
        def self.resolve(task_id)
          # Use ace-task's TaskManager to resolve task
          manager = Ace::Task::Organisms::TaskManager.new
          task = manager.show(task_id)

          unless task
            return {
              path: nil,
              prompts_path: nil,
              found: false,
              error: "Task not found: #{task_id}"
            }
          end

          # Extract task directory from task file path
          task_dir = task.path
          prompts_dir = File.join(task_dir, "prompts")

          {
            path: task_dir,
            prompts_path: prompts_dir,
            found: true,
            error: nil
          }
        rescue => e
          {
            path: nil,
            prompts_path: nil,
            found: false,
            error: "Error resolving task path: #{e.message}"
          }
        end

        # Extract task ID from branch name using configurable patterns
        # @param branch_name [String] e.g., "117-feature-name", "121.01-archive"
        # @param patterns [Array<String>|nil] Optional regex patterns (uses config if nil)
        # @return [String|nil] task ID or nil if not found
        #
        # Default pattern matches:
        #   117-feature → "117"
        #   121.01-archive → "121.01"
        # Does not match:
        #   main → nil
        #   feature-123 → nil (number not at start)
        def self.extract_from_branch(branch_name, patterns: nil)
          return nil if branch_name.nil? || branch_name.empty?

          # Get patterns from config or use default
          patterns ||= Ace::PromptPrep.config.dig("task", "branch_patterns")
          patterns ||= ['^(\d+(?:\.\d+)?)-']

          patterns.each do |pattern|
            match = branch_name.match(Regexp.new(pattern))
            return match[1] if match && match[1]
          end

          nil
        end
      end
    end
  end
end
