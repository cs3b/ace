# frozen_string_literal: true

require_relative 'task_sort_parser'
require 'set'

module CodingAgentTools
  module Molecules
    module TaskflowManagement
      # TaskSortEngine applies sorting to task collections
      # This is a molecule - it provides a focused operation for sorting tasks
      class TaskSortEngine
        # Sort result structure
        SortResult = Struct.new(:sorted_tasks, :cycle_detected, :sorted_count, :total_count, :sort_metadata) do
          def fully_sorted?
            !cycle_detected && sorted_count == total_count
          end

          def has_cycles?
            cycle_detected
          end
        end

        # Apply sorting to a collection of tasks
        # @param tasks [Array] Array of task data objects
        # @param sorts [Array<TaskSortParser::SortCriteria>] Array of sort criteria
        # @return [SortResult] Result with sorted tasks and metadata
        def self.apply_sorts(tasks, sorts)
          return SortResult.new(tasks, false, tasks.length, tasks.length, {}) if !sorts || sorts.empty?

          # Check if implementation-order sorting is requested
          if sorts.any?(&:implementation_order?)
            apply_implementation_order_sort(tasks, sorts)
          else
            apply_multi_attribute_sort(tasks, sorts)
          end
        end

        # Apply sorting from sort strings
        # @param tasks [Array] Array of task data objects
        # @param sort_string [String] Sort string like "priority:desc,id:asc"
        # @return [Hash] Hash with :result and :errors keys
        def self.apply_sort_string(tasks, sort_string)
          if !sort_string || sort_string.strip.empty?
            return { result: SortResult.new(tasks, false, tasks.length, tasks.length, {}),
                     errors: [] }
          end

          # Parse sorts
          sorts = TaskSortParser.parse_sorts(sort_string)

          # Validate sorts
          errors = TaskSortParser.validate_sorts(sorts)
          return { result: nil, errors: errors } unless errors.empty?

          # Apply sorts
          result = apply_sorts(tasks, sorts)

          { result: result, errors: [] }
        end

        # Get default sort for all command (implementation-order)
        # @return [String] Default sort string for all command
        def self.default_all_sort
          'implementation-order'
        end

        # Get default sort for next command (implementation-order)
        # @return [String] Default sort string for next command
        def self.default_next_sort
          'implementation-order'
        end

        # Apply implementation-order sorting (ID-based with dependency constraints)
        def self.apply_implementation_order_sort(tasks, _sorts)
          # Create task map
          task_map = {}
          tasks.each { |task| task_map[task.id] = task }

          # Start with tasks sorted by ID (natural order)
          sorted_tasks = tasks.sort_by do |task|
            [
              get_sort_metadata(task), # Optional sort metadata
              parse_task_sequential_number(task.id), # Task sequential number
              task.id.to_s # Task ID for deterministic ordering
            ]
          end

          # Build dependency graph
          task_dependents = Hash.new { |h, k| h[k] = [] }
          task_dependencies = Hash.new { |h, k| h[k] = [] }

          tasks.each do |task|
            dependencies = extract_dependencies(task)
            dependencies.each do |dep_id|
              # Only consider intra-release dependencies
              if task_map.key?(dep_id)
                task_dependents[dep_id] << task.id
                task_dependencies[task.id] << dep_id
              end
            end
          end

          # Apply dependency constraints with minimal reordering
          # Use a simple approach: for each task, ensure all its dependencies appear before it
          max_iterations = sorted_tasks.length * 2
          iteration = 0

          while iteration < max_iterations
            iteration += 1
            made_changes = false

            # Check each task to see if it needs to be moved
            (0...sorted_tasks.length).each do |i|
              task = sorted_tasks[i]
              dependencies = task_dependencies[task.id]

              next if dependencies.empty?

              # Find the latest position of any dependency
              latest_dep_position = -1
              dependencies.each do |dep_id|
                dep_position = sorted_tasks.find_index { |t| t.id == dep_id }
                latest_dep_position = dep_position if dep_position && dep_position > latest_dep_position
              end

              # If this task appears before its latest dependency, move it after
              next unless latest_dep_position >= 0 && i <= latest_dep_position

              # Remove task from current position
              task_to_move = sorted_tasks.delete_at(i)
              # Insert after the latest dependency
              sorted_tasks.insert(latest_dep_position, task_to_move)
              made_changes = true
              break # Restart the check after making a change
            end

            # If no changes were made, we're done
            break unless made_changes
          end

          # Check for cycles (if we hit max iterations)
          cycle_detected = iteration >= max_iterations

          SortResult.new(
            sorted_tasks,
            cycle_detected,
            sorted_tasks.length,
            tasks.length,
            { sort_type: 'implementation-order',
              dependency_levels: calculate_dependency_levels(sorted_tasks, task_map) }
          )
        end

        # Apply multi-attribute sorting
        def self.apply_multi_attribute_sort(tasks, sorts)
          sorted_tasks = tasks.sort do |a, b|
            # Compare using each sort criteria in order
            comparison_result = nil
            sorts.each do |sort|
              a_value = sort.get_sort_value(a)
              b_value = sort.get_sort_value(b)

              # Handle nil values (put them last)
              comparison = if a_value.nil? && b_value.nil?
                             0
                           elsif a_value.nil?
                             1
                           elsif b_value.nil?
                             -1
                           else
                             a_value <=> b_value
                           end

              # Apply direction
              comparison = -comparison if sort.descending?

              # If this criteria gives a definitive result, use it
              if comparison != 0
                comparison_result = comparison
                break
              end
            end

            # If all criteria are equal, sort by task ID for deterministic ordering
            comparison_result || (a.id.to_s <=> b.id.to_s)
          end

          SortResult.new(
            sorted_tasks,
            false,
            sorted_tasks.length,
            tasks.length,
            { sort_type: 'multi-attribute', criteria: sorts.map(&:raw_sort) }
          )
        end

        # Extract dependencies from task data
        def self.extract_dependencies(task)
          return [] unless task.dependencies

          case task.dependencies
          when Array
            task.dependencies.map(&:to_s)
          when String
            task.dependencies.split(',').map(&:strip)
          else
            []
          end
        end

        # Parse task sequential number for sorting
        def self.parse_task_sequential_number(task_id_str)
          return Float::INFINITY unless task_id_str&.is_a?(String)

          match = task_id_str.match(/\+task\.(\d+)$/)
          match ? match[1].to_i : Float::INFINITY
        end

        # Get sort metadata from task for implementation order
        def self.get_sort_metadata(task)
          # Try to get 'sort' attribute from frontmatter
          if task.respond_to?(:frontmatter) && task.frontmatter
            sort_value = task.frontmatter['sort'] || task.frontmatter[:sort]
            return sort_value.to_i if sort_value&.to_s&.match?(/^\d+$/)
          end

          # Default to 0 if no sort metadata
          0
        end

        # Calculate dependency levels for metadata
        def self.calculate_dependency_levels(sorted_tasks, task_map)
          levels = {}
          current_level = 0
          processed = Set.new

          sorted_tasks.each do |task|
            dependencies = extract_dependencies(task)
            intra_release_deps = dependencies.select { |dep| task_map.key?(dep) }

            if intra_release_deps.empty? || intra_release_deps.all? { |dep| processed.include?(dep) }
              # This task can be at the current level
              levels[task.id] = current_level
            else
              # This task needs to be at a higher level
              max_dep_level = intra_release_deps.map { |dep| levels[dep] || 0 }.max
              levels[task.id] = max_dep_level + 1
              current_level = [current_level, levels[task.id]].max
            end

            processed.add(task.id)
          end

          levels
        end

        private_class_method :apply_implementation_order_sort
      end
    end
  end
end
