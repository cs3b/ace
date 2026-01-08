# frozen_string_literal: true

require "dry/cli"
require "set"
require "json"
require "ace/core"

# Load CLI command classes
require_relative "cli/cache/sync"
require_relative "cli/cache/status"
require_relative "cli/cache/diff"
require_relative "cli/cache/clear"
require_relative "cli/providers/list"
require_relative "cli/providers/show"
require_relative "cli/providers/sync"
require_relative "cli/models/search"
require_relative "cli/models/info"
require_relative "cli/models/cost"
require_relative "cli/search"
require_relative "cli/info"
require_relative "cli/sync_shortcut"

module Ace
  module LLM
    module ModelsDev
      # CLI for ace-llm-models using dry-cli
      module CLI
        extend Dry::CLI::Registry

        # Application commands registered in this CLI (single source of truth)
        REGISTERED_COMMANDS = %w[cache providers models search info sync].freeze

        # dry-cli built-in commands (standard across all CLI gems)
        BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

        # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
        KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

        DEFAULT_COMMAND = "help"

        # Testable start method with default command routing
        def self.start(args)
          if args.empty? || !KNOWN_COMMANDS.include?(args.first)
            args = [DEFAULT_COMMAND] + args
          end
          Dry::CLI.new(self).call(arguments: args)
        end

        # Cache subcommands
        register "cache sync", Commands::Cache::Sync
        register "cache status", Commands::Cache::Status
        register "cache diff", Commands::Cache::Diff
        register "cache clear", Commands::Cache::Clear

        # Providers subcommands
        register "providers list", Commands::Providers::List
        register "providers show", Commands::Providers::Show
        register "providers sync", Commands::Providers::Sync

        # Models subcommands
        register "models search", Commands::Models::Search
        register "models info", Commands::Models::Info
        register "models cost", Commands::Models::Cost

        # Top-level shortcuts
        register "search", Commands::SearchShortcut
        register "info", Commands::InfoShortcut
        register "sync", Commands::SyncShortcut

        # Version command
        version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
          gem_name: "ace-llm-models",
          version: VERSION
        )
        register "version", version_cmd
        register "--version", version_cmd
      end
    end
  end
end
