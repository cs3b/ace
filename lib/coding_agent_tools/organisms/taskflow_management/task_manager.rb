# frozen_string_literal: true

require_relative '../../molecules/taskflow_management/task_file_loader'
require_relative '../../molecules/taskflow_management/task_dependency_checker'
require_relative '../../molecules/taskflow_management/release_path_resolver'
require_relative '../../molecules/taskflow_management/release_resolver'
require_relative '../../atoms/taskflow_management/directory_navigator'
require 'set'

module CodingAgentTools
  module Organisms
    module TaskflowManagement
      # TaskManager orchestrates molecules to provide high-level task management functionality
      # This is an organism - it combines multiple molecules to provide complex business logic
      class TaskManager
        # Result structures for clean API
        NextTaskResult = Struct.new(:task, :success, :message) do
          def success?
            success
          end

          def found?
            !task.nil?
          end
        end

        RecentTasksResult = Struct.new(:tasks, :success, :message) do
          def success?
            success
          end

          def count
            tasks&.size || 0
          end
        end

        AllTasksResult = Struct.new(:tasks, :success, :message, :cycle_detected, :sorted_count, :total_count) do
          def success?
            success
          end

          def fully_sorted?
            !cycle_detected && sorted_count == total_count
          end

          def has_cycles?
            cycle_detected
          end
        end

        # Initialize TaskManager
        # @param base_path [String] Base path for task resolution
        def initialize(base_path: '.')
          @base_path = base_path
          @release_resolver = Molecules::TaskflowManagement::ReleasePathResolver
          @file_loader = Molecules::TaskflowManagement::TaskFileLoader
          @dependency_checker = Molecules::TaskflowManagement::TaskDependencyChecker
        end

        # Find the next actionable task
        # @param release_path [String, nil] Optional specific release path
        # @return [NextTaskResult] Result with next task or error
        def find_next_task(release_path: nil)
          # Resolve release path
          release_info = resolve_release_path(release_path)
          return NextTaskResult.new(nil, false, release_info[:error]) unless release_info[:success]

          # Load tasks from the release
          tasks_result = load_tasks_from_release(release_info[:info])
          return NextTaskResult.new(nil, false, tasks_result[:error]) unless tasks_result[:success]

          # Find next actionable task using the same logic as get-next-task
          next_task = find_next_actionable_task(tasks_result[:tasks])
          if next_task
            NextTaskResult.new(next_task, true, nil)
          else
            NextTaskResult.new(nil, true, 'No actionable tasks found')
          end
        rescue StandardError => e
          NextTaskResult.new(nil, false, "Error finding next task: #{e.message}")
        end

        # Find recent tasks with time-based filtering
        # @param since_seconds [Integer, nil] Time window in seconds (default: 1 day, nil = no time filter)
        # @param statuses [Array<String>] Statuses to filter by (default: ['done', 'in-progress'])
        # @param release_path [String, nil] Optional specific release path
        # @return [RecentTasksResult] Result with recent tasks
        def find_recent_tasks(since_seconds: 86_400, statuses: %w[done in-progress], release_path: nil)
          since_time = since_seconds ? Time.now - since_seconds : nil
          all_tasks = []

          if release_path
            # Search in specific release
            release_info = resolve_release_path(release_path)
            return RecentTasksResult.new([], false, release_info[:error]) unless release_info[:success]

            tasks_result = load_tasks_from_release(release_info[:info])
            return RecentTasksResult.new([], false, tasks_result[:error]) unless tasks_result[:success]

            # Filter by modification time and status
            tasks_result[:tasks].each do |task_data|
              # Check modification time (skip if no time filter)
              mtime = File.mtime(task_data.path)
              next if since_time && mtime < since_time
              next unless statuses.include?(task_data.status)

              # Add modification time for sorting
              task_with_mtime = task_data.dup
              task_with_mtime.define_singleton_method(:mtime) { mtime }
              all_tasks << task_with_mtime
            end
          else
            # Search in both current and done directories (original behavior)
            search_paths = [
              File.join(@base_path, 'dev-taskflow/current'),
              File.join(@base_path, 'dev-taskflow/done')
            ]

            search_paths.each do |base_dir|
              next unless File.exist?(base_dir) && File.directory?(base_dir)

              # Find all task files recursively
              task_files = Dir.glob(File.join(base_dir, '**/tasks/*.md'))

              task_files.each do |file_path|
                # Check modification time (skip if no time filter)
                mtime = File.mtime(file_path)
                next if since_time && mtime < since_time

                # Load and filter task
                task_data = @file_loader.load_task_file(file_path)
                next unless task_data
                next unless statuses.include?(task_data.status)

                # Add modification time for sorting
                task_with_mtime = task_data.dup
                task_with_mtime.define_singleton_method(:mtime) { mtime }
                all_tasks << task_with_mtime
              end
            end
          end

          # Sort by modification time (newest first)
          all_tasks.sort_by! { |task| -task.mtime.to_i }

          RecentTasksResult.new(all_tasks, true, nil)
        rescue StandardError => e
          RecentTasksResult.new([], false, "Error finding recent tasks: #{e.message}")
        end

        # Get all tasks with topological sorting
        # @param release_path [String, nil] Optional specific release path
        # @return [AllTasksResult] Result with all tasks in topological order
        def get_all_tasks(release_path: nil)
          # Resolve release path
          release_info = resolve_release_path(release_path)
          return AllTasksResult.new([], false, release_info[:error], false, 0, 0) unless release_info[:success]

          # Load tasks from the release
          tasks_result = load_tasks_from_release(release_info[:info])
          return AllTasksResult.new([], false, tasks_result[:error], false, 0, 0) unless tasks_result[:success]

          # Perform topological sort
          sorted_result = topological_sort(tasks_result[:tasks])

          AllTasksResult.new(
            sorted_result[:sorted_tasks],
            true,
            nil,
            sorted_result[:cycle_detected],
            sorted_result[:sorted_count],
            sorted_result[:total_count]
          )
        rescue StandardError => e
          AllTasksResult.new([], false, "Error getting all tasks: #{e.message}", false, 0, 0)
        end

        # Find the next actionable task with priority logic
        # @param release_path [String, nil] Optional specific release path
        # @return [NextTaskResult] Result with highlighted next task
        def find_next_actionable_task_with_highlight(release_path: nil)
          result = find_next_task(release_path: release_path)
          return result unless result.success? && result.found?

          # Add highlight information
          highlighted_task = result.task.dup
          highlighted_task.define_singleton_method(:is_next_actionable?) { true }

          NextTaskResult.new(highlighted_task, true, nil)
        end

        private

        # Resolve release path using molecules
        def resolve_release_path(release_path)
          result = Molecules::TaskflowManagement::ReleaseResolver.resolve_release(release_path, base_path: @base_path)

          if result.success?
            { success: true, info: result.release_info, error: nil }
          else
            { success: false, info: nil, error: result.error_message }
          end
        end

        # Load tasks from release using molecules
        def load_tasks_from_release(release_info)
          tasks_dir = if release_info.respond_to?(:tasks_directory)
                        release_info.tasks_directory
                      else
                        File.join(release_info[:path] || release_info.path, 'tasks')
                      end

          return { success: false, error: "Tasks directory not found: #{tasks_dir}" } unless File.exist?(tasks_dir)

          load_result = @file_loader.load_tasks_from_directory(tasks_dir)

          if load_result.tasks.empty?
            { success: false, error: "No tasks found in #{tasks_dir}" }
          else
            { success: true, tasks: load_result.tasks, error: nil }
          end
        end

        # Find next actionable task using priority logic from get-next-task
        def find_next_actionable_task(tasks)
          # Create task map for dependency checking
          task_map = {}
          tasks.each { |task| task_map[task.id] = task }

          # Find actionable candidates (not done, all deps met)
          candidates = tasks.select do |task|
            next false if task.status == 'done'

            # Check if all dependencies are met
            dependency_result = @dependency_checker.check_task_dependencies(task.id, task_map)
            dependency_result.actionable?
          end

          # Sort candidates by priority logic
          sorted_candidates = candidates.sort_by do |task|
            status_priority = case task.status&.downcase
                              when 'in-progress' then 0
                              when 'pending' then 1
                              else 2
                              end

            task_sequential_num = parse_task_sequential_number(task.id)
            [status_priority, task_sequential_num, task.id.to_s]
          end

          sorted_candidates.first
        end

        # Parse task sequential number for sorting
        def parse_task_sequential_number(task_id_str)
          return Float::INFINITY unless task_id_str&.is_a?(String)

          match = task_id_str.match(/\+task\.(\d+)$/)
          match ? match[1].to_i : Float::INFINITY
        end

        # Perform topological sort with cycle detection
        def topological_sort(tasks)
          # Create task map
          task_map = {}
          tasks.each { |task| task_map[task.id] = task }

          # Initialize tracking variables
          sorted_tasks = []
          processed_ids = Set.new

          # Calculate in-degrees and build dependency graph
          in_degree = Hash.new(0)
          task_dependents = Hash.new { |h, k| h[k] = [] }

          tasks.each do |task|
            dependencies = extract_dependencies(task)
            dependencies.each do |dep_id|
              # Only consider intra-release dependencies
              if task_map.key?(dep_id)
                in_degree[task.id] += 1
                task_dependents[dep_id] << task.id
              end
            end
          end

          # Iteratively process tasks with zero in-degree
          loop do
            # Find tasks ready to process (in-degree 0 and not processed)
            ready_task_ids = task_map.keys.select do |task_id|
              in_degree[task_id] == 0 && !processed_ids.include?(task_id)
            end

            break if ready_task_ids.empty?

            # Sort this batch by task number for deterministic ordering
            ready_task_ids.sort_by! do |task_id|
              task = task_map[task_id]
              [parse_task_sequential_number(task.id), task.id.to_s]
            end

            # Process each ready task
            ready_task_ids.each do |task_id|
              task = task_map[task_id]
              sorted_tasks << task
              processed_ids.add(task_id)

              # Update in-degree for dependent tasks
              task_dependents[task_id].each do |dependent_id|
                in_degree[dependent_id] -= 1 if task_map.key?(dependent_id)
              end
            end
          end

          # Check for cycles
          cycle_detected = sorted_tasks.length < tasks.length

          {
            sorted_tasks: sorted_tasks,
            cycle_detected: cycle_detected,
            sorted_count: sorted_tasks.length,
            total_count: tasks.length
          }
        end

        # Extract dependencies from task data
        def extract_dependencies(task)
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
      end
    end
  end
end
