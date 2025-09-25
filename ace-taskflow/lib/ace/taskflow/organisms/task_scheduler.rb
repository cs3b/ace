# frozen_string_literal: true

require_relative "../models/task"

module Ace
  module Taskflow
    module Organisms
      # Handles rescheduling of tasks by managing sort values
      class TaskScheduler
        def initialize(task_manager)
          @task_manager = task_manager
        end

        def reschedule(task_identifiers, options = {})
          # Get all current tasks
          all_tasks = @task_manager.list_tasks(context: "all")

          # Resolve task identifiers to actual tasks
          tasks_to_reschedule = resolve_tasks(task_identifiers, all_tasks)

          if tasks_to_reschedule.empty?
            raise "No valid tasks found from provided identifiers"
          end

          # Apply the rescheduling strategy
          case options[:strategy]
          when :add_next
            reschedule_add_next(tasks_to_reschedule, all_tasks)
          when :add_at_end
            reschedule_add_at_end(tasks_to_reschedule, all_tasks)
          when :after
            reschedule_after(tasks_to_reschedule, all_tasks, options[:reference_task])
          when :before
            reschedule_before(tasks_to_reschedule, all_tasks, options[:reference_task])
          else
            # Default to add_next
            reschedule_add_next(tasks_to_reschedule, all_tasks)
          end
        end

        private

        def resolve_tasks(identifiers, all_tasks)
          resolved = []

          identifiers.each do |identifier|
            task = find_task(identifier, all_tasks)
            if task
              resolved << task
            else
              warn "Warning: Could not find task matching '#{identifier}'"
            end
          end

          resolved
        end

        def find_task(identifier, all_tasks)
          # Direct ID match
          task = all_tasks.find { |t| t[:id] == identifier }
          return task if task

          # ID without version prefix (e.g., "026")
          if /^\d+$/.match?(identifier)
            task = all_tasks.find { |t| t[:id] =~ /\+task\.#{identifier}$/ }
            return task if task
          end

          # Path match
          task = all_tasks.find { |t| t[:path] == identifier || t[:path]&.end_with?(identifier) }
          return task if task

          # Partial ID match (e.g., "task.026")
          all_tasks.find { |t| t[:id]&.include?(identifier) }
        end

        def reschedule_add_next(tasks_to_reschedule, all_tasks)
          # Find the lowest sort value among pending tasks
          pending_tasks = all_tasks.select { |t| t[:status] == "pending" }

          # Get current sort values
          min_sort = pending_tasks.map { |t| get_task_sort_value(t) }.compact.min || 1000

          # Assign new sort values starting from (min_sort - tasks_to_reschedule.length)
          new_sort_base = min_sort - tasks_to_reschedule.length

          tasks_to_reschedule.each_with_index do |task, index|
            new_sort_value = new_sort_base + index
            update_task_sort(task, new_sort_value)
            puts "  Rescheduled #{task[:id]} with sort value #{new_sort_value}"
          end
        end

        def reschedule_add_at_end(tasks_to_reschedule, all_tasks)
          # Find the highest sort value among all tasks
          max_sort = all_tasks.map { |t| get_task_sort_value(t) }.compact.max || 0

          # Also consider task sequential numbers for tasks without sort values
          max_sequential = all_tasks.map { |t| parse_task_sequential_number(t[:id]) }.compact.max || 0

          # Use the higher of the two as the base
          new_sort_base = [max_sort, max_sequential].max + 1

          tasks_to_reschedule.each_with_index do |task, index|
            new_sort_value = new_sort_base + index
            update_task_sort(task, new_sort_value)
            puts "  Rescheduled #{task[:id]} with sort value #{new_sort_value}"
          end
        end

        def reschedule_after(tasks_to_reschedule, all_tasks, reference_identifier)
          reference_task = find_task(reference_identifier, all_tasks)
          unless reference_task
            raise "Could not find reference task: #{reference_identifier}"
          end

          # Get the sort value of the reference task
          ref_sort = get_task_sort_value(reference_task) || parse_task_sequential_number(reference_task[:id]) || 0

          # Find the next task's sort value to determine the gap
          all_sorted = all_tasks.map { |t|
            [t, get_task_sort_value(t) || parse_task_sequential_number(t[:id]) || 0]
          }.sort_by { |_, sort| sort }

          ref_index = all_sorted.find_index { |t, _| t[:id] == reference_task[:id] }
          next_sort = if ref_index && ref_index < all_sorted.length - 1
            all_sorted[ref_index + 1][1]
          else
            ref_sort + 100
          end

          # Place tasks in the gap between reference and next task
          gap_size = next_sort - ref_sort
          increment = gap_size.to_f / (tasks_to_reschedule.length + 1)

          tasks_to_reschedule.each_with_index do |task, index|
            new_sort_value = (ref_sort + (increment * (index + 1))).to_i
            update_task_sort(task, new_sort_value)
            puts "  Rescheduled #{task[:id]} with sort value #{new_sort_value} (after #{reference_task[:id]})"
          end
        end

        def reschedule_before(tasks_to_reschedule, all_tasks, reference_identifier)
          reference_task = find_task(reference_identifier, all_tasks)
          unless reference_task
            raise "Could not find reference task: #{reference_identifier}"
          end

          # Get the sort value of the reference task
          ref_sort = get_task_sort_value(reference_task) || parse_task_sequential_number(reference_task[:id]) || 1000

          # Find the previous task's sort value to determine the gap
          all_sorted = all_tasks.map { |t|
            [t, get_task_sort_value(t) || parse_task_sequential_number(t[:id]) || 0]
          }.sort_by { |_, sort| sort }

          ref_index = all_sorted.find_index { |t, _| t[:id] == reference_task[:id] }
          prev_sort = if ref_index && ref_index > 0
            all_sorted[ref_index - 1][1]
          else
            ref_sort - 100
          end

          # Place tasks in the gap between previous and reference task
          gap_size = ref_sort - prev_sort
          increment = gap_size.to_f / (tasks_to_reschedule.length + 1)

          tasks_to_reschedule.each_with_index do |task, index|
            new_sort_value = (prev_sort + (increment * (index + 1))).to_i
            update_task_sort(task, new_sort_value)
            puts "  Rescheduled #{task[:id]} with sort value #{new_sort_value} (before #{reference_task[:id]})"
          end
        end

        def get_task_sort_value(task)
          task[:sort] if task[:sort].is_a?(Integer)
        end

        def parse_task_sequential_number(task_id_str)
          return nil unless task_id_str.is_a?(String)

          match = task_id_str.match(/\+task\.(\d+)$/)
          match ? match[1].to_i : nil
        end

        def update_task_sort(task, sort_value)
          # Read the task file
          content = File.read(task[:path])

          # Parse frontmatter
          if content =~ /\A---\n(.*?)\n---\n(.*)/m
            frontmatter = $1
            body = $2

            # Check if sort already exists in frontmatter
            new_frontmatter = if frontmatter =~ /^sort:\s*\d+$/
              # Update existing sort value
              frontmatter.gsub(/^sort:\s*\d+$/, "sort: #{sort_value}")
            else
              # Add sort value to frontmatter
              frontmatter + "\nsort: #{sort_value}"
            end

            # Write updated content
            new_content = "---\n#{new_frontmatter}\n---\n#{body}"
            File.write(task[:path], new_content)
          else
            warn "Warning: Could not parse frontmatter for #{task[:id]}"
          end
        end
      end
    end
  end
end