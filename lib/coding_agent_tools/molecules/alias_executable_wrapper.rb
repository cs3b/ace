# frozen_string_literal: true

require "stringio"

module CodingAgentTools
  module Molecules
    # AliasExecutableWrapper provides a specialized wrapper for alias executables
    # that automatically inject the alias name as the provider:model argument.
    # This allows users to call `gflash "prompt"` instead of `gflash gflash "prompt"`.
    #
    # @example Usage in an alias executable script
    #   #!/usr/bin/env ruby
    #   require_relative "../lib/coding_agent_tools/molecules/alias_executable_wrapper"
    #
    #   CodingAgentTools::Molecules::AliasExecutableWrapper.new(
    #     alias_name: "gflash",
    #     executable_name: "gflash"
    #   ).call
    class AliasExecutableWrapper
      # @param alias_name [String] The alias name to inject as first argument (e.g., "gflash")
      # @param executable_name [String] The name of the executable for output modification
      def initialize(alias_name:, executable_name:)
        @alias_name = alias_name
        @executable_name = executable_name
        @original_stdout = nil
        @original_stderr = nil
      end

      # Executes the wrapped CLI command with alias injection and common setup
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

      attr_reader :alias_name, :executable_name,
        :original_stdout, :original_stderr

      # Sets up bundler if available and needed
      def setup_bundler
        return if defined?(Bundler)
        return unless bundler_environment?

        begin
          require "bundler/setup"
        rescue LoadError
          # If bundler isn't available, continue without it
          # This can happen in subprocess calls where Ruby version differs
        end
      end

      # Checks if we're in a bundler environment
      def bundler_environment?
        !!(ENV["BUNDLE_GEMFILE"] || File.exist?(File.expand_path("../../../../Gemfile", __FILE__)))
      end

      # Sets up load paths for development
      def setup_load_path
        lib_path = File.expand_path("../../../../lib", __FILE__)
        $LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
      end

      # Requires necessary dependencies
      def require_dependencies
        require "coding_agent_tools"
        require "coding_agent_tools/cli"
        require "coding_agent_tools/error_reporter"
      end

      # Executes the CLI command with output capturing and modification
      def execute_with_output_capture
        prepare_arguments
        register_commands
        capture_and_execute
      end

      # Prepares ARGV with the alias name injected as first argument
      def prepare_arguments
        # Inject alias name as the first argument, followed by original arguments
        modified_args = ["llm", "unified_query", alias_name] + ARGV
        ARGV.clear
        ARGV.concat(modified_args)
      end

      # Calls the LLM command registration method
      def register_commands
        CodingAgentTools::Cli::Commands.register_llm_commands
      end

      # Captures output, executes CLI, and processes the result
      def capture_and_execute
        setup_output_capture
        execute_cli
        process_successful_output
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

      # Executes the main CLI
      def execute_cli
        Dry::CLI.new(CodingAgentTools::Cli::Commands).call
      end

      # Processes output when command succeeds without SystemExit
      def process_successful_output
        restore_streams
        output_content = get_captured_content
        print_modified_output(output_content)
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
        stdout_content = content[:stdout]
        stderr_content = content[:stderr]

        # Replace references to "llm-query" with the alias name in help and usage
        stdout_content = modify_stdout_for_alias(stdout_content)
        stderr_content = modify_stderr_for_alias(stderr_content)

        {stdout: stdout_content, stderr: stderr_content}
      end

      # Modifies stdout content for alias usage
      def modify_stdout_for_alias(content)
        # Replace command name in help output - handle both forms
        content = content.gsub(/Command:\s*[^\n]*/, "Command:\n  #{executable_name}")

        # Replace usage line to show simplified syntax
        content = content.gsub(
          /Usage:\s*[^\n]*/,
          "Usage:\n  #{executable_name} PROMPT"
        )

        # Update description to be alias-specific
        content = content.gsub(
          /Description:\s*Query any LLM provider with unified provider:model syntax/,
          "Description:\n  Query #{resolve_alias_description} (alias for #{alias_name})"
        )

        # Remove PROVIDER_MODEL argument from arguments section since it's automatic
        content = content.gsub(
          /Arguments:\s*\n\s*PROVIDER_MODEL[^\n]*\n/m,
          "Arguments:\n"
        )

        # Update examples to use the alias name directly
        content = update_examples_for_alias(content)

        content
      end

      # Modifies stderr content for alias usage
      def modify_stderr_for_alias(content)
        # Handle error messages that might reference the full command
        content.gsub(/llm-query/, executable_name)
      end

      # Updates examples section for alias usage
      def update_examples_for_alias(content)
        # Replace examples with alias-specific ones
        if content.include?("Examples:")
          alias_examples = generate_alias_examples
          content.gsub(/Examples:.*$/m, "Examples:\n#{alias_examples}")
        else
          content
        end
      end

      # Generates examples specific to this alias
      def generate_alias_examples
        case alias_name
        when "gflash"
          "  #{executable_name} \"What is Ruby programming language?\"\n" \
          "  #{executable_name} \"Explain quantum computing\" --format json\n" \
          "  #{executable_name} prompt.txt --output response.json"
        when "gpro"
          "  #{executable_name} \"Write a detailed technical analysis\"\n" \
          "  #{executable_name} \"Complex reasoning task\" --temperature 0.3\n" \
          "  #{executable_name} prompt.txt --system system.md --output response.md"
        when "csonet"
          "  #{executable_name} \"Analyze this code structure\"\n" \
          "  #{executable_name} \"Help with system design\" --format json\n" \
          "  #{executable_name} prompt.txt --output response.json"
        when "copus"
          "  #{executable_name} \"Creative writing task\"\n" \
          "  #{executable_name} \"Complex problem solving\" --temperature 0.7\n" \
          "  #{executable_name} prompt.txt --output response.md"
        when "o4mini"
          "  #{executable_name} \"Quick question\"\n" \
          "  #{executable_name} \"Simple task\" --format text\n" \
          "  #{executable_name} prompt.txt --output response.txt"
        when "o3"
          "  #{executable_name} \"Advanced reasoning task\"\n" \
          "  #{executable_name} \"Complex analysis\" --temperature 0.1\n" \
          "  #{executable_name} prompt.txt --system system.md --output response.json"
        else
          "  #{executable_name} \"Your prompt here\"\n" \
          "  #{executable_name} prompt.txt --output response.json"
        end
      end

      # Resolves alias to a human-readable description
      def resolve_alias_description
        case alias_name
        when "gflash"
          "Google Gemini 2.5 Flash"
        when "gpro"
          "Google Gemini 2.5 Pro"
        when "csonet"
          "Anthropic Claude 4.0 Sonnet"
        when "copus"
          "Anthropic Claude 4.0 Opus"
        when "o4mini"
          "OpenAI GPT-4o Mini"
        when "o3"
          "OpenAI o3"
        else
          "LLM model"
        end
      end

      # Restores original stdout and stderr
      def restore_streams
        $stdout = @original_stdout if @original_stdout
        $stderr = @original_stderr if @original_stderr
      end

      # Handles errors through the centralized error reporter
      def handle_error(error)
        CodingAgentTools::ErrorReporter.call(error, debug: ENV["DEBUG"] == "true")
        exit 1
      end
    end
  end
end
