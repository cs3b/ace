# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Resolves task dependencies and performs topological sorting
      class DependencyResolver
        # Check if all dependencies for a task are met
        # @param task [Hash] Task to check
        # @param all_tasks [Array<Hash>] All tasks in the system
        # @return [Boolean] True if all dependencies are met
        def self.dependencies_met?(task, all_tasks)
          return true if task[:dependencies].nil? || task[:dependencies].empty?

          task_map = build_task_map(all_tasks)

          task[:dependencies].all? do |dep_id|
            dep_task = task_map[normalize_id(dep_id)]
            dep_task && dep_task[:status] == 'done'
          end
        end

        # Get list of blocking tasks (unmet dependencies)
        # @param task [Hash] Task to check
        # @param all_tasks [Array<Hash>] All tasks in the system
        # @return [Array<Hash>] List of blocking tasks
        def self.get_blocking_tasks(task, all_tasks)
          return [] if task[:dependencies].nil? || task[:dependencies].empty?

          task_map = build_task_map(all_tasks)

          task[:dependencies].map do |dep_id|
            dep_task = task_map[normalize_id(dep_id)]
            next nil if dep_task.nil? || dep_task[:status] == 'done'
            dep_task
          end.compact
        end

        # Perform topological sort on tasks considering dependencies
        # @param tasks [Array<Hash>] Tasks to sort
        # @return [Array<Hash>] Topologically sorted tasks
        def self.topological_sort(tasks)
          # Build dependency graph
          graph = build_dependency_graph(tasks)
          task_map = build_task_map(tasks)

          # Find tasks with no dependencies
          sorted = []
          visited = Set.new

          # Use depth-first search for topological sort
          tasks.each do |task|
            visit_task(task[:id], graph, task_map, visited, sorted) unless visited.include?(task[:id])
          end

          sorted
        end

        # Sort tasks with dependency awareness
        # @param tasks [Array<Hash>] Tasks to sort
        # @param sort_by [Symbol] Primary sort criterion
        # @param ascending [Boolean] Sort direction
        # @return [Array<Hash>] Sorted tasks with dependencies considered
        def self.dependency_aware_sort(tasks, sort_by = :sort, ascending = true)
          # First, perform topological sort to get dependency order
          topo_sorted = topological_sort_with_levels(tasks)

          # Now apply the requested sort within each dependency level
          result = []
          topo_sorted.each do |level_tasks|
            sorted_level = apply_standard_sort(level_tasks, sort_by, ascending)
            result.concat(sorted_level)
          end

          result
        end

        # Perform topological sort grouped by dependency levels
        # @param tasks [Array<Hash>] Tasks to sort
        # @return [Array<Array<Hash>>] Tasks grouped by dependency level
        def self.topological_sort_with_levels(tasks)
          task_map = build_task_map(tasks)
          in_degree = {}
          dependents = {}

          # Initialize in-degree and dependents map
          tasks.each do |task|
            task_id = task[:id]
            in_degree[task_id] = 0
            dependents[task_id] = []
          end

          # Calculate in-degrees and build dependents map
          tasks.each do |task|
            next unless task[:dependencies]

            task[:dependencies].each do |dep_id|
              normalized_dep = normalize_id(dep_id)
              dep_task = task_map[normalized_dep]
              next unless dep_task

              in_degree[task[:id]] += 1
              dependents[dep_task[:id]] << task[:id]
            end
          end

          # Group tasks by levels
          levels = []
          processed = Set.new

          while processed.size < tasks.size
            # Find all tasks with in-degree 0 that haven't been processed
            current_level = []

            tasks.each do |task|
              next if processed.include?(task[:id])
              next unless in_degree[task[:id]] == 0

              current_level << task
              processed.add(task[:id])
            end

            # If no tasks can be added, we have a cycle or disconnected tasks
            if current_level.empty?
              # Add remaining tasks as a final level
              remaining = tasks.select { |t| !processed.include?(t[:id]) }
              levels << remaining unless remaining.empty?
              break
            end

            levels << current_level

            # Reduce in-degree for dependent tasks
            current_level.each do |task|
              dependents[task[:id]].each do |dependent_id|
                in_degree[dependent_id] -= 1
              end
            end
          end

          levels
        end

        # Check for circular dependencies
        # @param tasks [Array<Hash>] All tasks
        # @param from_task_id [String] Task to add dependency from
        # @param to_task_id [String] Task to add dependency to
        # @return [Array<String>, nil] Circular path if found, nil otherwise
        def self.check_circular_dependency(tasks, from_task_id, to_task_id)
          task_map = build_task_map(tasks)
          visited = Set.new
          path = []

          if has_path?(to_task_id, from_task_id, task_map, visited, path)
            path.unshift(from_task_id)
            path << from_task_id
            return path
          end

          nil
        end

        # Build dependency tree for visualization
        # @param task_id [String] Root task ID
        # @param all_tasks [Array<Hash>] All tasks
        # @param visited [Set] Already visited tasks (for cycle prevention)
        # @return [Hash] Tree structure with task and its dependencies
        def self.build_dependency_tree(task_id, all_tasks, visited = Set.new)
          return nil if visited.include?(task_id)
          visited.add(task_id)

          task_map = build_task_map(all_tasks)
          task = task_map[normalize_id(task_id)]
          return nil unless task

          tree = {
            task: task,
            dependencies: []
          }

          if task[:dependencies] && !task[:dependencies].empty?
            task[:dependencies].each do |dep_id|
              dep_tree = build_dependency_tree(dep_id, all_tasks, visited)
              tree[:dependencies] << dep_tree if dep_tree
            end
          end

          tree
        end

        # Build global dependency forest (multiple trees for independent chains)
        # @param tasks [Array<Hash>] All tasks
        # @return [Array<Hash>] Forest of dependency trees
        def self.build_dependency_forest(tasks)
          # Find root tasks (no other task depends on them)
          task_ids = tasks.map { |t| t[:id] }
          dependent_ids = tasks.flat_map { |t| t[:dependencies] || [] }.uniq
          root_ids = task_ids - dependent_ids

          # Build tree for each root
          forest = []
          visited = Set.new

          root_ids.each do |root_id|
            tree = build_dependency_tree(root_id, tasks, visited)
            forest << tree if tree
          end

          # Add any remaining unvisited tasks (cycles or orphans)
          tasks.each do |task|
            unless visited.include?(task[:id])
              tree = build_dependency_tree(task[:id], tasks, visited)
              forest << tree if tree
            end
          end

          forest
        end

        private

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

        def self.normalize_id(id)
          # Handle both full IDs and task numbers
          id.to_s
        end

        def self.build_dependency_graph(tasks)
          graph = {}
          tasks.each do |task|
            graph[task[:id]] = task[:dependencies] || []
          end
          graph
        end

        def self.visit_task(task_id, graph, task_map, visited, sorted)
          return if visited.include?(task_id)
          visited.add(task_id)

          # Visit dependencies first
          if graph[task_id]
            graph[task_id].each do |dep_id|
              visit_task(normalize_id(dep_id), graph, task_map, visited, sorted)
            end
          end

          # Add current task
          task = task_map[task_id]
          sorted << task if task
        end

        def self.apply_standard_sort(tasks, sort_by, ascending)
          # This mirrors the logic from TaskFilter.sort_tasks
          sorted = case sort_by
          when :sort
            tasks.sort do |a, b|
              # In-progress always comes first
              if a[:status] == 'in-progress' && b[:status] != 'in-progress'
                -1
              elsif b[:status] == 'in-progress' && a[:status] != 'in-progress'
                1
              elsif a[:sort] && b[:sort]
                a[:sort] <=> b[:sort]
              elsif a[:sort]
                -1
              elsif b[:sort]
                1
              else
                extract_task_number(a[:id]) <=> extract_task_number(b[:id])
              end
            end
          when :priority
            tasks.sort_by { |t| priority_value(t[:priority]) }
          when :status
            tasks.sort_by { |t| status_value(t[:status]) }
          when :id
            tasks.sort_by { |t| t[:id] || "" }
          else
            tasks
          end

          ascending ? sorted : sorted.reverse
        end

        def self.extract_task_number(task_id)
          return 999999 unless task_id
          if match = task_id.match(/task\.(\d+)$/)
            match[1].to_i
          else
            999999
          end
        end

        def self.priority_value(priority)
          case priority.to_s.downcase
          when "critical" then 0
          when "high" then 1
          when "medium" then 2
          when "low" then 3
          else 4
          end
        end

        def self.status_value(status)
          case status.to_s.downcase
          when "done" then 0
          when "in-progress" then 1
          when "pending" then 2
          when "blocked" then 3
          else 4
          end
        end

        def self.has_path?(from_id, to_id, task_map, visited, path)
          return true if from_id == to_id
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