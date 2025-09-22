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
        when "task"
          puts "Task management coming soon"
          exit 0
        when "release"
          puts "Release management coming soon"
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

      def self.show_help
        puts "Usage: ace-tf <subcommand> [options]"
        puts ""
        puts "Subcommands:"
        puts "  idea     - Capture ideas (replaces capture-it)"
        puts "  task     - Task management (coming soon)"
        puts "  release  - Release management (coming soon)"
        puts ""
        puts "Options:"
        puts "  -h, --help     Show this help message"
        puts "  -v, --version  Show version"
      end
    end
  end
end