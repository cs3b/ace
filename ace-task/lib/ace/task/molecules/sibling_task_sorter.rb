# frozen_string_literal: true

module Ace
  module Task
    module Molecules
      # Orders sibling tasks by dependency-safe topological order.
      # Position metadata influences the stable tie-break order, but never
      # overrides a dependency edge.
      class SiblingTaskSorter
        class CycleError < StandardError
          attr_reader :task_ids

          def initialize(task_ids)
            @task_ids = task_ids
            super("Cyclic sibling dependencies: #{task_ids.join(', ')}")
          end
        end

        def self.sort(tasks, raise_on_cycle: false)
          return [] if tasks.nil? || tasks.empty?

          indexed = tasks.each_with_index.map do |task, index|
            [task.id, {task: task, index: index}]
          end.to_h

          base_order = tasks
            .sort_by { |task| base_sort_key(task, indexed.fetch(task.id)[:index]) }
            .each_with_index
            .to_h { |task, index| [task.id, index] }

          dependents = Hash.new { |hash, key| hash[key] = [] }
          indegree = tasks.each_with_object({}) { |task, hash| hash[task.id] = 0 }

          tasks.each do |task|
            sibling_dependencies(task, indexed).each do |dependency_id|
              dependents[dependency_id] << task.id
              indegree[task.id] += 1
            end
          end

          available = indegree
            .select { |_task_id, degree| degree.zero? }
            .keys
            .sort_by { |task_id| base_order.fetch(task_id) }

          result = []
          until available.empty?
            current_id = available.shift
            result << indexed.fetch(current_id)[:task]

            dependents[current_id]
              .sort_by { |task_id| base_order.fetch(task_id) }
              .each do |dependent_id|
                indegree[dependent_id] -= 1
                next unless indegree[dependent_id].zero?

                insert_index = available.bsearch_index { |task_id| base_order.fetch(task_id) > base_order.fetch(dependent_id) }
                if insert_index
                  available.insert(insert_index, dependent_id)
                else
                  available << dependent_id
                end
              end
          end

          return result if result.length == tasks.length

          remaining_ids = tasks
            .map(&:id)
            .reject { |task_id| result.any? { |task| task.id == task_id } }
            .sort_by { |task_id| base_order.fetch(task_id) }

          raise CycleError, remaining_ids if raise_on_cycle

          result + remaining_ids.map { |task_id| indexed.fetch(task_id)[:task] }
        end

        def self.base_sort_key(task, original_index)
          position = task.metadata&.dig("position").to_s
          pinned = !position.empty?
          [pinned ? 0 : 1, position, original_index]
        end
        private_class_method :base_sort_key

        def self.sibling_dependencies(task, indexed)
          Array(task.dependencies).select { |dependency_id| indexed.key?(dependency_id) }
        end
        private_class_method :sibling_dependencies
      end
    end
  end
end
