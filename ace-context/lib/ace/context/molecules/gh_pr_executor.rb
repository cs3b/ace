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
          stdout, stderr, status = Timeout.timeout(@timeout) do
            execute_gh_command(args)
          end

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
        rescue Timeout::Error
          raise TimeoutError, "gh pr diff timed out after #{@timeout}s for #{@parsed.gh_format}"
        end

        protected

        # Execute gh command - can be overridden in tests for mocking
        #
        # Uses LC_ALL=C to ensure consistent English error messages across locales
        # for reliable error detection.
        #
        # @param args [Array<String>] Command arguments
        # @return [Array] stdout, stderr, status
        def execute_gh_command(args)
          Open3.capture3({ "LC_ALL" => "C" }, *args)
        end

        private

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

          # Error detection based on gh CLI stderr output.
          # Verified against gh version 2.x (tested with 2.40+). Error message patterns
          # may change in future versions - update regex patterns if gh output changes.
          if error_message.match?(/not found|Could not resolve/i)
            raise PrNotFoundError, "PR not found: #{@parsed.gh_format}"
          elsif error_message.match?(/authentication|Unauthorized|not logged in|auth login/i)
            raise GhAuthenticationError, "Not authenticated with GitHub. Run: gh auth login"
          else
            raise GhCommandError, "gh pr diff failed (exit #{status.exitstatus}): #{error_message}"
          end
        end
      end
    end
  end
end
