# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/task_manager"

module Ace
  module Taskflow
    module CLI
      module Commands
        module TaskSubcommands
          # dry-cli Command class for task create nested subcommand
          #
          # Calls TaskManager directly for task creation, bypassing the legacy
          # args-to-options round-trip through TaskCommand.
          #
          # Features:
          # - Proper help display via --help
          # - Type conversion for options
          # - Direct business logic invocation
          class Create < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Create a new task

              Creates a new task with optional metadata.
              Title can be provided as positional argument or via --title flag.
              When both are provided, --title takes precedence.

            DESC

            example [
              '                                          # Interactive prompt',
              '"Add caching layer"                       # With positional title',
              '--title "Fix bug" --status draft --estimate 2h  # With options',
              '"Write tests" --dependencies 041,042      # With dependencies',
              '"Archive output" --child-of 121           # As subtask',
              '--dry-run --title "Test"                  # Preview without creating'
            ]

            # Task metadata options
            argument :title, required: false, desc: "Task title (can also use --title)"

            option :title, type: :string, desc: "Task title (alternative to positional, takes precedence)"
            option :status, type: :string, desc: "Initial status (pending, draft, in-progress, done, blocked)"
            option :estimate, type: :string, desc: "Effort estimate (e.g., 2h, 1d, TBD)"
            option :dependencies, type: :string, desc: "Comma-separated dependency list (e.g., 041,042)"
            option :"child-of", type: :string, aliases: ["-p"], desc: "Create as subtask under parent task"
            option :backlog, type: :boolean, desc: "Create task in backlog"
            option :release, type: :string, desc: "Create in specific release"
            option :"dry-run", type: :boolean, aliases: ["-n"], desc: "Preview what would be created without creating"

            # Standard options (inherited from Base but need explicit definition for dry-cli)
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(title: nil, **options)
              # Display config summary unless quiet mode
              display_config_summary(options) unless quiet?(options)

              # Resolve title: --title flag takes precedence over positional
              final_title = options[:title] || title

              if final_title.nil? || final_title.empty?
                puts "\nUsage: ace-taskflow task create <title> [options]"
                puts "   or: ace-taskflow task create --title 'Task title' [options]"
                raise Ace::Core::CLI::Error.new("Task title is required")
              end

              # Resolve release
              release = determine_release(options)

              # Build metadata from options
              metadata = build_metadata(options)

              # Handle dry-run mode
              if options[:"dry-run"]
                display_dry_run(final_title, release, options[:"child-of"], metadata)
                return
              end

              # Call TaskManager directly
              manager = Ace::Taskflow::Organisms::TaskManager.new
              result = if options[:"child-of"]
                manager.create_subtask(
                  options[:"child-of"],
                  final_title,
                  release: release,
                  metadata: metadata
                )
              else
                manager.create_task(final_title, release: release, metadata: metadata)
              end

              # Display result
              unless result[:success]
                raise Ace::Core::CLI::Error.new(result[:message])
              end

              puts result[:message]
              puts "Path: #{result[:path]}"
            end

            private

            # Display config summary to stderr (per gem standards)
            # @param options [Hash] dry-cli parsed options
            def display_config_summary(options)
              return unless verbose?(options)

              Ace::Core::Atoms::ConfigSummary.display(
                command: "task create",
                config: Ace::Taskflow.config,
                defaults: Ace::Taskflow.default_config,
                options: options,
                summary_keys: %w[current_release task_dir]
              )
            end

            # Determine release from options
            # @param options [Hash] dry-cli parsed options
            # @return [String] Release identifier
            def determine_release(options)
              if options[:backlog]
                "backlog"
              elsif options[:release]
                options[:release]
              else
                "current"
              end
            end

            # Build metadata hash from dry-cli options
            # @param options [Hash] dry-cli parsed options
            # @return [Hash] Metadata for task creation
            def build_metadata(options)
              metadata = {}
              metadata[:status] = options[:status] if options[:status]
              metadata[:estimate] = options[:estimate] if options[:estimate]
              if options[:dependencies]
                metadata[:dependencies] = options[:dependencies].split(",").map(&:strip)
              end
              metadata
            end

            # Display dry-run preview
            # @param title [String] Task title
            # @param release [String] Release identifier
            # @param parent_ref [String, nil] Parent task reference (for subtask)
            # @param metadata [Hash] Task metadata
            def display_dry_run(title, release, parent_ref, metadata)
              puts "[DRY-RUN] Would create task:"
              puts "  Title: #{title}"
              puts "  Release: #{release}"

              if parent_ref
                puts "  Parent: #{parent_ref} (subtask)"
              end

              puts "  Status: #{metadata[:status] || 'pending'}"
              puts "  Estimate: #{metadata[:estimate] || 'TBD'}"

              if metadata[:dependencies]&.any?
                puts "  Dependencies: #{metadata[:dependencies].join(', ')}"
              end

              # Show estimated path pattern
              release_display = release == "current" ? "<current-release>" : release
              if parent_ref
                puts "  Path: .ace-taskflow/#{release_display}/tasks/<parent-dir>/<id>-<slug>.s.md"
              else
                puts "  Path: .ace-taskflow/#{release_display}/tasks/<id>-<slug>/<id>-<slug>.s.md"
              end

              puts ""
              puts "No files created (dry-run mode)"
            end

            # Build args array for TaskCommand#create_task from dry-cli options
            # Retained for backward compatibility with tests that exercise this method.
            # @param title [String, nil] Positional title argument
            # @param options [Hash] dry-cli parsed options
            # @return [Array<String>] Args array for TaskCommand#create_task
            def build_args_for_create(title, options)
              args = []

              # Title handling: --title takes precedence over positional
              final_title = options[:title] || title
              args << final_title if final_title

              # Add options as flags
              args << "--status" << options[:status] if options[:status]
              args << "--estimate" << options[:estimate] if options[:estimate]
              args << "--dependencies" << options[:dependencies] if options[:dependencies]
              args << "--child-of" << options[:"child-of"] if options[:"child-of"]
              args << "--backlog" if options[:backlog]
              args << "--release" << options[:release] if options[:release]
              args << "--dry-run" if options[:"dry-run"]

              args
            end
          end
        end
      end
    end
  end
end

