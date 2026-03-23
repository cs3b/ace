# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Molecules
        # Task committer molecule
        #
        # Commits task file changes using ace-git-commit or direct git commands.
        # Provides automatic commit message generation and handles commit operations.
        #
        # @example Commit task changes with automatic message
        #   committer = TaskCommitter.new
        #   success = committer.commit_task_changes(["task.081.md"], "in-progress")
        #
        # @example Commit with custom message
        #   success = committer.commit_with_message(["task.081.md"], "Custom commit message")
        class TaskCommitter
          # Fallback timeout for git commands
          # Used only when config is unavailable
          FALLBACK_TIMEOUT = 30

          # Initialize a new TaskCommitter
          #
          # @param timeout [Integer, nil] Command timeout in seconds (uses config default if nil)
          # @param use_ace_git_commit [Boolean] Whether to use ace-git-commit if available
          def initialize(timeout: nil, use_ace_git_commit: true)
            @timeout = timeout || config_timeout
            @use_ace_git_commit = use_ace_git_commit
          end

          private

          # Get timeout from config or fallback
          # @return [Integer] Timeout in seconds
          def config_timeout
            Ace::Git::Worktree.commit_timeout
          rescue
            FALLBACK_TIMEOUT
          end

          public

          # Commit task changes with automatic message generation
          #
          # @param files [Array<String>] Files to commit
          # @param status [String] Task status (for message generation)
          # @param task_id [String, nil] Task ID (for message generation)
          # @return [Boolean] true if commit was successful
          #
          # @example
          #   committer = TaskCommitter.new
          #   success = committer.commit_task_changes(["task.081.md"], "in-progress", "081")
          def commit_task_changes(files, status, task_id = nil)
            return false if files.nil? || files.empty?
            return false if status.nil? || status.empty?

            # Generate commit message
            message = generate_commit_message(status, task_id)

            commit_with_message(files, message)
          end

          # Commit files with a specific message
          #
          # @param files [Array<String>] Files to commit
          # @param message [String] Commit message
          # @return [Boolean] true if commit was successful
          #
          # @example
          #   success = committer.commit_with_message(["task.081.md"], "Update task metadata")
          def commit_with_message(files, message)
            return false if files.nil? || files.empty?
            return false if message.nil? || message.empty?

            # Filter to only existing files
            existing_files = Array(files).select { |file| File.exist?(file) }
            return false if existing_files.empty?

            # Try ace-git-commit first if enabled
            if @use_ace_git_commit && ace_git_commit_available?
              return commit_with_ace_git_commit(existing_files, message)
            end

            # Fallback to direct git commands
            commit_with_git(existing_files, message)
          end

          # Commit all changes with automatic message
          #
          # @param status [String] Task status
          # @param task_id [String, nil] Task ID
          # @return [Boolean] true if commit was successful
          #
          # @example
          #   success = committer.commit_all_changes("in-progress", "081")
          def commit_all_changes(status, task_id = nil)
            # Only attempt commit if there are actually changes to commit
            unless has_uncommitted_changes?
              puts "No changes to commit" if ENV["DEBUG"]
              return true
            end

            message = generate_commit_message(status, task_id)
            commit_all_with_message(message)
          end

          # Commit all changes with specific message
          #
          # @param message [String] Commit message
          # @return [Boolean] true if commit was successful
          #
          # @example
          #   success = committer.commit_all_with_message("Update all task files")
          def commit_all_with_message(message)
            return false if message.nil? || message.empty?

            # Try ace-git-commit first if enabled
            if @use_ace_git_commit && ace_git_commit_available?
              return commit_all_with_ace_git_commit(message)
            end

            # Fallback to direct git commands
            commit_all_with_git(message)
          end

          # Check if there are uncommitted changes
          #
          # @param files [Array<String>, nil] Specific files to check (nil for all)
          # @return [Boolean] true if there are uncommitted changes
          #
          # @example
          #   has_changes = committer.has_uncommitted_changes?
          #   has_changes = committer.has_uncommitted_changes?(["task.081.md"])
          def has_uncommitted_changes?(files = nil)
            if files.nil? || files.empty?
              # Check all changes
              result = execute_git_command("status", "--porcelain")
              result[:success] && !result[:output].strip.empty?
            else
              # Check specific files
              files.any? do |file|
                next false unless File.exist?(file)

                result = execute_git_command("diff", "--quiet", file)
                !result[:success]
              end
            end
          end

          # Get status of files
          #
          # @param files [Array<String>] Files to check
          # @return [Hash] Status information
          #
          # @example
          #   status = committer.get_file_status(["task.081.md"])
          #   status["task.081.md"] # => "modified"
          def get_file_status(files)
            status = {}

            Array(files).each do |file|
              next unless File.exist?(file)

              result = execute_git_command("status", "--porcelain", file)
              if result[:success]
                line = result[:output].strip
                if line.empty?
                  status[file] = "unmodified"
                else
                  # Parse git status output format
                  status_code = line[0, 2]
                  status[file] = parse_status_code(status_code)
                end
              else
                status[file] = "error"
              end
            end

            status
          end

          # Check if ace-git-commit is available
          #
          # @return [Boolean] true if ace-git-commit command is available
          def ace_git_commit_available?
            return @ace_git_commit_available if defined?(@ace_git_commit_available)

            result = execute_command("ace-git-commit", "--version", timeout: 5)
            @ace_git_commit_available = result[:success]
          end

          private

          # Generate a commit message based on status and task ID
          #
          # @param status [String] Task status
          # @param task_id [String, nil] Task ID
          # @return [String] Generated commit message
          def generate_commit_message(status, task_id = nil)
            if task_id
              "chore(task-#{task_id}): mark as #{status}"
            else
              "chore(tasks): update task status to #{status}"
            end
          end

          # Commit using ace-git-commit
          #
          # @param files [Array<String>] Files to commit
          # @param message [String] Commit message
          # @return [Boolean] true if commit was successful
          def commit_with_ace_git_commit(files, message)
            result = execute_command("ace-git-commit", "-m", message, *files, timeout: @timeout)
            result[:success]
          end

          # Commit all changes using ace-git-commit
          #
          # @param message [String] Commit message
          # @return [Boolean] true if commit was successful
          def commit_all_with_ace_git_commit(message)
            result = execute_command("ace-git-commit", "-m", message, timeout: @timeout)
            result[:success]
          end

          # Commit using direct git commands
          #
          # @param files [Array<String>] Files to commit
          # @param message [String] Commit message
          # @return [Boolean] true if commit was successful
          def commit_with_git(files, message)
            # Stage the files
            add_result = execute_git_command("add", *files)
            return false unless add_result[:success]

            # Commit
            commit_result = execute_git_command("commit", "-m", message)
            commit_result[:success]
          end

          # Commit all changes using direct git commands
          #
          # @param message [String] Commit message
          # @return [Boolean] true if commit was successful
          def commit_all_with_git(message)
            # Stage all changes
            add_result = execute_git_command("add", ".")
            return false unless add_result[:success]

            # Commit
            commit_result = execute_git_command("commit", "-m", message)
            commit_result[:success]
          end

          # Execute git command using ace-git if available
          #
          # @param args [Array<String>] Command arguments
          # @return [Hash] Result with :success, :output, :error, :exit_code
          def execute_git_command(*args)
            require_relative "../atoms/git_command"
            Atoms::GitCommand.execute(*args, timeout: @timeout)
          rescue LoadError
            # Fallback to direct git execution
            execute_command("git", *args, timeout: @timeout)
          end

          # Execute a command safely
          #
          # @param command [String] Command to execute
          # @param args [Array<String>] Command arguments
          # @param timeout [Integer] Command timeout
          # @return [Hash] Result with :success, :output, :error, :exit_code
          def execute_command(command, *args, timeout: FALLBACK_TIMEOUT)
            require "open3"

            full_command = [command] + args

            stdout, stderr, status = Open3.capture3(*full_command, timeout: timeout)

            {
              success: status.success?,
              output: stdout.to_s,
              error: stderr.to_s,
              exit_code: status.exitstatus
            }
          rescue Open3::CommandTimeout
            {
              success: false,
              output: "",
              error: "Command timed out after #{timeout} seconds",
              exit_code: 124
            }
          rescue => e
            {
              success: false,
              output: "",
              error: "Command execution failed: #{e.message}",
              exit_code: 1
            }
          end

          # Parse git status code to human-readable status
          #
          # @param status_code [String] Two-character status code from git
          # @return [String] Human-readable status
          def parse_status_code(status_code)
            case status_code
            when " M"
              "modified"
            when "A "
              "added"
            when "D "
              "deleted"
            when "R "
              "renamed"
            when "C "
              "copied"
            when "??"
              "untracked"
            else
              "unknown"
            end
          end
        end
      end
    end
  end
end
