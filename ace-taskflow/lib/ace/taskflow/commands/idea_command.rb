# frozen_string_literal: true

require_relative "../organisms/idea_writer"
require_relative "../molecules/config_loader"
require_relative "../molecules/release_resolver"

module Ace
  module Taskflow
    module Commands
      class IdeaCommand
        def initialize
          @config = Molecules::ConfigLoader.load
          @root_path = Molecules::ConfigLoader.find_root
        end

        def execute(args)
          # Parse command and options
          if args.empty? || args.first == "--help" || args.first == "-h"
            show_help
            exit 0
          end

          # Check for subcommands
          if ["to-task", "archive", "list"].include?(args.first)
            handle_subcommand(args)
            return
          end

          # Parse options for idea capture
          options = parse_options(args)

          if options[:content].empty?
            puts "Error: No idea content provided"
            show_help
            exit 1
          end

          # Determine target location
          location = determine_location(options)

          # Update config with location
          config = @config.dup
          if location == "backlog"
            config["idea"] ||= {}
            config["idea"]["directory"] = File.join(@root_path, "backlog", "ideas")
          elsif location.start_with?("v.")
            # Release-specific location
            release_path = resolve_release_path(location)
            if release_path
              config["idea"] ||= {}
              config["idea"]["directory"] = File.join(release_path, "ideas")
            else
              puts "Error: Release '#{location}' not found"
              exit 1
            end
          else
            # Active release (default)
            resolver = Molecules::ReleaseResolver.new(@root_path)
            primary = resolver.find_primary_active
            if primary
              config["idea"] ||= {}
              config["idea"]["directory"] = File.join(primary[:path], "ideas")
            else
              # Fall back to backlog if no active release
              config["idea"] ||= {}
              config["idea"]["directory"] = File.join(@root_path, "backlog", "ideas")
            end
          end

          # Capture the idea
          writer = Organisms::IdeaWriter.new(config)
          path = writer.write(options[:content])
          puts "Idea captured: #{path}"
        rescue => e
          puts "Error capturing idea: #{e.message}"
          exit 1
        end

        private

        def parse_options(args)
          options = {
            content: "",
            location: nil
          }

          content_parts = []
          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--backlog"
              options[:location] = "backlog"
              i += 1
            when "--release", "-r"
              options[:location] = args[i + 1]
              i += 2
            when "--current"
              options[:location] = "current"
              i += 1
            else
              content_parts << arg
              i += 1
            end
          end

          options[:content] = content_parts.join(" ")
          options
        end

        def determine_location(options)
          # Explicit location from flags
          return options[:location] if options[:location]

          # Default based on configuration
          default_location = @config.dig("defaults", "idea_location") || "active"

          case default_location
          when "active", "current"
            "current"
          when "backlog"
            "backlog"
          else
            default_location
          end
        end

        def resolve_release_path(release_name)
          resolver = Molecules::ReleaseResolver.new(@root_path)
          release = resolver.find_release(release_name)
          release ? release[:path] : nil
        end

        def handle_subcommand(args)
          subcommand = args.shift

          case subcommand
          when "to-task"
            convert_idea_to_task(args)
          when "archive"
            archive_idea(args)
          when "list"
            list_ideas(args)
          else
            puts "Unknown subcommand: #{subcommand}"
            show_help
            exit 1
          end
        end

        def convert_idea_to_task(args)
          puts "Converting idea to task..."
          puts "Note: This functionality is not yet implemented"
          exit 0
        end

        def archive_idea(args)
          puts "Archiving idea..."
          puts "Note: This functionality is not yet implemented"
          exit 0
        end

        def list_ideas(args)
          puts "Listing ideas..."
          puts "Note: This functionality is not yet implemented"
          puts "Use 'ace-taskflow ideas' instead"
          exit 0
        end

        def show_help
          puts "Usage: ace-taskflow idea <content> [options]"
          puts "       ace-taskflow idea <subcommand> [args]"
          puts ""
          puts "Capture ideas:"
          puts "  ace-taskflow idea <content>          # Capture to active release (default)"
          puts "  ace-taskflow idea <content> --backlog # Capture to backlog"
          puts "  ace-taskflow idea <content> --release <name> # Capture to specific release"
          puts ""
          puts "Options:"
          puts "  --backlog         Capture idea to backlog"
          puts "  --release <name>  Capture to specific release"
          puts "  --current         Capture to current/active release (default)"
          puts ""
          puts "Subcommands:"
          puts "  to-task <id>      Convert idea to task"
          puts "  archive <id>      Archive an idea"
          puts "  list              List ideas (use 'ace-taskflow ideas' instead)"
          puts ""
          puts "Examples:"
          puts '  ace-taskflow idea "Add caching layer"'
          puts '  ace-taskflow idea "Future feature" --backlog'
          puts '  ace-taskflow idea "Bug fix" --release v.0.9.1'
        end
      end
    end
  end
end