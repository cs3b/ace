# frozen_string_literal: true

require "open3"

module Ace
  module Git
    module Worktree
      module Atoms
        # Pure function wrapper for git command execution
        # Delegates to ace-git-diff CommandExecutor when available
        class GitCommand
          DEFAULT_TIMEOUT = 30 # seconds

          # Execute a git command with timeout and error handling
          # @param args [Array<String>] Git command arguments
          # @param options [Hash] Options for command execution
          # @option options [Integer] :timeout Timeout in seconds (default: 30)
          # @option options [String] :chdir Directory to execute command in
          # @return [Hash] Result with :success, :output, :error, :exit_code
          def self.execute(*args, **options)
            timeout = options.delete(:timeout) || DEFAULT_TIMEOUT
            chdir = options.delete(:chdir)

            # Try to use ace-git-diff CommandExecutor if available
            if defined?(Ace::GitDiff::Atoms::CommandExecutor)
              return Ace::GitDiff::Atoms::CommandExecutor.execute("git", *args, **options)
            end

            # Fallback to direct execution
            execute_direct(args, timeout: timeout, chdir: chdir)
          end

          # Check if we're in a git repository
          # @return [Boolean] true if in a git repo
          def self.in_git_repo?
            result = execute("rev-parse", "--git-dir")
            result[:success]
          end

          # Get the current git branch
          # @return [String, nil] Current branch name or nil if not on a branch
          def self.current_branch
            result = execute("rev-parse", "--abbrev-ref", "HEAD")
            result[:success] ? result[:output].strip : nil
          end

          # Get the repository root directory
          # @return [String, nil] Absolute path to repo root or nil
          def self.repo_root
            result = execute("rev-parse", "--show-toplevel")
            result[:success] ? result[:output].strip : nil
          end

          private

          # Direct execution fallback when ace-git-diff is not available
          def self.execute_direct(args, timeout:, chdir: nil)
            cmd_array = ["git", *args]

            stdout, stderr, status = nil
            begin
              Dir.chdir(chdir || Dir.pwd) do
                Timeout.timeout(timeout) do
                  stdout, stderr, status = Open3.capture3(*cmd_array)
                end
              end
            rescue Timeout::Error
              return {
                success: false,
                output: "",
                error: "Command timed out after #{timeout} seconds",
                exit_code: -1
              }
            rescue => e
              return {
                success: false,
                output: "",
                error: "Command failed: #{e.message}",
                exit_code: -1
              }
            end

            {
              success: status.success?,
              output: stdout,
              error: stderr,
              exit_code: status.exitstatus
            }
          end
        end
      end
    end
  end
end