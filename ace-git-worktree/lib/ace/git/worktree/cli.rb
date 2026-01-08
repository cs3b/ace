# frozen_string_literal: true

require "dry/cli"
require "set"

require_relative "version"
require_relative "cli/create"
require_relative "cli/list"
require_relative "cli/switch"
require_relative "cli/remove"
require_relative "cli/prune"
require_relative "cli/config"
require "ace/core"
require "ace/core/cli/dry_cli/base"

module Ace
  module Git
    module Worktree
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
          if args.empty? || !KNOWN_COMMANDS.include?(args.first)
            args = [DEFAULT_COMMAND] + args
          end
          Dry::CLI.new(self).call(arguments: args)
        end

        register "create", Create, aliases: []
        register "list", List, aliases: ["ls"]
        register "switch", Switch, aliases: ["cd"]
        register "remove", Remove, aliases: ["rm"]
        register "prune", Prune, aliases: []
        register "config", Config, aliases: []

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
