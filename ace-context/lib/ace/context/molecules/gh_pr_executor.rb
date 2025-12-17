# frozen_string_literal: true

require "open3"
require "timeout"
require_relative "../atoms/pr_identifier_parser"

module Ace
  module Context
    module Molecules
      # Execute gh CLI commands to fetch PR diffs
      class GhPrExecutor
        # Default timeout for gh commands (30 seconds)
        DEFAULT_TIMEOUT = 30

        # Error raised when gh CLI command fails
        class GhCommandError < StandardError; end

        # Error raised when gh is not installed
        class GhNotInstalledError < StandardError; end

        # Error raised when authentication fails
        class GhAuthenticationError < StandardError; end

        # Error raised when PR is not found
        class PrNotFoundError < StandardError; end

        # Error raised when command times out
        class TimeoutError < StandardError; end

        # Error message patterns from gh CLI (tested with gh 2.40+)
        # Update if gh CLI changes error message format in future versions
        PR_NOT_FOUND_PATTERN = /not found|Could not resolve/i
        AUTH_ERROR_PATTERN = /authentication|Unauthorized|not logged in|auth login/i

        def initialize(identifier, timeout: DEFAULT_TIMEOUT)
          @identifier = identifier
          @timeout = timeout
          @parsed = Atoms::PrIdentifierParser.parse(identifier)
        end

        # Fetch PR diff content
        #
        # @return [Hash] Result with :success, :diff, :error keys
        # @raise [TimeoutError] if command takes longer than timeout
        def fetch_diff
          raise ArgumentError, "Invalid PR identifier: #{@identifier}" if @parsed.nil?

          args = build_gh_command
          stdout, stderr, status = execute_with_timeout(args, @timeout)

          if status.success?
            {
              success: true,
              diff: stdout,
              identifier: @parsed.gh_format,
              source: build_source_label
            }
          else
            handle_error(stderr, status)
          end
        rescue Errno::ENOENT
          raise GhNotInstalledError, "GitHub CLI (gh) not installed. Install with: brew install gh"
        end

        protected

        # Execute command with timeout and proper process cleanup
        #
        # Uses Open3.popen3 with PID tracking to ensure child processes are
        # terminated on timeout, preventing orphaned processes.
        #
        # @param args [Array<String>] Command arguments
        # @param timeout_seconds [Integer] Timeout in seconds
        # @return [Array] stdout, stderr, status
        # @raise [TimeoutError] if command exceeds timeout
        def execute_with_timeout(args, timeout_seconds)
          pid = nil
          stdout_str = ""
          stderr_str = ""
          status = nil

          begin
            Timeout.timeout(timeout_seconds) do
              stdout_str, stderr_str, status, pid = run_command(args)
            end
          rescue Timeout::Error
            # Ensure child process is terminated on timeout
            terminate_process(pid) if pid
            raise TimeoutError, "gh pr diff timed out after #{timeout_seconds}s for #{@parsed.gh_format}"
          end

          [stdout_str, stderr_str, status]
        end

        # Run command and return output - can be overridden in tests for mocking
        #
        # Uses Open3.popen3 with PID tracking for proper process cleanup on timeout.
        # Uses LC_ALL=C to ensure consistent English error messages across locales
        # for reliable error detection.
        #
        # @param args [Array<String>] Command arguments
        # @return [Array] [stdout, stderr, status, pid]
        def run_command(args)
          stdout_str = ""
          stderr_str = ""
          status = nil
          pid = nil

          Open3.popen3({ "LC_ALL" => "C" }, *args) do |_stdin, stdout, stderr, wait_thr|
            pid = wait_thr.pid
            stdout_str = stdout.read
            stderr_str = stderr.read
            status = wait_thr.value
          end

          [stdout_str, stderr_str, status, pid]
        end

        private

        # Terminate a process gracefully, then forcefully if needed
        # @param pid [Integer] Process ID to terminate
        def terminate_process(pid)
          return unless pid

          begin
            # Try graceful termination first (SIGTERM)
            Process.kill("TERM", pid)
            # Give it a moment to terminate
            sleep(0.1)
            # Check if still running and force kill if needed
            Process.kill(0, pid) # Check if process exists
            Process.kill("KILL", pid)
          rescue Errno::ESRCH, Errno::EPERM
            # Process already terminated or we don't have permission - that's fine
          end
        end

        def build_gh_command
          args = ["gh", "pr", "diff", @parsed.gh_format]
          args
        end

        def build_source_label
          if @parsed.repo
            "pr:#{@parsed.repo}##{@parsed.number}"
          else
            "pr:#{@parsed.number}"
          end
        end

        def handle_error(stderr, status)
          error_message = stderr.to_s

          if error_message.match?(PR_NOT_FOUND_PATTERN)
            raise PrNotFoundError, "PR not found: #{@parsed.gh_format}"
          elsif error_message.match?(AUTH_ERROR_PATTERN)
            raise GhAuthenticationError, "Not authenticated with GitHub. Run: gh auth login"
          else
            raise GhCommandError, "gh pr diff failed (exit #{status.exitstatus}): #{error_message}"
          end
        end
      end
    end
  end
end
