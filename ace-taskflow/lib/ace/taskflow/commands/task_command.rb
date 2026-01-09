# frozen_string_literal: true

require "yaml"
require_relative "../organisms/task_manager"
require_relative "../molecules/list_preset_manager"
require_relative "../molecules/task_filter"
require_relative "../molecules/dependency_tree_visualizer"
require_relative "../molecules/task_arg_parser"
require_relative "../molecules/task_field_updater"
require 'stringio'
require_relative "../models/task"
require_relative "../atoms/path_formatter"
require_relative "helpers"

module Ace
  module Taskflow
    module Commands
      # Handle base task command (show next task, show specific task)
      #
      # This is a simplified version that only handles the base "task" command cases.
      # All subcommands (create, show, start, done, etc.) are now handled
      # by nested dry-cli commands in Commands::Task::* namespace.
      class TaskCommand
        include Helpers

        def initialize(args = [], options = {})
          @args = args
          @options = options
          @manager = Organisms::TaskManager.new
          @preset_manager = Molecules::ListPresetManager.new
        end

        def execute(args = nil)
          # Use passed args or instance args
          args ||= @args

          display_config_summary(args)

          # Parse display mode options first
          display_mode = parse_display_mode(args)

          # Check if this is a subcommand or direct task reference
          subaction = args.shift

          # Handle subcommands (for backward compatibility with tests and direct API calls)
          case subaction
          when nil, "next"
            show_next_task(args, display_mode: display_mode)
          when "show"
            reference = args.shift
            unless reference
              puts "Error: 'show' requires a task reference"
              puts "Usage: ace-taskflow task show <reference>"
              return 1
            end
            show_task(reference, display_mode: display_mode)
          when "create"
            execute_create(args)
          when "start"
            execute_start(args)
          when "done"
            execute_done(args)
          when "undone"
            execute_undone(args)
          when "defer"
            execute_defer(args)
          when "undefer"
            execute_undefer(args)
          when "move"
            execute_move(args)
          when "update"
            execute_update(args)
          when "add-dependency"
            execute_add_dependency(args)
          when "remove-dependency"
            execute_remove_dependency(args)
          else
            # Try to show specific task (direct reference)
            show_task(subaction, display_mode: display_mode)
          end
        rescue StandardError => e
          puts "Error: #{e.message}"
          return 1
        end

        private

        def execute_create(args)
          # Parse options using TaskArgParser
          begin
            options = Molecules::TaskArgParser.parse_create_args_with_optparse(args)
          rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
            puts "Error: #{e.message}"
            puts "\nUsage: ace-taskflow task create [TITLE] [options]"
            puts "Run 'ace-taskflow task create --help' for full usage"
            return 1
          end

          title = options[:title]

          if title.nil? || title.empty?
            puts "Error: Task title is required"
            puts "\nUsage: ace-taskflow task create <title> [options]"
            puts "   or: ace-taskflow task create --title 'Task title' [options]"
            puts "\nRun 'ace-taskflow task create --help' for full usage"
            return 1
          end

          # Handle dry-run mode
          if options[:dry_run]
            display_create_dry_run(title, options)
            return 0
          end

          # Route based on parent_ref presence
          result = if options[:parent_ref]
            @manager.create_subtask(
              options[:parent_ref],
              title,
              release: options[:release],
              metadata: options[:metadata] || {}
            )
          else
            @manager.create_task(title, release: options[:release], metadata: options[:metadata])
          end

          if result[:success]
            puts result[:message]
            puts "Path: #{result[:path]}"
            0
          else
            puts "Error: #{result[:message]}"
            1
          end
        end

        def execute_start(args)
          reference = args.first

          unless reference
            puts "Usage: ace-taskflow task start <reference>"
            puts "Example: ace-taskflow task start 019"
            return 1
          end

          result = @manager.start_task(reference)

          if result[:success]
            puts result[:message]
            puts "Started at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            0
          else
            puts "Error: #{result[:message]}"
            1
          end
        end

        def execute_done(args)
          reference = args.first

          unless reference
            puts "Usage: ace-taskflow task done <reference>"
            puts "Example: ace-taskflow task done 019"
            return 1
          end

          result = @manager.complete_task(reference)

          if result[:success]
            puts result[:message]
            puts "Completed at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            0
          else
            puts "Error: #{result[:message]}"
            1
          end
        end

        def execute_undone(args)
          reference = args.first

          unless reference
            puts "Usage: ace-taskflow task undone <reference>"
            puts "Example: ace-taskflow task undone 019"
            return 1
          end

          result = @manager.reopen_task(reference)

          if result[:success]
            puts result[:message]
            puts "Reopened at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            0
          else
            puts "Error: #{result[:message]}"
            1
          end
        end

        def execute_defer(args)
          reference = args.first

          unless reference
            puts "Usage: ace-taskflow task defer <reference>"
            puts "Example: ace-taskflow task defer 019"
            return 1
          end

          result = @manager.defer_task(reference)

          if result[:success]
            puts result[:message]
            puts "Deferred at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            0
          else
            puts "Error: #{result[:message]}"
            1
          end
        end

        def execute_undefer(args)
          reference = args.first

          unless reference
            puts "Usage: ace-taskflow task undefer <reference>"
            puts "Example: ace-taskflow task undefer 019"
            return 1
          end

          result = @manager.undefer_task(reference)

          if result[:success]
            puts result[:message]
            puts "Restored at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            0
          else
            puts "Error: #{result[:message]}"
            1
          end
        end

        def execute_move(args)
          # Parse arguments using TaskArgParser
          begin
            options = Molecules::TaskArgParser.parse_move_args_with_optparse(args)
          rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
            puts "Error: #{e.message}"
            puts "\nUsage: ace-taskflow task move TASK_REF [options]"
            puts "Run 'ace-taskflow task move --help' for full usage"
            return 1
          end

          reference = options[:task_ref]

          unless reference
            puts "Error: Task reference required"
            puts "\nUsage: ace-taskflow task move TASK_REF [options]"
            puts "Run 'ace-taskflow task move --help' for full usage"
            return 1
          end

          # Route based on --child-of value
          result = case options[:child_of]
          when :promote
            # --child-of without value: promote subtask to standalone
            @manager.promote_to_standalone(reference, dry_run: options[:dry_run])
          when "self"
            # --child-of self: convert to orchestrator
            @manager.convert_to_orchestrator(reference, dry_run: options[:dry_run])
          when String
            # --child-of PARENT: demote to subtask
            @manager.demote_to_subtask(reference, options[:child_of], dry_run: options[:dry_run])
          else
            # No --child-of: release move
            release_target = options[:release]
            unless release_target
              puts "Error: Target release required (use --release VERSION, --backlog, or positional argument)"
              puts "\nUsage: ace-taskflow task move TASK_REF TARGET_RELEASE"
              puts "   or: ace-taskflow task move TASK_REF --release VERSION"
              puts "   or: ace-taskflow task move TASK_REF --child-of PARENT"
              return 1
            end
            if options[:dry_run]
              puts "Note: --dry-run is not yet supported for release moves. Showing what would happen:"
              puts "  - Move task #{reference} to release #{release_target}"
              return 0
            end
            @manager.move_task(reference, release_target)
          end

          if result[:success]
            puts result[:message]
            if result[:dry_run] && result[:operations]
              puts "\nOperations that would be performed:"
              result[:operations].each { |op| puts "  - #{op}" }
            end
            puts "New reference: #{result[:new_reference]}" if result[:new_reference]
            puts "Subtask: #{result[:subtask_id]}" if result[:subtask_id] && !result[:dry_run]
            puts "Orchestrator: #{result[:orchestrator_path]}" if result[:orchestrator_path] && !result[:dry_run]
            puts "Subtask file: #{result[:subtask_path]}" if result[:subtask_path] && !result[:dry_run]
            puts "Path: #{result[:new_path]}" if result[:new_path] && !result[:dry_run]
            0
          else
            puts "Error: #{result[:message]}"
            1
          end
        end

        def execute_update(args)
          # Parse reference and --field flags
          reference = nil
          field_args = []

          args.each_with_index do |arg, i|
            if arg == "--field"
              # Next arg is the field=value
              field_args << args[i + 1] if args[i + 1]
            elsif !arg.start_with?("--") && reference.nil? && (i == 0 || args[i - 1] != "--field")
              # First non-flag argument is the reference
              reference = arg
            end
          end

          # Validate usage
          unless reference
            puts "Error: Task reference required"
            puts ""
            puts "Usage: ace-taskflow task update <reference> --field <key=value> [--field <key2=value2>]"
            return 1
          end

          if field_args.empty?
            puts "Error: At least one --field argument required"
            puts ""
            puts "Usage: ace-taskflow task update <reference> --field <key=value> [--field <key2=value2>]"
            return 2
          end

          # Parse field updates
          begin
            field_updates = Molecules::TaskFieldUpdater.parse_field_updates(field_args)
          rescue Molecules::TaskFieldUpdater::FieldUpdateError => e
            puts "Error: #{e.message}"
            puts ""
            puts "Expected format: --field key=value"
            return 2
          end

          # Update task
          result = @manager.update_task_fields(reference, field_updates)

          if result[:success]
            puts "Task updated: #{result[:task][:id] || reference}"
            puts "Updated fields:"
            result[:updated_fields].each do |field|
              value = field_updates[field]
              puts "  #{field}: #{value.inspect}"
            end
            puts "Task path: #{result[:path]}"
            0
          else
            puts "Error: #{result[:message]}"
            1
          end
        end

        def execute_add_dependency(args)
          task_ref = args.shift
          depends_on_ref = nil

          args.each_with_index do |arg, index|
            if arg == "--depends-on" || arg == "-d"
              depends_on_ref = args[index + 1]
              break
            end
          end

          # Validate arguments
          if task_ref.nil? || depends_on_ref.nil?
            puts "Usage: ace-taskflow task add-dependency <task_ref> --depends-on <dependency_ref>"
            puts "Example: ace-taskflow task add-dependency 034 --depends-on 031"
            return 1
          end

          # Add the dependency
          result = @manager.add_dependency(task_ref, depends_on_ref)

          if result[:success]
            puts result[:message]
            0
          else
            puts "Error: #{result[:message]}"
            1
          end
        end

        def execute_remove_dependency(args)
          task_ref = args.shift
          depends_on_ref = nil

          args.each_with_index do |arg, index|
            if arg == "--depends-on" || arg == "-d"
              depends_on_ref = args[index + 1]
              break
            end
          end

          # Validate arguments
          if task_ref.nil? || depends_on_ref.nil?
            puts "Usage: ace-taskflow task remove-dependency <task_ref> --depends-on <dependency_ref>"
            puts "Example: ace-taskflow task remove-dependency 034 --depends-on 031"
            return 1
          end

          # Remove the dependency
          result = @manager.remove_dependency(task_ref, depends_on_ref)

          if result[:success]
            puts result[:message]
            0
          else
            puts "Error: #{result[:message]}"
            1
          end
        end

        def display_create_dry_run(title, options)
          puts "[DRY-RUN] Would create task:"
          puts "  Title: #{title}"
          puts "  Release: #{options[:release]}"

          if options[:parent_ref]
            puts "  Parent: #{options[:parent_ref]} (subtask)"
          end

          metadata = options[:metadata] || {}
          puts "  Status: #{metadata[:status] || 'pending'}"
          puts "  Estimate: #{metadata[:estimate] || 'TBD'}"

          if metadata[:dependencies]&.any?
            puts "  Dependencies: #{metadata[:dependencies].join(', ')}"
          end

          # Show estimated path pattern
          release_display = options[:release] == "current" ? "<current-release>" : options[:release]
          if options[:parent_ref]
            puts "  Path: .ace-taskflow/#{release_display}/tasks/<parent-dir>/<id>-<slug>.s.md"
          else
            puts "  Path: .ace-taskflow/#{release_display}/tasks/<id>-<slug>/<id>-<slug>.s.md"
          end

          puts ""
          puts "No files created (dry-run mode)"
        end

        def parse_display_mode(args)
          # Check for display mode options and remove them from args
          if index = args.index("--path")
            args.delete_at(index)
            return "path"
          elsif index = args.index("--content")
            args.delete_at(index)
            return "content"
          elsif index = args.index("--tree")
            args.delete_at(index)
            return "tree"
          end
          # Default to formatted display
          "formatted"
        end

        def show_next_task(args, display_mode: "formatted")
          # Use tasks command with limit 1 to get the next task
          require_relative "tasks_command"
          tasks_cmd = TasksCommand.new

          # Add --limit 1 to args for single task display
          modified_args = ["next", "--limit", "1"]

          # Capture output to process it based on display mode
          original_stdout = $stdout
          output = StringIO.new
          $stdout = output

          begin
            tasks_cmd.execute(modified_args)
          rescue SystemExit => e
            # Handle exit calls from tasks command - but continue
          ensure
            $stdout = original_stdout
          end

          result = output.string

          # For path mode, extract just the path from output
          if display_mode == "path" && result.include?(".ace-taskflow/")
            # Extract path from the output
            lines = result.split("\n")
            path_line = lines.find { |l| l.include?(".ace-taskflow/") }
            if path_line
              # Clean up the path line to get just the path
              path = path_line.strip.gsub(/^\s+/, '')
              puts path
            else
              puts "No pending or in-progress tasks found."
            end
          elsif result && !result.empty?
            # For other modes, show full output
            puts result
          else
            # If no output captured, execute directly without capture
            tasks_cmd.execute(modified_args)
          end
        end

        # Public API: Display task details in specified format
        # Used by ContextCommand and other callers that need formatted task output
        # @since 0.24.0
        # @param reference [String] Task reference (e.g., "140", "task.140", "v.0.9.0+task.140")
        # @param display_mode [String] Display format: "path", "content", "tree", or "formatted"
        # @return [Integer] Exit code (0 for success, 1 for not found)
        def show_task(reference, display_mode: "path")
          task = @manager.show_task(reference)

          if task
            case display_mode
            when "path"
              display_task_path(task)
            when "content"
              display_task(task)
            when "tree"
              display_task_tree(task)
            else
              # Default formatted display
              display_task_formatted(task)
            end
          else
            puts "Task '#{reference}' not found."
            puts "Valid formats: 018, task.018, v.0.9.0+018, backlog+025"
            return 1
          end
        end

        def display_task_path(task_data)
          task = Models::Task.new(task_data)
          if task.path
            # Use project root, not .ace-taskflow root
            root_path = Dir.pwd
            relative_path = Atoms::PathFormatter.format_relative_path(task.path, root_path)
            puts relative_path
          else
            puts "# Task has no path"
            return 1
          end
        end

        def display_task(task_data)
          task = Models::Task.new(task_data)

          puts "Task: #{task.id || task.task_number}"
          puts "Title: #{task.title}"
          puts "Status: #{status_icon(task.status)} #{task.status}"
          puts "Priority: #{task.priority}"
          puts "Estimate: #{task.estimate || 'TBD'}"

          unless task.dependencies.empty?
            puts "Dependencies: #{task.dependencies.join(', ')}"
          end

          if task.path
            puts "Path: #{task.path}"
          end

          puts ""
          puts "--- Content ---"
          puts task.content if task.content
        end

        def status_icon(status)
          case status.to_s.downcase
          when "draft" then "⚫"
          when "pending" then "⚪"
          when "in-progress" then "🟡"
          when "done" then "🟢"
          when "blocked", "skipped" then "🔴"
          else "?"
          end
        end

        def display_task_formatted(task_data)
          task = Models::Task.new(task_data)

          status_str = status_icon(task.status)
          ref = task.qualified_reference || task.task_number || task.id
          display_title = strip_task_id_from_title(task.title)
          # Only add orchestrator marker if not already in the title
          orchestrator_marker = task_data[:is_orchestrator] && !display_title.include?("Orchestrator") ? " (Orchestrator)" : ""

          puts "Task: #{ref} #{status_str} #{display_title}#{orchestrator_marker}"

          # Show path on second line
          if task.path
            relative_path = format_relative_path(task.path)
            puts "  Path: #{relative_path}"
          end

          # Combine estimate and dependencies on one line if both present
          details = []
          details << "Estimate: #{task.estimate}" if task.estimate && task.estimate != "TBD"
          details << "Dependencies: #{task.dependencies.join(', ')}" unless task.dependencies.empty?

          if details.any?
            puts "  #{details.join(' | ')}"
          end

          # Show subtasks for orchestrator tasks
          if task_data[:is_orchestrator] || task_data[:subtask_ids]&.any?
            display_subtasks_for_orchestrator(task_data)
          end

          0  # Return success exit code
        end

        # Display subtasks for an orchestrator task
        def display_subtasks_for_orchestrator(orchestrator_data)
          subtask_ids = orchestrator_data[:subtask_ids] || []
          return if subtask_ids.empty?

          # Load subtasks
          subtasks = subtask_ids.map do |subtask_id|
            @manager.show_task(subtask_id)
          end.compact

          return if subtasks.empty?

          puts "  Subtasks:"
          subtasks.sort_by { |s| s[:id] || "" }.each_with_index do |subtask, idx|
            connector = idx == subtasks.length - 1 ? "└─" : "├─"
            status_str = status_icon(subtask[:status])
            ref = subtask[:id] || subtask[:task_number] || "unknown"
            display_title = strip_task_id_from_title(subtask[:title])
            puts "    #{connector} #{ref} #{status_str} #{display_title}"
          end
        end

        def display_task_tree(task_data)
          task = Models::Task.new(task_data)
          ref = task.qualified_reference || task.task_number || task.id

          puts "Task: #{ref} - #{task.title}"
          puts ""

          # Get all tasks to check dependencies
          all_tasks = @manager.list_tasks(release: "all")

          # Generate dependency tree
          tree_output = Molecules::DependencyTreeVisualizer.generate_task_tree(task.id, all_tasks)
          puts tree_output

          # Show blocking information if dependencies exist
          if task.dependencies && !task.dependencies.empty?
            puts ""
            blocking_tasks = Molecules::DependencyResolver.get_blocking_tasks(task_data, all_tasks)
            if blocking_tasks.any?
              puts "Blocked by: #{blocking_tasks.map { |t| t[:task_number] || t[:id] }.join(', ')}"
            else
              puts "All dependencies met - ready to start"
            end
          end
        end

        def format_relative_path(path)
          # Use project root, not .ace-taskflow root
          root_path = Dir.pwd
          Atoms::PathFormatter.format_relative_path(path, root_path)
        end

        def parse_release(args)
          args.each_with_index do |arg, index|
            case arg
            when "--backlog"
              return "backlog"
            when "--release"
              return args[index + 1]
            when "--current"
              return "current"
            end
          end
          "current"
        end

        def get_tasks_for_preset(preset_config)
          release = preset_config[:release] || 'current'
          filters_raw = preset_config[:filters] || {}

          # Convert string keys to symbols for compatibility with TaskManager
          filters = {}
          filters_raw.each do |key, value|
            filters[key.to_sym] = value
          end

          @manager.list_tasks(release: release, filters: filters)
        end

        def apply_preset_sorting(tasks, preset_config)
          sort_config = preset_config[:sort] || { by: :sort, ascending: true }

          Molecules::TaskFilter.sort_tasks(
            tasks,
            sort_config[:by],
            sort_config[:ascending]
          )
        end

        def display_config_summary(args)
          return if @options[:quiet]

          require "ace/core"
          Ace::Core::Atoms::ConfigSummary.display_if_needed(
            command: "taskflow",
            config: Ace::Taskflow.config,
            defaults: load_defaults,
            options: @options,
            quiet: false,
            args: args
          )
        end

        def load_defaults
          gem_root = Gem.loaded_specs["ace-taskflow"]&.gem_dir ||
                     File.expand_path("../../../../../..", __dir__)
          defaults_path = File.join(gem_root, ".ace-defaults", "taskflow", "config.yml")

          unless File.exist?(defaults_path)
            return {}
          end

          YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
        end
      end
    end
  end
end
