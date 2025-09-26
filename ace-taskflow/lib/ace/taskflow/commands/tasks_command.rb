# frozen_string_literal: true

require_relative "../organisms/task_manager"
require_relative "../molecules/task_filter"
require_relative "../molecules/list_preset_manager"
require_relative "../molecules/dependency_tree_visualizer"
require_relative "../molecules/stats_formatter"
require_relative "../models/task"

module Ace
  module Taskflow
    module Commands
      # Handle tasks (plural) subcommand for browsing/listing
      class TasksCommand
        def initialize
          @manager = Organisms::TaskManager.new
          @preset_manager = Molecules::ListPresetManager.new
          @stats_formatter = Molecules::StatsFormatter.new
        end

        def execute(args)
          # Check for reschedule subcommand
          if args.first == "reschedule"
            args.shift # Remove "reschedule"
            return execute_reschedule(args)
          end

          # Check if first argument is a preset name
          preset_name = detect_preset_name(args)
          if preset_name
            args.shift # Remove preset name from args
            execute_with_preset(preset_name, args)
          elsif args.empty? || (!args.first.start_with?('-') && !@preset_manager.preset_exists?(args.first, :tasks))
            # Default to 'next' preset when no arguments or no valid preset/flag
            execute_with_preset('next', args)
          else
            # Fallback to legacy flag-based execution for backward compatibility
            execute_legacy(args)
          end
        rescue StandardError => e
          puts "Error: #{e.message}"
          exit 1
        end

        private

        def detect_preset_name(args)
          return nil if args.empty? || args.first.start_with?('-')

          potential_preset = args.first
          # Check if it's a known preset or custom preset
          if @preset_manager.preset_exists?(potential_preset, :tasks)
            potential_preset
          else
            nil
          end
        end

        def execute_with_preset(preset_name, remaining_args)
          # Parse additional filters from remaining args
          additional_filters = parse_additional_filters(remaining_args)

          # Check for stats only (other formatters handled after filtering)
          if additional_filters[:stats]
            show_statistics_for_preset(preset_name)
            return
          end

          # Apply preset with additional filters
          preset_config = @preset_manager.apply_preset(preset_name, additional_filters)
          return unless preset_config

          # Get tasks based on preset configuration
          tasks = get_tasks_for_preset(preset_config)

          # Sort tasks according to preset
          tasks = apply_preset_sorting(tasks, preset_config)

          # Apply limit if specified
          original_count = tasks.size
          if additional_filters[:limit] && additional_filters[:limit] > 0
            tasks = tasks.take(additional_filters[:limit])
          end

          # Display tasks with appropriate formatter
          if tasks.empty?
            puts "No tasks found for preset '#{preset_name}'."
          elsif additional_filters[:tree]
            display_tree_with_preset(tasks, preset_config, original_count, additional_filters[:limit])
          elsif additional_filters[:path]
            display_paths_with_preset(tasks, preset_config, original_count, additional_filters[:limit])
          elsif additional_filters[:list]
            display_list_with_preset(tasks, preset_config, original_count, additional_filters[:limit])
          else
            display_tasks_with_preset(tasks, preset_config, original_count, additional_filters[:limit])
          end
        end

        def execute_legacy(args)
          # Original implementation for backward compatibility
          options = parse_options(args)

          # Get tasks based on context
          tasks = if options[:all]
            @manager.list_tasks(context: "all", filters: options[:filters])
          elsif options[:backlog]
            @manager.list_tasks(context: "backlog", filters: options[:filters])
          elsif options[:release]
            @manager.list_tasks(context: options[:release], filters: options[:filters])
          elsif options[:recent]
            @manager.get_recent_tasks(days: options[:days] || 7)
          elsif options[:stats]
            show_statistics(options[:context] || "all")
            return
          else
            @manager.list_tasks(context: "current", filters: options[:filters])
          end

          # Sort tasks
          if options[:sort]
            tasks = Molecules::TaskFilter.sort_tasks(
              tasks,
              options[:sort][:by],
              options[:sort][:ascending]
            )
          end

          # Apply limit if specified
          if options[:limit] && options[:limit] > 0
            tasks = tasks.take(options[:limit])
          end

          # Display tasks with appropriate formatter
          if tasks.empty?
            puts "No tasks found."
          elsif options[:tree]
            show_dependency_tree(tasks, options)
          elsif options[:path]
            display_task_paths(tasks, options)
          elsif options[:list]
            display_task_list(tasks, options)
          else
            display_tasks(tasks, options)
          end
        end

        def parse_additional_filters(args)
          filters = {}

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--status"
              filters[:status] = args[i + 1].split(',') if i + 1 < args.length
              i += 2
            when "--priority"
              filters[:priority] = args[i + 1].split(',') if i + 1 < args.length
              i += 2
            when "--days"
              filters[:days] = args[i + 1].to_i if i + 1 < args.length
              i += 2
            when "--limit"
              filters[:limit] = args[i + 1].to_i if i + 1 < args.length
              i += 2
            when "--stats"
              filters[:stats] = true
              i += 1
            when "--tree"
              filters[:tree] = true
              i += 1
            when "--path"
              filters[:path] = true
              i += 1
            when "--list"
              filters[:list] = true
              i += 1
            when "--help", "-h"
              show_help
              exit 0
            else
              i += 1
            end
          end

          filters
        end

        def get_tasks_for_preset(preset_config)
          context = preset_config[:context] || 'current'
          filters_raw = preset_config[:filters] || {}

          # Convert string keys to symbols for compatibility with TaskManager
          filters = {}
          filters_raw.each do |key, value|
            filters[key.to_sym] = value
          end

          case context
          when 'all'
            @manager.list_tasks(context: "all", filters: filters)
          when 'backlog'
            @manager.list_tasks(context: "backlog", filters: filters)
          when 'current'
            @manager.list_tasks(context: "current", filters: filters)
          else
            # Assume it's a specific release context
            @manager.list_tasks(context: context, filters: filters)
          end
        end

        def apply_preset_sorting(tasks, preset_config)
          sort_config = preset_config[:sort] || { by: :sort, ascending: true }

          Molecules::TaskFilter.sort_tasks(
            tasks,
            sort_config[:by],
            sort_config[:ascending]
          )
        end

        def display_tasks_with_preset(tasks, preset_config, original_count = nil, limit = nil)
          # Display three-line header
          context = preset_config[:context] || 'current'
          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            context: context
          )
          puts header

          # Check if grouping is needed
          display_config = preset_config[:display] || {}
          if display_config[:group_by] == 'context' || display_config[:group_by] == :context
            grouped = tasks.group_by { |t| t[:context] }
            grouped.each do |context, context_tasks|
              puts ""
              puts "#{context}:"
              context_tasks.each { |task| display_task_line(task) }
            end
          else
            tasks.each { |task| display_task_line(task) }
          end
        end

        def show_statistics_for_preset(preset_name)
          preset_config = @preset_manager.apply_preset(preset_name)
          return unless preset_config

          context = preset_config[:context] || 'current'
          puts @stats_formatter.format_stats_view(context: context)
        end

        def parse_options(args)
          options = {
            filters: { status: ["in-progress", "pending"] },  # Default to actionable tasks
            sort: { by: :sort, ascending: true }  # Default to sort field
          }

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--all"
              options[:all] = true
              options[:filters].delete(:status)  # Remove default status filter for --all
              i += 1
            when "--backlog"
              options[:backlog] = true
              i += 1
            when "--release"
              options[:release] = args[i + 1]
              i += 2
            when "--status"
              options[:filters][:status] = args[i + 1].split(',')
              i += 2
            when "--priority"
              options[:filters][:priority] = args[i + 1].split(',')
              i += 2
            when "--recent"
              options[:recent] = true
              i += 1
            when "--days"
              options[:days] = args[i + 1].to_i
              i += 2
            when "--stats"
              options[:stats] = true
              i += 1
            when "--tree"
              options[:tree] = true
              i += 1
            when "--path"
              options[:path] = true
              i += 1
            when "--list"
              options[:list] = true
              i += 1
            when "--sort"
              sort_spec = args[i + 1]
              if sort_spec.include?(':')
                field, direction = sort_spec.split(':')
                options[:sort][:by] = field.to_sym
                options[:sort][:ascending] = direction == 'asc'
              else
                options[:sort][:by] = sort_spec.to_sym
              end
              i += 2
            when "--limit"
              options[:limit] = args[i + 1].to_i
              i += 2
            when "--help", "-h"
              show_help
              exit 0
            else
              i += 1
            end
          end

          options
        end

        def display_tasks(tasks, options)
          # Display three-line header
          context = if options[:all]
                     "all"
                   elsif options[:backlog]
                     "backlog"
                   elsif options[:release]
                     options[:release]
                   else
                     "current"
                   end

          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            context: context
          )
          puts header

          # Group by context if showing all
          if options[:all]
            grouped = tasks.group_by { |t| t[:context] }
            grouped.each do |context, context_tasks|
              puts ""
              puts "#{context}:"
              context_tasks.each { |task| display_task_line(task) }
            end
          else
            tasks.each { |task| display_task_line(task) }
          end
        end

        def display_task_line(task_data)
          task = Models::Task.new(task_data)

          status_str = status_icon(task.status)
          ref = task.qualified_reference || task.task_number || task.id

          puts "  #{ref.ljust(15)} #{status_str} #{task.title}"

          # Show path on second line
          if task.path
            relative_path = format_relative_path(task.path)
            puts "    #{relative_path}"
          end

          # Combine estimate and dependencies on one line if both present
          details = []
          details << "Estimate: #{task.estimate}" if task.estimate && task.estimate != "TBD"
          details << "Dependencies: #{task.dependencies.join(', ')}" unless task.dependencies.empty?

          if details.any?
            puts "    #{details.join(' | ')}"
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

        def show_statistics(context)
          puts @stats_formatter.format_stats_view(context: context)
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

        # Priority indicator removed - using status colors instead

        def execute_reschedule(args)
          require_relative "../organisms/task_scheduler"
          scheduler = Organisms::TaskScheduler.new(@manager)

          # Parse reschedule options
          tasks_to_reschedule = []
          options = { strategy: nil }

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--add-next"
              options[:strategy] = :add_next
              i += 1
            when "--add-at-end"
              options[:strategy] = :add_at_end
              i += 1
            when "--after"
              options[:strategy] = :after
              options[:reference_task] = args[i + 1]
              i += 2
            when "--before"
              options[:strategy] = :before
              options[:reference_task] = args[i + 1]
              i += 2
            when "--help", "-h"
              show_reschedule_help
              return
            else
              # This is a task identifier
              tasks_to_reschedule << arg
              i += 1
            end
          end

          if tasks_to_reschedule.empty?
            puts "Error: No tasks specified for rescheduling"
            puts "Usage: ace-taskflow tasks reschedule <task_ids> [options]"
            return 1
          end

          # Use default strategy if none specified
          if options[:strategy].nil?
            # Load configuration to get default
            require_relative "../molecules/config_loader"
            config = Molecules::ConfigLoader.load
            default_strategy = config.dig('tasks', 'defaults', 'reschedule_strategy') || 'add_next'
            options[:strategy] = default_strategy.to_sym
          end

          # Execute the rescheduling
          begin
            scheduler.reschedule(tasks_to_reschedule, options)
            puts "Successfully rescheduled #{tasks_to_reschedule.size} task(s)"
          rescue StandardError => e
            puts "Error: #{e.message}"
            return 1
          end
        end

        def show_reschedule_help
          puts "Usage: ace-taskflow tasks reschedule <task_ids> [options]"
          puts ""
          puts "Reschedule tasks by updating their sort values in frontmatter."
          puts ""
          puts "Arguments:"
          puts "  <task_ids>           Task IDs to reschedule (e.g., 025, task.026, v.0.9.0+task.027)"
          puts ""
          puts "Options:"
          puts "  --add-next           Place tasks before existing pending tasks (front of queue)"
          puts "  --add-at-end         Place tasks after highest task (end of queue)"
          puts "  --after <task>       Place tasks after specific task"
          puts "  --before <task>      Place tasks before specific task"
          puts "  --help, -h           Show this help message"
          puts ""
          puts "Examples:"
          puts "  ace-taskflow tasks reschedule 025 026 027"
          puts "  ace-taskflow tasks reschedule 025 026 --add-next"
          puts "  ace-taskflow tasks reschedule 025 --after task.029"
          puts "  ace-taskflow tasks reschedule 025 --before v.0.9.0+task.029"
          puts ""
          puts "Note: Default strategy can be configured via 'tasks.defaults.reschedule_strategy'"
          puts "      Valid values: 'add_next' (default), 'add_at_end'"
        end

        def show_help
          puts "Usage: ace-taskflow tasks [preset] [options]"
          puts "       ace-taskflow tasks reschedule <tasks> [options]"
          puts ""
          puts "Presets (recommended):"
          available_presets = @preset_manager.list_presets(:tasks)
          available_presets.each do |preset|
            name = preset[:name]
            desc = preset[:description]
            default_marker = preset[:default] ? " (default)" : ""
            puts "  #{name.ljust(12)} #{desc}#{default_marker}"
          end
          puts ""
          puts "Subcommands:"
          puts "  reschedule           Reorder tasks by updating sort values"
          puts ""
          puts "Preset Examples:"
          puts "  ace-taskflow tasks                    # Uses 'next' preset (default)"
          puts "  ace-taskflow tasks recent             # Recently modified tasks"
          puts "  ace-taskflow tasks recent --days 3    # Recent with custom filter"
          puts "  ace-taskflow tasks all                # All tasks, grouped by context"
          puts "  ace-taskflow tasks pending            # Only pending tasks"
          puts "  ace-taskflow tasks next --stats       # Statistics for next preset"
          puts ""
          puts "Legacy Flag Options (backward compatibility):"
          puts "  --all                List ALL tasks (backlog + releases)"
          puts "  --backlog            List backlog tasks"
          puts "  --release <name>     List tasks in specific release"
          puts "  --status <statuses>  Filter by status (comma-separated)"
          puts "  --priority <levels>  Filter by priority (comma-separated)"
          puts "  --recent             Show recently modified tasks"
          puts "  --days <n>           Days to look back (default: 7)"
          puts "  --stats              Show task statistics"
          puts "  --sort <field>       Sort by field (priority, status, id, modified)"
          puts "  --limit <n>          Limit number of results displayed"
          puts ""
          puts "Additional Preset Filters:"
          puts "  --status <statuses>  Add status filter to preset"
          puts "  --priority <levels>  Add priority filter to preset"
          puts "  --days <n>           Modify days for time-based presets"
          puts "  --limit <n>          Limit number of results displayed"
          puts "  --stats              Show statistics for preset"
          puts "  --tree               Show dependency tree view"
          puts "  --path               Show paths only"
          puts "  --list               Show simple list format"
          puts ""
          puts "Reschedule Options:"
          puts "  --add-next           Place tasks before existing pending tasks"
          puts "  --add-at-end         Place tasks after highest task"
          puts "  --after <task>       Place tasks after specific task"
          puts "  --before <task>      Place tasks before specific task"
          puts ""
          puts "Custom Presets:"
          puts "  Create YAML files in .ace/taskflow/presets/ to define custom presets"
          puts "  Example: .ace/taskflow/presets/urgent.yml"
        end

        def show_dependency_tree_for_preset(preset_name)
          preset_config = @preset_manager.apply_preset(preset_name)
          return unless preset_config

          tasks = get_tasks_for_preset(preset_config)
          puts "Dependency Tree for '#{preset_name}' preset:"
          puts preset_config[:description] if preset_config[:description]
          puts "=" * 50
          puts ""
          puts Molecules::DependencyTreeVisualizer.generate_forest(tasks)
        end

        def show_dependency_tree(tasks, options)
          # Display three-line header
          context = if options[:all]
                     "all"
                   elsif options[:release]
                     options[:release]
                   else
                     "current"
                   end

          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            context: context
          )
          puts header

          # Get ALL tasks for complete dependency visualization
          all_tasks = @manager.list_tasks(context: "all")
          puts ""
          puts Molecules::DependencyTreeVisualizer.generate_forest(tasks, all_tasks)
        end

        # Formatter methods for preset context
        def display_tree_with_preset(tasks, preset_config, original_count = nil, limit = nil)
          # Display three-line header
          context = preset_config[:context] || 'current'
          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            context: context
          )
          puts header

          # Get ALL tasks for complete dependency visualization
          all_tasks = @manager.list_tasks(context: "all")
          puts ""
          puts Molecules::DependencyTreeVisualizer.generate_forest(tasks, all_tasks)
        end

        def display_paths_with_preset(tasks, preset_config, original_count = nil, limit = nil)
          # Display three-line header
          context = preset_config[:context] || 'current'
          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            context: context
          )
          puts header

          tasks.each do |task|
            puts task[:path] if task[:path]
          end
        end

        def display_list_with_preset(tasks, preset_config, original_count = nil, limit = nil)
          # Display three-line header
          context = preset_config[:context] || 'current'
          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            context: context
          )
          puts header

          tasks.each do |task|
            ref = task[:task_number] || task[:id]
            puts "#{ref} #{task[:title]}"
          end
        end

        # Formatter methods for legacy context
        def display_task_paths(tasks, options)
          # Display three-line header
          context = if options[:all]
                     "all"
                   elsif options[:backlog]
                     "backlog"
                   elsif options[:release]
                     options[:release]
                   else
                     "current"
                   end

          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            context: context
          )
          puts header

          tasks.each do |task|
            puts task[:path] if task[:path]
          end
        end

        def display_task_list(tasks, options)
          # Display three-line header
          context = if options[:all]
                     "all"
                   elsif options[:backlog]
                     "backlog"
                   elsif options[:release]
                     options[:release]
                   else
                     "current"
                   end

          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            context: context
          )
          puts header

          tasks.each do |task|
            ref = task[:task_number] || task[:id]
            puts "#{ref} #{task[:title]}"
          end
        end
      end
    end
  end
end