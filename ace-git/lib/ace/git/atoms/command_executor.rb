# frozen_string_literal: true

require "open3"
require "timeout"

module Ace
  module Git
    module Atoms
      # Pure functions for executing git commands safely
      # Migrated from ace-git-diff
      #
      # Lock Retry Behavior:
      # - Automatically retries git commands that encounter .git/index.lock errors
      # - Uses progressive delays: 1s, 2s, 3s, 4s (total 10s across 4 retries)
      # - On each retry, attempts to clean orphaned locks (dead PID) or stale locks (>10s)
      # - Configurable via lock_retry section in .ace/git/config.yml
      # - Only git commands are retried; non-git commands fail immediately
      #
      # This retry logic prevents "Unable to create .git/index.lock" errors
      # that commonly occur in multi-worktree environments or when operations
      # are interrupted (Ctrl+C, crashes, timeouts).
      module CommandExecutor
        class << self
          # Execute a command safely using array arguments to prevent command injection
          # @param command_parts [Array<String>] Command parts to execute
          # @param timeout [Integer] Timeout in seconds (default from config)
          # @param env [Hash] Optional environment variables to set for the command
          # @return [Hash] Result with output, error, and success status
          def execute(*command_parts, timeout: Ace::Git.git_timeout, env: nil)
            # Check if lock retry is enabled (default: true)
            lock_retry_config = Ace::Git.config["lock_retry"]
            lock_retry_enabled = lock_retry_config.nil? ? true : lock_retry_config["enabled"] != false

            if lock_retry_enabled && !command_parts.empty? && command_parts.first == "git"
              execute_with_lock_retry(command_parts, timeout: timeout, env: env, config: lock_retry_config)
            else
              execute_once(command_parts, timeout: timeout, env: env)
            end
          end

          private

          # Execute command with lock error retry logic
          # @param command_parts [Array<String>] Command parts to execute
          # @param timeout [Integer] Timeout in seconds
          # @param env [Hash] Optional environment variables
          # @param config [Hash] Lock retry configuration
          # @return [Hash] Result with output, error, and success status
          def execute_with_lock_retry(command_parts, timeout:, env:, config:)
            config ||= {}
            # Use fetch to respect zero values (e.g., max_retries: 0 to disable retries)
            max_retries = config.fetch("max_retries", 4)
            stale_cleanup = config.fetch("stale_cleanup", true)
            stale_threshold = config.fetch("stale_threshold_seconds", 10)

            result = nil
            last_lock_info = nil
            repo_root = nil

            (0..max_retries).each do |attempt|
              result = execute_once(command_parts, timeout: timeout, env: env)

              # Success or non-lock error - return immediately
              break if result[:success] || !LockErrorDetector.lock_error_result?(result)

              # Attempt lock cleanup on every retry (checks orphaned PID first, then age)
              if stale_cleanup
                repo_root ||= CommandExecutor.repo_root
                if repo_root
                  clean_result = StaleLockCleaner.clean(repo_root, stale_threshold)
                  last_lock_info = clean_result
                  if clean_result[:cleaned] && (ENV["ACE_DEBUG"] || ENV["DEBUG"])
                    warn "[ace-git] #{clean_result[:message]}"
                  end
                end
              end

              # Sleep before retry (except on last attempt)
              break if attempt == max_retries

              # Progressive delays: 1s, 2s, 3s, 4s (total 10s across 4 retries)
              sleep_seconds = attempt + 1
              pid_note = last_lock_info&.dig(:pid) ? " (PID #{last_lock_info[:pid]})" : ""
              warn "[ace-git] Lock detected#{pid_note}, waiting #{sleep_seconds}s (attempt #{attempt + 1}/#{max_retries + 1})..."
              Kernel.sleep(sleep_seconds)
            end

            # Add retry context to error message if all retries failed
            if !result[:success] && LockErrorDetector.lock_error_result?(result)
              error = "Git index locked after #{max_retries + 1} attempts (#{max_retries} retries). #{result[:error]}"
              if last_lock_info && last_lock_info[:status] == :active && last_lock_info[:pid]
                error += " Active lock held by PID #{last_lock_info[:pid]}."
              end
              result[:error] = error
            end

            result
          end

          # Execute command once without retry logic
          # @param command_parts [Array<String>] Command parts to execute
          # @param timeout [Integer] Timeout in seconds
          # @param env [Hash] Optional environment variables
          # @return [Hash] Result with output, error, and success status
          def execute_once(command_parts, timeout:, env:)
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

          public

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
            result = execute_once(["git", "rev-parse", "--show-toplevel"], timeout: Ace::Git.git_timeout, env: nil)
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
          def changed_files(range = nil)
            range = "origin/main...HEAD" if range.nil? && ref_exists?("origin/main")
            args = ["git", "diff", "--name-only"]
            args << range if range && !range.empty?

            result = execute(*args)
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

          # Check if there are untracked changes
          # @return [Boolean] True if there are untracked files
          def has_untracked_changes?
            result = execute("git", "ls-files", "--others", "--exclude-standard")
            result[:success] && !result[:output].strip.empty?
          end

          # Check whether a git reference exists in the repository.
          #
          # @param ref [String] Git ref to validate
          # @return [Boolean] True if ref resolves, false otherwise
          def ref_exists?(ref)
            return false if ref.nil? || ref.strip.empty?

            result = execute("git", "rev-parse", "--verify", "#{ref}^{}")
            result[:success]
          end
        end
      end
    end
  end
end
