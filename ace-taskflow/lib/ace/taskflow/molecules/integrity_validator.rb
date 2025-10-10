# frozen_string_literal: true

require_relative "../molecules/task_loader"
require_relative "../molecules/idea_loader"
require_relative "../molecules/release_resolver"

module Ace
  module Taskflow
    module Molecules
      # Validates cross-component integrity and references
      class IntegrityValidator
        def initialize(root_path = nil)
          @root_path = root_path || find_taskflow_root
          @task_loader = TaskLoader.new(@root_path)
          @idea_loader = IdeaLoader.new(@root_path)
          @release_resolver = ReleaseResolver.new(@root_path)
        end

        # Validate all cross-references and integrity
        # @return [Hash] Validation result with :valid, :issues
        def validate_all
          issues = []

          # Load all components
          tasks = load_all_tasks
          ideas = load_all_ideas
          releases = load_all_releases

          # Check for duplicate IDs
          check_duplicate_ids(tasks, ideas, issues)

          # Validate task dependencies
          validate_dependencies(tasks, issues)

          # Check for circular dependencies
          check_circular_dependencies(tasks, issues)

          # Validate status-location consistency
          validate_status_location_consistency(tasks, ideas, issues)

          # Check references between components
          validate_cross_references(tasks, ideas, releases, issues)

          {
            valid: issues.none? { |i| i[:type] == :error },
            issues: issues,
            stats: {
              tasks: tasks.size,
              ideas: ideas.size,
              releases: releases.size
            }
          }
        end

        private

        def find_taskflow_root
          current = Dir.pwd
          while current != "/"
            taskflow_dir = File.join(current, ".ace-taskflow")
            return taskflow_dir if Dir.exist?(taskflow_dir)
            current = File.dirname(current)
          end
          nil
        end

        def load_all_tasks
          tasks = []

          # Load from all releases
          @release_resolver.find_all.each do |release|
            context_tasks = @task_loader.load_tasks_from_context(release[:path])
            tasks.concat(context_tasks)
          end

          # Load from backlog
          backlog_path = File.join(@root_path, "backlog")
          if Dir.exist?(backlog_path)
            backlog_tasks = @task_loader.load_tasks_from_context(backlog_path)
            tasks.concat(backlog_tasks)
          end

          tasks
        end

        def load_all_ideas
          ideas = []

          # Load from all releases
          @release_resolver.find_all.each do |release|
            release_ideas = @idea_loader.load_all(context: release[:name], scope: :all)
            ideas.concat(release_ideas)
          end

          # Load from backlog
          backlog_ideas = @idea_loader.load_all(context: "backlog", scope: :all)
          ideas.concat(backlog_ideas)

          ideas
        end

        def load_all_releases
          @release_resolver.find_all
        end

        def check_duplicate_ids(tasks, ideas, issues)
          # Check for duplicate task IDs
          task_ids = {}
          tasks.each do |task|
            id = task[:id]
            next unless id

            if task_ids[id]
              issues << {
                type: :error,
                message: "Duplicate task ID: #{id}",
                locations: [task[:path], task_ids[id][:path]]
              }
            else
              task_ids[id] = task
            end
          end

          # Check for duplicate idea IDs (if ideas have IDs)
          idea_ids = {}
          ideas.each do |idea|
            id = idea[:id] || idea[:filename]
            if idea_ids[id]
              issues << {
                type: :warning,
                message: "Duplicate idea identifier: #{id}",
                locations: [idea[:path], idea_ids[id][:path]]
              }
            else
              idea_ids[id] = idea
            end
          end
        end

        def validate_dependencies(tasks, issues)
          task_map = tasks.each_with_object({}) { |task, map| map[task[:id]] = task if task[:id] }

          tasks.each do |task|
            next unless task[:dependencies] && task[:dependencies].any?

            task[:dependencies].each do |dep_id|
              # Check if dependency exists
              unless task_map[dep_id]
                issues << {
                  type: :error,
                  message: "Task #{task[:id]} depends on non-existent task: #{dep_id}",
                  location: task[:path]
                }
              end

              # Check if dependency is not done when task is active
              if task_map[dep_id] && task[:status] == "in-progress"
                dep_task = task_map[dep_id]
                unless dep_task[:status] == "done"
                  issues << {
                    type: :warning,
                    message: "Task #{task[:id]} is in-progress but dependency #{dep_id} is not done (status: #{dep_task[:status]})",
                    location: task[:path]
                  }
                end
              end
            end
          end
        end

        def check_circular_dependencies(tasks, issues)
          task_map = tasks.each_with_object({}) { |task, map| map[task[:id]] = task if task[:id] }

          tasks.each do |task|
            next unless task[:id] && task[:dependencies]

            visited = Set.new
            cycle = detect_cycle(task[:id], task_map, visited, [])

            if cycle
              issues << {
                type: :error,
                message: "Circular dependency detected",
                cycle: cycle,
                location: task[:path]
              }
            end
          end
        end

        def detect_cycle(task_id, task_map, visited, path)
          return nil unless task_map[task_id]

          # If we've seen this task in the current path, we have a cycle
          return path + [task_id] if path.include?(task_id)

          # If we've already fully explored this task, no cycle from here
          return nil if visited.include?(task_id)

          task = task_map[task_id]
          return nil unless task[:dependencies]

          new_path = path + [task_id]

          task[:dependencies].each do |dep_id|
            cycle = detect_cycle(dep_id, task_map, visited, new_path)
            return cycle if cycle
          end

          visited.add(task_id)
          nil
        end

        def validate_status_location_consistency(tasks, ideas, issues)
          # Check tasks
          tasks.each do |task|
            next unless task[:path] && task[:status]

            is_in_done_dir = task[:path].include?("/done/")

            if task[:status] == "done" && !is_in_done_dir
              issues << {
                type: :warning,
                message: "Task #{task[:id]} has status 'done' but is not in done/ directory",
                location: task[:path]
              }
            elsif task[:status] != "done" && is_in_done_dir
              issues << {
                type: :error,
                message: "Task #{task[:id]} is in done/ directory but status is '#{task[:status]}'",
                location: task[:path]
              }
            end
          end

          # Check ideas
          ideas.each do |idea|
            next unless idea[:path]

            is_in_done_dir = idea[:path].include?("/done/")
            status = idea[:status] || (is_in_done_dir ? "done" : "pending")

            if status == "done" && !is_in_done_dir
              issues << {
                type: :info,
                message: "Idea #{idea[:filename]} marked as done but not in done/ directory",
                location: idea[:path]
              }
            end
          end
        end

        def validate_cross_references(tasks, ideas, releases, issues)
          # Check if tasks reference valid releases
          tasks.each do |task|
            next unless task[:id]

            # Extract release version from task ID (v.X.Y.Z+task.NNN)
            if task[:id] =~ /^(v\.\d+\.\d+\.\d+)\+task\.\d+$/
              release_version = $1
              unless releases.any? { |r| r[:name] == release_version }
                issues << {
                  type: :warning,
                  message: "Task #{task[:id]} references non-existent release: #{release_version}",
                  location: task[:path]
                }
              end
            end
          end

          # Check for orphaned ideas (ideas without corresponding tasks)
          # This is informational only
          idea_count_by_release = {}
          ideas.each do |idea|
            context = idea[:context] || "unknown"
            idea_count_by_release[context] ||= 0
            idea_count_by_release[context] += 1
          end

          idea_count_by_release.each do |context, count|
            if count > 50  # Arbitrary threshold
              issues << {
                type: :info,
                message: "Release #{context} has #{count} ideas - consider processing backlog",
                location: context
              }
            end
          end
        end
      end
    end
  end
end