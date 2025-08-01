# frozen_string_literal: true

require 'dry/cli'
require_relative '../../../organisms/taskflow_management/task_manager'
require_relative '../../../atoms/project_root_detector'
require_relative '../../../molecules/taskflow_management/task_sort_engine'
require_relative '../../../molecules/taskflow_management/task_filter_engine'
require_relative '../../../molecules/taskflow_management/unified_task_formatter'
require_relative '../../../molecules/taskflow_management/task_status_summary'

module CodingAgentTools
  module Cli
    module Commands
      module Task
        # List command for listing all tasks with topological sorting
        class List < Dry::CLI::Command
          desc 'List all tasks in current release with dependency order'

          option :debug, type: :boolean, default: false, aliases: ['d'],
                         desc: 'Enable debug output for verbose error information'

          option :show_cycles, type: :boolean, default: false,
                               desc: 'Show additional information about dependency cycles'

          option :sort, type: :string,
                        desc: "Sort criteria (e.g., 'priority:desc,id:asc' or 'implementation-order')"

          option :filter, type: :array,
                          desc: "Filter criteria (e.g., 'status:pending' or 'priority:!low')"

          option :verbose, type: :boolean, default: false, aliases: ['v'],
                           desc: 'Show detailed task information (old format)'

          option :release, type: :string,
                           desc: 'Release to work with (version, codename, fullname, or path). Defaults to current release.'

          example [
            '',
            '--debug',
            '--show-cycles',
            '--sort priority:desc,id:asc',
            '--filter status:pending --filter priority:high',
            '--sort implementation-order'
          ]

          def call(**options)
            # Use ProjectRootDetector for reliable path resolution
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            task_manager = CodingAgentTools::Organisms::TaskflowManagement::TaskManager.new(base_path: project_root)

            # Get all tasks first
            tasks_result = task_manager.get_list_tasks(release_path: options[:release])
            unless tasks_result.success?
              error_output("Error: #{tasks_result.message}")
              return 1
            end

            # Apply filtering if specified
            filter_strings = options[:filter] || []
            tasks = tasks_result.tasks
            unless filter_strings.empty?
              filter_result = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterEngine.apply_filter_strings(
                tasks, filter_strings
              )
              unless filter_result[:errors].empty?
                filter_result[:errors].each { |error| error_output("Filter error: #{error}") }
                return 1
              end
              tasks = filter_result[:tasks]
            end

            # Apply sorting (default to implementation-order)
            sort_string = options[:sort] || CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine.default_list_sort
            sort_result_hash = CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine.apply_sort_string(tasks,
                                                                                                                 sort_string)
            unless sort_result_hash[:errors].empty?
              sort_result_hash[:errors].each { |error| error_output("Sort error: #{error}") }
              return 1
            end

            final_result = sort_result_hash[:result]

            # Generate status summary from all tasks in the current release (before filtering)
            status_summary = CodingAgentTools::Molecules::TaskflowManagement::TaskStatusSummary.generate_summary(tasks_result.tasks)

            handle_result(final_result, options, status_summary)
            0
          rescue StandardError => e
            handle_error(e, options[:debug])
            1
          end

          private

          def handle_result(result, options, status_summary = nil)
            if result.sorted_tasks.empty?
              # Show status summary even when no tasks match the filter criteria
              puts status_summary.formatted_text if status_summary
              puts 'No tasks found matching criteria'
              return
            end

            display_header(result, options, status_summary)
            result.sorted_tasks.each_with_index do |task, index|
              puts '' if index > 0 && options[:verbose] # Add blank line between tasks only in verbose mode
              Molecules::TaskflowManagement::UnifiedTaskFormatter.format_task(
                task,
                verbose: options[:verbose],
                show_time: true,
                show_path: !options[:verbose] # Show path in compact mode
              )
            end
            display_footer(result, options) if options[:show_cycles] || result.has_cycles?
          end

          def display_header(result, _options, status_summary = nil)
            # Display status summary first if available
            puts status_summary.formatted_text if status_summary

            puts "All Tasks (#{result.sorted_tasks.size} total):"
            puts '=' * 50

            # Show sort/filter metadata if available
            if result.sort_metadata && !result.sort_metadata.empty?
              sort_type = result.sort_metadata[:sort_type] || 'custom'
              puts colorize("ℹ️  Sorted by: #{sort_type}", :blue)
            end

            return if result.fully_sorted?

            if result.has_cycles?
              puts colorize('⚠️  WARNING: Dependency cycles detected!', :yellow)
              puts colorize("   #{result.sorted_count}/#{result.total_count} tasks sorted", :yellow)
            else
              puts colorize('ℹ️  Some tasks may have external dependencies', :blue)
            end
            puts ''
          end

          def display_footer(result, _options)
            return unless result.has_cycles?

            puts ''
            puts colorize('Dependency Cycle Information:', :red)
            puts colorize("  • #{result.sorted_count} tasks successfully sorted", :green)
            puts colorize("  • #{result.total_count - result.sorted_count} tasks in cycles", :red)
            puts colorize('  • Review task dependencies to resolve cycles', :yellow)
          end

          def status_color_for(status)
            case status&.downcase
            when 'done'
              :green
            when 'in-progress'
              :blue
            when 'pending'
              :yellow
            when 'blocked'
              :red
            else
              :default
            end
          end

          def priority_color_for(priority)
            case priority&.downcase
            when 'high'
              :red
            when 'medium'
              :yellow
            when 'low'
              :green
            else
              :default
            end
          end

          def colorize(text, color)
            # Simple colorization - can be enhanced with proper color support
            case color
            when :red
              "\e[31m#{text}\e[0m"
            when :green
              "\e[32m#{text}\e[0m"
            when :yellow
              "\e[33m#{text}\e[0m"
            when :blue
              "\e[34m#{text}\e[0m"
            else
              text
            end
          end

          def handle_error(error, debug_enabled)
            if debug_enabled
              error_output("Error: #{error.class.name}: #{error.message}")
              error_output("\nBacktrace:")
              error.backtrace.each { |line| error_output("  #{line}") } if error.backtrace
            else
              error_output("Error: #{error.message}")
              error_output('Use --debug flag for more information')
            end
          end

          def error_output(message)
            warn message
          end
        end
      end
    end
  end
end
