# frozen_string_literal: true

require "ace/core/cli/base"

module Ace
  module Git
    module Worktree
      class CLI < Ace::Core::CLI::Base
        # class_options :quiet, :verbose, :debug inherited from Base

        # Prevent Thor from consuming command-specific options
        # Let CreateCommand, SwitchCommand, etc. handle their own options
        stop_on_unknown_option! :create, :switch, :remove, :prune, :list

        # Override help to add task-aware worktrees section
        def self.help(shell, subcommand = false)
          super
          shell.say ""
          shell.say "Task-Aware Worktrees:"
          shell.say "  Create worktrees linked to tasks or PRs:"
          shell.say "    ace-git-worktree create --task 081"
          shell.say "    ace-git-worktree create --pr 123"
          shell.say ""
          shell.say "Examples:"
          shell.say "  ace-git-worktree create --task 081   # Worktree for task"
          shell.say "  ace-git-worktree list                # List worktrees"
          shell.say "  ace-git-worktree switch 081          # Switch by task"
        end

        desc "create [BRANCH] [OPTIONS]", "Create a new worktree"
        long_desc <<~DESC
          Create a new git worktree. Supports task-aware, PR, and traditional worktree creation.

          SYNTAX:
            ace-git-worktree create [BRANCH] [OPTIONS]

          TASK-AWARE:
            ace-git-worktree create --task <task-id>
            ace-git-worktree create --task 081 --dry-run

          PR-AWARE:
            ace-git-worktree create --pr <pr-number>
            ace-git-worktree create --pr 123

          TRADITIONAL:
            ace-git-worktree create <branch-name>
            ace-git-worktree create feature/new-auth --checkout

          EXAMPLES:

            # Create worktree for task
            $ ace-git-worktree create --task 081

            # Create worktree for PR
            $ ace-git-worktree create --pr 123

            # Create with branch name
            $ ace-git-worktree create feature/new-auth

            # Dry run to preview
            $ ace-git-worktree create --task 081 --dry-run

          CONFIGURATION:

            Global config:  ~/.ace/git-worktree/config.yml
            Project config: .ace/git-worktree/config.yml
            Example:        ace-git-worktree/.ace-defaults/git-worktree/config.yml

          OUTPUT:

            Created worktree path printed to stdout
            Exit codes: 0 (success), 1 (error)
        DESC
        def create(*args)
          # Handle --help/-h passed as first argument
          if args.first == "--help" || args.first == "-h"
            invoke :help, ["create"]
            return 0
          end
          display_config_summary("create")
          Commands::CreateCommand.new.run(args)
        end

        desc "list [OPTIONS]", "List all worktrees"
        long_desc <<~DESC
          List all git worktrees with optional filtering.

          SYNTAX:
            ace-git-worktree list [OPTIONS]

          EXAMPLES:

            # List all worktrees
            $ ace-git-worktree list

            # Show task information
            $ ace-git-worktree list --show-tasks

            # Verbose output
            $ ace-git-worktree list --verbose

          CONFIGURATION:

            Global config:  ~/.ace/git-worktree/config.yml
            Project config: .ace/git-worktree/config.yml
            Example:        ace-git-worktree/.ace-defaults/git-worktree/config.yml

          OUTPUT:

            Table format with worktree details
            Exit codes: 0 (success), 1 (error)
        DESC
        def list(*args)
          display_config_summary("list")
          Commands::ListCommand.new.run(args)
        end

        desc "switch <IDENTIFIER>", "Switch to a worktree"
        long_desc <<~DESC
          Switch to a worktree by returning its path.

          SYNTAX:
            ace-git-worktree switch <IDENTIFIER>

          EXAMPLES:

            # Switch by task number
            $ ace-git-worktree switch 081

            # Switch by branch name
            $ ace-git-worktree switch feature-branch

          CONFIGURATION:

            Global config:  ~/.ace/git-worktree/config.yml
            Project config: .ace/git-worktree/config.yml
            Example:        ace-git-worktree/.ace-defaults/git-worktree/config.yml

          OUTPUT:

            Worktree path printed to stdout (for cd with backticks)
            Exit codes: 0 (success), 1 (error)
        DESC
        def switch(*args)
          # Handle --help/-h passed as first argument
          if args.first == "--help" || args.first == "-h"
            invoke :help, ["switch"]
            return 0
          end
          display_config_summary("switch")
          Commands::SwitchCommand.new.run(args)
        end

        desc "remove <IDENTIFIER> [OPTIONS]", "Remove a worktree"
        long_desc <<~DESC
          Remove a git worktree.

          SYNTAX:
            ace-git-worktree remove <IDENTIFIER> [OPTIONS]

          EXAMPLES:

            # Remove by task ID
            $ ace-git-worktree remove --task 081

            # Remove by branch name
            $ ace-git-worktree remove feature-branch

            # Force removal
            $ ace-git-worktree remove --force 123

          CONFIGURATION:

            Global config:  ~/.ace/git-worktree/config.yml
            Project config: .ace/git-worktree/config.yml
            Example:        ace-git-worktree/.ace-defaults/git-worktree/config.yml

          OUTPUT:

            Removal confirmation printed to stdout
            Exit codes: 0 (success), 1 (error)
        DESC
        def remove(*args)
          # Handle --help/-h passed as first argument
          if args.first == "--help" || args.first == "-h"
            invoke :help, ["remove"]
            return 0
          end
          display_config_summary("remove")
          Commands::RemoveCommand.new.run(args)
        end

        desc "prune [OPTIONS]", "Clean up deleted worktrees"
        long_desc <<~DESC
          Prune worktrees that have been deleted from the filesystem.

          SYNTAX:
            ace-git-worktree prune [OPTIONS]

          EXAMPLES:

            # Prune deleted worktrees
            $ ace-git-worktree prune

            # Dry run to preview
            $ ace-git-worktree prune --dry-run

          CONFIGURATION:

            Global config:  ~/.ace/git-worktree/config.yml
            Project config: .ace/git-worktree/config.yml
            Example:        ace-git-worktree/.ace-defaults/git-worktree/config.yml

          OUTPUT:

            Pruned worktrees listed
            Exit codes: 0 (success), 1 (error)
        DESC
        def prune(*args)
          # Handle --help/-h passed as first argument
          if args.first == "--help" || args.first == "-h"
            invoke :help, ["prune"]
            return 0
          end
          display_config_summary("prune")
          Commands::PruneCommand.new.run(args)
        end

        desc "config [OPTIONS]", "Show/manage configuration"
        long_desc <<~DESC
          Show configuration and file locations.

          SYNTAX:
            ace-git-worktree config [OPTIONS]

          EXAMPLES:

            # Show configuration
            $ ace-git-worktree config

            # Show config file locations
            $ ace-git-worktree config --files

          CONFIGURATION:

            Global config:  ~/.ace/git-worktree/config.yml
            Project config: .ace/git-worktree/config.yml
            Example:        ace-git-worktree/.ace-defaults/git-worktree/config.yml

          OUTPUT:

            Configuration details printed to stdout
            Exit codes: 0 (success), 1 (error)
        DESC
        option :files, type: :boolean, desc: "Show configuration file locations"
        def config(*args)
          display_config_summary("config")
          Commands::ConfigCommand.new.run(args)
        end

        # Aliases
        map %w[ls] => :list
        map %w[rm] => :remove
        map %w[cd] => :switch

        desc "version", "Show version"
        long_desc <<~DESC
          Display the current version of ace-git-worktree.

          EXAMPLES:

            $ ace-git-worktree version
            $ ace-git-worktree --version
        DESC
        def version
          puts "ace-git-worktree version #{Ace::Git::Worktree::VERSION}"
          0
        end
        map "--version" => :version

        private

        def display_config_summary(command)
          return if options[:quiet]

          require "ace/core"
          Ace::Core::Atoms::ConfigSummary.display(
            command: command,
            config: Ace::Git::Worktree.config,
            defaults: {},
            options: options,
            quiet: false
          )
        end
      end
    end
  end
end
