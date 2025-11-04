# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      # CLI class for ace-git-worktree
      #
      # Provides the main command-line interface with routing to specific
      # command classes. Follows the ace-taskflow pattern with case/when routing.
      #
      # @example Usage from executable
      #   CLI.new(ARGV).run
      class CLI
        # Initialize a new CLI
        #
        # @param args [Array<String>] Command line arguments
        def initialize(args = ARGV)
          @args = args
          @commands = {}
          @commands_registered = false
        end

        # Run the CLI
        #
        # @return [Integer] Exit code (0 for success, 1 for error)
        def run
          # Handle no arguments
          if @args.empty?
            show_help
            return 0
          end

          # Handle help/version first
          case @args.first
          when "--help", "-h", "help"
            show_help
            return 0
          when "--version", "-v", "version"
            show_version
            return 0
          end

          # Route to command
          command_name = @args.first
          command_args = @args[1..-1]

          # Register commands only when we need them
          ensure_commands_registered
          command = @commands[command_name]
          if command
            command.run(command_args)
          else
            puts "Error: Unknown command '#{command_name}'"
            puts
            show_help
            1
          end
        rescue StandardError => e
          puts "Unexpected error: #{e.message}"
          puts

          # Provide specific guidance for common errors
          case e.message
          when /ace-taskflow/
            puts "ace-taskflow dependency issue detected:"
            puts "  1. Install ace-taskflow: gem install ace-taskflow"
            puts "  2. Check PATH: which ace-taskflow"
            puts "  3. For task operations, ensure ace-taskflow is available"
          when /git.*not found|git.*command/
            puts "Git dependency issue detected:"
            puts "  1. Install git: https://git-scm.com/downloads"
            puts "  2. Check git is in PATH: which git"
            puts "  3. Ensure you're in a git repository"
          when /permission.*denied|access.*denied/
            puts "Permission issue detected:"
            puts "  1. Check directory permissions"
            puts "  2. Ensure git repository is accessible"
            puts "  3. Try running with appropriate permissions"
          end

          puts
          show_help
          1
        end

        private

        # Ensure commands are registered (lazy loading)
        def ensure_commands_registered
          return if @commands_registered
          register_commands
          @commands_registered = true
        end

        # Register all available commands
        def register_commands
          @commands["create"] = Commands::CreateCommand.new
          @commands["list"] = Commands::ListCommand.new
          @commands["switch"] = Commands::SwitchCommand.new
          @commands["remove"] = Commands::RemoveCommand.new
          @commands["prune"] = Commands::PruneCommand.new
          @commands["config"] = Commands::ConfigCommand.new

          # Add aliases
          @commands["ls"] = @commands["list"]
          @commands["rm"] = @commands["remove"]
          @commands["cd"] = @commands["switch"]
        end

        # Show help information
        def show_help
          puts <<~HELP
            ace-git-worktree - Task-aware git worktree management

            USAGE:
                ace-git-worktree <command> [OPTIONS]

            COMMANDS:
                create      Create a new worktree
                list        List all worktrees
                switch      Switch to a worktree
                remove      Remove a worktree
                prune       Clean up deleted worktrees
                config      Show/manage configuration

            TASK-AWARE WORKFLOW:
                ace-git-worktree create --task <task-id>     Create worktree for task
                ace-git-worktree switch <task-id>            Switch to task worktree
                ace-git-worktree remove --task <task-id>     Remove task worktree

            TRADITIONAL WORKFLOW:
                ace-git-worktree create <branch-name>        Create traditional worktree
                ace-git-worktree switch <branch-name>       Switch to worktree
                ace-git-worktree remove <identifier>        Remove worktree

            EXAMPLES:
                # Create task-aware worktree
                ace-git-worktree create --task 081

                # List all worktrees
                ace-git-worktree list --show-tasks

                # Switch to task worktree
                cd $(ace-git-worktree switch 081)

                # Remove task worktree
                ace-git-worktree remove --task 081

                # Clean up deleted worktrees
                ace-git-worktree prune

                # Show configuration
                ace-git-worktree config

            HELP:
                Use 'ace-git-worktree <command> --help' for command-specific help

            CONFIGURATION:
                Configuration is loaded from .ace/git/worktree.yml
                See 'ace-git-worktree config --files' for file locations

            VERSION:
                #{VERSION}

            For more information, see the project documentation.
          HELP
        end

        # Show version information
        def show_version
          puts "ace-git-worktree version #{VERSION}"
          puts "Part of the ACE ecosystem"
        end

        # Get version from version module
        #
        # @return [String] Version string
        def VERSION
          version_file = File.expand_path("../version.rb", __dir__)
          if File.exist?(version_file)
            load version_file
            return Ace::Git::Worktree::VERSION
          else
            return "0.1.0"
          end
        rescue StandardError
          "0.1.0"
        end
      end
    end
  end
end