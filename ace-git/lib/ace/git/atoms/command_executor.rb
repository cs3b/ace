# frozen_string_literal: true

require "open3"
require "timeout"

module Ace
  module Git
    module Atoms
      # Pure functions for executing git commands safely
      # Migrated from ace-git-diff
      module CommandExecutor
        class << self
          # Execute a command safely using array arguments to prevent command injection
          # @param command_parts [Array<String>] Command parts to execute
          # @param timeout [Integer] Timeout in seconds (default from config)
          # @param env [Hash] Optional environment variables to set for the command
          # @return [Hash] Result with output, error, and success status
          def execute(*command_parts, timeout: Ace::Git.git_timeout, env: nil)
            # Using Timeout to prevent hanging on network issues or stuck git operations
            Timeout.timeout(timeout) do
              # Using Open3.capture3 to avoid shell injection
              # Arguments are passed directly as array elements, not through shell
              # If env is provided, prepend it to the command (Open3 convention)
              args = env ? [env, *command_parts] : command_parts
              stdout, stderr, status = Open3.capture3(*args)

              {
                success: status.success?,
                output: stdout,
                error: stderr,
                exit_code: status.exitstatus
              }
            end
          rescue Timeout::Error
            {
              success: false,
              output: "",
              error: "Command timed out after #{timeout} seconds: #{command_parts.join(' ')}",
              exit_code: -1
            }
          rescue StandardError => e
            # Log backtrace for debugging when DEBUG environment variable is set
            # This helps diagnose implementation bugs vs command failures
            warn e.backtrace.join("\n") if ENV["DEBUG"]
            {
              success: false,
              output: "",
              error: e.message,
              exit_code: -1
            }
          end

          # Execute git diff command
          # @param args [Array<String>] Arguments to pass to git diff
          # @param raise_on_error [Boolean] If true, raises GitError on failure
          # @return [String] Diff output (empty string if no changes, raises on error if raise_on_error)
          def git_diff(*args, raise_on_error: false)
            result = execute("git", "diff", *args)
            if result[:success]
              result[:output]
            elsif raise_on_error
              raise Ace::Git::GitError, "git diff failed: #{result[:error]}"
            else
              ""
            end
          end

          # Get staged changes
          # @return [String] Diff of staged changes
          def staged_diff
            result = execute("git", "diff", "--cached")
            result[:success] ? result[:output] : ""
          end

          # Get working directory changes
          # @return [String] Diff of working directory changes
          def working_diff
            result = execute("git", "diff")
            result[:success] ? result[:output] : ""
          end

          # Check if we're in a git repository
          # @return [Boolean] True if in a git repository
          def in_git_repo?
            result = execute("git", "rev-parse", "--git-dir")
            result[:success]
          end

          # Get current branch name or commit SHA if detached
          # @return [String, nil] Current branch name, commit SHA (if detached), or nil on error
          def current_branch
            result = execute("git", "rev-parse", "--abbrev-ref", "HEAD")
            return nil unless result[:success]

            branch = result[:output].strip
            return branch unless branch == "HEAD"

            # Detached HEAD - return commit SHA instead
            sha_result = execute("git", "rev-parse", "HEAD")
            sha_result[:success] ? sha_result[:output].strip : nil
          end

          # Get repository root path
          # @return [String, nil] Repository root path or nil on error
          def repo_root
            result = execute("git", "rev-parse", "--show-toplevel")
            result[:success] ? result[:output].strip : nil
          end

          # Get remote tracking branch
          # @return [String, nil] Remote tracking branch or nil
          def tracking_branch
            result = execute("git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
            result[:success] ? result[:output].strip : nil
          end

          # Get list of changed files
          # @param range [String] Git range to check
          # @return [Array<String>] List of changed file paths
          def changed_files(range = "origin/main...HEAD")
            result = execute("git", "diff", "--name-only", range)
            return [] unless result[:success]

            result[:output].split("\n").map(&:strip).reject(&:empty?)
          end

          # Check if there are unstaged changes
          # @return [Boolean] True if there are unstaged changes
          def has_unstaged_changes?
            !working_diff.strip.empty?
          end

          # Check if there are staged changes
          # @return [Boolean] True if there are staged changes
          def has_staged_changes?
            !staged_diff.strip.empty?
          end
        end
      end
    end
  end
end
