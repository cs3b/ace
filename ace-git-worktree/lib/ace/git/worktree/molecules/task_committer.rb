# frozen_string_literal: true

require_relative "../atoms/git_command"

module Ace
  module Git
    module Worktree
      module Molecules
        # Commits task changes using ace-git-commit or git directly
        class TaskCommitter
          # Commit task changes
          # @param task_metadata [Models::TaskMetadata] Task being worked on
          # @param message [String] Commit message (uses template if not provided)
          # @param options [Hash] Options
          # @return [Hash] Result with :success, :output, :error
          def self.commit_task_changes(task_metadata, message = nil, options = {})
            return error_result("Task metadata cannot be nil") if task_metadata.nil?

            # Generate commit message from template if not provided
            if message.nil? || message.empty?
              config = options[:config] || Worktree.configuration
              template = config.commit_message_format || "chore(task-{id}): mark as in-progress, creating worktree"
              message = format_message(template, task_metadata)
            end

            # Get task file path
            task_file = task_metadata.path
            if task_file.nil? || task_file.empty?
              # Try to construct path from task ID
              task_file = find_task_file(task_metadata.id)
              return error_result("Cannot find task file for #{task_metadata.id}") unless task_file
            end

            # Stage the task file
            stage_result = stage_file(task_file)
            return stage_result unless stage_result[:success]

            # Try to use ace-git-commit if available
            if ace_git_commit_available?
              commit_with_ace_git_commit(message)
            else
              # Fallback to direct git commit
              commit_with_git(message)
            end
          end

          # Check if there are changes to commit
          # @return [Boolean] true if there are staged changes
          def self.has_staged_changes?
            result = Atoms::GitCommand.execute("diff", "--cached", "--quiet")
            # git diff --cached --quiet returns 1 if there are changes
            !result[:success]
          end

          # Stage a specific file
          # @param file_path [String] File to stage
          # @return [Hash] Result
          def self.stage_file(file_path)
            return error_result("File path cannot be empty") if file_path.nil? || file_path.empty?

            result = Atoms::GitCommand.execute("add", file_path)

            if result[:success]
              {
                success: true,
                output: "Staged: #{file_path}"
              }
            else
              error_result("Failed to stage file: #{result[:error]}")
            end
          end

          private

          def self.error_result(message)
            {
              success: false,
              error: message
            }
          end

          # Format commit message from template
          def self.format_message(template, task_metadata)
            variables = task_metadata.template_variables
            message = template.dup

            variables.each do |key, value|
              message.gsub!("{#{key}}", value.to_s)
            end

            message
          end

          # Find task file from task ID
          def self.find_task_file(task_id)
            # Try to find task file using ace-taskflow
            result = execute_command(["ace-taskflow", "task", task_id, "--path"])
            if result[:success]
              path = result[:output].strip
              return path unless path.empty?
            end

            # Fallback to searching for the file
            # This is a simplified approach - in production would be more robust
            Dir.glob(".ace-taskflow/**/task.*.md").find do |file|
              file.include?(task_id.to_s)
            end
          end

          # Check if ace-git-commit is available
          def self.ace_git_commit_available?
            result = execute_command(["ace-git-commit", "--version"])
            result[:success]
          end

          # Commit using ace-git-commit
          def self.commit_with_ace_git_commit(message)
            # ace-git-commit handles the commit with proper formatting
            result = execute_command(["ace-git-commit", "--message", message, "--no-llm"])

            if result[:success]
              {
                success: true,
                output: result[:output]
              }
            else
              error_result("ace-git-commit failed: #{result[:error]}")
            end
          end

          # Commit using git directly
          def self.commit_with_git(message)
            result = Atoms::GitCommand.execute("commit", "-m", message)

            if result[:success]
              {
                success: true,
                output: result[:output]
              }
            else
              error_result("git commit failed: #{result[:error]}")
            end
          end

          # Execute external command
          def self.execute_command(cmd_array)
            require 'open3'

            begin
              stdout, stderr, status = Open3.capture3(*cmd_array)
              {
                success: status.success?,
                output: stdout,
                error: stderr
              }
            rescue Errno::ENOENT
              {
                success: false,
                output: "",
                error: "Command not found: #{cmd_array.first}"
              }
            rescue => e
              {
                success: false,
                output: "",
                error: e.message
              }
            end
          end
        end
      end
    end
  end
end