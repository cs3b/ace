# frozen_string_literal: true

require "dry/cli"

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

        PROGRAM_NAME = "ace-git-worktree"

        REGISTERED_COMMANDS = [
          ["create", "Create a new worktree for task, PR, or branch"],
          ["list", "List active worktrees with optional task metadata"],
          ["switch", "Resolve a worktree path for cd navigation"],
          ["remove", "Remove a worktree by task, branch, or path"],
          ["prune", "Prune stale/deleted worktree references"],
          ["config", "Show and validate configuration"]
        ].freeze

        HELP_EXAMPLES = [
          "ace-git-worktree create --task 148    # Isolated worktree for task",
          "ace-git-worktree list --show-tasks    # Worktrees with task context",
          "ace-git-worktree switch 148           # Get path for cd",
          "ace-git-worktree prune --dry-run      # Preview stale cleanup"
        ].freeze

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

        help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
          program_name: PROGRAM_NAME,
          version: Ace::Git::Worktree::VERSION,
          commands: REGISTERED_COMMANDS,
          examples: HELP_EXAMPLES
        )
        register "help", help_cmd
        register "--help", help_cmd
        register "-h", help_cmd
      end
    end
  end
end
