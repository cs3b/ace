# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../llm"
# Commands
require_relative "cli/commands/query"
require_relative "cli/commands/list_providers"

module Ace
  module LLM
    # dry-cli based CLI registry for ace-llm
    #
    # Standard multi-command CLI with help, version, query, and list-providers.
    module CLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-llm"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["query", "Send a prompt to an LLM provider"],
        ["list-providers", "List available LLM providers"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-llm query \"Explain this code\"",
        "ace-llm query --model claude-sonnet \"Summarize\"",
        "ace-llm list-providers"
      ].freeze

      # Register query command
      register "query", Commands::Query

      # Register list-providers command
      register "list-providers", Commands::ListProviders

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: PROGRAM_NAME,
        version: Ace::LLM::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::LLM::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd

      # Entry point for CLI invocation (used by tests and exe/)
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for errors)
      def self.start(args)
        Dry::CLI.new(self).call(arguments: args)
      end
    end
  end
end
