# frozen_string_literal: true

require 'fileutils'

module Ace
  module Taskflow
    module Molecules
      # Handles atomic move of task directories to done/ subdirectory
      class TaskDirectoryMover
        # Move a task directory to done/ subdirectory atomically
        # @param task_path [String] Full path to the task file
        # @return [Hash] Result with :success, :new_path, and :message
        def move_to_done(task_path)
          return { success: false, message: "Task path not provided" } unless task_path
          return { success: false, message: "Task file not found: #{task_path}" } unless File.exist?(task_path)

          # Get task directory (parent of the task file)
          task_dir = File.dirname(task_path)
          task_dir_name = File.basename(task_dir)

          # Determine parent context directory (e.g., .ace-taskflow/v.0.9.0/t)
          parent_dir = File.dirname(task_dir)

          # Create done directory if it doesn't exist
          done_dir = File.join(parent_dir, "done")
          FileUtils.mkdir_p(done_dir) unless File.directory?(done_dir)

          # Target path in done directory
          target_dir = File.join(done_dir, task_dir_name)

          # Check if target already exists
          if File.exist?(target_dir)
            return {
              success: false,
              message: "Target already exists in done/: #{target_dir}"
            }
          end

          begin
            # Perform atomic move
            FileUtils.mv(task_dir, target_dir)

            # Calculate new task file path
            task_filename = File.basename(task_path)
            new_task_path = File.join(target_dir, task_filename)

            {
              success: true,
              new_path: new_task_path,
              message: "Task moved to done/"
            }
          rescue StandardError => e
            {
              success: false,
              message: "Failed to move task directory: #{e.message}"
            }
          end
        end

        # Move a task directory back from done/ subdirectory
        # @param task_path [String] Full path to the task file in done/
        # @return [Hash] Result with :success, :new_path, and :message
        def restore_from_done(task_path)
          return { success: false, message: "Task path not provided" } unless task_path
          return { success: false, message: "Task file not found: #{task_path}" } unless File.exist?(task_path)

          # Verify task is in done/ directory
          unless task_path.include?("/done/")
            return {
              success: false,
              message: "Task is not in done/ directory"
            }
          end

          # Get task directory and determine restoration path
          task_dir = File.dirname(task_path)
          task_dir_name = File.basename(task_dir)
          done_dir = File.dirname(task_dir)
          parent_dir = File.dirname(done_dir)

          # Target path in parent directory
          target_dir = File.join(parent_dir, task_dir_name)

          # Check if target already exists
          if File.exist?(target_dir)
            return {
              success: false,
              message: "Target already exists: #{target_dir}"
            }
          end

          begin
            # Perform atomic move
            FileUtils.mv(task_dir, target_dir)

            # Calculate new task file path
            task_filename = File.basename(task_path)
            new_task_path = File.join(target_dir, task_filename)

            {
              success: true,
              new_path: new_task_path,
              message: "Task restored from done/"
            }
          rescue StandardError => e
            {
              success: false,
              message: "Failed to restore task directory: #{e.message}"
            }
          end
        end
      end
    end
  end
end