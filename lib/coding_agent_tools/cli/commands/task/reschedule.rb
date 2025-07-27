# frozen_string_literal: true

require "dry/cli"
require_relative "../../../atoms/project_root_detector"
require_relative "../../../organisms/taskflow_management/task_manager"
require_relative "../../../molecules/taskflow_management/task_filter_engine"

module CodingAgentTools
  module Cli
    module Commands
      module Task
        # Reschedule command for reordering tasks with flexible sorting options
        class Reschedule < Dry::CLI::Command
          desc "Reschedule tasks by updating their sort order"

          argument :tasks, desc: "List of task IDs or file paths to reschedule", type: :array

          option :add_next, type: :boolean, default: false, aliases: ["n"],
            desc: "Add tasks before existing pending tasks"

          option :add_at_the_end, type: :boolean, default: false, aliases: ["e"],
            desc: "Add tasks after highest pending task number (default behavior)"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          example [
            "v.0.3.0+task.001 v.0.3.0+task.002",
            "118 119 120 --add-next",
            "path/to/task1.md path/to/task2.md --add-at-the-end",
            "--add-next task.001 task.002 task.003"
          ]

          def call(tasks: [], **options)
            if tasks.empty?
              error_output("Error: No tasks specified for rescheduling")
              error_output("Usage: task-manager reschedule TASK_ID [TASK_ID...] [OPTIONS]")
              return 1
            end

            # Use ProjectRootDetector for reliable path resolution
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            task_manager = CodingAgentTools::Organisms::TaskflowManagement::TaskManager.new(base_path: project_root)

            # Get all tasks to understand current state
            tasks_result = task_manager.get_all_tasks
            unless tasks_result.success?
              error_output("Error: #{tasks_result.message}")
              return 1
            end

            # Resolve task identifiers to actual tasks
            tasks_to_reschedule = resolve_tasks(tasks, tasks_result.tasks)
            if tasks_to_reschedule.empty?
              error_output("Error: No valid tasks found from provided identifiers")
              return 1
            end

            # Determine rescheduling strategy
            if options[:add_next]
              reschedule_add_next(tasks_to_reschedule, tasks_result.tasks, task_manager)
            else
              # Default behavior is add-at-the-end
              reschedule_add_at_end(tasks_to_reschedule, tasks_result.tasks, task_manager)
            end

            puts "Successfully rescheduled #{tasks_to_reschedule.length} task(s)"
            0
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def resolve_tasks(identifiers, all_tasks)
            resolved_tasks = []

            identifiers.each do |identifier|
              # Try to find task by ID, path, or partial match
              task = find_task(identifier, all_tasks)
              if task
                resolved_tasks << task
              else
                error_output("Warning: Could not find task matching '#{identifier}'")
              end
            end

            resolved_tasks
          end

          def find_task(identifier, all_tasks)
            # Direct ID match
            task = all_tasks.find { |t| t.id == identifier }
            return task if task

            # ID without version prefix
            if identifier =~ /^\d+$/
              task = all_tasks.find { |t| t.id =~ /\+task\.#{identifier}$/ }
              return task if task
            end

            # Path match
            task = all_tasks.find { |t| t.path == identifier || t.path.end_with?(identifier) }
            return task if task

            # Partial ID match
            all_tasks.find { |t| t.id.include?(identifier) }
          end

          def reschedule_add_next(tasks_to_reschedule, all_tasks, task_manager)
            # Find the lowest sort value among pending tasks
            pending_tasks = all_tasks.select { |t| t.status == "pending" }
            
            # Get current sort values
            min_sort = pending_tasks.map { |t| get_task_sort_value(t) }.compact.min || 1000
            
            # Assign new sort values starting from (min_sort - tasks_to_reschedule.length)
            new_sort_base = min_sort - tasks_to_reschedule.length
            
            tasks_to_reschedule.each_with_index do |task, index|
              new_sort_value = new_sort_base + index
              update_task_sort(task, new_sort_value, task_manager)
              puts "  Rescheduled #{task.id} with sort value #{new_sort_value}"
            end
          end

          def reschedule_add_at_end(tasks_to_reschedule, all_tasks, task_manager)
            # Find the highest sort value among all tasks
            max_sort = all_tasks.map { |t| get_task_sort_value(t) }.compact.max || 0
            
            # Also consider task sequential numbers for tasks without sort values
            max_sequential = all_tasks.map { |t| parse_task_sequential_number(t.id) }.compact.max || 0
            
            # Use the higher of the two as the base
            new_sort_base = [max_sort, max_sequential].max + 1
            
            tasks_to_reschedule.each_with_index do |task, index|
              new_sort_value = new_sort_base + index
              update_task_sort(task, new_sort_value, task_manager)
              puts "  Rescheduled #{task.id} with sort value #{new_sort_value}"
            end
          end

          def get_task_sort_value(task)
            if task.respond_to?(:frontmatter) && task.frontmatter
              sort_value = task.frontmatter["sort"] || task.frontmatter[:sort]
              return sort_value.to_i if sort_value&.to_s&.match?(/^\d+$/)
            end
            nil
          end

          def parse_task_sequential_number(task_id_str)
            return nil unless task_id_str&.is_a?(String)
            match = task_id_str.match(/\+task\.(\d+)$/)
            match ? match[1].to_i : nil
          end

          def update_task_sort(task, sort_value, task_manager)
            # Read the task file
            content = File.read(task.path)
            
            # Parse frontmatter
            if content =~ /\A---\n(.*?)\n---\n(.*)/m
              frontmatter = $1
              body = $2
              
              # Check if sort already exists in frontmatter
              if frontmatter =~ /^sort:\s*\d+$/
                # Update existing sort value
                new_frontmatter = frontmatter.gsub(/^sort:\s*\d+$/, "sort: #{sort_value}")
              else
                # Add sort value to frontmatter
                new_frontmatter = frontmatter + "\nsort: #{sort_value}"
              end
              
              # Write updated content
              new_content = "---\n#{new_frontmatter}\n---\n#{body}"
              File.write(task.path, new_content)
            else
              error_output("Warning: Could not parse frontmatter for #{task.id}")
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