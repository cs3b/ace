# frozen_string_literal: true

require "ace/support/items"

module Ace
  module Task
    module Molecules
      # Dependency-aware ordering for the smart list sort.
      #
      # Ready tasks (every dependency satisfied, or the task itself done or
      # archived) come first under the existing smart comparator. Tasks with
      # unmet dependencies follow in a topological tail ordered by dependency
      # depth (fewest hops to readiness first, with the smart comparator as
      # tie-breaker). Tasks caught in a dependency cycle render last so cycles
      # stay visible instead of hiding or looping.
      class DependencyAwareSmartSorter
        # Status that satisfies a dependency.
        SATISFIED_STATUSES = %w[done].freeze
        # Folder that satisfies a dependency regardless of status (archived).
        ARCHIVE_FOLDER = "_archive"

        # Ordered listing plus the ids of cyclic tasks (for list rendering).
        Result = Struct.new(:tasks, :cycle_ids)

        # @param tasks [Array<Models::Task>] Tasks in the current listing
        # @param score_fn [Proc] ->(task) { Float } existing smart score
        # @param pin_accessor [Proc] ->(task) { position, nil } pinned position
        # @param external_statuses [Hash{String => Array(String, String)}]
        #   [status, special_folder] for dependency references outside the
        #   listing (e.g. archived); absent entries count as unmet.
        # @return [Result]
        def self.sort(tasks, score_fn:, pin_accessor:, external_statuses: {})
          return Result.new([], []) if tasks.nil? || tasks.empty?

          index = {}
          tasks.each { |task| index[task.id] = task }

          unmet_deps = {}
          tasks.each do |task|
            deps = normalize_dependencies(task.dependencies)
            unmet_deps[task.id] = deps.reject { |dep| satisfied?(dep, index, external_statuses) }
          end

          ready = []
          unmet_ids = {}
          tasks.each do |task|
            if unmet_deps[task.id].empty? || satisfied_state?(task.status, task.special_folder)
              ready << task
            else
              unmet_ids[task.id] = true
            end
          end

          cycle_ids = cyclic_ids(index, unmet_deps)
          cycle_lookup = cycle_ids.each_with_object({}) { |id, lookup| lookup[id] = true }
          cycle_ids.each { |id| unmet_ids.delete(id) }

          depths = depth_map(index, unmet_deps, unmet_ids)

          ordered = order_group(ready, score_fn, pin_accessor)
          unmet_ids.keys.group_by { |id| depths[id] }.sort.each do |_depth, ids|
            ordered.concat(order_group(ids.map { |id| index[id] }, score_fn, pin_accessor))
          end
          cyclic_tasks = tasks.select { |task| cycle_lookup[task.id] }
          ordered.concat(order_group(cyclic_tasks, score_fn, pin_accessor))

          Result.new(ordered, cycle_ids)
        end

        class << self
          private

          def order_group(group, score_fn, pin_accessor)
            return [] if group.empty?

            Ace::Support::Items::Molecules::SmartSorter.sort(
              group, score_fn: score_fn, pin_accessor: pin_accessor
            )
          end

          def normalize_dependencies(raw)
            Array(raw).compact.map(&:to_s)
          end

          # A dependency is satisfied when the referenced task is done or
          # archived. References outside the listing consult external_statuses;
          # unknown references stay unmet so a task cannot appear ready.
          def satisfied?(dep_id, index, external_statuses)
            task = index[dep_id]
            return satisfied_state?(task.status, task.special_folder) if task

            external = external_statuses[dep_id]
            return satisfied_state?(external[0], external[1]) if external

            false
          end

          def satisfied_state?(status, special_folder)
            SATISFIED_STATUSES.include?(status.to_s.downcase) || special_folder == ARCHIVE_FOLDER
          end

          # Cyclic ids: members of any strongly connected component of the
          # unmet-dependency graph larger than one, plus self-dependencies.
          def cyclic_ids(index, unmet_deps)
            edges = {}
            index.each_key do |id|
              edges[id] = unmet_deps[id].select { |dep| index.key?(dep) }
            end

            cyclic = []
            strongly_connected_cyclic_ids(edges, cyclic)
            cyclic
          end

          # Tarjan's algorithm over unmet edges (recursion depth is bounded by
          # the dependency chain length, which is small for task graphs).
          def strongly_connected_cyclic_ids(edges, cyclic)
            counter = 0
            indices = {}
            lowlinks = {}
            stack = []
            on_stack = {}

            visit = nil
            visit = lambda do |vertex|
              indices[vertex] = lowlinks[vertex] = counter
              counter += 1
              stack.push(vertex)
              on_stack[vertex] = true

              edges[vertex].each do |neighbor|
                if indices.key?(neighbor)
                  lowlinks[vertex] = [lowlinks[vertex], indices[neighbor]].min if on_stack[neighbor]
                else
                  visit.call(neighbor)
                  lowlinks[vertex] = [lowlinks[vertex], lowlinks[neighbor]].min
                end
              end

              if lowlinks[vertex] == indices[vertex]
                component = []
                loop do
                  member = stack.pop
                  on_stack[member] = false
                  component << member
                  break if member == vertex
                end

                cyclic.concat(component) if component.length > 1 || component.any? { |id| edges[id].include?(id) }
              end
            end

            edges.each_key do |vertex|
              visit.call(vertex) unless indices.key?(vertex)
            end
          end

          # Hop distance to the ready/satisfied boundary for unmet acyclic
          # tasks. Missing, ready, and cyclic dependencies contribute zero, so
          # traversal stays finite and acyclic by construction.
          def depth_map(index, unmet_deps, unmet_ids)
            depths = {}
            unmet_ids.each_key do |id|
              compute_depth(id, index, unmet_deps, unmet_ids, depths)
            end
            depths
          end

          def compute_depth(id, index, unmet_deps, unmet_ids, depths)
            return depths[id] if depths.key?(id)

            deepest = unmet_deps[id].map do |dep|
              if unmet_ids[dep]
                compute_depth(dep, index, unmet_deps, unmet_ids, depths)
              else
                0
              end
            end.max || 0
            depths[id] = 1 + deepest
          end
        end
      end
    end
  end
end
