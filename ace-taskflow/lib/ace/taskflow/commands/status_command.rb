# frozen_string_literal: true

require "optparse"
require_relative "../organisms/taskflow_context_loader"
require_relative "../molecules/task_display_formatter"
# Note: StatsFormatter not used here - we format release header inline
# to avoid TaskManager re-instantiation (context loader already has release stats)
require_relative "../atoms/task_reference_parser"

module Ace
  module Taskflow
    module Commands
      # Handle status subcommand - provides taskflow status
      # Shows current task, activity, and operational state
      # Git state is available via ace-git context command
      class StatusCommand
        def execute(args)
          # Parse options
          options = parse_options(args)

          # If help was shown, return early with success
          # If invalid option was encountered, return early with failure
          if options.key?(:help_shown)
            return options[:help_shown] ? 0 : 1
          end

          # Build loader options from CLI flags (override config per ADR-022)
          # Use options.key? instead of truthiness check to allow 0 values (0 disables section)
          loader_options = {}
          loader_options[:recently_done_limit] = options[:recently_done_limit] if options.key?(:recently_done_limit)
          loader_options[:up_next_limit] = options[:up_next_limit] if options.key?(:up_next_limit)
          loader_options[:include_drafts] = options[:include_drafts] if options.key?(:include_drafts)

          # Load context with activity options
          context = Organisms::TaskflowContextLoader.load(loader_options)

          # Format and output
          # Pass include_activity option for display control (default: true)
          display_options = loader_options.merge(
            include_activity: options.fetch(:include_activity, true)
          )

          case options[:format]
          when "json"
            output_json(context, display_options)
          else
            output_markdown(context, display_options)
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
            opts.banner = "Usage: ace-taskflow status [options]"
            opts.separator ""
            opts.separator "Show current taskflow status (release, task, and activity)."
            opts.separator "Git state is available via 'ace-git context' command."
            opts.separator ""
            opts.separator "Options:"

            opts.on("--json", "Output as JSON") do
              options[:format] = "json"
            end

            opts.on("--markdown", "Output as Markdown (default)") do
              options[:format] = "markdown"
            end

            opts.separator ""
            opts.separator "Activity Display (override config):"

            opts.on("--recently-done-limit N", Integer, "Max recently done tasks to show") do |n|
              options[:recently_done_limit] = n
            end

            opts.on("--up-next-limit N", Integer, "Max up next tasks to show") do |n|
              options[:up_next_limit] = n
            end

            opts.on("--[no-]include-drafts", "Include draft tasks in Up Next") do |v|
              options[:include_drafts] = v
            end

            opts.on("--[no-]include-activity", "Include task activity section (default: true)") do |v|
              options[:include_activity] = v
            end

            opts.on("-h", "--help", "Show this help") do
              puts opts
              puts ""
              puts "Examples:"
              puts "  ace-taskflow status"
              puts "  ace-taskflow status --json"
              puts "  ace-taskflow status --recently-done-limit 5 --up-next-limit 10"
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

        def output_json(context, display_options = {})
          require "json"
          # Convert RepoContext objects to hash for JSON serialization
          json_context = serialize_context_for_json(context)
          # Remove task_activity if --no-include-activity was specified
          json_context.delete(:task_activity) if display_options[:include_activity] == false
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

        def output_markdown(context, display_options = {})
          puts "# Taskflow Status"
          puts ""

          # Only show taskflow-specific info (release, task)
          # Git state is handled by ace-git context command
          output_task_section(context[:task], context[:release])

          # Output task activity section if available and not disabled
          if context[:task_activity] && display_options[:include_activity] != false
            puts ""
            # Pass limit options to skip sections when limit=0
            output_activity_section(context[:task_activity], display_options)
          end
        end

        def output_activity_section(activity, loader_options = {})
          # Skip sections entirely when their limit is explicitly set to 0
          format_options = {
            skip_recently_done: loader_options[:recently_done_limit] == 0,
            skip_up_next: loader_options[:up_next_limit] == 0
          }
          formatted = Molecules::TaskDisplayFormatter.format_activity_section(activity, format_options)
          puts formatted unless formatted.empty?
        end

        def output_task_section(task, release = nil)
          # Show release info before task (belongs to ace-taskflow context)
          # Format inline using loader-provided stats to avoid TaskManager re-instantiation
          if release
            puts "## Release: #{format_release_header(release)}"
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

          # Compute relative path; Pathname raises ArgumentError if paths don't share ancestor
          begin
            path_obj.relative_path_from(root_obj).to_s
          rescue ArgumentError
            # Path is not under project_root, return original
            path
          end
        end

        # Format release header using loader-provided stats
        # Avoids StatsFormatter instantiation which would create TaskManager/ReleaseResolver
        # @param release [Hash] Release info with :name, :done_tasks, :total_tasks, :codename
        # @return [String] Formatted header like "v.0.9.0: 15/31 tasks • Mono-Repo Multiple Gems"
        def format_release_header(release)
          name = release[:name]
          done = release[:done_tasks] || 0
          total = release[:total_tasks] || 0
          codename = release[:codename]

          header = "#{name}: #{done}/#{total} tasks"
          header += " • #{codename}" if codename && !codename.empty?
          header
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
            # Log unexpected errors for debugging, but don't fail the entire status command
            if defined?(Ace::Core) && Ace::Core.respond_to?(:logger)
              Ace::Core.logger.debug("[StatusCommand] Task lookup error: #{e.message}")
            elsif ENV["DEBUG"]
              $stderr.puts "[StatusCommand] Task lookup error: #{e.message}"
            end
          ensure
            $stdout = original_stdout
          end

          output.string
        end
      end
    end
  end
end
