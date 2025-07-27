# frozen_string_literal: true

require "open3"
require "timeout"
require "shellwords"

module CodingAgentTools
  module Atoms
    module TaskflowManagement
      # ShellCommandExecutor provides safe command execution utilities
      # This is an atom - it has no dependencies on other parts of this gem
      class ShellCommandExecutor
        # Command execution result
        CommandResult = Struct.new(:success, :stdout, :stderr, :exit_code, :duration) do
          def success?
            success
          end

          def failure?
            !success
          end
        end

        # Default timeout for command execution (30 seconds)
        DEFAULT_TIMEOUT = 30

        # Maximum allowed command length for security
        MAX_COMMAND_LENGTH = 8192

        # Execute a shell command with safety checks and error handling
        # @param command [String] Command to execute
        # @param timeout [Integer] Maximum execution time in seconds (default: 30)
        # @param working_directory [String, nil] Directory to execute command in (default: current)
        # @param environment [Hash] Environment variables to set (default: {})
        # @param capture_output [Boolean] Whether to capture stdout/stderr (default: true)
        # @return [CommandResult] Execution result
        # @raise [ArgumentError] If command is invalid
        # @raise [SecurityError] If command fails security validation
        def self.execute(command, timeout: DEFAULT_TIMEOUT, working_directory: nil, environment: {}, capture_output: true)
          validate_command(command)
          validate_timeout(timeout)
          validate_working_directory(working_directory) if working_directory
          validate_environment(environment)

          start_time = Time.now

          begin
            # Set up execution options
            options = {}
            options[:chdir] = working_directory if working_directory

            # Combine current environment with provided environment
            execution_env = ENV.to_h.merge(environment)

            if capture_output
              execute_with_capture(command, execution_env, options, timeout, start_time)
            else
              execute_without_capture(command, execution_env, options, timeout, start_time)
            end
          rescue => e
            duration = Time.now - start_time
            CommandResult.new(false, "", "Execution error: #{e.message}", -1, duration)
          end
        end

        # Execute command and return only success/failure status
        # @param command [String] Command to execute
        # @param timeout [Integer] Maximum execution time in seconds (default: 30)
        # @param working_directory [String, nil] Directory to execute command in
        # @param environment [Hash] Environment variables to set
        # @return [Boolean] True if command succeeded (exit code 0)
        def self.execute_simple(command, timeout: DEFAULT_TIMEOUT, working_directory: nil, environment: {})
          # Capture output during tests to prevent pollution
          capture_output = test_environment?
          result = execute(command, timeout: timeout, working_directory: working_directory, environment: environment, capture_output: capture_output)
          result.success?
        end

        # Validate command for security and safety
        # @param command [String] Command to validate
        # @return [Boolean] True if command appears safe
        def self.safe_command?(command)
          return false unless command.is_a?(String)
          return false if command.nil? || command.empty?
          return false if command.length > MAX_COMMAND_LENGTH

          # Check for null bytes and control characters
          return false if command.include?("\0")
          return false if command.match?(/[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]/)

          # Basic checks for potentially dangerous patterns
          dangerous_patterns = [
            /rm\s+-rf/, # rm -rf commands
            /format\s+/, # format commands
            /dd\s+/, # dd commands
            />\s*\/dev\//, # redirects to device files
            /\|\s*dd\s+/ # piped dd commands
          ]

          dangerous_patterns.each do |pattern|
            return false if command.match?(pattern)
          end

          true
        end

        # Build command with escaped arguments
        # @param base_command [String] Base command (e.g., "ls", "git")
        # @param arguments [Array<String>] Arguments to append
        # @return [String] Complete command with escaped arguments
        def self.build_command(base_command, arguments = [])
          raise ArgumentError, "base_command cannot be nil or empty" if base_command.nil? || base_command.empty?
          raise ArgumentError, "arguments must be an array" unless arguments.is_a?(Array)

          escaped_args = arguments.map { |arg| Shellwords.escape(arg.to_s) }
          ([base_command] + escaped_args).join(" ")
        end

        # Execute command with retries
        # @param command [String] Command to execute
        # @param max_retries [Integer] Maximum number of retries (default: 2)
        # @param retry_delay [Float] Delay between retries in seconds (default: 1.0)
        # @param timeout [Integer] Timeout per attempt (default: 30)
        # @return [CommandResult] Final execution result
        def self.execute_with_retries(command, max_retries: 2, retry_delay: 1.0, timeout: DEFAULT_TIMEOUT)
          last_result = nil
          (max_retries + 1).times do |attempt|
            result = execute(command, timeout: timeout)
            return result if result.success?

            last_result = result

            # Don't sleep after the last attempt
            if attempt < max_retries
              sleep(retry_delay)
            end
          end

          last_result
        end

        class << self
          private

          # Check if we're running in a test environment
          # @return [Boolean] True if in test environment
          def test_environment?
            ENV["CI"] || defined?(RSpec) || ENV["RAILS_ENV"] == "test" || ENV["RACK_ENV"] == "test"
          end

          # Validate command string
          # @param command [String] Command to validate
          # @raise [ArgumentError] If command is invalid
          # @raise [SecurityError] If command fails security checks
          def validate_command(command)
            raise ArgumentError, "command must be a string" unless command.is_a?(String)
            raise ArgumentError, "command cannot be nil or empty" if command.nil? || command.empty?
            raise SecurityError, "command failed security validation" unless safe_command?(command)
          end

          # Validate timeout parameter
          # @param timeout [Integer] Timeout value
          # @raise [ArgumentError] If timeout is invalid
          def validate_timeout(timeout)
            raise ArgumentError, "timeout must be a positive integer" unless timeout.is_a?(Integer) && timeout > 0
            raise ArgumentError, "timeout too large (max 3600 seconds)" if timeout > 3600
          end

          # Validate working directory
          # @param directory [String] Directory path
          # @raise [ArgumentError] If directory is invalid
          def validate_working_directory(directory)
            raise ArgumentError, "working_directory must be a string" unless directory.is_a?(String)
            raise ArgumentError, "working_directory cannot be empty" if directory.empty?
            raise SecurityError, "working_directory failed security validation" unless safe_directory_path?(directory)
          end

          # Validate environment variables
          # @param environment [Hash] Environment variables
          # @raise [ArgumentError] If environment is invalid
          def validate_environment(environment)
            raise ArgumentError, "environment must be a hash" unless environment.is_a?(Hash)

            environment.each do |key, value|
              raise ArgumentError, "environment key must be a string" unless key.is_a?(String)
              raise ArgumentError, "environment value must be a string" unless value.is_a?(String)
              raise ArgumentError, "environment key cannot be empty" if key.empty?
              raise SecurityError, "environment key contains invalid characters" if key.match?(/[\x00-\x1f\x7f=]/)
              raise SecurityError, "environment value contains null bytes" if value.include?("\0")
            end
          end

          # Execute command with output capture
          # @param command [String] Command to execute
          # @param env [Hash] Environment variables
          # @param options [Hash] Execution options
          # @param timeout [Integer] Timeout in seconds
          # @param start_time [Time] Start time for duration calculation
          # @return [CommandResult] Execution result
          def execute_with_capture(command, env, options, timeout, start_time)
            stdout_str = ""
            stderr_str = ""
            exit_code = nil

            begin
              Timeout.timeout(timeout) do
                Open3.popen3(env, command, **options) do |stdin, stdout, stderr, wait_thread|
                  stdin.close

                  # Read outputs
                  stdout_str = stdout.read
                  stderr_str = stderr.read

                  exit_code = wait_thread.value.exitstatus
                end
              end
            rescue Timeout::Error
              duration = Time.now - start_time
              return CommandResult.new(false, "", "Command timed out after #{timeout} seconds", -1, duration)
            rescue => e
              duration = Time.now - start_time
              return CommandResult.new(false, "", "Execution error: #{e.message}", -1, duration)
            end

            duration = Time.now - start_time
            success = exit_code == 0
            CommandResult.new(success, stdout_str, stderr_str, exit_code, duration)
          end

          # Execute command without output capture
          # @param command [String] Command to execute
          # @param env [Hash] Environment variables
          # @param options [Hash] Execution options
          # @param timeout [Integer] Timeout in seconds
          # @param start_time [Time] Start time for duration calculation
          # @return [CommandResult] Execution result
          def execute_without_capture(command, env, options, timeout, start_time)
            exit_code = nil

            begin
              Timeout.timeout(timeout) do
                exit_code = system(env, command, **options) ? 0 : ($?.exitstatus || -1)
              end
            rescue Timeout::Error
              duration = Time.now - start_time
              return CommandResult.new(false, "", "Command timed out after #{timeout} seconds", -1, duration)
            rescue => e
              duration = Time.now - start_time
              return CommandResult.new(false, "", "Execution error: #{e.message}", -1, duration)
            end

            duration = Time.now - start_time
            success = exit_code == 0
            CommandResult.new(success, "", "", exit_code, duration)
          end

          # Check if directory path is safe
          # @param path [String] Directory path
          # @return [Boolean] True if safe
          def safe_directory_path?(path)
            return false if path.nil? || path.empty?
            return false unless path.is_a?(String)
            return false if path.include?("\0")
            return false if path.match?(/[\x00-\x1f\x7f]/)
            return false if path.include?("../")
            return false if path.include?("..\\")
            return false if path.length > 4096
            true
          end
        end
      end
    end
  end
end
