# frozen_string_literal: true

require "optparse"

module Ace
  module Taskflow
    class CLI
      def self.start(args)
        subcommand = args.shift

        case subcommand
        when "idea"
          require_relative "commands/idea_command"
          Commands::IdeaCommand.new.execute(args)
        when "ideas"
          require_relative "commands/ideas_command"
          Commands::IdeasCommand.new.execute(args)
        when "task"
          require_relative "commands/task_command"
          Commands::TaskCommand.new.execute(args)
        when "tasks"
          require_relative "commands/tasks_command"
          Commands::TasksCommand.new.execute(args)
        when "release"
          require_relative "commands/release_command"
          Commands::ReleaseCommand.new.execute(args)
        when "releases"
          require_relative "commands/releases_command"
          Commands::ReleasesCommand.new.execute(args)
        when "migrate-paths"
          require_relative "cli/migrate_paths"
          Commands::MigratePaths.run(args)
        when "config"
          show_config
          exit 0
        when "--version", "-v"
          puts "ace-taskflow #{VERSION}"
          exit 0
        when "--help", "-h", nil
          show_help
          exit 0
        else
          puts "Unknown subcommand: #{subcommand}"
          show_help
          exit 1
        end
      end

      def self.show_config
        require_relative "molecules/config_loader"
        config = Molecules::ConfigLoader.load

        puts "ace-taskflow Configuration:"
        puts "=" * 50
        puts "Root directory: #{config['root']}"
        puts "Task directory: #{config['task_dir']}"
        puts "Active strategy: #{config['active_strategy']}"
        puts "Allow multiple active: #{config['allow_multiple_active']}"
        puts ""
        puts "References:"
        puts "  Allow qualified: #{config['references']['allow_qualified']}"
        puts "  Allow cross-release: #{config['references']['allow_cross_release']}"
        puts ""
        puts "Defaults:"
        puts "  Idea location: #{config['defaults']['idea_location']}"
        puts "  Task location: #{config['defaults']['task_location']}"
      end

      def self.show_help
        puts "Usage: ace-taskflow <subcommand> [options]"
        puts ""
        puts "Task Management:"
        puts "  task     - Operations on single tasks"
        puts "  tasks    - Browse and list multiple tasks"
        puts ""
        puts "Release Management:"
        puts "  release  - Operations on single releases"
        puts "  releases - Browse and list multiple releases"
        puts ""
        puts "Idea Management:"
        puts "  idea     - Operations on single ideas"
        puts "  ideas    - Browse and list multiple ideas"
        puts ""
        puts "Configuration:"
        puts "  config   - Show current configuration"
        puts ""
        puts "Options:"
        puts "  -h, --help     Show this help message"
        puts "  -v, --version  Show version"
        puts ""
        puts "Examples:"
        puts "  ace-taskflow task                    # Show next task"
        puts "  ace-taskflow tasks --status pending  # List pending tasks"
        puts "  ace-taskflow release                 # Show active release"
        puts "  ace-taskflow releases --stats        # Show release statistics"
        puts "  ace-taskflow idea                    # Show next idea"
        puts "  ace-taskflow idea create 'Add caching' # Capture an idea"
        puts "  ace-taskflow ideas --all             # List all ideas"
        puts ""
        puts "For subcommand help:"
        puts "  ace-taskflow <subcommand> --help"
      end
    end
  end
end