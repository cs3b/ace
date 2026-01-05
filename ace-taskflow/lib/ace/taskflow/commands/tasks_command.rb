# frozen_string_literal: true

require_relative "../organisms/task_manager"
require_relative "../molecules/task_filter"
require_relative "../molecules/list_preset_manager"
require_relative "../molecules/dependency_tree_visualizer"
require_relative "../molecules/stats_formatter"
require_relative "../models/task"
require_relative "../atoms/path_formatter"
require_relative "../atoms/filter_parser"
require_relative "helpers"

module Ace
  module Taskflow
    module Commands
      # Handle tasks (plural) subcommand for browsing/listing
      class TasksCommand
        include Helpers
        def initialize
          @root_path = Molecules::ConfigLoader.find_root
          @manager = Organisms::TaskManager.new
          @config = Taskflow.configuration
          @preset_manager = Molecules::ListPresetManager.new
          @stats_formatter = Molecules::StatsFormatter.new(@root_path)
        end

        def execute(args, thor_options = {})
          # Check for reschedule subcommand
          if args.first == "reschedule"
            args.shift # Remove "reschedule"
            return execute_reschedule(args)
          end

          # Merge Thor options for --status, --stats, --tree, --all, --limit, --format
          # These Thor class options are passed from CLI routing
          if thor_options[:status]
            args.unshift("--status", thor_options[:status])
          end
          if thor_options[:stats]
            args.unshift("--stats")
          end
          if thor_options[:tree]
            args.unshift("--tree")
          end
          if thor_options[:all]
            args.unshift("--all")
          end
          if thor_options[:limit]
            args.unshift("--limit", thor_options[:limit].to_s)
          end
          if thor_options[:format]
            args.unshift("--format", thor_options[:format])
          end

          # Check if first argument is a preset name
          preset_name = detect_preset_name(args)
          if preset_name
            args.shift # Remove preset name from args
          else
            # Default to 'next' preset for tasks
            preset_name = 'next'
          end

          execute_with_preset(preset_name, args)
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

        def parse_additional_filters(args)
          filters = {}
          filter_strings = []

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            # NEW: Unified filter syntax
            when "--filter"
              if i + 1 < args.length
                filter_strings << args[i + 1]
                i += 2
              else
                raise ArgumentError, "Missing value for --filter flag. Use: --filter key:value"
              end
            when "--filter-clear"
              filters[:filter_clear] = true
              i += 1
            # REMOVED: Legacy filter flags with helpful error messages
            when "--status"
              suggested_value = args[i + 1] if i + 1 < args.length
              suggested_filter = if suggested_value
                # Convert comma-separated to pipe-separated
                converted = suggested_value.gsub(/,\s*/, '|')
                "--filter status:#{converted}"
              else
                "--filter status:value"
              end
              raise ArgumentError, "Error: --status flag is no longer supported. Use: #{suggested_filter}"
            when "--priority"
              suggested_value = args[i + 1] if i + 1 < args.length
              suggested_filter = if suggested_value
                converted = suggested_value.gsub(/,\s*/, '|')
                "--filter priority:#{converted}"
              else
                "--filter priority:value"
              end
              raise ArgumentError, "Error: --priority flag is no longer supported. Use: #{suggested_filter}"
            # KEPT: Convenience and formatting flags
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
            # Hierarchical display flags
            when "--subtasks"
              filters[:subtasks_display] = :show
              i += 1
            when "--no-subtasks"
              filters[:subtasks_display] = :hide
              i += 1
            when "--flat"
              filters[:flat] = true
              i += 1
            # KEPT: Release selection flags (not filters)
            when "--backlog"
              filters[:release] = "backlog"
              i += 1
            when "--release"
              filters[:release] = args[i + 1] if i + 1 < args.length
              i += 2
            when "--sort"
              sort_spec = args[i + 1]
              if sort_spec && sort_spec.include?(':')
                field, direction = sort_spec.split(':')
                filters[:sort] = { by: field.to_sym, ascending: direction == 'asc' }
              elsif sort_spec
                filters[:sort] = { by: sort_spec.to_sym, ascending: true }
              end
              i += 2
            when "--help", "-h"
              show_help
              exit 0
            else
              i += 1
            end
          end

          # Parse filter strings into filter specifications
          if filter_strings.any?
            filters[:filter_specs] = Atoms::FilterParser.parse(filter_strings)
          end

          filters
        end

        def execute_with_preset(preset_name, remaining_args)
          # Parse additional filters from remaining args
          additional_filters = parse_additional_filters(remaining_args)

          # Handle preset override from legacy flags
          if additional_filters[:_preset_override]
            preset_name = additional_filters.delete(:_preset_override)
          end

          # Check for stats only (other formatters handled after filtering)
          if additional_filters[:stats]
            return show_statistics_for_preset(preset_name, additional_filters)
          end

          # Handle filter-clear: if set, don't pass old-style filters to preset
          if additional_filters[:filter_clear]
            # Apply preset but ignore its filters
            preset_config = @preset_manager.apply_preset(preset_name, {})
            return 1 unless preset_config
            # Clear the preset filters but keep release, sort, glob, display
            preset_config[:filters] = {}
          else
            # Apply preset with additional filters (normal flow)
            preset_config = @preset_manager.apply_preset(preset_name, additional_filters)
            return 1 unless preset_config
          end

          # Store filter_specs in preset_config so TaskFilter can access them
          if additional_filters[:filter_specs]
            preset_config[:filter_specs] = additional_filters[:filter_specs]
          end

          # Override release if provided via flags
          if additional_filters[:release]
            preset_config[:release] = additional_filters[:release]
          end

          # Override sort if provided
          if additional_filters[:sort]
            preset_config[:sort] = additional_filters[:sort]
          end

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
          if additional_filters[:tree]
            display_tree_with_preset(tasks, preset_config, original_count, additional_filters[:limit])
          elsif additional_filters[:path]
            display_paths_with_preset(tasks, preset_config, original_count, additional_filters[:limit])
          elsif additional_filters[:list]
            display_list_with_preset(tasks, preset_config, original_count, additional_filters[:limit])
          elsif additional_filters[:flat]
            display_flat_with_preset(tasks, preset_config, original_count, additional_filters[:limit])
          elsif additional_filters[:subtasks_display] == :show
            display_hierarchical_with_preset(tasks, preset_config, original_count, additional_filters[:limit])
          elsif additional_filters[:subtasks_display] == :hide
            display_no_subtasks_with_preset(tasks, preset_config, original_count, additional_filters[:limit])
          else
            # Default: use config to determine subtask display mode
            subtasks_mode = Taskflow.configuration.subtasks_display_mode
            if subtasks_mode == "enabled"
              display_hierarchical_with_preset(tasks, preset_config, original_count, additional_filters[:limit])
            else
              display_tasks_with_preset(tasks, preset_config, original_count, additional_filters[:limit])
            end
          end
        end


        def get_tasks_for_preset(preset_config)
          release = preset_config[:release] || 'current'
          filters_raw = preset_config[:filters] || {}
          glob = preset_config[:glob]

          # If no glob provided, use 'all' preset to get default
          unless glob
            all_preset = @preset_manager.apply_preset('all', {}, :tasks)
            glob = all_preset[:glob] if all_preset
          end

          # Filter glob patterns to only include task-related patterns (already prefixed by preset manager)
          glob = filter_glob_by_type(glob, @config.task_dir)

          # Convert string keys to symbols for compatibility with TaskManager
          filters = {}
          filters_raw.each do |key, value|
            filters[key.to_sym] = value
          end

          # Add filter_specs to filters hash so TaskFilter can access them
          if preset_config[:filter_specs]
            filters[:filter_specs] = preset_config[:filter_specs]
          end

          case release
          when 'all'
            @manager.list_tasks(release: "all", filters: filters, glob: glob)
          when 'backlog'
            @manager.list_tasks(release: "backlog", filters: filters, glob: glob)
          when 'current'
            @manager.list_tasks(release: "current", filters: filters, glob: glob)
          else
            # Assume it's a specific release
            @manager.list_tasks(release: release, filters: filters, glob: glob)
          end
        end

        def apply_preset_sorting(tasks, preset_config)
          sort_config = preset_config[:sort] || { by: :sort, ascending: true }

          # Handle both string and symbol keys
          sort_by = sort_config[:by] || sort_config["by"] || :sort
          sort_by = sort_by.to_sym if sort_by.is_a?(String)
          ascending = sort_config[:ascending]
          ascending = sort_config["ascending"] if ascending.nil?
          ascending = true if ascending.nil?

          Molecules::TaskFilter.sort_tasks(
            tasks,
            sort_by,
            ascending
          )
        end

        def display_tasks_with_preset(tasks, preset_config, original_count = nil, limit = nil)
          # Display three-line header
          release = preset_config[:release] || 'current'
          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            release: release
          )
          puts header

          # Handle empty results
          if tasks.empty?
            puts ""
            puts "No tasks found for preset '#{preset_config[:name]}'."
            return 0
          end

          # Check if grouping is needed
          display_config = preset_config[:display] || {}
          if display_config[:group_by] == 'release' || display_config[:group_by] == :release
            grouped = tasks.group_by { |t| t[:release] }
            grouped.each do |release, release_tasks|
              puts ""
              puts "#{release}:"
              release_tasks.each { |task| display_task_line(task) }
            end
          else
            tasks.each { |task| display_task_line(task) }
          end

          0
        end

        def show_statistics_for_preset(preset_name, additional_filters = {})
          preset_config = @preset_manager.apply_preset(preset_name, additional_filters)
          return 1 unless preset_config

          # Override release if provided via flags
          if additional_filters[:release]
            release = additional_filters[:release]
          else
            release = preset_config[:release] || 'current'
          end

          puts @stats_formatter.format_stats_view(release: release)
          0
        end

        def display_task_line(task_data)
          task = Models::Task.new(task_data)

          status_str = status_icon(task.status)
          ref = task.qualified_reference || task.task_number || task.id || "unknown"
          display_title = strip_task_id_from_title(task.title)

          puts "  #{ref.ljust(15)} #{status_str} #{display_title}"

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
          # Use project root, not .ace-taskflow root
          root_path = Dir.pwd
          Atoms::PathFormatter.format_relative_path(path, root_path)
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
            name = preset[:name] || "unknown"
            desc = preset[:description] || ""
            default_marker = preset[:default] ? " (default)" : ""
            puts "  #{name.ljust(12)} #{desc}#{default_marker}"
          end
          puts ""
          puts "Subcommands:"
          puts "  reschedule           Reorder tasks by updating sort values"
          puts ""
          puts "Preset Examples:"
          puts "  ace-taskflow tasks                           # Uses 'next' preset (default)"
          puts "  ace-taskflow tasks recent                    # Recently modified tasks"
          puts "  ace-taskflow tasks all                       # All tasks in current release"
          puts "  ace-taskflow tasks all-releases              # All tasks across all releases"
          puts ""
          puts "Filtering Options:"
          puts "  --filter <key>:<value>                       Filter by any frontmatter field"
          puts "  --filter-clear                               Clear preset filters (keep release/scope/sort)"
          puts ""
          puts "Filter Operators:"
          puts "  Simple:     --filter status:pending         Exact match (case-insensitive)"
          puts "  OR values:  --filter status:pending|done    Match any value (pipe-separated)"
          puts "  Negation:   --filter status:!done           Exclude matches"
          puts "  Array:      --filter dependencies:task.081  Value in array"
          puts "  Multiple:   --filter status:pending --filter priority:high    AND logic"
          puts ""
          puts "Filter Examples:"
          puts "  ace-taskflow tasks --filter status:pending --filter priority:high"
          puts "  ace-taskflow tasks --filter status:pending|in-progress"
          puts "  ace-taskflow tasks all --filter status:!done --filter status:!blocked"
          puts "  ace-taskflow tasks next --filter-clear --filter priority:high"
          puts "  ace-taskflow tasks --filter team:backend --filter sprint:12"
          puts ""
          puts "Release Selection:"
          puts "  --backlog            List backlog tasks"
          puts "  --release <name>     List tasks in specific release"
          puts ""
          puts "Display Options:"
          puts "  --days <n>           Days to look back (default: 7)"
          puts "  --limit <n>          Limit number of results displayed"
          puts "  --stats              Show task statistics"
          puts "  --tree               Show dependency tree view"
          puts "  --path               Show paths only"
          puts "  --list               Show simple list format"
          puts "  --subtasks           Show hierarchical task display with tree chars"
          puts "  --no-subtasks        Hide subtasks, show count instead"
          puts "  --flat               Show all tasks without hierarchy grouping"
          puts "  --sort <field>       Sort by field (priority, status, id, modified)"
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
          release = if options[:all]
                     "all"
                   elsif options[:release]
                     options[:release]
                   else
                     "current"
                   end

          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            release: release
          )
          puts header

          # Get ALL tasks for complete dependency visualization
          all_tasks = @manager.list_tasks(release: "all")
          puts ""
          puts Molecules::DependencyTreeVisualizer.generate_forest(tasks, all_tasks)
        end

        # Formatter methods for preset release
        def display_tree_with_preset(tasks, preset_config, original_count = nil, limit = nil)
          # Display three-line header
          release = preset_config[:release] || 'current'
          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            release: release
          )
          puts header

          # Handle empty results
          if tasks.empty?
            puts ""
            puts "No tasks found for preset '#{preset_config[:name]}'."
            return 0
          end

          # Get ALL tasks for complete dependency visualization
          all_tasks = @manager.list_tasks(release: "all")
          puts ""
          puts Molecules::DependencyTreeVisualizer.generate_forest(tasks, all_tasks)
          0
        end

        def display_paths_with_preset(tasks, preset_config, original_count = nil, limit = nil)
          # Display three-line header
          release = preset_config[:release] || 'current'
          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            release: release
          )
          puts header

          # Handle empty results
          if tasks.empty?
            puts ""
            puts "No tasks found for preset '#{preset_config[:name]}'."
            return 0
          end

          # Use project root, not .ace-taskflow root
          root_path = Dir.pwd
          tasks.each do |task|
            if task[:path]
              relative_path = Atoms::PathFormatter.format_relative_path(task[:path], root_path)
              puts relative_path
            end
          end

          0
        end

        def display_list_with_preset(tasks, preset_config, original_count = nil, limit = nil)
          # Display three-line header
          release = preset_config[:release] || 'current'
          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            release: release
          )
          puts header

          # Handle empty results
          if tasks.empty?
            puts ""
            puts "No tasks found for preset '#{preset_config[:name]}'."
            return 0
          end

          tasks.each do |task|
            ref = task[:task_number] || task[:id]
            puts "#{ref} #{task[:title]}"
          end

          0
        end

        # Hierarchical display with tree characters
        def display_hierarchical_with_preset(tasks, preset_config, original_count = nil, limit = nil)
          release = preset_config[:release] || 'current'
          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            release: release
          )
          puts header

          if tasks.empty?
            puts ""
            puts "No tasks found for preset '#{preset_config[:name]}'."
            return 0
          end

          # Separate orchestrators, subtasks, and single tasks
          orchestrators = tasks.select { |t| t[:is_orchestrator] }
          subtasks_by_parent = tasks.select { |t| t[:parent_id] }.group_by { |t| t[:parent_id] }
          singles = tasks.reject { |t| t[:is_orchestrator] || t[:parent_id] }

          # Display orchestrators with their subtasks
          orchestrators.each do |orch|
            display_task_line(orch)
            children = subtasks_by_parent[orch[:id]] || []
            children.sort_by { |s| s[:id] || "" }.each_with_index do |subtask, idx|
              connector = idx == children.length - 1 ? "└─" : "├─"
              display_subtask_line(subtask, connector)
            end
          end

          # Display subtasks whose parents are not in the result set (orphan subtasks)
          orphan_subtasks = tasks.select do |t|
            t[:parent_id] && !orchestrators.any? { |o| o[:id] == t[:parent_id] }
          end
          orphan_subtasks.each { |task| display_task_line(task) }

          # Display single tasks
          singles.each { |task| display_task_line(task) }

          0
        end

        # Display without subtasks, showing count instead
        def display_no_subtasks_with_preset(tasks, preset_config, original_count = nil, limit = nil)
          release = preset_config[:release] || 'current'

          # Filter out subtasks for display
          top_level_tasks = tasks.reject { |t| t[:parent_id] }
          subtask_counts = tasks.select { |t| t[:parent_id] }.group_by { |t| t[:parent_id] }
                               .transform_values(&:count)

          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: top_level_tasks.size,
            release: release
          )
          puts header

          if top_level_tasks.empty?
            puts ""
            puts "No tasks found for preset '#{preset_config[:name]}'."
            return 0
          end

          top_level_tasks.each do |task|
            subtask_count = subtask_counts[task[:id]] || 0
            display_task_line_with_subtask_count(task, subtask_count)
          end

          0
        end

        # Flat display (no hierarchy grouping)
        def display_flat_with_preset(tasks, preset_config, original_count = nil, limit = nil)
          release = preset_config[:release] || 'current'
          header = @stats_formatter.format_header(
            command_type: :tasks,
            displayed_count: tasks.size,
            release: release
          )
          puts header

          if tasks.empty?
            puts ""
            puts "No tasks found for preset '#{preset_config[:name]}'."
            return 0
          end

          # Sort all tasks by ID for flat display
          sorted_tasks = tasks.sort_by { |t| t[:id] || t[:task_number] || "" }
          sorted_tasks.each { |task| display_task_line(task) }

          0
        end

        # Display a subtask with tree connector
        def display_subtask_line(task_data, connector)
          task = Models::Task.new(task_data)

          status_str = status_icon(task.status)
          ref = task.qualified_reference || task.task_number || task.id || "unknown"
          display_title = strip_task_id_from_title(task.title)

          puts "    #{connector} #{ref.ljust(12)} #{status_str} #{display_title}"
        end

        # Display task with subtask count indicator
        def display_task_line_with_subtask_count(task_data, subtask_count)
          task = Models::Task.new(task_data)

          status_str = status_icon(task.status)
          ref = task.qualified_reference || task.task_number || task.id || "unknown"
          display_title = strip_task_id_from_title(task.title)

          count_str = subtask_count > 0 ? " (#{subtask_count} subtasks)" : ""
          orchestrator_marker = task_data[:is_orchestrator] ? " (Orchestrator)" : ""

          puts "  #{ref.ljust(15)} #{status_str} #{display_title}#{orchestrator_marker}#{count_str}"

          # Show path on second line
          if task.path
            relative_path = format_relative_path(task.path)
            puts "    #{relative_path}"
          end
        end
      end
    end
  end
end