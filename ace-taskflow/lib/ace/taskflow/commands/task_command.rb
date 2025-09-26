# frozen_string_literal: true

require_relative "../organisms/task_manager"
require_relative "../molecules/list_preset_manager"
require_relative "../molecules/task_filter"
require_relative "../molecules/dependency_tree_visualizer"
require 'stringio'
require_relative "../models/task"

module Ace
  module Taskflow
    module Commands
      # Handle task subcommand
      class TaskCommand
        def initialize
          @manager = Organisms::TaskManager.new
          @preset_manager = Molecules::ListPresetManager.new
        end

        def execute(args)
          # Parse display mode options first
          display_mode = parse_display_mode(args)

          subaction = args.shift

          case subaction
          when nil, "next"
            show_next_task(args, display_mode: display_mode)
          when "create"
            create_task(args)
          when "start"
            start_task(args)
          when "done"
            complete_task(args)
          when "move"
            move_task(args)
          when "update"
            update_task(args)
          when "add-dependency"
            add_dependency(args)
          when "remove-dependency"
            remove_dependency(args)
          when "--help", "-h"
            show_help
          else
            # Try to show specific task
            show_task(subaction, display_mode: display_mode)
          end
        rescue StandardError => e
          puts "Error: #{e.message}"
          exit 1
        end

        private

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

        def show_next_task(args, display_mode: "path")
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
            else
              # For other modes, show full output
              puts result
            end
          ensure
            $stdout = original_stdout
          end
        end

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
            exit 1
          end
        end

        def create_task(args)
          # Parse options
          title_parts = []
          context = "current"

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--backlog"
              context = "backlog"
              i += 1
            when "--release"
              context = args[i + 1]
              i += 2
            else
              title_parts << arg
              i += 1
            end
          end

          title = title_parts.join(" ")

          if title.empty?
            puts "Usage: ace-taskflow task create <title> [options]"
            puts "Options:"
            puts "  --backlog          Create in backlog"
            puts "  --release <name>   Create in specific release"
            exit 1
          end

          result = @manager.create_task(title, context: context)

          if result[:success]
            puts result[:message]
            puts "Path: #{result[:path]}"
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def start_task(args)
          reference = args.first

          unless reference
            puts "Usage: ace-taskflow task start <reference>"
            puts "Example: ace-taskflow task start 019"
            exit 1
          end

          result = @manager.start_task(reference)

          if result[:success]
            puts result[:message]
            puts "Started at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def complete_task(args)
          reference = args.first

          unless reference
            puts "Usage: ace-taskflow task done <reference>"
            puts "Example: ace-taskflow task done 019"
            exit 1
          end

          result = @manager.complete_task(reference)

          if result[:success]
            puts result[:message]
            puts "Completed at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def move_task(args)
          reference = args[0]
          target = args[1]

          unless reference && target
            puts "Usage: ace-taskflow task move <reference> <target>"
            puts "Examples:"
            puts "  ace-taskflow task move 019 backlog"
            puts "  ace-taskflow task move backlog+025 v.0.10.0"
            exit 1
          end

          result = @manager.move_task(reference, target)

          if result[:success]
            puts result[:message]
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def update_task(args)
          reference = args.first

          unless reference
            puts "Usage: ace-taskflow task update <reference>"
            puts "Note: This command is not yet implemented"
            exit 1
          end

          puts "Task update functionality coming soon"
          exit 0
        end

        def display_task_path(task_data)
          task = Models::Task.new(task_data)
          if task.path
            puts task.path
          else
            puts "# Task has no path"
            exit 1
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

        def add_dependency(args)
          # Parse arguments
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
            exit 1
          end

          # Add the dependency
          result = @manager.add_dependency(task_ref, depends_on_ref)

          if result[:success]
            puts result[:message]
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def remove_dependency(args)
          # Parse arguments
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
            exit 1
          end

          # Remove the dependency
          result = @manager.remove_dependency(task_ref, depends_on_ref)

          if result[:success]
            puts result[:message]
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def parse_context(args)
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
          context = preset_config[:context] || 'current'
          filters_raw = preset_config[:filters] || {}

          # Convert string keys to symbols for compatibility with TaskManager
          filters = {}
          filters_raw.each do |key, value|
            filters[key.to_sym] = value
          end

          @manager.list_tasks(context: context, filters: filters)
        end

        def apply_preset_sorting(tasks, preset_config)
          sort_config = preset_config[:sort] || { by: :sort, ascending: true }

          Molecules::TaskFilter.sort_tasks(
            tasks,
            sort_config[:by],
            sort_config[:ascending]
          )
        end

        def display_task_formatted(task_data)
          task = Models::Task.new(task_data)

          status_str = status_icon(task.status)
          ref = task.qualified_reference || task.task_number || task.id

          puts "Task: #{ref} #{status_str} #{task.title}"

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
        end

        def display_task_tree(task_data)
          task = Models::Task.new(task_data)
          ref = task.qualified_reference || task.task_number || task.id

          puts "Task: #{ref} - #{task.title}"
          puts ""

          # Get all tasks to check dependencies
          all_tasks = @manager.list_tasks(context: "all")

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
          # Make path relative to project root
          root_path = @manager.instance_variable_get(:@root_path) || Dir.pwd
          relative = path.sub(/^#{Regexp.escape(root_path)}\/?/, "")

          # Truncate if too long
          max_length = 70
          if relative.length > max_length
            # Keep the beginning and end, truncate middle
            start_length = 35
            end_length = 32
            "#{relative[0...start_length]}...#{relative[-end_length..]}"
          else
            relative
          end
        end

        def show_help
          puts "Usage: ace-taskflow task [subcommand] [options]"
          puts ""
          puts "Subcommands:"
          puts "  (none)             Show next task from active release"
          puts "  <reference>        Show specific task"
          puts "    --tree           Show task dependency tree"
          puts "  create <title>     Create new task"
          puts "    --backlog        Create in backlog"
          puts "    --release <name> Create in specific release"
          puts "  start <reference>  Mark task as in-progress"
          puts "  done <reference>   Mark task as completed"
          puts "  move <ref> <target> Move task to different context"
          puts "  update <reference> Update task metadata"
          puts "  add-dependency <ref> --depends-on <dep>"
          puts "                     Add dependency to task"
          puts "  remove-dependency <ref> --depends-on <dep>"
          puts "                     Remove dependency from task"
          puts ""
          puts "Display Options:"
          puts "  --path             Show only task file path"
          puts "  --content          Show full task content"
          puts "  (default)          Show formatted task with status"
          puts ""
          puts "Reference formats:"
          puts "  018               Task in current context"
          puts "  task.018          Task in current context"
          puts "  v.0.9.0+018       Task from specific release"
          puts "  backlog+025       Task from backlog"
          puts "  current+018       Explicit current/active"
          puts ""
          puts "Examples:"
          puts "  ace-taskflow task                    # Show next task path"
          puts "  ace-taskflow task --content          # Show next task with full content"
          puts "  ace-taskflow task 019 --path         # Show path for task 019"
          puts "  ace-taskflow task 019 --content      # Show full content for task 019"
          puts "  ace-taskflow task create 'Add caching layer'"
          puts "  ace-taskflow task start 019"
          puts "  ace-taskflow task done 019"
          puts "  ace-taskflow task move backlog+025 v.0.10.0"
        end
      end
    end
  end
end