# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/taskflow_management/task_manager"
require_relative "../../../atoms/project_root_detector"

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

          example [
            "",
            "--limit 3",
            "--debug"
          ]

          def call(**options)
            limit = validate_limit(options[:limit]) if options[:limit]
            limit ||= options[:limit] || 1

            # Use ProjectRootDetector for reliable path resolution
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            task_manager = CodingAgentTools::Organisms::TaskflowManagement::TaskManager.new(base_path: project_root)

            if limit == 1
              # Return single task for backward compatibility
              result = task_manager.find_next_actionable_task_with_highlight
              handle_single_task_result(result, options)
            else
              # Return multiple tasks
              handle_multiple_tasks(task_manager, options.merge(limit: limit))
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

          def handle_single_task_result(result, options)
            unless result.success?
              error_output("Error: #{result.message}")
              return
            end

            unless result.found?
              puts "No actionable tasks found"
              return
            end

            display_task_info(result.task)
          end

          def handle_multiple_tasks(task_manager, options)
            # Get all tasks and filter for actionable ones
            all_result = task_manager.get_all_tasks
            
            unless all_result.success?
              error_output("Error: #{all_result.message}")
              return
            end

            actionable_tasks = filter_actionable_tasks(all_result.tasks)
            
            if actionable_tasks.empty?
              puts "No actionable tasks found"
              return
            end

            # Limit results
            limited_tasks = actionable_tasks.take(options[:limit])
            
            limited_tasks.each_with_index do |task, index|
              puts "" if index > 0  # Add blank line between tasks
              display_task_info(task, index + 1, limited_tasks.size)
            end
          end

          def filter_actionable_tasks(tasks)
            # Filter for tasks that are not done and could be actionable
            tasks.select { |task| task.status != "done" }
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