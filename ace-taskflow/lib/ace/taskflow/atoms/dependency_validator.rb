# frozen_string_literal: true

module Ace
  module Taskflow
    module Atoms
      # Pure functions for validating task dependencies
      class DependencyValidator
        # Check if a dependency reference is valid
        # @param dep_id [String] Dependency ID to validate
        # @param task_map [Hash] Map of task IDs to tasks
        # @return [Boolean] True if valid
        def self.valid_reference?(dep_id, task_map)
          return false if dep_id.nil? || dep_id.empty?

          normalized = normalize_id(dep_id)
          task_map.key?(normalized)
        end

        # Check for self-dependency
        # @param task_id [String] Task ID
        # @param dep_id [String] Dependency ID
        # @return [Boolean] True if self-dependency
        def self.self_dependency?(task_id, dep_id)
          normalize_id(task_id) == normalize_id(dep_id)
        end

        # Check if adding a dependency would create a cycle
        # @param from_task_id [String] Task adding the dependency
        # @param to_task_id [String] Task being depended on
        # @param task_map [Hash] Map of all tasks
        # @return [Boolean] True if would create a cycle
        def self.would_create_cycle?(from_task_id, to_task_id, task_map)
          # Check if there's already a path from to_task_id to from_task_id
          has_path?(to_task_id, from_task_id, task_map, Set.new)
        end

        # Find circular dependency path if it exists
        # @param from_task_id [String] Starting task
        # @param to_task_id [String] Target task
        # @param task_map [Hash] Map of all tasks
        # @return [Array<String>, nil] Path if circular, nil otherwise
        def self.find_circular_path(from_task_id, to_task_id, task_map)
          path = []
          if has_path?(to_task_id, from_task_id, task_map, Set.new, path)
            path.unshift(from_task_id)
            path << from_task_id
            return path
          end
          nil
        end

        # Validate all dependencies for a task
        # @param task [Hash] Task to validate
        # @param all_tasks [Array<Hash>] All tasks
        # @return [Hash] Validation result with :valid and :errors
        def self.validate_task_dependencies(task, all_tasks)
          errors = []
          task_map = build_task_map(all_tasks)

          return { valid: true, errors: [] } if task[:dependencies].nil? || task[:dependencies].empty?

          task[:dependencies].each do |dep_id|
            # Check if reference exists
            unless valid_reference?(dep_id, task_map)
              errors << "Dependency '#{dep_id}' does not exist"
              next
            end

            # Check for self-dependency
            if self_dependency?(task[:id], dep_id)
              errors << "Task cannot depend on itself"
              next
            end

            # Check for circular dependency
            if would_create_cycle?(task[:id], dep_id, task_map)
              path = find_circular_path(task[:id], dep_id, task_map)
              errors << "Circular dependency detected: #{path.join(' -> ')}"
            end
          end

          { valid: errors.empty?, errors: errors }
        end

        # Validate dependencies for all tasks
        # @param tasks [Array<Hash>] Tasks to validate
        # @return [Hash] Map of task IDs to validation results
        def self.validate_all_dependencies(tasks)
          results = {}

          tasks.each do |task|
            result = validate_task_dependencies(task, tasks)
            results[task[:id]] = result if !result[:valid]
          end

          results
        end

        private

        def self.normalize_id(id)
          return nil if id.nil?

          # Handle both full IDs and task numbers
          id.to_s.strip
        end

        def self.build_task_map(tasks)
          tasks.each_with_object({}) do |task, map|
            map[task[:id]] = task
            # Also map by task number for flexible reference
            if task[:task_number]
              map[task[:task_number]] = task
              # Also map with "task." prefix for compatibility
              map["task.#{task[:task_number]}"] = task
            end
            # Extract and map just the numeric part
            if task[:id] && match = task[:id].match(/task\.(\d+)$/)
              map["task.#{match[1]}"] = task
            end
          end
        end

        def self.has_path?(from_id, to_id, task_map, visited, path = [])
          return true if normalize_id(from_id) == normalize_id(to_id)
          return false if visited.include?(from_id)

          visited.add(from_id)
          path << from_id

          from_task = task_map[normalize_id(from_id)]
          return false unless from_task && from_task[:dependencies]

          from_task[:dependencies].each do |dep_id|
            if has_path?(normalize_id(dep_id), to_id, task_map, visited, path)
              return true
            end
          end

          path.pop
          false
        end
      end
    end
  end
end