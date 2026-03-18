# frozen_string_literal: true

require "ace/support/cli"
require "json"
require "ace/core"

# Load CLI command classes (Hanami pattern: CLI::Commands::)
require_relative "cli/commands/cache/sync"
require_relative "cli/commands/cache/status"
require_relative "cli/commands/cache/diff"
require_relative "cli/commands/cache/clear"
require_relative "cli/commands/models/search"
require_relative "cli/commands/models/info"
require_relative "cli/commands/models/cost"

module Ace
  module Support
    module Models
      # CLI for ace-models using ace-support-cli.
      #
      # After the split, ace-models handles cache and model operations.
      # Provider management moved to ace-llm-providers.
      module CLI
        extend Ace::Support::Cli::RegistryDsl

        PROGRAM_NAME = "ace-models"

        # Application commands with descriptions (for help output)
        REGISTERED_COMMANDS = [
          ["search", "Search for models by name or pattern"],
          ["info", "Show detailed model information"],
          ["cost", "Calculate token cost for a model"],
          ["sync", "Sync model cache from models.dev"],
          ["status", "Show cache sync status"],
          ["diff", "Show changes since last sync"],
          ["clear", "Clear the model cache"]
        ].freeze

        HELP_EXAMPLES = [
          "ace-models search claude              # Find models by name",
          "ace-models info claude-sonnet-4-6     # Pricing and context window",
          "ace-models cost claude-opus-4-6       # Token cost calculator",
          "ace-models sync                       # Update from models.dev"
        ].freeze

        # Register flat commands (previously nested under cache/models namespaces)
        register "search", CLI::Commands::ModelsSubcommands::Search
        register "info", CLI::Commands::ModelsSubcommands::Info
        register "cost", CLI::Commands::ModelsSubcommands::Cost
        register "sync", CLI::Commands::Cache::Sync
        register "status", CLI::Commands::Cache::Status
        register "diff", CLI::Commands::Cache::Diff
        register "clear", CLI::Commands::Cache::Clear

        # Version command
        version_cmd = Ace::Support::Cli::VersionCommand.build(
          gem_name: PROGRAM_NAME,
          version: VERSION
        )
        register "version", version_cmd
        register "--version", version_cmd

        # Help command
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
