# frozen_string_literal: true

require "dry/cli"
require_relative "../commands/idea_command"
require_relative "../commands/ideas_command"
require_relative "../models/idea"
require_relative "../atoms/path_formatter"

module Ace
  module Taskflow
    module CLI
      # dry-cli Command class for base idea command
      #
      # Handles:
      # - Showing next idea (no arguments)
      # - Showing specific idea by partial name (argument provided)
      #
      # Subcommands (create, done, park, unpark, reschedule) are now
      # registered separately as nested dry-cli commands.
      #
      # IMPORTANT: Does NOT define argument declarations to allow dry-cli
      # to properly route to nested subcommands. Uses options[:args] instead.
      class Idea < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Show idea details

          Displays the next idea from the active release, or shows
          a specific idea by partial name or ID.

          For creating and managing ideas, use the nested subcommands:
            - idea create
            - idea done
            - idea park
            - idea unpark
            - idea reschedule

        DESC

        example [
          '                         # Show next idea',
          'caching                  # Show idea by partial name',
          'idea.123                 # Show idea by ID'
        ]

        option :backlog, type: :boolean, desc: "Show idea from backlog"
        option :release, type: :string, aliases: %w[-r], desc: "Show idea from specific release"
        option :current, type: :boolean, desc: "Show idea from current/active release (default)"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(**options)
          # Display config summary unless quiet mode
          display_config_summary(options) unless quiet?(options)

          # Remaining arguments are in options[:args]
          # dry-cli passes unparsed arguments here when no argument declaration matches
          args = options[:args] || []

          # If no reference, show next idea
          if args.empty?
            show_next_idea
          else
            # First arg is the reference
            reference = args.first
            show_idea_by_reference(reference, options)
          end
        end

        private

        # Display config summary
        def display_config_summary(options)
          return unless verbose?(options)

          Ace::Core::Atoms::ConfigSummary.display(
            command: "idea",
            config: Ace::Taskflow.config,
            defaults: Ace::Taskflow.default_config,
            options: options,
            summary_keys: %w[current_release idea_location]
          )
        end

        # Show next idea using ideas command
        def show_next_idea
          ideas_cmd = Commands::IdeasCommand.new
          modified_args = ["--limit", "1"]

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

          exit_success
        end

        # Show idea by reference
        # @param reference [String] Idea reference (partial name or ID)
        # @param options [Hash] dry-cli parsed options
        def show_idea_by_reference(reference, options)
          root_path = Ace::Taskflow::Molecules::ConfigLoader.find_root
          idea_loader = Ace::Taskflow::Molecules::IdeaLoader.new(root_path)

          # Parse release from options
          release = parse_release(options)

          idea = idea_loader.find_by_partial_name(reference, release: release)

          if idea
            # Load with full content
            full_idea = idea_loader.load_idea(idea[:path])
            display_idea(full_idea)
            exit_success
          else
            puts "No idea found matching '#{reference}' in #{release_name(release)}."
            exit_failure
          end
        end

        # Parse release from options
        # @param options [Hash] dry-cli parsed options
        # @return [String] Release identifier
        def parse_release(options)
          return "backlog" if options[:backlog]
          return options[:release] if options[:release]
          return "current" if options[:current]
          "current"
        end

        # Get human-readable release name
        # @param release [String] Release identifier
        # @return [String] Human-readable name
        def release_name(release)
          case release
          when "current", "active"
            "current release"
          when "backlog"
            "backlog"
          else
            "release #{release}"
          end
        end

        # Display idea details
        # @param idea_data [Hash] Idea data from loader
        def display_idea(idea_data)
          idea = Ace::Taskflow::Models::Idea.new(idea_data)

          puts "Idea: #{idea.id || idea.filename}"
          puts "Title: #{idea.title}"
          puts "Created: #{idea.created_at}"
          puts "Release: #{idea.release}"

          if idea.path
            # Use project root, not .ace-taskflow root
            root_path = Dir.pwd
            relative_path = Ace::Taskflow::Atoms::PathFormatter.format_relative_path(idea.path, root_path)
            puts "Path: #{relative_path}"
          end

          if idea.content
            puts ""
            puts "--- Content ---"
            puts idea.content
          end
        end
      end
    end
  end
end

