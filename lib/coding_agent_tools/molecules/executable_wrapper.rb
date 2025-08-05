# frozen_string_literal: true

require 'stringio'

module CodingAgentTools
  module Molecules
    # ExecutableWrapper provides a reusable pattern for executable scripts that wrap CLI commands.
    # This molecule encapsulates the common functionality shared across all exe/* scripts including:
    # - Bundler setup
    # - Load path configuration
    # - Argument modification and CLI execution
    # - Output capturing and modification
    # - Error handling and cleanup
    #
    # @example Usage in an executable script
    #   #!/usr/bin/env ruby
    #   require_relative "../lib/coding_agent_tools/molecules/executable_wrapper"
    #
    #   CodingAgentTools::Molecules::ExecutableWrapper.new(
    #     command_path: ["llm", "models"],
    #     registration_method: :register_llm_commands,
    #     executable_name: "llm-gemini-models"
    #   ).call
    class ExecutableWrapper
      # @param command_path [Array<String>] The command path to prepend to ARGV (e.g., ["llm", "models"])
      # @param registration_method [Symbol] The method to call for command registration (e.g., :register_llm_commands)
      # @param executable_name [String] The name of the executable for output modification
      def initialize(command_path:, registration_method:, executable_name:)
        @command_path = command_path
        @registration_method = registration_method
        @executable_name = executable_name
        @original_stdout = nil
        @original_stderr = nil
      end

      # Executes the wrapped CLI command with all common setup and cleanup
      # @return [void]
      def call
        setup_bundler
        setup_load_path
        require_dependencies
        execute_with_output_capture
      rescue => e
        handle_error(e)
      ensure
        restore_streams
      end

      private

      attr_reader :command_path, :registration_method, :executable_name,
        :original_stdout, :original_stderr

      # Sets up bundler if available and needed
      def setup_bundler
        return if defined?(Bundler)
        return unless bundler_environment?

        # Explicitly set the Gemfile path to ensure we use the gem's Gemfile
        # regardless of the current working directory
        gem_gemfile_path = File.expand_path('../../../Gemfile', __dir__)
        ENV['BUNDLE_GEMFILE'] = gem_gemfile_path if File.exist?(gem_gemfile_path)

        begin
          require 'bundler/setup'
        rescue LoadError
          # If bundler isn't available, continue without it
          # This can happen in subprocess calls where Ruby version differs
        end
      end

      # Checks if we're in a bundler environment
      def bundler_environment?
        !!(ENV['BUNDLE_GEMFILE'] || File.exist?(File.expand_path('../../../Gemfile', __dir__)))
      end

      # Sets up load paths for development
      def setup_load_path
        lib_path = File.expand_path('../../../lib', __dir__)
        $LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
      end

      # Requires necessary dependencies
      def require_dependencies
        require 'coding_agent_tools'
        require 'coding_agent_tools/cli'
        require 'coding_agent_tools/error_reporter'
      end

      # Executes the CLI command with output capturing and modification
      def execute_with_output_capture
        prepare_arguments
        register_commands
        capture_and_execute
      end

      # Prepares ARGV with the command path
      def prepare_arguments
        modified_args = command_path + ARGV
        ARGV.clear
        ARGV.concat(modified_args)
      end

      # Calls the appropriate command registration method
      def register_commands
        CodingAgentTools::Cli::Commands.public_send(registration_method)
      end

      # Captures output, executes CLI, and processes the result
      def capture_and_execute
        setup_output_capture
        status_code = execute_cli
        process_output_and_exit(status_code)
      rescue SystemExit => e
        process_system_exit(e)
      end

      # Sets up output capturing with StringIO
      def setup_output_capture
        @original_stdout = $stdout
        @original_stderr = $stderr
        @captured_stdout = StringIO.new
        @captured_stderr = StringIO.new
        $stdout = @captured_stdout
        $stderr = @captured_stderr
      end

      # Executes the main CLI and returns the exit status
      def execute_cli
        result = Dry::CLI.new(CodingAgentTools::Cli::Commands).call
        # CLI commands now return status codes instead of exiting
        # Return 0 if result is nil (successful completion) or the actual status code
        # Handle unexpected types (like Set) that can occur due to CLI registration issues
        if result.nil?
          0
        elsif result.is_a?(Integer)
          result
        else
          # If we get an unexpected type from Dry::CLI, check captured stderr for errors
          # This is a workaround for Dry::CLI sometimes returning unexpected types
          stderr_content = @captured_stderr&.string || ''
          if stderr_content.include?('Error:') || stderr_content.include?('ERROR:')
            1  # Indicate failure if there are error messages
          else
            0  # Default to success if no obvious errors
          end
        end
      end

      # Processes output and exits with the appropriate status code
      def process_output_and_exit(status_code)
        restore_streams
        output_content = get_captured_content
        print_modified_output(output_content)

        # Handle case where CLI returns unexpected types (e.g., Set instead of Integer)
        # This can happen when CLI registration has issues
        unless status_code.is_a?(Integer)
          status_code = 0 # Assume success if we get an unexpected type
        end

        exit(status_code) if status_code != 0
      end

      # Processes output when SystemExit is raised
      def process_system_exit(system_exit)
        restore_streams
        output_content = get_captured_content
        print_modified_output(output_content)
        raise system_exit
      end

      # Gets the captured output content
      def get_captured_content
        {
          stdout: @captured_stdout.string,
          stderr: @captured_stderr.string
        }
      end

      # Prints the modified output to the restored streams
      def print_modified_output(content)
        modified_content = modify_output_messages(content)
        $stdout.print(modified_content[:stdout]) unless modified_content[:stdout].empty?
        $stderr.print(modified_content[:stderr]) unless modified_content[:stderr].empty?
      end

      # Modifies output messages to show executable name instead of full command path
      def modify_output_messages(content)
        command_string = command_path.join(' ')

        stdout_content = content[:stdout]
        stderr_content = content[:stderr]

        if stdout_content.include?(command_string) || stderr_content.include?(command_string)
          stdout_content = modify_stdout_content(stdout_content, command_string)
          stderr_content = modify_stderr_content(stderr_content, command_string)
        end

        { stdout: stdout_content, stderr: stderr_content }
      end

      # Modifies stdout content
      def modify_stdout_content(content, command_string)
        content.gsub("#{executable_name} #{command_string}", executable_name)
      end

      # Modifies stderr content
      def modify_stderr_content(content, command_string)
        # Simple replacement of exact command string references
        # Avoid complex regex patterns that might cause duplication
        escaped_command = Regexp.escape(command_string)

        # Replace command path references with executable name, preserving quotes and additional args
        # Match quotes around path + command + optional args and replace with quotes around executable name + args
        content.gsub(/"[^"]*#{escaped_command}([^"]*)"/, "\"#{executable_name}\\1\"")
      end

      # Restores original stdout and stderr
      def restore_streams
        $stdout = @original_stdout if @original_stdout
        $stderr = @original_stderr if @original_stderr
      end

      # Handles errors through the centralized error reporter
      def handle_error(error)
        CodingAgentTools::ErrorReporter.call(error, debug: ENV['DEBUG'] == 'true')
        exit 1
      end
    end
  end
end
