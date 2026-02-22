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
require_relative "cli/commands/providers/list"
require_relative "cli/commands/providers/show"
require_relative "cli/commands/providers/sync"
require_relative "cli/commands/models/search"
require_relative "cli/commands/models/info"
require_relative "cli/commands/models/cost"
require_relative "cli/commands/search"
require_relative "cli/commands/info"
require_relative "cli/commands/sync_shortcut"

module Ace
  module Support
    module Models
      # CLI for ace-models using dry-cli
      module CLI
        extend Dry::CLI::Registry
        include Ace::Core::CLI::DryCli::CommandGroups

        # Command groups for --help output (used by usage_formatter)
        COMMAND_GROUPS = {
          "Cache" => %w[cache],
          "Providers" => %w[providers],
          "Models" => %w[models],
          "Shortcuts" => %w[search info sync]
        }.freeze

        # Application commands registered in this CLI (single source of truth)
        REGISTERED_COMMANDS = %w[cache providers models search info sync].freeze

        # dry-cli built-in commands (standard across all CLI gems)
        BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

        # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
        KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

        DEFAULT_COMMAND = "help"

        # Namespace commands that have subcommands but no leaf command.
        # dry-cli prints these to stderr with exit code 1 when --help is passed.
        NAMESPACE_COMMANDS = %w[cache providers models].freeze

        # Testable start method with default command routing
        def self.start(args)
          # Handle help explicitly (dry-cli doesn't handle registry-level help)
          if args.first && %w[help --help -h].include?(args.first)
            puts Dry::CLI::Usage.call(get([]), registry: self)
            return 0
          end

          # Handle namespace-level help (e.g., "cache --help", "providers -h")
          # dry-cli doesn't handle this properly — it prints to stderr with exit code 1
          if args.length == 2 && NAMESPACE_COMMANDS.include?(args.first) && %w[--help -h].include?(args.last)
            result = get(args.first(1))
            # Don't pass registry for namespace help — avoids group matching
            # against top-level groups when showing a namespace subtree
            puts Dry::CLI::Usage.call(result)
            return 0
          end

          if args.empty? || !KNOWN_COMMANDS.include?(args.first)
            args = [DEFAULT_COMMAND] + args
          end
          Dry::CLI.new(self).call(arguments: args)
        end

        # Cache subcommands (Hanami pattern: CLI::Commands::)
        register "cache sync", CLI::Commands::Cache::Sync
        register "cache status", CLI::Commands::Cache::Status
        register "cache diff", CLI::Commands::Cache::Diff
        register "cache clear", CLI::Commands::Cache::Clear

        # Providers subcommands
        register "providers list", CLI::Commands::Providers::List
        register "providers show", CLI::Commands::Providers::Show
        register "providers sync", CLI::Commands::Providers::Sync

        # Models subcommands
        # Note: Uses ModelsSubcommands:: to avoid constant collision with outer
        # Ace::Support::Models module (Ruby constant lookup limitation)
        register "models search", CLI::Commands::ModelsSubcommands::Search
        register "models info", CLI::Commands::ModelsSubcommands::Info
        register "models cost", CLI::Commands::ModelsSubcommands::Cost

        # Top-level shortcuts
        register "search", CLI::Commands::SearchShortcut
        register "info", CLI::Commands::InfoShortcut
        register "sync", CLI::Commands::SyncShortcut

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
