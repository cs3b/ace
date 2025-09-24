# frozen_string_literal: true

require_relative "../organisms/task_manager"
require_relative "../molecules/task_filter"
require_relative "../models/task"

module Ace
  module Taskflow
    module Commands
      # Handle tasks (plural) subcommand for browsing/listing
      class TasksCommand
        def initialize
          @manager = Organisms::TaskManager.new
        end

        def execute(args)
          # Parse options
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
        rescue StandardError => e
          puts "Error: #{e.message}"
          exit 1
        end

        private

        def parse_options(args)
          options = {
            filters: {},
            sort: { by: :priority, ascending: false }
          }

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--all"
              options[:all] = true
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

        def show_help
          puts "Usage: ace-taskflow tasks [options]"
          puts ""
          puts "Options:"
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
          puts "Sort formats:"
          puts "  --sort priority:desc  Sort by priority descending"
          puts "  --sort id:asc         Sort by ID ascending"
          puts ""
          puts "Examples:"
          puts "  ace-taskflow tasks"
          puts "  ace-taskflow tasks --all"
          puts "  ace-taskflow tasks --backlog"
          puts "  ace-taskflow tasks --status pending,in-progress"
          puts "  ace-taskflow tasks --priority high,critical"
          puts "  ace-taskflow tasks --recent --days 3"
          puts "  ace-taskflow tasks --stats"
        end
      end
    end
  end
end