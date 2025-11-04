# frozen_string_literal: true

require_relative "version"

module Ace
  module Git
    module Worktree
      # Main CLI router (custom pattern, not Thor)
      class CLI
        def self.start(args)
          new.run(args)
        end

        def run(args)
          # Handle version flag
          if args.include?("--version") || args.include?("-v")
            puts "ace-git-worktree version #{VERSION}"
            return 0
          end

          # Handle help at root level
          if args.empty? || args.include?("--help") || args.include?("-h")
            print_help
            return 0
          end

          # Route to command
          command = args.shift

          case command
          when "create"
            require_relative "commands/create_command"
            Commands::CreateCommand.new.execute(args)
          when "list"
            require_relative "commands/list_command"
            Commands::ListCommand.new.execute(args)
          when "switch"
            require_relative "commands/switch_command"
            Commands::SwitchCommand.new.execute(args)
          when "remove"
            require_relative "commands/remove_command"
            Commands::RemoveCommand.new.execute(args)
          when "prune"
            require_relative "commands/prune_command"
            Commands::PruneCommand.new.execute(args)
          when "config"
            require_relative "commands/config_command"
            Commands::ConfigCommand.new.execute(args)
          else
            puts "Unknown command: #{command}"
            puts ""
            print_help
            1
          end
        end

        private

        def print_help
          puts <<~HELP
            ace-git-worktree - Git worktree management with ACE task integration

            Usage: ace-git-worktree <command> [options]

            Commands:
              create    Create a new worktree (task-aware or traditional)
              list      List all worktrees with optional task associations
              switch    Navigate to a worktree by task ID or name
              remove    Remove a worktree with cleanup
              prune     Clean up deleted worktrees from git metadata
              config    Display current configuration

            Global Options:
              --version, -v    Show version information
              --help, -h       Show this help message

            Command Help:
              ace-git-worktree <command> --help

            Examples:
              # Create task-aware worktree
              ace-git-worktree create --task 081

              # Create traditional worktree
              ace-git-worktree create feature-branch

              # List worktrees with task associations
              ace-git-worktree list --show-tasks

              # Navigate to a worktree
              cd $(ace-git-worktree switch 081)

              # Remove a worktree
              ace-git-worktree remove 081

            Configuration:
              Configuration is loaded from .ace/git/worktree.yml
              See 'ace-git-worktree config' to view current settings

            For more information, see:
              https://github.com/yourusername/ace-git-worktree
          HELP
        end
      end
    end
  end
end