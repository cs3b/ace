# frozen_string_literal: true

require "open3"
require "timeout"

module Ace
  module Git
    module Github
      # Executes the GitHub CLI (`gh`) with timeout and structured output.
      #
      # Owns every `gh` subprocess invocation for ACE: presence probes, auth
      # probes, and arbitrary `gh` subcommands. Failures are classified with
      # the shared provider taxonomy. A test runner may be injected instead of
      # spawning real processes (see Providers::Base).
      module CliExecutor
        DEFAULT_TIMEOUT = 30
        DEFAULT_SIMPLE_TIMEOUT = 10
        BINARY = "gh"

        class << self
          # Execute a `gh` subcommand with timeout and structured output.
          #
          # @param subcommand [String] gh subcommand path (e.g. "pr")
          # @param args [Array<String>] remaining arguments
          # @param timeout [Integer, nil] seconds before the call times out
          # @param runner [Proc, nil] injectable command runner for tests;
          #   receives kwargs (args:, timeout:, env:), returns result hash
          # @return [Hash] {success:, stdout:, stderr:, exit_code:}
          # @raise [Ace::Git::ProviderCliMissingError] when `gh` is missing
          # @raise [Ace::Git::ProviderUnreachableError] when the call times out
          def execute(subcommand, args = [], timeout: nil, runner: nil)
            timeout_seconds = timeout || Ace::Git.network_timeout || DEFAULT_TIMEOUT
            result = run_command([BINARY, subcommand] + args, timeout_seconds, runner)
            if result == :timeout
              raise Ace::Git::ProviderUnreachableError,
                "gh command timed out after #{timeout_seconds} seconds: #{([subcommand] + args).join(" ")}"
            end

            result
          end

          # Probe whether the `gh` binary is installed and runnable.
          #
          # @param runner [Proc, nil] injectable command runner for tests
          # @return [Boolean]
          def installed?(runner: nil)
            result = execute_simple(["--version"], runner: runner)
            result != :timeout && result[:success]
          end

          # Probe whether `gh` is authenticated for the current host.
          #
          # @param runner [Proc, nil] injectable command runner for tests
          # @return [Boolean]
          def authenticated?(runner: nil)
            result = execute_simple(["auth", "status"], runner: runner)
            result != :timeout && result[:success]
          end

          # @raise [Ace::Git::ProviderCliMissingError] when `gh` is missing
          def check_installed!(runner: nil)
            return true if installed?(runner: runner)

            raise Ace::Git::ProviderCliMissingError,
              "GitHub CLI (gh) is not installed or not runnable; install the GitHub CLI and retry"
          end

          # @raise [Ace::Git::ProviderAuthenticationError] when unauthenticated
          def check_authenticated!(runner: nil)
            return true if authenticated?(runner: runner)

            raise Ace::Git::ProviderAuthenticationError,
              "GitHub CLI (gh) is not authenticated; run: gh auth login"
          end

          # Run a full argument vector against `gh`.
          #
          # @return [Hash] result hash, or :timeout sentinel on timeout
          def run_command(command, timeout_seconds, runner = nil)
            if runner
              call_runner(runner, command, timeout_seconds)
            else
              spawn_with_timeout(command, timeout_seconds)
            end
          end

          def execute_simple(args, timeout: nil, runner: nil)
            timeout_seconds = timeout || Ace::Git.network_timeout || DEFAULT_SIMPLE_TIMEOUT
            run_command([BINARY] + args, timeout_seconds, runner)
          end

          def call_runner(runner, command, timeout_seconds)
            runner.call(args: command, timeout: timeout_seconds, env: {"LC_ALL" => "C"})
          rescue StandardError => e
            {success: false, stdout: "", stderr: e.message, exit_code: 1}
          end

          def spawn_with_timeout(command, timeout_seconds)
            stdout_str, stderr_str, status = Timeout.timeout(timeout_seconds) do
              Open3.capture3({"LC_ALL" => "C"}, *command)
            end

            {
              success: status.success?,
              stdout: stdout_str,
              stderr: stderr_str,
              exit_code: status.exitstatus
            }
          rescue Timeout::Error
            :timeout
          rescue Errno::ENOENT
            raise Ace::Git::ProviderCliMissingError,
              "GitHub CLI (gh) is not installed or not runnable; install the GitHub CLI and retry"
          end
        end
      end
    end
  end
end
