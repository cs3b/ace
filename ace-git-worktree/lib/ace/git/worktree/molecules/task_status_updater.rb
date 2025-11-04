# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Molecules
        # Updates task status via ace-taskflow
        class TaskStatusUpdater
          # Update task status to in-progress
          # @param task_id [String] Task ID or reference
          # @return [Hash] Result with :success, :output, :error
          def self.mark_in_progress(task_id)
            return error_result("Task ID cannot be empty") if task_id.nil? || task_id.empty?

            # Use ace-taskflow task start command
            result = execute_taskflow("task", "start", task_id)

            if result[:success]
              {
                success: true,
                output: result[:output]
              }
            else
              # Try alternative approach - update command
              update_result = execute_taskflow("task", "update", task_id, "--field", "status=in-progress")

              if update_result[:success]
                {
                  success: true,
                  output: update_result[:output]
                }
              else
                error_result("Failed to update task status: #{result[:error]}")
              end
            end
          end

          # Update task with worktree metadata
          # @param task_id [String] Task ID
          # @param metadata [Models::WorktreeMetadata] Worktree metadata to add
          # @return [Hash] Result with :success, :output, :error
          def self.add_worktree_metadata(task_id, metadata)
            return error_result("Task ID cannot be empty") if task_id.nil? || task_id.empty?
            return error_result("Metadata cannot be nil") if metadata.nil?

            # Use ace-taskflow task update command to add nested fields
            # Format: --field worktree.branch=value --field worktree.path=value
            update_args = ["task", "update", task_id]
            update_args << "--field" << "worktree.branch=#{metadata.branch}"
            update_args << "--field" << "worktree.path=#{metadata.path}"
            update_args << "--field" << "worktree.created_at=#{metadata.created_at}"

            result = execute_taskflow(*update_args)

            if result[:success]
              {
                success: true,
                output: result[:output]
              }
            else
              error_result("Failed to add worktree metadata: #{result[:error]}")
            end
          end

          # Remove worktree metadata from task
          # @param task_id [String] Task ID
          # @return [Hash] Result with :success, :output, :error
          def self.remove_worktree_metadata(task_id)
            return error_result("Task ID cannot be empty") if task_id.nil? || task_id.empty?

            # Remove the entire worktree section
            result = execute_taskflow("task", "update", task_id, "--remove-field", "worktree")

            if result[:success]
              {
                success: true,
                output: result[:output]
              }
            else
              # If remove-field not supported, try setting to empty
              clear_result = execute_taskflow("task", "update", task_id,
                                             "--field", "worktree.branch=",
                                             "--field", "worktree.path=",
                                             "--field", "worktree.created_at=")
              if clear_result[:success]
                {
                  success: true,
                  output: clear_result[:output]
                }
              else
                error_result("Failed to remove worktree metadata: #{result[:error]}")
              end
            end
          end

          # Mark task as done
          # @param task_id [String] Task ID
          # @return [Hash] Result with :success, :output, :error
          def self.mark_done(task_id)
            return error_result("Task ID cannot be empty") if task_id.nil? || task_id.empty?

            result = execute_taskflow("task", "done", task_id)

            if result[:success]
              {
                success: true,
                output: result[:output]
              }
            else
              error_result("Failed to mark task as done: #{result[:error]}")
            end
          end

          private

          def self.error_result(message)
            {
              success: false,
              error: message
            }
          end

          def self.execute_taskflow(*args)
            require 'open3'

            cmd_array = ["ace-taskflow", *args]

            begin
              stdout, stderr, status = Open3.capture3(*cmd_array)
              {
                success: status.success?,
                output: stdout,
                error: stderr,
                exit_code: status.exitstatus
              }
            rescue Errno::ENOENT
              {
                success: false,
                output: "",
                error: "ace-taskflow command not found. Please install the ace-taskflow gem.",
                exit_code: 127
              }
            rescue => e
              {
                success: false,
                output: "",
                error: "Failed to execute ace-taskflow: #{e.message}",
                exit_code: -1
              }
            end
          end
        end
      end
    end
  end
end