# frozen_string_literal: true

require "dry/cli"
require "set"

require_relative "version"
require_relative "cli/commands/create"
require_relative "cli/commands/list"
require_relative "cli/commands/switch"
require_relative "cli/commands/remove"
require_relative "cli/commands/prune"
require_relative "cli/commands/config"
require "ace/core"
require "ace/core/cli/dry_cli/base"

module Ace
  module Git
    module Worktree
      # dry-cli based CLI registry for ace-git-worktree
      #
      # This follows the Hanami pattern with all commands in CLI::Commands:: namespace.
      module CLI
        extend Dry::CLI::Registry

        # Application commands registered in this CLI (single source of truth)
        REGISTERED_COMMANDS = %w[create list switch remove prune config].freeze

        # Command aliases (must be kept in sync with register calls below)
        COMMAND_ALIASES = %w[ls cd rm].freeze

        # dry-cli built-in commands (standard across all CLI gems)
        BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

        # Auto-derived from REGISTERED + ALIASES + BUILTIN (no manual maintenance needed)
        # Using Set for O(1) lookup performance
        KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + COMMAND_ALIASES + BUILTIN_COMMANDS).freeze

        # Default command - create is the most common action
        DEFAULT_COMMAND = "create"

        # Testable start method with default command routing
        def self.start(args)
          # Handle help explicitly (dry-cli doesn't handle registry-level help)
          if args.first && %w[help --help -h].include?(args.first)
            puts Dry::CLI::Usage.call(get([]), registry: self)
            return 0
          end

          if args.empty? || !KNOWN_COMMANDS.include?(args.first)
            args = [DEFAULT_COMMAND] + args
          end
          Dry::CLI.new(self).call(arguments: args)
        end

        # Register commands (Hanami pattern: CLI::Commands::*)
        register "create", CLI::Commands::Create, aliases: []
        register "list", CLI::Commands::List, aliases: ["ls"]
        register "switch", CLI::Commands::Switch, aliases: ["cd"]
        register "remove", CLI::Commands::Remove, aliases: ["rm"]
        register "prune", CLI::Commands::Prune, aliases: []
        register "config", CLI::Commands::Config, aliases: []

        # Version command
        version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
          gem_name: "ace-git-worktree",
          version: Ace::Git::Worktree::VERSION
        )
        register "version", version_cmd
        register "--version", version_cmd
      end
    end
  end
end
