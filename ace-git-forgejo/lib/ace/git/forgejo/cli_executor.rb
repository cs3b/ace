# frozen_string_literal: true

require "open3"
require "timeout"

module Ace
  module Git
    module Forgejo
      # Executes the Forgejo CLI (`fj`) with timeout and structured output.
      #
      # Owns every `fj` subprocess invocation for ACE. A test runner may be
      # injected instead of spawning real processes (see Providers::Base).
      module CliExecutor
        DEFAULT_TIMEOUT = 30
        BINARY = "fj"

        class << self
          # Execute an `fj` command with timeout and structured output.
          #
          # @param args [Array<String>] full argument vector after the binary
          # @param timeout [Integer, nil] seconds before the call times out
          # @param runner [Proc, nil] injectable command runner for tests
          # @return [Hash] {success:, stdout:, stderr:, exit_code:}
          # @raise [Ace::Git::ProviderCliMissingError] when `fj` is missing
          # @raise [Ace::Git::ProviderUnreachableError] when the call times out
          def execute(args, timeout: nil, runner: nil)
            timeout_seconds = timeout || Ace::Git.network_timeout || DEFAULT_TIMEOUT
            result = run_command([BINARY] + args, timeout_seconds, runner)
            if result == :timeout
              raise Ace::Git::ProviderUnreachableError,
                "fj command timed out after #{timeout_seconds} seconds: #{args.join(" ")}"
            end

            result
          end

          # Probe whether the `fj` binary is installed and runnable.
          # `fj` has no `--version` flag (it rejects it with "unexpected
          # argument"); the supported presence probe is `fj version`.
          def installed?(runner: nil)
            result = execute(["version"], runner: runner)
            result != :timeout && result[:success]
          rescue Ace::Git::ProviderCliMissingError
            false
          end

          # Probe whether the resolved server host has a configured `fj` login.
          # `fj auth list` exits nonzero when no instance is configured and
          # prints one host per line otherwise.
          def authenticated?(host, runner: nil)
            result = execute(["auth", "list"], runner: runner)
            return false unless result[:success]

            hosts = result[:stdout].to_s.lines.map(&:strip).reject(&:empty?)
            return hosts.any? unless host

            hosts.any? { |line| line.include?(host.to_s) }
          rescue Ace::Git::ProviderCliMissingError
            false
          end

          # @raise [Ace::Git::ProviderCliMissingError] when `fj` is missing
          def check_installed!(runner: nil)
            return true if installed?(runner: runner)

            raise Ace::Git::ProviderCliMissingError,
              "Forgejo CLI (fj) is not installed or not runnable; install the Forgejo CLI and retry"
          end

          # @raise [Ace::Git::ProviderAuthenticationError] when unauthenticated
          def check_authenticated!(host: nil, runner: nil)
            return true if authenticated?(host, runner: runner)

            raise Ace::Git::ProviderAuthenticationError,
              "Forgejo CLI (fj) has no usable login for #{host || "the target host"}; " \
              "check fj auth list"
          end

          # Run a full argument vector against `fj`.
          #
          # @return [Hash] result hash, or :timeout sentinel on timeout
          def run_command(command, timeout_seconds, runner = nil)
            if runner
              call_runner(runner, command, timeout_seconds)
            else
              spawn_with_timeout(command, timeout_seconds)
            end
          end

          private

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
              "Forgejo CLI (fj) is not installed or not runnable; install the Forgejo CLI and retry"
          end
        end
      end
    end
  end
end
