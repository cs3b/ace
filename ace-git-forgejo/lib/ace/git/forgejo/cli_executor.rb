# frozen_string_literal: true

require "open3"
require "timeout"
require_relative "parsers"
require_relative "repository_binding"

module Ace
  module Git
    module Forgejo
      # Executes the Forgejo CLI (`fj`) with timeout and structured output.
      #
      # Owns every `fj` subprocess invocation for ACE. Two launch paths exist:
      #
      # - {execute_control}: allowlisted login/version probes (`fj version`,
      #   `fj auth list`) that are host- or installation-scoped.
      # - {execute_repository}: repository-scoped commands, which require the
      #   validated selected {RepositoryBinding::Target} and a named operation
      #   with an observed argv form. The executor stamps `-H <authority>`
      #   from the target and refuses unobserved operations before launch —
      #   repository selection never comes from cwd, remotes, a default
      #   login, or user `fj` configuration.
      #
      # A test runner may be injected instead of spawning real processes
      # (see Providers::Base).
      module CliExecutor
        DEFAULT_TIMEOUT = 30
        BINARY = "fj"

        # Host/installation-scoped probes; never repository targeting.
        CONTROL_ARGS = {
          version: ["version"],
          auth_list: ["auth", "list"]
        }.freeze

        class << self
          # Execute an allowlisted control command with timeout.
          #
          # @param command [Symbol] key in {CONTROL_ARGS}
          # @return [Hash] {success:, stdout:, stderr:, exit_code:}
          # @raise [Ace::Git::ProviderCliMissingError] when `fj` is missing
          # @raise [Ace::Git::ProviderUnreachableError] when the call times out
          # @raise [ArgumentError] when the command is not allowlisted
          def execute_control(command, timeout: nil, runner: nil)
            args = CONTROL_ARGS.fetch(command) do
              raise ArgumentError, "Unknown fj control command #{command.inspect}"
            end
            execute(args, timeout: timeout, runner: runner)
          end

          # Execute one repository-scoped operation bound to the selected
          # target. The operation must have an observed argv form; the host
          # flag is stamped here so no caller can omit selection.
          #
          # @param target [RepositoryBinding::Target] validated selected repository
          # @param operation [Symbol] repository operation (RepositoryBinding::FORMS)
          # @param arguments [Array<Object>] per-operation arguments
          # @return [Hash] {success:, stdout:, stderr:, exit_code:}
          # @raise [Ace::Git::ConfigError] when the target is missing/invalid
          # @raise [Ace::Git::ProviderUnsupportedCapabilityError] when the
          #   operation has no observed form
          # @raise [Ace::Git::ProviderCliMissingError] when `fj` is missing
          # @raise [Ace::Git::ProviderUnreachableError] when the call times out
          def execute_repository(target:, operation:, arguments: [], timeout: nil, runner: nil)
            unless target.is_a?(RepositoryBinding::Target)
              raise Ace::Git::ConfigError,
                "Repository commands require a validated selected Forgejo target"
            end

            argv = RepositoryBinding.argv_for(operation, target, arguments)
            execute(["-H", target.authority] + argv, timeout: timeout, runner: runner)
          end

          # Probe whether the `fj` binary is installed and runnable.
          # `fj` has no `--version` flag (it rejects it with "unexpected
          # argument"); the supported presence probe is `fj version`.
          def installed?(runner: nil)
            result = execute_control(:version, runner: runner)
            result[:success]
          rescue Ace::Git::ProviderCliMissingError
            false
          end

          # @return [String, nil] installed forgejo-cli version (e.g. "v0.6.0"),
          #   or nil when `fj version` output is unparseable
          # @raise [Ace::Git::ProviderCliMissingError] when `fj` is missing
          #   or the version probe fails
          def installed_version(runner: nil)
            result = execute_control(:version, runner: runner)
            unless result[:success]
              raise Ace::Git::ProviderCliMissingError,
                "Forgejo CLI (fj) is not installed or not runnable; install the Forgejo CLI and retry"
            end

            match = result[:stdout].to_s.match(/\bfj\s+(v?\d+\.\d+\.\d+)\b/)
            match && match[1].sub(/\Av?/, "v")
          end

          # @raise [Ace::Git::ProviderUnsupportedCapabilityError] when the
          #   installed version was never observed; it must not inherit the
          #   capability table of an observed version
          def check_version_supported!(runner: nil)
            version = installed_version(runner: runner)
            return version if RepositoryBinding::OBSERVED_VERSIONS.include?(version)

            raise Ace::Git::ProviderUnsupportedCapabilityError,
              "Installed forgejo-cli version #{version || "of unknown version"} was never " \
              "observed; observed versions: #{RepositoryBinding::OBSERVED_VERSIONS.join(", ")}. " \
              "Observe its real surface before repository operations are allowed " \
              "(see the ace-git-forgejo repository binding evidence)"
          end

          # Probe whether the resolved server authority has a configured `fj`
          # login. `fj auth list` prints "No logins." (stderr, exit 0) when no
          # instance is configured; configured hosts are listed one per line.
          # Comparison is exact against the selected authority — never a
          # substring of an unrelated line.
          def authenticated?(authority, runner: nil)
            result = execute_control(:auth_list, runner: runner)
            return false unless result[:success]

            lines = "#{result[:stdout]}\n#{result[:stderr]}".lines
            lines.map { |line| Parsers.clean(line) }.any? do |line|
              !line.empty? && line.casecmp(authority.to_s)&.zero?
            end
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
          def check_authenticated!(authority:, runner: nil)
            return true if authenticated?(authority, runner: runner)

            raise Ace::Git::ProviderAuthenticationError,
              "Forgejo CLI (fj) has no usable login for #{authority || "the target host"}; " \
              "check fj auth list"
          end

          # Run a full argument vector against `fj`.
          #
          # @return [Hash] result hash
          def execute(args, timeout: nil, runner: nil)
            timeout_seconds = timeout || Ace::Git.network_timeout || DEFAULT_TIMEOUT
            result = run_command([BINARY] + args, timeout_seconds, runner)
            if result == :timeout
              raise Ace::Git::ProviderUnreachableError,
                "fj command timed out after #{timeout_seconds} seconds: #{args.join(" ")}"
            end

            result
          end

          private

          def run_command(command, timeout_seconds, runner)
            if runner
              call_runner(runner, command, timeout_seconds)
            else
              spawn_with_timeout(command, timeout_seconds)
            end
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
              "Forgejo CLI (fj) is not installed or not runnable; install the Forgejo CLI and retry"
          end
        end
      end
    end
  end
end
