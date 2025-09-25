# frozen_string_literal: true

require_relative "../organisms/task_manager"
require_relative "../molecules/task_filter"
require_relative "../molecules/list_preset_manager"
require_relative "../models/task"

module Ace
  module Taskflow
    module Commands
      # Handle tasks (plural) subcommand for browsing/listing
      class TasksCommand
        def initialize
          @manager = Organisms::TaskManager.new
          @preset_manager = Molecules::ListPresetManager.new
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

          # Check for special flags
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

          # Display tasks
          if tasks.empty?
            puts "No tasks found for preset '#{preset_name}'."
          else
            display_tasks_with_preset(tasks, preset_config)
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

          # Display tasks
          if tasks.empty?
            puts "No tasks found."
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
            when "--stats"
              filters[:stats] = true
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
          filters = preset_config[:filters] || {}

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

        def display_tasks_with_preset(tasks, preset_config)
          preset_name = preset_config[:name]
          description = preset_config[:description]

          puts "Tasks: #{preset_name} (#{tasks.size} found)"
          puts description if description && description != "#{preset_name} preset"
          puts "=" * 50

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
          stats = @manager.get_statistics(context: context)

          puts "Task Statistics for '#{preset_name}' preset:"
          puts preset_config[:description] if preset_config[:description]
          puts "=" * 50
          puts "Total: #{stats[:total]} tasks"
          puts ""

          if stats[:by_status].any?
            puts "By Status:"
            stats[:by_status].each do |status, count|
              icon = status_icon(status)
              percentage = (count.to_f / stats[:total] * 100).round
              puts "  #{icon} #{status.capitalize}: #{count} (#{percentage}%)"
            end
            puts ""
          end

          if stats[:by_priority].any?
            puts "By Priority:"
            stats[:by_priority].each do |priority, count|
              indicator = priority_indicator(priority)
              percentage = (count.to_f / stats[:total] * 100).round
              puts "  #{indicator} #{priority.capitalize}: #{count} (#{percentage}%)"
            end
            puts ""
          end

          if stats[:by_context].any? && context == "all"
            puts "By Context:"
            stats[:by_context].each do |ctx, count|
              percentage = (count.to_f / stats[:total] * 100).round
              puts "  #{ctx}: #{count} (#{percentage}%)"
            end
          end
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
          if options[:recent]
            puts "Recent Tasks (#{tasks.size} found):"
          elsif options[:all]
            puts "All Tasks (#{tasks.size} total):"
          elsif options[:backlog]
            puts "Backlog Tasks (#{tasks.size}):"
          elsif options[:release]
            puts "Tasks in #{options[:release]} (#{tasks.size}):"
          else
            puts "Tasks in Active Release (#{tasks.size}):"
          end
          puts "=" * 50

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
          priority_str = priority_indicator(task.priority)
          ref = task.qualified_reference || task.task_number || task.id

          puts "  #{ref.ljust(15)} #{status_str} #{priority_str} #{task.title}"

          # Show path on second line
          if task.path
            relative_path = format_relative_path(task.path)
            puts "    #{relative_path}"
          end

          if task.estimate && task.estimate != "TBD"
            puts "    Estimate: #{task.estimate}"
          end

          unless task.dependencies.empty?
            puts "    Dependencies: #{task.dependencies.join(', ')}"
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
          stats = @manager.get_statistics(context: context)

          puts "Task Statistics:"
          puts "=" * 50
          puts "Total: #{stats[:total]} tasks"
          puts ""

          if stats[:by_status].any?
            puts "By Status:"
            stats[:by_status].each do |status, count|
              icon = status_icon(status)
              percentage = (count.to_f / stats[:total] * 100).round
              puts "  #{icon} #{status.capitalize}: #{count} (#{percentage}%)"
            end
            puts ""
          end

          if stats[:by_priority].any?
            puts "By Priority:"
            stats[:by_priority].each do |priority, count|
              indicator = priority_indicator(priority)
              percentage = (count.to_f / stats[:total] * 100).round
              puts "  #{indicator} #{priority.capitalize}: #{count} (#{percentage}%)"
            end
            puts ""
          end

          if stats[:by_context].any? && context == "all"
            puts "By Context:"
            stats[:by_context].each do |ctx, count|
              percentage = (count.to_f / stats[:total] * 100).round
              puts "  #{ctx}: #{count} (#{percentage}%)"
            end
          end
        end

        def status_icon(status)
          case status.to_s.downcase
          when "done" then "✓"
          when "in-progress" then "⚡"
          when "pending" then "○"
          when "blocked" then "⊘"
          else "?"
          end
        end

        def priority_indicator(priority)
          case priority.to_s.downcase
          when "critical" then "🔴"
          when "high" then "🟡"
          when "medium" then "🟢"
          when "low" then "⚪"
          else "⚪"
          end
        end

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
          puts ""
          puts "Additional Preset Filters:"
          puts "  --status <statuses>  Add status filter to preset"
          puts "  --priority <levels>  Add priority filter to preset"
          puts "  --days <n>           Modify days for time-based presets"
          puts "  --stats              Show statistics for preset"
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
      end
    end
  end
end