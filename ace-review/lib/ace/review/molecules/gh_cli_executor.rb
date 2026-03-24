# frozen_string_literal: true

require "open3"
require "timeout"

module Ace
  module Review
    module Molecules
      # Safely execute gh CLI commands with error handling
      class GhCliExecutor
        # Default timeout for gh CLI operations
        DEFAULT_GH_TIMEOUT = 30

        # Execute a gh CLI command
        #
        # @param subcommand [String] The gh subcommand (e.g., "pr", "api")
        # @param args [Array<String>] Arguments to pass to the subcommand
        # @param options [Hash] Additional options
        # @option options [Integer] :timeout Timeout in seconds (default: from config or 30)
        # @return [Hash] Result with :success, :stdout, :stderr, :exit_code
        def self.execute(subcommand, args = [], options = {})
          check_installed

          timeout_seconds = options[:timeout] ||
            Ace::Review.get("defaults", "gh_timeout") ||
            DEFAULT_GH_TIMEOUT
          command = ["gh", subcommand] + args

          run_command(command, timeout_seconds)
        rescue Timeout::Error
          raise Ace::Review::Errors::GhNetworkError, "gh command timed out after #{timeout_seconds} seconds"
        end

        # Check if gh CLI is installed
        #
        # @return [Boolean] true if installed
        # @raise [GhCliNotInstalledError] if not installed
        def self.check_installed
          result = execute_simple("--version")
          result[:success]
        rescue Ace::Review::Errors::GhCliNotInstalledError
          raise
        end

        # Check if user is authenticated with GitHub
        #
        # @return [Hash] Auth status with :authenticated, :username
        # @raise [GhAuthenticationError] if not authenticated
        def self.check_authenticated
          result = execute_simple("auth", ["status"])

          if result[:success]
            # Extract username from stderr (gh auth status outputs to stderr)
            username = extract_username(result[:stderr])
            {
              authenticated: true,
              username: username
            }
          else
            raise Ace::Review::Errors::GhAuthenticationError
          end
        end

        # Default timeout for simple operations
        DEFAULT_SIMPLE_TIMEOUT = 10

        # Execute a simple gh command without error checking
        # Used internally to avoid infinite recursion in check_installed
        #
        # @param command [String] The gh subcommand
        # @param args [Array<String>] Arguments
        # @param timeout_seconds [Integer] Timeout in seconds (default: from config or 10)
        # @return [Hash] Result hash
        def self.execute_simple(command, args = [], timeout_seconds = nil)
          timeout_seconds ||= Ace::Review.get("defaults", "gh_simple_timeout") || DEFAULT_SIMPLE_TIMEOUT
          cmd = ["gh", command] + args
          run_command(cmd, timeout_seconds)
        rescue Timeout::Error
          {
            success: false,
            stdout: "",
            stderr: "Command timed out",
            exit_code: 1
          }
        end

        # Extract username from gh auth status output
        #
        # @param output [String] Output from gh auth status
        # @return [String, nil] Username if found
        def self.extract_username(output)
          # gh auth status output format: "✓ Logged in to github.com as username ..."
          match = output.match(/Logged in to .+ as (\S+)/)
          match ? match[1] : nil
        end

        # Execute a command with timeout and error handling
        # Private helper to reduce duplication between execute and execute_simple
        #
        # @param command [Array<String>] Full command array including "gh"
        # @param timeout_seconds [Integer] Timeout in seconds
        # @return [Hash] Result with :success, :stdout, :stderr, :exit_code
        # @raise [GhCliNotInstalledError] if gh is not installed
        # @raise [Timeout::Error] if command times out (caller should handle)
        def self.run_command(command, timeout_seconds)
          stdout_str, stderr_str, status = Timeout.timeout(timeout_seconds) do
            Open3.capture3(*command)
          end

          {
            success: status.success?,
            stdout: stdout_str,
            stderr: stderr_str,
            exit_code: status.exitstatus
          }
        rescue Errno::ENOENT
          raise Ace::Review::Errors::GhCliNotInstalledError
        end

        private_class_method :execute_simple, :extract_username, :run_command
      end
    end
  end
end
