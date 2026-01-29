# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/idea_writer"
require_relative "../../../molecules/config_loader"
require_relative "../../../molecules/release_resolver"
require_relative "../../../molecules/idea_arg_parser"
require_relative "../../../atoms/path_formatter"

module Ace
  module Taskflow
    module CLI
      module Commands
        module IdeaSubcommands
          # dry-cli Command class for idea create nested subcommand
          #
          # Captures ideas with optional metadata and location targeting.
          #
          # Features:
          # - Proper help display via --help
          # - Type conversion for options
          # - Direct business logic invocation
          class Create < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Create a new idea

              Captures a new idea with optional content and location targeting.
              Content can be provided as positional argument or via --note flag.
              When both are provided, --note takes precedence.

            DESC

            example [
              '"Add caching layer"                    # With positional content',
              '--note "Explicit text"                 # With --note flag (takes precedence)',
              '--clipboard                            # Read content from clipboard',
              '--backlog                              # Create in backlog',
              '--maybe                                # Create in maybe/ scope',
              '--anyday                               # Create in anyday/ scope',
              '--git-commit                           # Auto-commit the idea file',
              '--llm-enhance                          # Enhance with LLM suggestions'
            ]

            # Idea content and location options
            argument :content, required: false, desc: "Idea content (can also use --note)"

            option :note, type: :string, aliases: %w[-n], desc: "Explicit note text (takes precedence over positional)"
            option :clipboard, type: :boolean, aliases: %w[-c], desc: "Read content from clipboard"
            option :backlog, type: :boolean, desc: "Create in backlog"
            option :release, type: :string, aliases: %w[-r], desc: "Create in specific release"
            option :current, type: :boolean, desc: "Create in current/active release"
            option :maybe, type: :boolean, desc: "Create in maybe/ scope (uncertain ideas)"
            option :anyday, type: :boolean, desc: "Create in anyday/ scope (not urgent)"
            option :"git-commit", type: :boolean, aliases: %w[-gc], desc: "Auto-commit the idea file"
            option :"no-git-commit", type: :boolean, desc: "Don't commit (overrides config)"
            option :"llm-enhance", type: :boolean, aliases: %w[-llm --llm], desc: "Enhance with LLM suggestions"
            option :"no-llm-enhance", type: :boolean, desc: "Don't enhance (overrides config)"

            # Standard options (inherited from Base but need explicit definition for dry-cli)
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(content: nil, **options)
              # Display config summary unless quiet mode
              display_config_summary(options) unless quiet?(options)

              # Build capture options from dry-cli options
              capture_options = build_capture_options(content, options)

              # Validate that content is provided (either via --note, positional, or --clipboard)
              if capture_options[:content].empty? && !capture_options[:clipboard]
                puts "\nUsage: ace-taskflow idea create <content> [options]"
                puts "   or: ace-taskflow idea create --note 'Idea content' [options]"
                puts "   or: ace-taskflow idea create --clipboard [options]"
                raise Ace::Core::CLI::Error.new("Idea content is required")
              end

              # Execute idea creation
              execute_create(capture_options)
            end

            private

            # Display config summary to stderr (per gem standards)
            # @param options [Hash] dry-cli parsed options
            def display_config_summary(options)
              return unless verbose?(options)

              Ace::Core::Atoms::ConfigSummary.display(
                command: "idea create",
                config: Ace::Taskflow.config,
                defaults: Ace::Taskflow.default_config,
                options: options,
                summary_keys: %w[current_release idea_location]
              )
            end

            # Build capture options hash from dry-cli options
            # @param content [String, nil] Positional content argument
            # @param options [Hash] dry-cli parsed options
            # @return [Hash] Options for IdeaArgParser
            def build_capture_options(content, options)
              # Build args array for IdeaArgParser
              args = []

              # Add options as flags first
              args << "--note" << options[:note] if options[:note]
              args << "--clipboard" if options[:clipboard]

              # Content handling: only add positional content if --note is not provided
              # --note takes precedence, so don't duplicate by adding positional arg too
              final_content = options[:note] || content
              args << final_content if final_content && !options[:note]
              args << "--backlog" if options[:backlog]
              args << "--release" << options[:release] if options[:release]
              args << "--current" if options[:current]
              args << "--maybe" if options[:maybe]
              args << "--anyday" if options[:anyday]
              args << "--git-commit" if options[:"git-commit"]
              args << "--no-git-commit" if options[:"no-git-commit"]
              args << "--llm-enhance" if options[:"llm-enhance"]
              args << "--no-llm-enhance" if options[:"no-llm-enhance"]

              # Parse using IdeaArgParser
              Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options(args)
            end

            # Execute idea creation logic
            # @param capture_options [Hash] Parsed capture options
            def execute_create(capture_options)
              config = Ace::Taskflow::Molecules::ConfigLoader.load
              root_path = Ace::Taskflow::Molecules::ConfigLoader.find_root

              # Determine target location
              location = determine_location(capture_options, config, root_path)

              # Check if --current was explicitly provided
              explicit_current = capture_options[:location] == "current"

              # Update config with location
              target_config = config.dup
              if location == "backlog"
                target_config["directory"] = File.join(root_path, "backlog", "ideas")
              elsif location.start_with?("v.")
                # Release-specific location
                release_path = resolve_release_path(location, root_path)
                if release_path
                  target_config["directory"] = File.join(release_path, "ideas")
                else
                  raise Ace::Core::CLI::Error.new("Release '#{location}' not found")
                end
              else
                # Active release (default or explicit --current)
                resolver = Ace::Taskflow::Molecules::ReleaseResolver.new(root_path)
                primary = resolver.find_primary_active
                if primary
                  target_config["directory"] = File.join(primary[:path], "ideas")
                else
                  # If --current was explicitly provided but no release exists, error
                  if explicit_current
                    puts "Use 'ace-taskflow release create' to create a release, or omit --current to save to backlog."
                    raise Ace::Core::CLI::Error.new("No current release found.")
                  end
                  # Fall back to backlog if no active release (implicit/default behavior)
                  target_config["directory"] = File.join(root_path, "backlog", "ideas")
                end
              end

              # Append scope subdirectory if --maybe or --anyday flag was provided
              if capture_options[:subdirectory]
                target_config["directory"] = File.join(target_config["directory"], capture_options[:subdirectory])
              end

              # Capture the idea with options
              writer = Ace::Taskflow::Organisms::IdeaWriter.new(target_config)
              path = writer.write(capture_options[:content], capture_options)

              # Use project root, not .ace-taskflow root
              relative_path = Ace::Taskflow::Atoms::PathFormatter.format_relative_path(path, Dir.pwd)
              puts "Idea captured: #{relative_path}"
            end

            # Determine idea location from capture options
            # @param capture_options [Hash] Parsed options from IdeaArgParser
            # @param config [Hash] Configuration
            # @param root_path [String] Root path
            # @return [String] Location identifier
            def determine_location(capture_options, config, root_path)
              # Explicit location from flags
              return capture_options[:location] if capture_options[:location]

              # Default based on configuration
              Ace::Taskflow::Molecules::IdeaArgParser.determine_location(capture_options, config)
            end

            # Resolve release path from release name
            # @param release_name [String] Release identifier
            # @param root_path [String] Root path
            # @return [String, nil] Release path or nil if not found
            def resolve_release_path(release_name, root_path)
              resolver = Ace::Taskflow::Molecules::ReleaseResolver.new(root_path)
              release = resolver.find_release(release_name)
              release ? release[:path] : nil
            end
          end
        end
      end
    end
  end
end
