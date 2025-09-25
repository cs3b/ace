# frozen_string_literal: true

require "fileutils"
require_relative "../molecules/task_loader"
require_relative "../molecules/task_filter"
require_relative "../molecules/release_resolver"
require_relative "../molecules/config_loader"
require_relative "../atoms/task_reference_parser"
require_relative "../atoms/path_builder"
require_relative "../atoms/yaml_parser"

module Ace
  module Taskflow
    module Organisms
      # Task business logic orchestration
      class TaskManager
        attr_reader :root_path, :config

        def initialize(config = nil)
          @config = config || Molecules::ConfigLoader.load
          @root_path = Molecules::ConfigLoader.find_root
          @task_loader = Molecules::TaskLoader.new(@root_path)
          @release_resolver = Molecules::ReleaseResolver.new(@root_path)
        end

        # Get next task to work on
        # @param context [String] Context to search (current, backlog, specific release)
        # @return [Hash, nil] Next task or nil
        def get_next_task(context: "current")
          tasks = list_tasks(context: context, filters: { status: ["pending", "in-progress"] })

          # Prioritize in-progress tasks
          in_progress = tasks.select { |t| t[:status] == "in-progress" }
          return in_progress.first unless in_progress.empty?

          # For pending tasks, sort by sort value first, then by ID
          pending = tasks.select { |t| t[:status] == "pending" }
          return nil if pending.empty?

          # Sort pending tasks: those with sort values first (ascending), then by task ID
          sorted_pending = pending.sort do |a, b|
            if a[:sort] && b[:sort]
              a[:sort] <=> b[:sort]
            elsif a[:sort]
              -1  # a has sort, comes first
            elsif b[:sort]
              1   # b has sort, comes first
            else
              # Neither has sort, compare by task ID number
              a_num = a[:id]&.match(/task\.(\d+)$/)&.[](1)&.to_i || 999999
              b_num = b[:id]&.match(/task\.(\d+)$/)&.[](1)&.to_i || 999999
              a_num <=> b_num
            end
          end

          sorted_pending.first
        end

        # Show specific task
        # @param reference [String] Task reference
        # @return [Hash, nil] Task data or nil
        def show_task(reference)
          @task_loader.find_task_by_reference(reference)
        end

        # List tasks with optional filtering
        # @param context [String] Context to list from
        # @param filters [Hash] Filter criteria
        # @return [Array<Hash>] Filtered tasks
        def list_tasks(context: "current", filters: {})
          # Resolve context to path
          context_path = resolve_context_path(context)
          return [] unless context_path

          # Load tasks from context
          tasks = if context == "all"
            @task_loader.load_all_tasks
          else
            @task_loader.load_tasks_from_context(context_path)
          end

          # Apply filters
          Molecules::TaskFilter.apply_filters(tasks, filters)
        end

        # Create new task
        # @param title [String] Task title
        # @param context [String] Target context
        # @param metadata [Hash] Additional metadata
        # @return [Hash] Result with :success, :message, :task_id
        def create_task(title, context: "current", metadata: {})
          # Resolve context
          context_path = resolve_context_path(context)
          unless context_path
            return { success: false, message: "Invalid context: #{context}" }
          end

          # Generate task ID
          task_number = generate_task_number(context_path)
          task_id = generate_task_id(context, task_number)

          # Create task directory and file with descriptive name
          task_dir = Atoms::PathBuilder.build_task_path("", context_path, task_number)
          filename = Atoms::PathBuilder.generate_task_filename(title)
          task_file = File.join(task_dir, filename)

          begin
            FileUtils.mkdir_p(task_dir)
            FileUtils.mkdir_p(File.join(task_dir, "docs"))
            FileUtils.mkdir_p(File.join(task_dir, "qa"))

            # Generate task content
            content = generate_task_template(task_id, title, metadata)
            File.write(task_file, content)

            {
              success: true,
              message: "Created task #{task_id}",
              task_id: task_id,
              path: task_file
            }
          rescue StandardError => e
            { success: false, message: "Failed to create task: #{e.message}" }
          end
        end

        # Start working on a task (mark as in-progress)
        # @param reference [String] Task reference
        # @return [Hash] Result with :success and :message
        def start_task(reference)
          update_task_status(reference, "in-progress")
        end

        # Mark task as done
        # @param reference [String] Task reference
        # @return [Hash] Result with :success and :message
        def complete_task(reference)
          update_task_status(reference, "done")
        end

        # Update task status
        # @param reference [String] Task reference
        # @param new_status [String] New status
        # @return [Hash] Result with :success and :message
        def update_task_status(reference, new_status)
          task = @task_loader.find_task_by_reference(reference)
          unless task
            return { success: false, message: "Task #{reference} not found" }
          end

          # Validate status transition
          unless valid_status_transition?(task[:status], new_status)
            return {
              success: false,
              message: "Invalid status transition: #{task[:status]} → #{new_status}"
            }
          end

          # Update the task file
          if @task_loader.update_task_status(task[:path], new_status)
            {
              success: true,
              message: "Task #{reference} status updated to #{new_status}"
            }
          else
            { success: false, message: "Failed to update task status" }
          end
        end

        # Move task between contexts
        # @param reference [String] Task reference
        # @param target [String] Target context (backlog, v.0.10.0, etc.)
        # @return [Hash] Result with :success, :message, :new_reference
        def move_task(reference, target)
          # Find source task
          task = @task_loader.find_task_by_reference(reference)
          unless task
            return { success: false, message: "Task #{reference} not found" }
          end

          # Resolve target context
          target_path = resolve_context_path(target)
          unless target_path
            return { success: false, message: "Invalid target context: #{target}" }
          end

          # Generate new task number in target
          new_number = generate_task_number(target_path)
          new_id = generate_task_id(target, new_number)

          # Build paths
          old_dir = File.dirname(task[:path])
          new_dir = Atoms::PathBuilder.build_task_path("", target_path, new_number)

          begin
            # Create target directory
            FileUtils.mkdir_p(File.dirname(new_dir))

            # Move task directory
            FileUtils.mv(old_dir, new_dir)

            # Find the task file in the new directory (it has the same name as before)
            task_filename = File.basename(task[:path])
            new_task_file = File.join(new_dir, task_filename)

            # Update task ID in file
            update_task_id_in_file(new_task_file, new_id)

            new_reference = Atoms::TaskReferenceParser.format(target, new_number)

            {
              success: true,
              message: "Moved task #{reference} → #{new_reference}",
              new_reference: new_reference
            }
          rescue StandardError => e
            { success: false, message: "Failed to move task: #{e.message}" }
          end
        end

        # Get recent tasks
        # @param days [Integer] Number of days to look back
        # @param context [String] Context to search
        # @return [Array<Hash>] Recent tasks
        def get_recent_tasks(days: 7, context: "all")
          list_tasks(context: context, filters: { recent_days: days })
        end

        # Get task statistics
        # @param context [String] Context to analyze
        # @return [Hash] Statistics
        def get_statistics(context: "all")
          tasks = list_tasks(context: context)

          stats = {
            total: tasks.size,
            by_status: {},
            by_priority: {},
            by_context: {}
          }

          tasks.each do |task|
            # Count by status
            status = task[:status] || "unknown"
            stats[:by_status][status] ||= 0
            stats[:by_status][status] += 1

            # Count by priority
            priority = task[:priority] || "unknown"
            stats[:by_priority][priority] ||= 0
            stats[:by_priority][priority] += 1

            # Count by context
            ctx = task[:context] || "unknown"
            stats[:by_context][ctx] ||= 0
            stats[:by_context][ctx] += 1
          end

          stats
        end

        private

        def resolve_context_path(context)
          case context
          when "current", "active"
            primary = @release_resolver.find_primary_active
            primary ? primary[:path] : nil
          when "backlog"
            File.join(@root_path, "backlog")
          when "all"
            @root_path
          else
            # Try to resolve as release
            release = @release_resolver.find_release(context)
            release ? release[:path] : nil
          end
        end

        def generate_task_number(context_path)
          task_dir = File.join(context_path, "t")
          return "001" unless File.directory?(task_dir)

          # Find highest existing number
          existing = Dir.glob(File.join(task_dir, "*")).map do |path|
            File.basename(path).to_i
          end

          next_number = existing.max.to_i + 1
          next_number.to_s.rjust(3, '0')
        end

        def generate_task_id(context, number)
          if context == "backlog"
            "backlog+task.#{number}"
          elsif context.start_with?("v.")
            "#{context}+task.#{number}"
          else
            # For current/active, use the actual release version
            primary = @release_resolver.find_primary_active
            if primary
              "#{primary[:name]}+task.#{number}"
            else
              "task.#{number}"
            end
          end
        end

        def generate_task_template(task_id, title, metadata)
          <<~TEMPLATE
            ---
            id: #{task_id}
            status: #{metadata[:status] || 'pending'}
            priority: #{metadata[:priority] || 'medium'}
            estimate: #{metadata[:estimate] || 'TBD'}
            dependencies: #{(metadata[:dependencies] || []).inspect}
            ---

            # #{title}

            ## Description

            *Task description goes here*

            ## Acceptance Criteria

            - [ ] Criterion 1
            - [ ] Criterion 2
            - [ ] Criterion 3

            ## Implementation Notes

            *Implementation details and notes*
          TEMPLATE
        end

        def valid_status_transition?(from, to)
          # Define valid transitions
          transitions = {
            "draft" => ["pending", "blocked"],
            "pending" => ["in-progress", "blocked"],
            "in-progress" => ["done", "pending", "blocked"],
            "blocked" => ["pending", "in-progress"],
            "done" => ["pending"] # Allow reopening
          }

          allowed = transitions[from] || []
          allowed.include?(to)
        end

        def update_task_id_in_file(file_path, new_id)
          content = File.read(file_path)
          updated = content.sub(/^id:\s*.+$/m, "id: #{new_id}")
          File.write(file_path, updated)
        end
      end
    end
  end
end