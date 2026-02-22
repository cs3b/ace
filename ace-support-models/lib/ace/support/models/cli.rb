# frozen_string_literal: true

require "dry/cli"
require "set"
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
      # CLI for ace-models using dry-cli.
      #
      # After the split, ace-models handles cache and model operations.
      # Provider management moved to ace-llm-providers.
      module CLI
        extend Dry::CLI::Registry
        extend Ace::Core::CLI::DryCli::DefaultRouting

        PROGRAM_NAME = "ace-models"

        # Flat commands — all previously nested commands are now top-level
        REGISTERED_COMMANDS = %w[search info cost sync status diff clear].freeze

        # dry-cli built-in commands (standard across all CLI gems)
        BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

        # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
        KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

        DEFAULT_COMMAND = "search"

        HELP_EXAMPLES = [
          ["Search for models", "ace-models gpt-4"],
          ["Show model info", "ace-models info openai:gpt-4o"],
          ["Calculate cost", "ace-models cost openai:gpt-4o -i 5000 -o 2000"],
          ["Sync cache from models.dev", "ace-models sync"],
          ["Show cache status", "ace-models status"],
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
        version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
          gem_name: "ace-models",
          version: VERSION
        )
        register "version", version_cmd
        register "--version", version_cmd
      end
    end
  end
end
