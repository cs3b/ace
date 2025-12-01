# frozen_string_literal: true

module Ace
  module Review
    module Molecules
      # Resolve task references to task directory paths using ace-taskflow
      class TaskResolver
        # Resolve a task reference to its directory path
        # @param task_reference [String] Task reference (e.g., "114", "task.114", "v.0.9.0+114")
        # @return [Hash, nil] Hash with :path, :task_number, :release, or nil if not found
        def self.resolve(task_reference)
          # Try to load ace-taskflow
          begin
            require 'ace/taskflow'
            require 'ace/taskflow/organisms/task_manager'
          rescue LoadError
            return nil
          end

          # Use TaskManager to find the task
          task_manager = Ace::Taskflow::Organisms::TaskManager.new
          task = task_manager.show_task(task_reference)

          return nil unless task

          # Extract task directory from task file path
          task_file_path = task[:path]
          return nil unless task_file_path.to_s.strip != ""

          task_dir = File.dirname(task_file_path)

          {
            path: task_dir,
            task_number: task[:task_number],
            release: task[:release],
            task_id: task[:id]
          }
        rescue Ace::Taskflow::Error => e
          # Handle known ace-taskflow errors
          warn "Warning: Task '#{task_reference}' could not be resolved: #{e.message}"
          nil
        rescue StandardError => e
          # Graceful degradation for unexpected errors
          warn "Warning: Failed to resolve task '#{task_reference}': #{e.class} - #{e.message}"
          warn e.backtrace.join("\n") if $DEBUG
          nil
        end
      end
    end
  end
end
