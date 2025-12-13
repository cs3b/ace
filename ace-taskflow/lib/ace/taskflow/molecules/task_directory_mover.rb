# frozen_string_literal: true

require 'fileutils'
require_relative '../configuration'

module Ace
  module Taskflow
    module Molecules
      # Handles atomic move of task directories to _archive/ subdirectory
      class TaskDirectoryMover
        # Move a task directory to _archive/ subdirectory atomically
        # @param task_path [String] Full path to the task file
        # @return [Hash] Result with :success, :new_path, and :message
        def move_to_archive(task_path)
          return { success: false, message: "Task path not provided" } unless task_path
          return { success: false, message: "Task file not found: #{task_path}" } unless File.exist?(task_path)

          # Get task directory (parent of the task file)
          task_dir = File.dirname(task_path)
          task_dir_name = File.basename(task_dir)

          # Determine parent release directory (e.g., .ace-taskflow/v.0.9.0/t)
          parent_dir = File.dirname(task_dir)

          # Get archive directory name from configuration
          archive_dir_name = Ace::Taskflow.configuration.done_dir

          # Check if task is already in archive directory (idempotent operation)
          if task_path.include?("/#{archive_dir_name}/")
            task_filename = File.basename(task_path)
            return {
              success: true,
              new_path: task_path,
              message: "Task already in #{archive_dir_name}/"
            }
          end

          # Create archive directory if it doesn't exist
          archive_dir = File.join(parent_dir, archive_dir_name)
          FileUtils.mkdir_p(archive_dir) unless File.directory?(archive_dir)

          # Target path in archive directory
          target_dir = File.join(archive_dir, task_dir_name)

          # Check if target already exists (idempotent - task already moved)
          if File.exist?(target_dir)
            task_filename = File.basename(task_path)
            new_task_path = File.join(target_dir, task_filename)
            return {
              success: true,
              new_path: new_task_path,
              message: "Task already in #{archive_dir_name}/"
            }
          end

          begin
            # Clean up backup files before moving
            cleanup_backup_files(task_dir)

            # Perform atomic move
            FileUtils.mv(task_dir, target_dir)

            # Calculate new task file path
            task_filename = File.basename(task_path)
            new_task_path = File.join(target_dir, task_filename)

            {
              success: true,
              new_path: new_task_path,
              message: "Task moved to #{archive_dir_name}/"
            }
          rescue StandardError => e
            {
              success: false,
              message: "Failed to move task directory: #{e.message}"
            }
          end
        end

        # Backward compatibility alias for move_to_archive
        # @deprecated Use move_to_archive instead
        def move_to_done(task_path)
          warn "[DEPRECATION] `move_to_done` is deprecated. Use `move_to_archive` instead."
          move_to_archive(task_path)
        end

        # Move a task directory back from _archive/ subdirectory
        # @param task_path [String] Full path to the task file in _archive/
        # @return [Hash] Result with :success, :new_path, and :message
        def restore_from_archive(task_path)
          return { success: false, message: "Task path not provided" } unless task_path
          return { success: false, message: "Task file not found: #{task_path}" } unless File.exist?(task_path)

          # Get archive directory name from configuration
          archive_dir_name = Ace::Taskflow.configuration.done_dir

          # Verify task is in archive directory
          unless task_path.include?("/#{archive_dir_name}/")
            return {
              success: false,
              message: "Task is not in #{archive_dir_name}/ directory"
            }
          end

          # Get task directory and determine restoration path
          task_dir = File.dirname(task_path)
          task_dir_name = File.basename(task_dir)
          archive_dir = File.dirname(task_dir)
          parent_dir = File.dirname(archive_dir)

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
              message: "Task restored from #{Ace::Taskflow.configuration.done_dir}/"
            }
          rescue StandardError => e
            {
              success: false,
              message: "Failed to restore task directory: #{e.message}"
            }
          end
        end

        # Backward compatibility alias for restore_from_archive
        # @deprecated Use restore_from_archive instead
        def restore_from_done(task_path)
          warn "[DEPRECATION] `restore_from_done` is deprecated. Use `restore_from_archive` instead."
          restore_from_archive(task_path)
        end

        # Move a task directory to _deferred/ subdirectory atomically
        # @param task_path [String] Full path to the task file
        # @return [Hash] Result with :success, :new_path, and :message
        def move_to_deferred(task_path)
          return { success: false, message: "Task path not provided" } unless task_path
          return { success: false, message: "Task file not found: #{task_path}" } unless File.exist?(task_path)

          # Get task directory (parent of the task file)
          task_dir = File.dirname(task_path)
          task_dir_name = File.basename(task_dir)

          # Determine parent release directory (e.g., .ace-taskflow/v.0.9.0/t)
          parent_dir = File.dirname(task_dir)

          # Get deferred directory name from configuration
          deferred_dir_name = Ace::Taskflow.configuration.deferred_dir

          # Check if task is already in deferred directory (idempotent operation)
          if task_path.include?("/#{deferred_dir_name}/")
            task_filename = File.basename(task_path)
            return {
              success: true,
              new_path: task_path,
              message: "Task already in #{deferred_dir_name}/"
            }
          end

          # Create deferred directory if it doesn't exist
          deferred_dir = File.join(parent_dir, deferred_dir_name)
          FileUtils.mkdir_p(deferred_dir) unless File.directory?(deferred_dir)

          # Target path in deferred directory
          target_dir = File.join(deferred_dir, task_dir_name)

          # Check if target already exists (idempotent - task already moved)
          if File.exist?(target_dir)
            task_filename = File.basename(task_path)
            new_task_path = File.join(target_dir, task_filename)
            return {
              success: true,
              new_path: new_task_path,
              message: "Task already in #{deferred_dir_name}/"
            }
          end

          begin
            # Clean up backup files before moving
            cleanup_backup_files(task_dir)

            # Perform atomic move
            FileUtils.mv(task_dir, target_dir)

            # Calculate new task file path
            task_filename = File.basename(task_path)
            new_task_path = File.join(target_dir, task_filename)

            {
              success: true,
              new_path: new_task_path,
              message: "Task moved to #{deferred_dir_name}/"
            }
          rescue StandardError => e
            {
              success: false,
              message: "Failed to move task directory: #{e.message}"
            }
          end
        end

        # Move a task directory back from _deferred/ subdirectory
        # @param task_path [String] Full path to the task file in _deferred/
        # @return [Hash] Result with :success, :new_path, and :message
        def restore_from_deferred(task_path)
          return { success: false, message: "Task path not provided" } unless task_path
          return { success: false, message: "Task file not found: #{task_path}" } unless File.exist?(task_path)

          # Get deferred directory name from configuration
          deferred_dir_name = Ace::Taskflow.configuration.deferred_dir

          # Verify task is in deferred directory
          unless task_path.include?("/#{deferred_dir_name}/")
            return {
              success: false,
              message: "Task is not in #{deferred_dir_name}/ directory"
            }
          end

          # Get task directory and determine restoration path
          task_dir = File.dirname(task_path)
          task_dir_name = File.basename(task_dir)
          deferred_dir = File.dirname(task_dir)
          parent_dir = File.dirname(deferred_dir)

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
              message: "Task restored from #{Ace::Taskflow.configuration.deferred_dir}/"
            }
          rescue StandardError => e
            {
              success: false,
              message: "Failed to restore task directory: #{e.message}"
            }
          end
        end

        private

        # Remove backup files from a directory before moving to _archive/
        # @param dir_path [String] Path to the directory to clean
        def cleanup_backup_files(dir_path)
          return unless File.directory?(dir_path)

          # Find and remove all .backup.* files recursively
          Dir.glob(File.join(dir_path, "**", "*.backup.*")).each do |backup_file|
            File.delete(backup_file) if File.file?(backup_file)
          end
        end
      end
    end
  end
end