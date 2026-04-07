# frozen_string_literal: true

require "open3"
require "timeout"

module Ace
  module Git
    module Molecules
      # Safely execute gh CLI commands with timeout and structured output.
      class GhCliExecutor
        DEFAULT_GH_TIMEOUT = 30
        DEFAULT_SIMPLE_TIMEOUT = 10

        def self.execute(subcommand, args = [], timeout: nil)
          check_installed
          timeout_seconds = timeout || Ace::Git.network_timeout || DEFAULT_GH_TIMEOUT
          command = ["gh", subcommand] + args
          run_command(command, timeout_seconds)
        rescue Timeout::Error
          raise Ace::Git::TimeoutError, "gh command timed out after #{timeout_seconds} seconds"
        end

        def self.check_installed
          result = execute_simple("--version")
          raise Ace::Git::GhNotInstalledError unless result[:success]

          true
        end

        def self.check_authenticated
          result = execute_simple("auth", ["status"])
          raise Ace::Git::GhAuthenticationError unless result[:success]

          {
            authenticated: true,
            username: extract_username(result[:stderr])
          }
        end

        def self.execute_simple(command, args = [], timeout_seconds = nil)
          timeout_seconds ||= Ace::Git.network_timeout || DEFAULT_SIMPLE_TIMEOUT
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

        def self.extract_username(output)
          match = output.match(/Logged in to .+ as (\S+)/)
          match ? match[1] : nil
        end

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
          raise Ace::Git::GhNotInstalledError
        end

        private_class_method :execute_simple, :extract_username, :run_command
      end
    end
  end
end
