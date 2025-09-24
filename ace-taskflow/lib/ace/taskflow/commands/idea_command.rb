# frozen_string_literal: true

require_relative "../organisms/idea_writer"
require_relative "../molecules/config_loader"
require_relative "../molecules/release_resolver"
require_relative "../molecules/idea_loader"
require_relative "../models/idea"

module Ace
  module Taskflow
    module Commands
      class IdeaCommand
        def initialize
          @config = Molecules::ConfigLoader.load
          @root_path = Molecules::ConfigLoader.find_root
          @idea_loader = Molecules::IdeaLoader.new(@root_path)
        end

        def execute(args)
          # Parse command and options
          if args.include?("--help") || args.include?("-h")
            show_help
            exit 0
          end

          subaction = args.shift

          case subaction
          when nil
            show_next_idea(args)
          when "create"
            create_idea(args)
          when "to-task"
            convert_idea_to_task(args)
          when "archive"
            archive_idea(args)
          when "--help", "-h"
            show_help
            exit 0
          else
            # Try to show specific idea by partial name
            show_idea(subaction, args)
          end
        rescue => e
          puts "Error: #{e.message}"
          exit 1
        end

        private

        def show_next_idea(args)
          context = parse_context(args)
          idea = @idea_loader.find_next(context: context)

          if idea
            display_idea(idea)
          else
            puts "No ideas found in #{context_name(context)}."
            puts "Use 'ace-taskflow idea create' to capture a new idea."
          end
        end

        def show_idea(reference, args)
          context = parse_context(args)
          idea = @idea_loader.find_by_partial_name(reference, context: context)

          if idea
            # Load with full content
            full_idea = @idea_loader.load_idea(idea[:path])
            display_idea(full_idea)
          else
            puts "No idea found matching '#{reference}' in #{context_name(context)}."
            exit 1
          end
        end

        def create_idea(args)
          # Parse options for idea capture
          options = parse_capture_options(args)

          if options[:content].empty?
            puts "Usage: ace-taskflow idea create <content> [options]"
            puts "Options:"
            puts "  --backlog          Create in backlog"
            puts "  --release <name>   Create in specific release"
            exit 1
          end

          # Determine target location
          location = determine_location(options)

          # Update config with location
          config = @config.dup
          if location == "backlog"
            config["directory"] = File.join(@root_path, "backlog", "ideas")
          elsif location.start_with?("v.")
            # Release-specific location
            release_path = resolve_release_path(location)
            if release_path
              config["directory"] = File.join(release_path, "ideas")
            else
              puts "Error: Release '#{location}' not found"
              exit 1
            end
          else
            # Active release (default)
            resolver = Molecules::ReleaseResolver.new(@root_path)
            primary = resolver.find_primary_active
            if primary
              config["directory"] = File.join(primary[:path], "ideas")
            else
              # Fall back to backlog if no active release
              config["directory"] = File.join(@root_path, "backlog", "ideas")
            end
          end

          # Capture the idea
          writer = Organisms::IdeaWriter.new(config)
          path = writer.write(options[:content])
          puts "Idea captured: #{path}"
        end

        def display_idea(idea_data)
          idea = Models::Idea.new(idea_data)

          puts "Idea: #{idea.id || idea.filename}"
          puts "Title: #{idea.title}"
          puts "Created: #{idea.created_at}"
          puts "Context: #{idea.context}"

          if idea.path
            puts "Path: #{idea.path}"
          end

          if idea.content
            puts ""
            puts "--- Content ---"
            puts idea.content
          end
        end

        def parse_context(args)
          args.each_with_index do |arg, index|
            case arg
            when "--backlog"
              return "backlog"
            when "--release", "-r"
              return args[index + 1]
            when "--current"
              return "current"
            end
          end
          "current"
        end

        def context_name(context)
          case context
          when "current", "active"
            "current release"
          when "backlog"
            "backlog"
          else
            "release #{context}"
          end
        end

        def parse_capture_options(args)
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

        def parse_options(args)
          parse_capture_options(args)
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


        def show_help
          puts "Usage: ace-taskflow idea [subcommand] [options]"
          puts ""
          puts "Subcommands:"
          puts "  (none)             Show next idea from active release"
          puts "  <partial-name>     Show idea matching partial name"
          puts "  create <content>   Capture new idea"
          puts "    --backlog        Create in backlog"
          puts "    --release <name> Create in specific release"
          puts "  to-task <id>       Convert idea to task"
          puts "  archive <id>       Archive an idea"
          puts ""
          puts "Options:"
          puts "  --backlog          Work with backlog ideas"
          puts "  --release <name>   Work with specific release"
          puts "  --current          Work with current/active release (default)"
          puts ""
          puts "Examples:"
          puts "  ace-taskflow idea"
          puts "  ace-taskflow idea caching"
          puts "  ace-taskflow idea create 'Add caching layer'"
          puts "  ace-taskflow idea create 'Future feature' --backlog"
          puts "  ace-taskflow idea create 'Bug fix' --release v.0.9.1"
        end
      end
    end
  end
end