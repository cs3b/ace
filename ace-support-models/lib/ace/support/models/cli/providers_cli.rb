# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../version"

# Reuse existing provider command classes
require_relative "commands/providers/list"
require_relative "commands/providers/show"
require_relative "commands/providers/sync"

module Ace
  module Support
    module Models
      # Flat CLI registry for ace-llm-providers (LLM provider management).
      #
      # Replaces the nested `ace-models providers <subcommand>` pattern with
      # flat `ace-llm-providers <command>` invocations.
      module ProvidersCLI
        extend Ace::Support::Cli::RegistryDsl

        PROGRAM_NAME = "ace-llm-providers"

        # Application commands with descriptions (for help output)
        REGISTERED_COMMANDS = [
          ["list", "List all available LLM providers"],
          ["show", "Show detailed information for a provider"],
          ["sync", "Synchronize provider configurations"]
        ].freeze

        HELP_EXAMPLES = [
          "ace-llm-providers",
          "ace-llm-providers show openai",
          "ace-llm-providers sync --apply",
          "ace-llm-providers sync -p anthropic"
        ].freeze

        # Register flat commands (reusing existing command classes)
        register "list", CLI::Commands::Providers::List
        register "show", CLI::Commands::Providers::Show
        register "sync", CLI::Commands::Providers::Sync

        # Register version command
        version_cmd = Ace::Support::Cli::VersionCommand.build(
          gem_name: PROGRAM_NAME,
          version: VERSION
        )
        register "version", version_cmd
        register "--version", version_cmd

        # Register help command
        help_cmd = Ace::Support::Cli::HelpCommand.build(
          program_name: PROGRAM_NAME,
          version: VERSION,
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
          Ace::Support::Cli::Runner.new(self).call(args: args)
        end
      end
    end
  end
end
