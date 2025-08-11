# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    # SystemCommandExecutor provides safe system command execution
    # This is an atom - it has no internal dependencies and provides basic functionality
    class SystemCommandExecutor
      # Execute a system command safely
      # @param command [String] Command to execute
      # @param timeout [Integer] Timeout in seconds (default: 120)
      # @return [Hash] Result with success status, output, and error
      def execute(command, timeout: 120)
        return {success: false, error: "Command cannot be nil"} if command.nil?
        return {success: false, error: "Command cannot be empty"} if command.strip.empty?

        begin
          # Use Open3 for better process control
          require "open3"
          require "timeout"

          output = ""
          error_output = ""
          exit_status = nil

          Timeout.timeout(timeout) do
            Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
              stdin.close # We don't need to send input

              # Read output and error streams
              output = stdout.read
              error_output = stderr.read

              exit_status = wait_thr.value.exitstatus
            end
          end

          if exit_status == 0
            {success: true, output: output, error: nil}
          else
            error_msg = error_output.empty? ? "Command failed (exit code: #{exit_status})" : error_output
            {success: false, output: output, error: error_msg}
          end
        rescue Timeout::Error
          {success: false, error: "Command timed out after #{timeout} seconds"}
        rescue Errno::ENOENT => e
          {success: false, error: "Command not found: #{e.message}"}
        rescue => e
          {success: false, error: "Command execution failed: #{e.message}"}
        end
      end

      # Check if a command is available
      # @param command [String] Command name to check
      # @return [Boolean] True if command is available
      def command_available?(command)
        result = execute("which #{command}", timeout: 5)
        result[:success]
      end
    end
  end
end
