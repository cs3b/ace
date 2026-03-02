# frozen_string_literal: true

module Ace
  module Review
    module Molecules
      # Resolve task references to task directory paths using ace-task
      class TaskResolver
        # Resolve a task reference to its directory path
        # @param task_reference [String] Task reference (e.g., "114", "task.114", "8pp.t.q7w")
        # @return [Hash, nil] Hash with :path, :task_id, or nil if not found
        def self.resolve(task_reference)
          # Try to load ace-task
          begin
            require 'ace/task'
            require 'ace/task/organisms/task_manager'
          rescue LoadError
            return nil
          end

          # Use TaskManager to find the task
          task_manager = Ace::Task::Organisms::TaskManager.new
          task = task_manager.show(task_reference)

          return nil unless task

          # Extract task directory from task object
          task_dir = task.path
          return nil unless task_dir.to_s.strip != ""

          {
            path: task_dir,
            spec_path: task.file_path,
            task_id: task.id
          }
        rescue Ace::Task::Error => e
          # Handle known ace-task errors
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
