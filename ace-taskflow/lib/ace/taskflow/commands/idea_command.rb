# frozen_string_literal: true

require_relative "../organisms/idea_writer"
require_relative "../molecules/config_loader"
require_relative "../molecules/release_resolver"
require_relative "../molecules/idea_loader"
require_relative "../molecules/idea_arg_parser"
require_relative "../models/idea"
require_relative "../atoms/path_formatter"
require 'stringio'

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
          when "done"
            mark_idea_done(args)
          when "reschedule"
            reschedule_idea(args)
          when "to-task"
            convert_idea_to_task(args)
          when "archive"
            archive_idea(args)
          when "--help", "-h"
            show_help
            exit 0
          else
            # Try to show specific idea by partial name, or create if not found
            show_idea_or_create(subaction, args)
          end
        rescue => e
          puts "Error: #{e.message}"
          exit 1
        end

        private

        def show_next_idea(args)
          # Use ideas command with limit 1 to get the next idea
          require_relative "ideas_command"
          ideas_cmd = IdeasCommand.new

          # Add --limit 1 to args for single idea display
          modified_args = args + ["--limit", "1"]

          # Capture output to process it
          original_stdout = $stdout
          output = StringIO.new
          $stdout = output

          begin
            ideas_cmd.execute(modified_args)
          rescue SystemExit => e
            # Handle exit calls from ideas command - but continue
          ensure
            $stdout = original_stdout
          end

          result = output.string

          # Check if no ideas were found
          if result.include?("No ideas found")
            puts "No ideas found in current release."
            puts "Use 'ace-taskflow idea create' to capture a new idea."
          elsif result && !result.empty?
            # Show the output from ideas command
            puts result
          else
            # If no output captured, try showing ideas directly
            ideas_cmd.execute(modified_args)
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

        def show_idea_or_create(first_arg, remaining_args)
          # If first_arg is a flag, treat this as a create command
          if first_arg.start_with?("--") || first_arg.start_with?("-")
            all_args = [first_arg] + remaining_args
            create_idea(all_args)
            return
          end

          # Try to find an existing idea
          context = parse_context(remaining_args)
          idea = @idea_loader.find_by_partial_name(first_arg, context: context)

          if idea
            # Found an idea, show it
            full_idea = @idea_loader.load_idea(idea[:path])
            display_idea(full_idea)
          else
            # No idea found, treat all arguments as content for a new idea
            all_args = [first_arg] + remaining_args
            create_idea(all_args)
          end
        end

        def create_idea(args)
          # Parse options for idea capture using IdeaArgParser
          options = Molecules::IdeaArgParser.parse_capture_options(args)

          # Check if content is provided (either via --note, positional, or --clipboard)
          if options[:content].empty? && !options[:clipboard]
            puts "Usage: ace-taskflow idea create <content> [options]"
            puts "Options:"
            puts "  --note <text>, -n    Explicit note text (takes precedence)"
            puts "  --clipboard, -c      Read content from clipboard"
            puts "  --backlog            Create in backlog"
            puts "  --release <name>     Create in specific release"
            puts "  --git-commit, -gc    Auto-commit the idea file"
            puts "  --llm-enhance, -llm  Enhance with LLM suggestions"
            exit 1
          end

          # Determine target location
          location = determine_location(options)

          # Check if --current was explicitly provided
          explicit_current = options[:location] == "current"

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
            # Active release (default or explicit --current)
            resolver = Molecules::ReleaseResolver.new(@root_path)
            primary = resolver.find_primary_active
            if primary
              config["directory"] = File.join(primary[:path], "ideas")
            else
              # If --current was explicitly provided but no release exists, error
              if explicit_current
                puts "Error: No current release found."
                puts "Use 'ace-taskflow release create' to create a release, or omit --current to save to backlog."
                exit 1
              end
              # Fall back to backlog if no active release (implicit/default behavior)
              config["directory"] = File.join(@root_path, "backlog", "ideas")
            end
          end

          # Capture the idea with options
          writer = Organisms::IdeaWriter.new(config)
          path = writer.write(options[:content], options)
          # Use project root, not .ace-taskflow root
          root_path = Dir.pwd
          relative_path = Atoms::PathFormatter.format_relative_path(path, root_path)
          puts "Idea captured: #{relative_path}"
        end

        def display_idea(idea_data)
          idea = Models::Idea.new(idea_data)

          puts "Idea: #{idea.id || idea.filename}"
          puts "Title: #{idea.title}"
          puts "Created: #{idea.created_at}"
          puts "Context: #{idea.context}"

          if idea.path
            # Use project root, not .ace-taskflow root
            root_path = Dir.pwd
            relative_path = Atoms::PathFormatter.format_relative_path(idea.path, root_path)
            puts "Path: #{relative_path}"
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

        # Delegated to IdeaArgParser - keeping for backward compatibility
        def parse_options(args)
          Molecules::IdeaArgParser.parse_capture_options(args)
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

        def reschedule_idea(args)
          reference = args.shift

          unless reference
            puts "Usage: ace-taskflow idea reschedule <reference> [options]"
            puts "Options:"
            puts "  --add-next         Place before other pending ideas"
            puts "  --add-at-end       Place after all ideas"
            puts "  --after <ref>      Place after specific idea"
            puts "  --before <ref>     Place before specific idea"
            exit 1
          end

          # Parse options
          options = {}
          i = 0
          while i < args.length
            case args[i]
            when "--add-next"
              options[:add_next] = true
              i += 1
            when "--add-at-end"
              options[:add_at_end] = true
              i += 1
            when "--after"
              options[:after] = args[i + 1]
              i += 2
            when "--before"
              options[:before] = args[i + 1]
              i += 2
            else
              i += 1
            end
          end

          # Reschedule the idea
          require_relative "../organisms/idea_scheduler"
          scheduler = Organisms::IdeaScheduler.new(@root_path)
          result = scheduler.reschedule(reference, options)

          if result[:success]
            puts result[:message]
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def mark_idea_done(args)
          reference = args.first

          unless reference
            puts "Usage: ace-taskflow idea done <reference>"
            puts "Example: ace-taskflow idea done implement-caching"
            exit 1
          end

          # Find the idea
          context = parse_context(args[1..-1] || [])
          idea = @idea_loader.find_by_partial_name(reference, context: context)

          unless idea
            puts "No idea found matching '#{reference}' in #{context_name(context)}."
            exit 1
          end

          # Move idea to done
          require_relative "../molecules/idea_directory_mover"
          mover = Molecules::IdeaDirectoryMover.new
          result = mover.move_to_done(idea[:path])

          if result[:success]
            puts "Idea '#{reference}' marked as done and moved to done/"
            puts "Completed at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end


        def show_help
          puts "Usage: ace-taskflow idea [subcommand] [options]"
          puts ""
          puts "Subcommands:"
          puts "  (none)             Show next idea from active release"
          puts "  <partial-name>     Show idea matching partial name"
          puts "  create <content>   Capture new idea"
          puts "    --note <text>, -n   Explicit note text (takes precedence)"
          puts "    --clipboard, -c     Read content from clipboard"
          puts "    --backlog           Create in backlog"
          puts "    --release <name>    Create in specific release"
          puts "    --git-commit, -gc   Auto-commit the idea file"
          puts "    --no-git-commit     Don't commit (overrides config)"
          puts "    --llm-enhance, -llm Enhance with LLM suggestions"
          puts "    --no-llm-enhance    Don't enhance (overrides config)"
          puts "  done <reference>   Mark idea as done and move to done/"
          puts "  reschedule <ref>   Reorder idea position"
          puts "    --add-next       Place before other pending ideas"
          puts "    --add-at-end     Place after all ideas"
          puts "    --after <ref>    Place after specific idea"
          puts "    --before <ref>   Place before specific idea"
          puts "  to-task <id>       Convert idea to task"
          puts "  archive <id>       Archive an idea"
          puts ""
          puts "Options:"
          puts "  --backlog          Work with backlog ideas"
          puts "  --release <name>   Work with specific release"
          puts "  --current          Work with current/active release (default)"
          puts ""
          puts "Configuration:"
          puts "  Set defaults in .ace/taskflow/config.yml:"
          puts "    taskflow:"
          puts "      idea:"
          puts "        defaults:"
          puts "          git_commit: true    # Auto-commit by default"
          puts "          llm_enhance: true   # Auto-enhance by default"
          puts ""
          puts "Examples:"
          puts "  ace-taskflow idea"
          puts "  ace-taskflow idea caching"
          puts "  ace-taskflow idea create 'Add caching layer'"
          puts "  ace-taskflow idea create --note 'Explicit text'"
          puts "  ace-taskflow idea create --clipboard"
          puts "  ace-taskflow idea create 'Main context' --clipboard"
          puts "  ace-taskflow idea create 'Future feature' --backlog"
          puts "  ace-taskflow idea create 'Bug fix' --release v.0.9.1"
          puts "  ace-taskflow idea create 'New feature' --git-commit"
          puts "  ace-taskflow idea create 'Complex task' --llm-enhance --git-commit"
        end
      end
    end
  end
end