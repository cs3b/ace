# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/taskflow_management/task_manager"
require_relative "../../../atoms/project_root_detector"
require_relative "../../../molecules/taskflow_management/task_sort_engine"
require_relative "../../../molecules/taskflow_management/task_filter_engine"

module CodingAgentTools
  module Cli
    module Commands
      module Task
        # Next command for finding the next actionable task
        class Next < Dry::CLI::Command
          desc "Find the next actionable task to work on"

          option :limit, type: :integer, default: 1,
            desc: "Maximum number of tasks to return (default: 1)"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          option :sort, type: :string,
            desc: "Sort criteria (e.g., 'priority:desc,id:asc' or 'implementation-order')"

          option :filter, type: :array,
            desc: "Filter criteria (e.g., 'status:pending' or 'priority:!low')"

          example [
            "",
            "--limit 3",
            "--debug",
            "--sort priority:desc,id:asc",
            "--filter status:pending --filter priority:high",
            "--sort implementation-order"
          ]

          def call(**options)
            limit = validate_limit(options[:limit]) if options[:limit]
            limit ||= options[:limit] || 1

            # Use ProjectRootDetector for reliable path resolution
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            task_manager = CodingAgentTools::Organisms::TaskflowManagement::TaskManager.new(base_path: project_root)

            # Get all tasks first
            tasks_result = task_manager.get_all_tasks
            unless tasks_result.success?
              error_output("Error: #{tasks_result.message}")
              return 1
            end

            # Apply default filters for next command (pending and in-progress only)
            filter_strings = options[:filter] || CodingAgentTools::Molecules::TaskflowManagement::TaskFilterEngine.default_next_filters
            filter_result = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterEngine.apply_filter_strings(tasks_result.tasks, filter_strings)
            unless filter_result[:errors].empty?
              filter_result[:errors].each { |error| error_output("Filter error: #{error}") }
              return 1
            end
            tasks = filter_result[:tasks]

            # Apply sorting (default to implementation-order)
            sort_string = options[:sort] || CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine.default_next_sort
            sort_result_hash = CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine.apply_sort_string(tasks, sort_string)
            unless sort_result_hash[:errors].empty?
              sort_result_hash[:errors].each { |error| error_output("Sort error: #{error}") }
              return 1
            end

            final_result = sort_result_hash[:result]

            if final_result.sorted_tasks.empty?
              puts "No actionable tasks found"
              return 0
            end

            # Limit results
            limited_tasks = final_result.sorted_tasks.take(limit)

            if limit == 1
              display_task_info(limited_tasks.first)
            else
              limited_tasks.each_with_index do |task, index|
                puts "" if index > 0  # Add blank line between tasks
                display_task_info(task, index + 1, limited_tasks.size)
              end
            end
            0
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def validate_limit(limit)
            limit_int = limit.to_i
            unless limit_int.positive?
              raise ArgumentError, "Limit must be a positive integer, got: #{limit}"
            end
            limit_int
          end

          def display_task_info(task, index = nil, total = nil)
            if index && total
              puts "Task #{index}/#{total}:"
            end

            puts "  ID:    #{task.id}"
            puts "  Title: #{task.title || extract_title_from_content(task)}"
            puts "  Path:  #{task.path}"
            puts "  Status: #{task.status}"

            if task.dependencies && !task.dependencies.empty?
              deps = task.dependencies.is_a?(Array) ? task.dependencies.join(", ") : task.dependencies
              puts "  Dependencies: #{deps}"
            end
          end

          def extract_title_from_content(task)
            # Try to extract title from content if not available in metadata
            return "Unknown" unless task.respond_to?(:content) && task.content

            # Look for first heading
            lines = task.content.split("\n")
            heading_line = lines.find { |line| line.start_with?("# ") }
            if heading_line
              heading_line.sub(/^# /, "").strip
            else
              "Unknown"
            end
          end

          def handle_error(error, debug_enabled)
            if debug_enabled
              error_output("Error: #{error.class.name}: #{error.message}")
              error_output("\nBacktrace:")
              error.backtrace.each { |line| error_output("  #{line}") }
            else
              error_output("Error: #{error.message}")
              error_output("Use --debug flag for more information")
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
