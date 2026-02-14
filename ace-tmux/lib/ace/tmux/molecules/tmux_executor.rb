# frozen_string_literal: true

require "open3"

module Ace
  module Tmux
    module Molecules
      # Executes tmux commands via different execution strategies
      #
      # Provides three modes:
      #   - capture: Run and capture stdout/stderr (for queries)
      #   - run: Run via system() (for mutations)
      #   - exec: Replace process via Kernel.exec (for attach)
      class TmuxExecutor
        # Run a command and capture output
        #
        # @param cmd [Array<String>] Command array
        # @return [ExecutionResult] Result with stdout, stderr, success?
        def capture(cmd)
          stdout, stderr, status = Open3.capture3(*cmd)
          ExecutionResult.new(
            stdout: stdout.strip,
            stderr: stderr.strip,
            success: status.success?,
            exit_code: status.exitstatus
          )
        end

        # Run a command via system (fire and forget with status)
        #
        # @param cmd [Array<String>] Command array
        # @return [Boolean] true if command succeeded
        def run(cmd)
          system(*cmd)
        end

        # Replace current process with command (for tmux attach)
        #
        # @param cmd [Array<String>] Command array
        # @return [void] Never returns (replaces process)
        def exec(cmd)
          Kernel.exec(*cmd)
        end

        # Check if tmux is available
        #
        # @param tmux [String] tmux binary path
        # @return [Boolean]
        def tmux_available?(tmux: "tmux")
          result = capture([tmux, "-V"])
          result.success?
        rescue Errno::ENOENT
          false
        end
      end

      # Immutable result of a tmux command execution
      class ExecutionResult
        attr_reader :stdout, :stderr, :exit_code

        def initialize(stdout:, stderr:, success:, exit_code:)
          @stdout = stdout
          @stderr = stderr
          @success = success
          @exit_code = exit_code
        end

        def success?
          @success
        end
      end
    end
  end
end
