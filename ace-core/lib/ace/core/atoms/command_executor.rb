# frozen_string_literal: true

require 'open3'
require 'timeout'

module Ace
  module Core
    module Atoms
      # Pure command execution functions with safety features
      module CommandExecutor
        # Default timeout for commands (30 seconds)
        DEFAULT_TIMEOUT = 30

        # Maximum output size (1MB)
        MAX_OUTPUT_SIZE = 1_048_576

        module_function

        # Execute a command with timeout and output capture
        # @param command [String] Command to execute
        # @param timeout [Integer] Timeout in seconds
        # @param max_output [Integer] Maximum output size in bytes
        # @param cwd [String] Working directory for command
        # @return [Hash] {success: Boolean, stdout: String, stderr: String, exit_code: Integer, error: String}
        def execute(command, timeout: DEFAULT_TIMEOUT, max_output: MAX_OUTPUT_SIZE, cwd: nil)
          return { success: false, error: "Command cannot be nil" } if command.nil?
          return { success: false, error: "Command cannot be empty" } if command.strip.empty?

          stdout_data = String.new
          stderr_data = String.new
          exit_status = nil
          truncated = false

          options = {}
          options[:chdir] = cwd if cwd && Dir.exist?(cwd)

          begin
            Timeout::timeout(timeout) do
              Open3.popen3(command, options) do |stdin, stdout, stderr, wait_thr|
                stdin.close

                # Read output with size limits
                stdout_reader = Thread.new do
                  Thread.current.report_on_exception = false
                  begin
                    stdout.each_char do |char|
                      if stdout_data.bytesize < max_output
                        stdout_data << char
                      else
                        truncated = true
                        break
                      end
                    end
                  rescue IOError
                    # Stream was closed, this is expected on timeout
                  end
                end

                stderr_reader = Thread.new do
                  Thread.current.report_on_exception = false
                  begin
                    stderr.each_char do |char|
                      if stderr_data.bytesize < max_output
                        stderr_data << char
                      else
                        truncated = true
                        break
                      end
                    end
                  rescue IOError
                    # Stream was closed, this is expected on timeout
                  end
                end

                stdout_reader.join
                stderr_reader.join

                exit_status = wait_thr.value
              end
            end

            result = {
              success: exit_status.success?,
              stdout: stdout_data,
              stderr: stderr_data,
              exit_code: exit_status.exitstatus
            }

            result[:warning] = "Output truncated (exceeded #{max_output} bytes)" if truncated

            result
          rescue Timeout::Error
            {
              success: false,
              stdout: stdout_data,
              stderr: stderr_data,
              error: "Command timed out after #{timeout} seconds"
            }
          rescue Errno::ENOENT => e
            {
              success: false,
              error: "Command not found: #{command.split.first}"
            }
          rescue => e
            {
              success: false,
              stdout: stdout_data,
              stderr: stderr_data,
              error: "Command execution failed: #{e.message}"
            }
          end
        end

        # Execute command and return only stdout if successful
        # @param command [String] Command to execute
        # @param options [Hash] Execution options
        # @return [String, nil] Command output or nil if failed
        def capture(command, **options)
          result = execute(command, **options)
          result[:success] ? result[:stdout] : nil
        end

        # Check if a command is available in PATH
        # @param command [String] Command name to check
        # @return [Boolean] true if command is available
        def available?(command)
          return false if command.nil? || command.empty?

          # Extract just the command name (first word)
          cmd = command.split.first

          # Check if command exists in PATH
          ENV['PATH'].split(File::PATH_SEPARATOR).any? do |path|
            executable = File.join(path, cmd)
            File.executable?(executable) && !File.directory?(executable)
          end
        rescue
          false
        end

        # Execute command with real-time output streaming
        # @param command [String] Command to execute
        # @param output_callback [Proc] Callback for output lines
        # @param timeout [Integer] Timeout in seconds
        # @param cwd [String] Working directory
        # @return [Hash] {success: Boolean, exit_code: Integer, error: String}
        def stream(command, output_callback: nil, timeout: DEFAULT_TIMEOUT, cwd: nil)
          return { success: false, error: "Command cannot be nil" } if command.nil?

          options = {}
          options[:chdir] = cwd if cwd && Dir.exist?(cwd)

          exit_status = nil

          begin
            Timeout::timeout(timeout) do
              Open3.popen2e(command, options) do |stdin, stdout_err, wait_thr|
                stdin.close

                stdout_err.each_line do |line|
                  output_callback&.call(line.chomp)
                end

                exit_status = wait_thr.value
              end
            end

            {
              success: exit_status.success?,
              exit_code: exit_status.exitstatus
            }
          rescue Timeout::Error
            {
              success: false,
              error: "Command timed out after #{timeout} seconds"
            }
          rescue Errno::ENOENT
            {
              success: false,
              error: "Command not found: #{command.split.first}"
            }
          rescue => e
            {
              success: false,
              error: "Command execution failed: #{e.message}"
            }
          end
        end

        # Execute multiple commands in sequence
        # @param commands [Array<String>] Commands to execute
        # @param options [Hash] Execution options
        # @return [Array<Hash>] Results for each command
        def execute_batch(commands, **options)
          return [] if commands.nil? || commands.empty?

          commands.map do |command|
            result = execute(command, **options)
            result[:command] = command
            result
          end
        end

        # Build a safe command string with proper escaping
        # @param command [String] Base command
        # @param args [Array<String>] Arguments to add
        # @return [String] Safe command string
        def build_command(command, *args)
          return nil if command.nil?

          escaped_args = args.flatten.compact.map do |arg|
            # Shell escape the argument
            if arg.match?(/[^A-Za-z0-9_\-.,:\/@]/)
              # Properly escape single quotes in shell arguments
              "'#{arg.gsub("'", "'\\''")}'"
            else
              arg
            end
          end

          [command, *escaped_args].join(' ')
        end
      end
    end
  end
end