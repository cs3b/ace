# frozen_string_literal: true

require_relative 'dependency_resolver'

module Ace
  module Taskflow
    module Molecules
      # Visualizes task dependencies as ASCII trees
      class DependencyTreeVisualizer
        # Generate tree view for a single task and its dependencies
        # @param task_id [String] Root task ID
        # @param all_tasks [Array<Hash>] All tasks
        # @return [String] ASCII tree representation
        def self.generate_task_tree(task_id, all_tasks)
          tree = DependencyResolver.build_dependency_tree(task_id, all_tasks)
          return "Task not found: #{task_id}" unless tree

          lines = []
          render_tree_node(tree, lines, "", true)
          lines.join("\n")
        end

        # Generate forest view for all task dependencies
        # @param tasks [Array<Hash>] Filtered tasks to show
        # @param all_tasks [Array<Hash>] All tasks (for complete dependency chains)
        # @return [String] ASCII forest representation
        def self.generate_forest(tasks, all_tasks = nil)
          # Use all_tasks if provided, otherwise fall back to tasks
          all_tasks ||= tasks

          # Build forest from filtered tasks but include all dependencies
          forest = build_filtered_forest(tasks, all_tasks)
          return "No tasks with dependencies found" if forest.empty?

          lines = []
          lines << "Dependency Tree:"
          lines << "=" * 48

          # Group by context if available
          contexts = forest.map { |tree| tree[:task][:context] }.uniq.compact

          if contexts.size > 1
            contexts.each do |context|
              lines << ""
              lines << "#{context}:"
              context_trees = forest.select { |tree| tree[:task][:context] == context }
              render_forest_trees(context_trees, lines)
            end
          else
            render_forest_trees(forest, lines)
          end

          lines << ""
          lines << "Legend: 🟢 done  🟡 in-progress  ⚪ pending  ⚫ draft  🔴 blocked"
          lines.join("\n")
        end

        # Build forest including complete dependency chains
        def self.build_filtered_forest(filtered_tasks, all_tasks)
          # Get task IDs from filtered tasks
          filtered_ids = filtered_tasks.map { |t| t[:id] }.to_set

          # Build complete dependency trees for filtered tasks
          forest = []
          visited = Set.new

          filtered_tasks.each do |task|
            # Build complete tree including all dependencies
            tree = DependencyResolver.build_dependency_tree(task[:id], all_tasks, visited)
            forest << tree if tree
          end

          forest
        end

        # Generate compact tree view for task listing
        # @param tasks [Array<Hash>] Tasks to display
        # @return [String] Compact tree representation
        def self.generate_compact_tree(tasks)
          forest = DependencyResolver.build_dependency_forest(tasks)
          lines = []

          forest.each_with_index do |tree, index|
            prefix = index < forest.size - 1 ? "├─" : "└─"
            render_compact_node(tree, lines, prefix, "   ")
          end

          lines.join("\n")
        end

        private

        def self.render_tree_node(node, lines, prefix, is_last)
          task = node[:task]
          status_icon = get_status_icon(task)
          blocked = node[:dependencies].any? { |d| d[:task][:status] != 'done' } if node[:dependencies].any?

          # Build the task line
          connector = is_last ? "└─" : "├─"
          task_line = "#{prefix}#{connector} #{task[:task_number] || task[:id]} #{status_icon}"
          task_line += " #{task[:title]}" if task[:title]
          task_line += " [BLOCKED]" if blocked && task[:status] == 'pending'

          lines << task_line

          # Render dependencies
          if node[:dependencies] && !node[:dependencies].empty?
            node[:dependencies].each_with_index do |dep, index|
              is_last_dep = index == node[:dependencies].size - 1
              new_prefix = prefix + (is_last ? "   " : "│  ")
              render_tree_node(dep, lines, new_prefix, is_last_dep)
            end
          end
        end

        def self.render_forest_trees(trees, lines)
          trees.each_with_index do |tree, index|
            prefix = index < trees.size - 1 ? "├─" : "└─"
            task = tree[:task]
            status_icon = get_status_icon(task)

            task_line = "#{prefix} #{task[:task_number] || task[:id]} #{status_icon}"
            task_line += " #{task[:title]}" if task[:title]
            lines << task_line

            # Render dependencies with proper indentation
            if tree[:dependencies] && !tree[:dependencies].empty?
              child_prefix = index < trees.size - 1 ? "│  " : "   "
              render_dependencies(tree[:dependencies], lines, child_prefix)
            end
          end
        end

        def self.render_dependencies(deps, lines, prefix)
          deps.each_with_index do |dep, index|
            is_last = index == deps.size - 1
            connector = is_last ? "└─" : "├─"
            task = dep[:task]
            status_icon = get_status_icon(task)

            task_line = "#{prefix}#{connector} #{task[:task_number] || task[:id]} #{status_icon}"
            task_line += " #{task[:title]}" if task[:title]
            lines << task_line

            # Recursively render sub-dependencies
            if dep[:dependencies] && !dep[:dependencies].empty?
              new_prefix = prefix + (is_last ? "   " : "│  ")
              render_dependencies(dep[:dependencies], lines, new_prefix)
            end
          end
        end

        def self.render_compact_node(node, lines, prefix, indent)
          task = node[:task]
          status_icon = get_status_icon(task)

          task_line = "#{prefix} #{task[:task_number] || task[:id]} #{task[:title]} #{status_icon}"
          lines << task_line

          if node[:dependencies] && !node[:dependencies].empty?
            node[:dependencies].each_with_index do |dep, index|
              is_last = index == node[:dependencies].size - 1
              new_prefix = indent + (is_last ? "└─" : "├─")
              new_indent = indent + (is_last ? "   " : "│  ")
              render_compact_node(dep, lines, new_prefix, new_indent)
            end
          end
        end

        def self.get_status_icon(task)
          case task[:status].to_s.downcase
          when 'draft'
            '⚫'
          when 'pending'
            '⚪'
          when 'in-progress'
            '🟡'
          when 'done'
            '🟢'
          when 'blocked', 'skipped'
            '🔴'
          else
            '❓'
          end
        end

        def self.get_priority_color(priority)
          case priority.to_s.downcase
          when 'critical'
            '🔴'
          when 'high'
            '🟠'
          when 'medium'
            '🟡'
          when 'low'
            '⚪'
          else
            ''
          end
        end
      end
    end
  end
end