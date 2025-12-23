# frozen_string_literal: true

require "optparse"
require_relative "../organisms/taskflow_context_loader"
require_relative "../molecules/task_display_formatter"
require_relative "../atoms/task_reference_parser"

module Ace
  module Taskflow
    module Commands
      # Handle context subcommand - provides taskflow context
      # Git state is available via ace-git context command
      class ContextCommand
        def execute(args)
          # Parse options
          options = parse_options(args)

          # If help was shown, return early with success
          # If invalid option was encountered, return early with failure
          if options.key?(:help_shown)
            return options[:help_shown] ? 0 : 1
          end

          # Load context (options no longer passed - taskflow doesn't do git operations)
          context = Organisms::TaskflowContextLoader.load

          # Format and output
          case options[:format]
          when "json"
            output_json(context)
          else
            output_markdown(context)
          end

          0
        rescue StandardError => e
          $stderr.puts "Error: #{e.message}"
          $stderr.puts e.backtrace.join("\n") if ENV["DEBUG"]
          1
        end

        private

        def parse_options(args)
          options = {
            format: "markdown"
          }

          parser = OptionParser.new do |opts|
            opts.banner = "Usage: ace-taskflow context [options]"
            opts.separator ""
            opts.separator "Get taskflow context (release and task information)."
            opts.separator "Git state is available via 'ace-git context' command."
            opts.separator ""
            opts.separator "Options:"

            opts.on("--json", "Output as JSON") do
              options[:format] = "json"
            end

            opts.on("--markdown", "Output as Markdown (default)") do
              options[:format] = "markdown"
            end

            opts.on("-h", "--help", "Show this help") do
              puts opts
              puts ""
              puts "Examples:"
              puts "  ace-taskflow context"
              puts "  ace-taskflow context --json"
              puts "  ace-git context      # For git state (branch, PR, etc.)"
              options[:help_shown] = true
              return options
            end
          end

          begin
            parser.parse!(args)
          rescue OptionParser::InvalidOption => e
            $stderr.puts "Error: #{e.message}"
            $stderr.puts "Use --help for usage information"
            options[:help_shown] = false
            return options
          end

          options
        end

        def output_json(context)
          require "json"
          # Convert RepoContext objects to hash for JSON serialization
          json_context = serialize_context_for_json(context)
          puts JSON.pretty_generate(json_context)
        end

        # Serialize context for JSON output
        # Handles nested values recursively
        def serialize_context_for_json(context)
          deep_serialize(context)
        end

        # Recursively serialize values for JSON output
        def deep_serialize(value)
          case value
          when Hash
            value.transform_values { |v| deep_serialize(v) }
          when Array
            value.map { |v| deep_serialize(v) }
          else
            value
          end
        end

        def output_markdown(context)
          puts "# Taskflow Context"
          puts ""

          # Only show taskflow-specific info (release, task)
          # Git state is handled by ace-git context command
          output_task_section(context[:task], context[:release])
        end

        def output_task_section(task, release = nil)
          # Show release info before task (belongs to ace-taskflow context)
          if release
            puts "Release: #{release[:name]} (#{release[:progress]}% - #{release[:done_tasks]}/#{release[:total_tasks]} tasks)"
            puts ""
          end

          if task.nil?
            puts "No task pattern detected in branch name."
            puts ""
            return
          end

          # Status icon
          status_icon = status_icon_for(task[:status])

          # Compact header with title inline
          puts "## Task: #{task[:id]} [#{status_icon}] #{task[:title]}"

          # Indented path
          path = format_relative_path(task[:path])
          puts "  Path: #{path}"
          puts ""

          # Run ace-taskflow task and show full output (indented)
          # If this is a subtask, show parent task context instead
          task_ref = task[:parent] || extract_task_number(task[:id])
          if task_ref
            # Add header for parent task context
            puts "### Parent Task" if task[:parent]
            show_task_details_from_command(task_ref)
          else
            puts "  Error: Invalid task reference (malformed task ID)"
          end
        end

        # Format status as emoji icon - delegates to shared TaskDisplayFormatter
        def status_icon_for(status)
          Molecules::TaskDisplayFormatter.status_icon(status)
        end

        # Extract task number from ID (e.g., "v.0.9.0+task.140.02" -> "140.02")
        # Returns nil if the ID format is invalid
        # Delegates to TaskReferenceParser for consistent parsing
        def extract_task_number(id)
          Atoms::TaskReferenceParser.extract_number(id)
        end

        # Format path relative to current directory using Pathname for cross-platform compatibility
        def format_relative_path(path)
          return path unless path

          project_root = ENV["PROJECT_ROOT_PATH"]
          return path unless project_root

          # Use Pathname for cross-platform path manipulation
          require "pathname"
          path_obj = Pathname.new(path)
          root_obj = Pathname.new(project_root)

          # Only compute relative path if path is under project_root
          begin
            if path_obj.descend.first == root_obj.descend.first || path.to_s.start_with?(project_root)
              path_obj.relative_path_from(root_obj).to_s
            else
              path
            end
          rescue ArgumentError
            # Path is not under project_root, return original
            path
          end
        end

        # Run ace-taskflow task command and indent output by 2 spaces
        # Returns true if output was shown successfully, false otherwise
        def show_task_details_from_command(task_ref)
          output = fetch_task_output(task_ref)
          if output.empty?
            # Task lookup failed (TaskCommand returns empty output for not-found)
            return false
          end
          output.each_line do |line|
            puts "  #{line}"
          end
          true
        end

        # Fetch task output by calling TaskCommand directly
        # This avoids subprocess overhead (~0.5-1s) from Ruby startup
        # Separate method to allow stubbing in tests
        def fetch_task_output(task_ref)
          require_relative "task_command"
          require "stringio"

          original_stdout = $stdout
          output = StringIO.new
          $stdout = output

          begin
            # Use public API - execute with task reference
            cmd = Ace::Taskflow::Commands::TaskCommand.new
            cmd.execute([task_ref.to_s])
          rescue StandardError => e
            # Log unexpected errors for DEBUG, but don't fail the entire context command
            $stderr.puts "Debug [ContextCommand]: Task lookup error: #{e.message}" if ENV["DEBUG"]
          ensure
            $stdout = original_stdout
          end

          output.string
        end
      end
    end
  end
end
