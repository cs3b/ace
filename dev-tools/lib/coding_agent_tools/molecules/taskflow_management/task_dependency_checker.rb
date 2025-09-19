# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module TaskflowManagement
      # TaskDependencyChecker provides dependency validation and analysis
      class TaskDependencyChecker
        # Dependency check result
        DependencyResult = Struct.new(:task_id, :actionable, :unmet_dependencies, :cycle_detected, :cycle_path) do
          def actionable?
            actionable
          end

          def has_unmet_dependencies?
            !unmet_dependencies.nil? && !unmet_dependencies.empty?
          end
        end

        # Check if a task is actionable
        def self.check_task_dependencies(task_id, task_map)
          task_data = task_map[task_id]
          return DependencyResult.new(task_id, false, [], false, nil) unless task_data

          return DependencyResult.new(task_id, true, [], false, nil) if task_done?(task_data)

          dependencies = extract_dependencies(task_data)
          unmet_dependencies = find_unmet_dependencies(dependencies, task_map)

          actionable = unmet_dependencies.empty?
          DependencyResult.new(task_id, actionable, unmet_dependencies, false, nil)
        end

        # Find all actionable tasks
        def self.find_actionable_tasks(task_map)
          actionable_tasks = []

          task_map.each do |task_id, task_data|
            next if task_done?(task_data)

            result = check_task_dependencies(task_id, task_map)
            actionable_tasks << task_id if result.actionable?
          end

          actionable_tasks
        end

        class << self
          private

          def task_done?(task_data)
            return false if task_data.nil?

            status = if task_data.respond_to?(:status)
              task_data.status
            elsif task_data.respond_to?(:[])
              task_data[:status] || task_data["status"]
            end

            status == "done"
          end

          def extract_dependencies(task_data)
            return [] if task_data.nil?

            deps = if task_data.respond_to?(:dependencies)
              task_data.dependencies
            elsif task_data.respond_to?(:[])
              task_data[:dependencies] || task_data["dependencies"]
            end

            case deps
            when Array
              deps.map(&:to_s)
            when String
              deps.split(",").map(&:strip)
            else
              []
            end
          end

          def find_unmet_dependencies(dependencies, task_map)
            unmet = []

            dependencies.each do |dep_id|
              dep_task = task_map[dep_id]
              if dep_task.nil?
                next
              elsif !task_done?(dep_task)
                unmet << dep_id
              end
            end

            unmet
          end
        end
      end
    end
  end
end
