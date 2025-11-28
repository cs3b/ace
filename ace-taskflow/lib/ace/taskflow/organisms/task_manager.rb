# frozen_string_literal: true

require "fileutils"
require "ace/support/markdown"
require_relative "../molecules/task_loader"
require_relative "../molecules/task_filter"
require_relative "../molecules/release_resolver"
require_relative "../molecules/config_loader"
require_relative "../molecules/task_slug_generator"
require_relative "../molecules/dependency_resolver"
require_relative "../molecules/task_selector"
require_relative "../molecules/task_statistics"
require_relative "../molecules/status_validator"
require_relative "../atoms/task_reference_parser"
require_relative "../atoms/path_builder"
require_relative "../atoms/yaml_parser"
require_relative "../atoms/dependency_validator"

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
        # @param release [String] Release to search (current, backlog, specific release)
        # @return [Hash, nil] Next task or nil
        def get_next_task(release: "current")
          tasks = list_tasks(release: release, filters: { status: ["pending", "in-progress"] })

          # Delegate to pure logic molecule
          Molecules::TaskSelector.select_next(tasks)
        end

        # Show specific task
        # @param reference [String] Task reference
        # @return [Hash, nil] Task data or nil
        def show_task(reference)
          @task_loader.find_task_by_reference(reference)
        end

        # List tasks with optional filtering
        # @param release [String] Release to list from
        # @param filters [Hash] Filter criteria
        # @param glob [Array<String>, nil] Optional glob patterns for loading
        # @return [Array<Hash>] Filtered tasks
        def list_tasks(release: "current", filters: {}, glob: nil)
          # If glob patterns provided, use glob-based loading
          if glob && !glob.empty?
            release_path = resolve_release_path(release)
            return [] unless release_path
            tasks = @task_loader.load_tasks_with_glob(release_path, glob)
            return Molecules::TaskFilter.apply_filters(tasks, filters)
          end

          # Otherwise use traditional release-based loading
          release_path = resolve_release_path(release)
          return [] unless release_path

          # Load tasks from release
          tasks = if release == "all"
            @task_loader.load_all_tasks
          else
            @task_loader.load_tasks_from_release(release_path)
          end

          # Apply filters
          Molecules::TaskFilter.apply_filters(tasks, filters)
        end

        # Create new task
        # @param title [String] Task title
        # @param release [String] Target release
        # @param metadata [Hash] Additional metadata
        # @return [Hash] Result with :success, :message, :task_id
        def create_task(title, release: "current", metadata: {})
          # Resolve release
          release_path = resolve_release_path(release)
          unless release_path
            return { success: false, message: "Invalid release: #{release}" }
          end

          # Generate task ID and slug
          task_number = generate_task_number(release_path)
          task_id = generate_task_id(release, task_number)

          # Safety check: Verify ID doesn't exist in either t/ or done/
          if task_id_exists?(release_path, task_id)
            return {
              success: false,
              message: "Task ID #{task_id} already exists! This should not happen. Please report this issue."
            }
          end

          # Generate hierarchical slugs using LLM with fallback
          require_relative "../molecules/llm_slug_generator"
          slug_gen = Molecules::LlmSlugGenerator.new(debug: ENV["DEBUG"] == "true")
          slug_result = slug_gen.generate_task_slugs(title, metadata)

          folder_slug = slug_result[:folder_slug]
          file_slug = slug_result[:file_slug]

          # Create task directory with hierarchical naming: {number}-{folder-slug}
          task_config = Ace::Taskflow.configuration
          task_dir = File.join(release_path, task_config.task_dir, "#{task_number}-#{folder_slug}")

          # Create file with new naming convention: {number}-{file-slug}.s.md
          filename = "#{task_number}-#{file_slug}.s.md"
          task_file = File.join(task_dir, filename)

          begin
            FileUtils.mkdir_p(task_dir)
            FileUtils.mkdir_p(File.join(task_dir, "docs"))
            FileUtils.mkdir_p(File.join(task_dir, "qa"))

            # Generate task content
            content = generate_task_template(task_id, title, metadata)
            Ace::Support::Markdown::Organisms::SafeFileWriter.write(
              task_file,
              content,
              backup: true,
              validate: true
            )

            {
              success: true,
              message: "Created task #{task_id}",
              task_id: task_id,
              task_number: task_number,
              path: task_file
            }
          rescue StandardError => e
            { success: false, message: "Failed to create task: #{e.message}" }
          end
        end

        # Create a new subtask under a parent task
        # @param parent_ref [String] Parent task reference (e.g., "121", "v.0.9.0+task.121")
        # @param title [String] Subtask title
        # @param release [String, nil] Optional release override (from --release/--backlog CLI flags)
        # @param metadata [Hash] Additional metadata
        # @return [Hash] Result with :success, :message, :task_id, :path
        def create_subtask(parent_ref, title, release: nil, metadata: {})
          # 1. Parse parent reference
          parsed = Atoms::TaskReferenceParser.parse(parent_ref)
          unless parsed
            return { success: false, message: "Invalid parent reference: #{parent_ref}" }
          end

          # 2. Check if trying to create subtask of subtask (not supported)
          if parsed[:subtask] && parsed[:subtask] != "00"
            return {
              success: false,
              message: "Cannot create subtask of subtask (#{parent_ref}). Subtasks can only be one level deep."
            }
          end

          # 3. Resolve release path
          # Priority: 1. Explicit release from CLI, 2. Qualified parent ref, 3. Default to current
          resolved_release = if release
            release  # Use explicit release from CLI (--release/--backlog)
          elsif parsed[:qualified]
            parsed[:release]  # Use release from qualified parent ref
          else
            "current"  # Default to current
          end
          release_path = resolve_release_path(resolved_release)
          unless release_path
            return { success: false, message: "Release not found: #{resolved_release}" }
          end

          # 4. Find parent task directory
          parent_number = parsed[:number]
          parent_dir = find_parent_task_directory(release_path, parent_number)

          unless parent_dir
            return {
              success: false,
              message: "Parent task #{parent_number} not found. Create the parent task first."
            }
          end

          # 5. Check parent is orchestrator or has subtasks already
          unless is_orchestrator_directory?(parent_dir, parent_number)
            return {
              success: false,
              message: "Task #{parent_number} is not an orchestrator. Create `#{parent_number}.00-orchestrator.s.md` first or convert it to an orchestrator."
            }
          end

          # 6. Get next subtask number
          subtask_num = get_next_subtask_number(parent_dir, parent_number)

          if subtask_num > 99
            return { success: false, message: "Maximum subtask limit (99) reached for task #{parent_number}" }
          end

          # 7. Generate subtask ID and slugs
          formatted_subtask = subtask_num.to_s.rjust(2, '0')
          resolved_release = resolve_release_name(release_path)
          subtask_id = "#{resolved_release}+task.#{parent_number}.#{formatted_subtask}"

          # Generate slug using LLM
          require_relative "../molecules/llm_slug_generator"
          slug_gen = Molecules::LlmSlugGenerator.new(debug: ENV["DEBUG"] == "true")
          slug_result = slug_gen.generate_task_slugs(title, metadata)
          file_slug = slug_result[:file_slug]

          # 8. Build dependencies (previous subtask if exists)
          dependencies = if subtask_num > 1
            prev_subtask = (subtask_num - 1).to_s.rjust(2, '0')
            ["#{resolved_release}+task.#{parent_number}.#{prev_subtask}"]
          else
            []
          end

          # 9. Generate subtask content
          parent_id = "#{resolved_release}+task.#{parent_number}"
          content = generate_subtask_template(subtask_id, title, parent_id, dependencies, metadata)

          # 10. Write file
          filename = "#{parent_number}.#{formatted_subtask}-#{file_slug}.s.md"
          subtask_file = File.join(parent_dir, filename)

          begin
            Ace::Support::Markdown::Organisms::SafeFileWriter.write(
              subtask_file,
              content,
              backup: false,
              validate: true
            )

            {
              success: true,
              message: "Created subtask #{subtask_id}",
              task_id: subtask_id,
              path: subtask_file
            }
          rescue StandardError => e
            { success: false, message: "Failed to create subtask: #{e.message}" }
          end
        end

        # Start working on a task (mark as in-progress)
        # @param reference [String] Task reference
        # @return [Hash] Result with :success and :message
        def start_task(reference)
          update_task_status(reference, "in-progress")
        end

        # Mark task as done and optionally move to done/
        # For subtasks: only update status, don't move folder (folder belongs to orchestrator)
        # For orchestrators: move folder only when ALL subtasks have terminal status
        # For single tasks: move folder as usual
        # @param reference [String] Task reference
        # @return [Hash] Result with :success and :message
        def complete_task(reference)
          task = @task_loader.find_task_by_reference(reference)
          return { success: false, message: "Task #{reference} not found" } unless task

          # Update status first
          status_result = update_task_status(reference, "done")
          return status_result unless status_result[:success]

          # Check if status update was idempotent (already done)
          was_already_done = status_result[:message].include?("already has status")

          # Handle completion based on task type
          if task[:parent_id]
            handle_subtask_completion(task, reference)
          elsif task[:is_orchestrator]
            handle_orchestrator_completion(task, reference, was_already_done)
          else
            handle_single_task_completion(task, reference, was_already_done)
          end
        end

        private

        # Handle completion of a subtask
        # Subtasks don't move folders - they stay with the orchestrator
        # @param task [Hash] Subtask data
        # @param reference [String] Task reference
        # @return [Hash] Result with :success and :message
        def handle_subtask_completion(task, reference)
          orchestrator_message = check_and_complete_orchestrator(task[:parent_id])
          message = "Subtask #{reference} marked as done"
          message += "\n#{orchestrator_message}" if orchestrator_message
          { success: true, message: message }
        end

        # Handle completion of an orchestrator task
        # Only moves folder if all subtasks have terminal status
        # @param task [Hash] Orchestrator task data
        # @param reference [String] Task reference
        # @param was_already_done [Boolean] Whether status was already done
        # @return [Hash] Result with :success and :message
        def handle_orchestrator_completion(task, reference, was_already_done)
          if all_subtasks_terminal?(task)
            move_result = move_task_to_done(task)
            format_completion_message(reference, was_already_done, move_result)
          else
            pending_subtasks = count_pending_subtasks(task)
            { success: true, message: "Orchestrator #{reference} marked as done (#{pending_subtasks} subtask(s) still pending)" }
          end
        end

        # Handle completion of a single (non-orchestrator, non-subtask) task
        # Moves folder to done/ directory
        # @param task [Hash] Task data
        # @param reference [String] Task reference
        # @param was_already_done [Boolean] Whether status was already done
        # @return [Hash] Result with :success and :message
        def handle_single_task_completion(task, reference, was_already_done)
          move_result = move_task_to_done(task)
          format_completion_message(reference, was_already_done, move_result)
        end

        # Move task folder to done directory
        # @param task [Hash] Task data
        # @return [Hash] Move result
        def move_task_to_done(task)
          require_relative "../molecules/task_directory_mover"
          mover = Molecules::TaskDirectoryMover.new
          mover.move_to_done(task[:path])
        end

        # Format completion message based on status and move results
        # @param reference [String] Task reference
        # @param was_already_done [Boolean] Was already marked as done
        # @param move_result [Hash] Move operation result
        # @return [Hash] Formatted result message
        def format_completion_message(reference, was_already_done, move_result)
          if move_result[:success]
            was_already_moved = move_result[:message].include?("already in done")

            if was_already_done && was_already_moved
              { success: true, message: "Task #{reference} already completed" }
            elsif was_already_done
              { success: true, message: "Task #{reference} already marked as done, moved to done/" }
            elsif was_already_moved
              { success: true, message: "Task #{reference} marked as done (already in done/)" }
            else
              { success: true, message: "Task #{reference} marked as done and moved to done/" }
            end
          else
            { success: true, message: "Task #{reference} marked as done (move to done/ failed: #{move_result[:message]})" }
          end
        end

        # Check if all subtasks have terminal status
        # @param orchestrator [Hash] Orchestrator task data
        # @return [Boolean] True if all subtasks are terminal
        def all_subtasks_terminal?(orchestrator)
          subtask_ids = orchestrator[:subtask_ids] || []
          return true if subtask_ids.empty?

          terminal_statuses = Ace::Taskflow.configuration.terminal_statuses
          subtask_ids.all? do |subtask_id|
            subtask = @task_loader.find_task_by_reference(subtask_id)
            subtask && terminal_statuses.include?(subtask[:status]&.downcase)
          end
        end

        # Count pending (non-terminal) subtasks
        # @param orchestrator [Hash] Orchestrator task data
        # @return [Integer] Count of pending subtasks
        def count_pending_subtasks(orchestrator)
          subtask_ids = orchestrator[:subtask_ids] || []
          terminal_statuses = Ace::Taskflow.configuration.terminal_statuses

          subtask_ids.count do |subtask_id|
            subtask = @task_loader.find_task_by_reference(subtask_id)
            !subtask || !terminal_statuses.include?(subtask[:status]&.downcase)
          end
        end

        # Check if orchestrator should auto-complete when all subtasks are done
        # @param orchestrator_id [String] Orchestrator task ID
        # @return [String, nil] Message if orchestrator was auto-completed, nil otherwise
        def check_and_complete_orchestrator(orchestrator_id)
          orchestrator = @task_loader.find_task_by_reference(orchestrator_id)
          return nil unless orchestrator
          return nil unless orchestrator[:is_orchestrator]

          # Check if all subtasks are now terminal
          if all_subtasks_terminal?(orchestrator)
            # Auto-complete the orchestrator
            update_task_status(orchestrator_id, "done")
            move_task_to_done(orchestrator)
            "Orchestrator #{orchestrator_id} auto-completed (all subtasks done)"
          end
        end

        public

        # Add dependency to a task
        # @param reference [String] Task reference
        # @param depends_on [String] Dependency task reference
        # @return [Hash] Result with :success and :message
        def add_dependency(reference, depends_on)
          task = @task_loader.find_task_by_reference(reference)
          unless task
            return { success: false, message: "Task #{reference} not found" }
          end

          dep_task = @task_loader.find_task_by_reference(depends_on)
          unless dep_task
            return { success: false, message: "Dependency task #{depends_on} not found" }
          end

          # Check for self-dependency
          if Atoms::DependencyValidator.self_dependency?(task[:id], dep_task[:id])
            return { success: false, message: "Task cannot depend on itself" }
          end

          # Check if dependency already exists
          current_deps = task[:dependencies] || []
          dep_id = dep_task[:id]
          if current_deps.include?(dep_id) || current_deps.include?(dep_task[:task_number])
            return { success: false, message: "Dependency already exists" }
          end

          # Check for circular dependency
          all_tasks = @task_loader.load_all_tasks
          task_map = all_tasks.each_with_object({}) do |t, map|
            map[t[:id]] = t
            map[t[:task_number]] = t if t[:task_number]
          end

          if Atoms::DependencyValidator.would_create_cycle?(task[:id], dep_task[:id], task_map)
            path = Atoms::DependencyValidator.find_circular_path(task[:id], dep_task[:id], task_map)
            return {
              success: false,
              message: "Would create circular dependency: #{path.join(' -> ')}"
            }
          end

          # Add the dependency
          new_deps = current_deps + [dep_id]
          if @task_loader.update_task_dependencies(task[:path], new_deps)
            {
              success: true,
              message: "Added dependency: #{reference} now depends on #{depends_on}"
            }
          else
            { success: false, message: "Failed to update task dependencies" }
          end
        end

        # Remove dependency from a task
        # @param reference [String] Task reference
        # @param depends_on [String] Dependency task reference to remove
        # @return [Hash] Result with :success and :message
        def remove_dependency(reference, depends_on)
          task = @task_loader.find_task_by_reference(reference)
          unless task
            return { success: false, message: "Task #{reference} not found" }
          end

          dep_task = @task_loader.find_task_by_reference(depends_on)
          unless dep_task
            return { success: false, message: "Dependency task #{depends_on} not found" }
          end

          # Check if dependency exists
          current_deps = task[:dependencies] || []
          dep_id = dep_task[:id]
          dep_num = dep_task[:task_number]

          unless current_deps.include?(dep_id) || current_deps.include?(dep_num)
            return { success: false, message: "Dependency does not exist" }
          end

          # Remove the dependency
          new_deps = current_deps.reject { |d| d == dep_id || d == dep_num }
          if @task_loader.update_task_dependencies(task[:path], new_deps)
            {
              success: true,
              message: "Removed dependency: #{reference} no longer depends on #{depends_on}"
            }
          else
            { success: false, message: "Failed to update task dependencies" }
          end
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

          # Check if this is an idempotent operation (already in desired state)
          if Molecules::StatusValidator.idempotent_operation?(task[:status], new_status)
            return {
              success: true,
              message: "Task #{reference} already has status: #{new_status}"
            }
          end

          # Get flexible/strict mode from config (default: flexible)
          strict_transitions = @config.dig("taskflow", "strict_transitions") == true
          flexible_mode = !strict_transitions

          # Validate status transition using pure logic molecule
          unless Molecules::StatusValidator.valid_transition?(task[:status], new_status, flexible: flexible_mode)
            return {
              success: false,
              message: "Invalid status transition: #{task[:status]} → #{new_status}"
            }
          end

          # Check dependencies if transitioning to in-progress
          if new_status == "in-progress" && !task[:dependencies].to_a.empty?
            all_tasks = @task_loader.load_all_tasks
            unless Molecules::DependencyResolver.dependencies_met?(task, all_tasks)
              blocking_tasks = Molecules::DependencyResolver.get_blocking_tasks(task, all_tasks)
              blocking_refs = blocking_tasks.map { |t| t[:task_number] || t[:id] }
              return {
                success: false,
                message: "Cannot start task: blocked by dependencies #{blocking_refs.join(', ')}"
              }
            end
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

        # Update task fields
        # @param reference [String] Task reference
        # @param field_updates [Hash] Field updates to apply
        # @return [Hash] Result with :success, :message, :updated_fields, :task, :path
        def update_task_fields(reference, field_updates)
          task = @task_loader.find_task_by_reference(reference)
          unless task
            return { success: false, message: "Task not found: #{reference}" }
          end

          # Update the task file
          result = @task_loader.update_task_field(task[:path], field_updates)

          if result[:success]
            {
              success: true,
              message: "Task updated: #{task[:id] || reference}",
              updated_fields: result[:updated_fields],
              task: task,
              path: result[:path]
            }
          else
            {
              success: false,
              message: result[:message],
              path: result[:path]
            }
          end
        end

        # Move task between releases
        # @param reference [String] Task reference
        # @param target [String] Target release (backlog, v.0.10.0, etc.)
        # @return [Hash] Result with :success, :message, :new_reference
        def move_task(reference, target)
          # Find source task
          task = @task_loader.find_task_by_reference(reference)
          unless task
            return { success: false, message: "Task #{reference} not found" }
          end

          # Resolve target release
          target_path = resolve_release_path(target)
          unless target_path
            return { success: false, message: "Invalid target release: #{target}" }
          end

          # Generate new task number and slug in target
          new_number = generate_task_number(target_path)
          new_id = generate_task_id(target, new_number)

          # Extract title from task for slug generation
          task_title = task[:title] || "Untitled Task"
          slug_part = Molecules::TaskSlugGenerator.generate_descriptive_part(task_title, task[:metadata] || {})

          # Build paths
          old_dir = File.dirname(task[:path])
          new_dir = Atoms::PathBuilder.build_task_path("", target_path, new_number, slug_part)

          begin
            # Create target directory
            FileUtils.mkdir_p(File.dirname(new_dir))

            # Move task directory
            FileUtils.mv(old_dir, new_dir)

            # Use new naming convention for moved task
            new_task_file = File.join(new_dir, "task.#{new_number}.s.md")

            # If old task uses different naming, rename it
            old_filename = File.basename(task[:path])
            temp_file = File.join(new_dir, old_filename)
            if File.exist?(temp_file) && temp_file != new_task_file
              FileUtils.mv(temp_file, new_task_file)
            end

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
        # @param release [String] Release to search
        # @return [Array<Hash>] Recent tasks
        def get_recent_tasks(days: 7, release: "all")
          list_tasks(release: release, filters: { recent_days: days })
        end

        # Get task statistics
        # @param release [String] Release to analyze
        # @return [Hash] Statistics
        def get_statistics(release: "all")
          # Use glob pattern to include all tasks (including maybe/, anyday/, done/ subdirectories)
          # Match both old format (task.NNN.s.md) and new hierarchical format (NNN-slug.s.md)
          tasks = list_tasks(release: release, glob: ["**/task.[0-9][0-9][0-9].s.md", "**/[0-9][0-9][0-9]-*.s.md"])

          # Delegate to pure logic molecule
          Molecules::TaskStatistics.calculate(tasks)
        end

        private

        def resolve_release_path(release)
          case release
          when "current", "active"
            primary = @release_resolver.find_primary_active
            primary ? primary[:path] : nil
          when "backlog"
            File.join(@root_path, "backlog")
          when "all"
            @root_path
          else
            # Try to resolve as release
            release_info = @release_resolver.find_release(release)
            release_info ? release_info[:path] : nil
          end
        end

        def generate_task_number(release_path)
          # Load ALL tasks from ALL releases to find global maximum
          # This ensures task IDs are never reused across the entire project
          all_tasks = @task_loader.load_all_tasks

          # Extract task numbers from all tasks
          existing_numbers = all_tasks.map do |task|
            # Task number can be in task[:task_number] or extracted from task[:id]
            task[:task_number]&.to_i || extract_number_from_id(task[:id])
          end.compact

          return "001" if existing_numbers.empty?

          next_number = existing_numbers.max + 1
          next_number.to_s.rjust(3, '0')
        end

        # Extract numeric part from task ID (e.g., "v.0.9.0+task.058" → 58)
        # @param id [String] Task ID
        # @return [Integer, nil] Extracted number or nil
        def extract_number_from_id(id)
          return nil unless id

          match = id.match(/task\.(\d+)/)
          match ? match[1].to_i : nil
        end

        def generate_task_id(release, number)
          if release == "backlog"
            "backlog+task.#{number}"
          elsif release.start_with?("v.")
            "#{release}+task.#{number}"
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


        def update_task_id_in_file(file_path, new_id)
          content = File.read(file_path)
          updated = content.sub(/^id:\s*.+$/m, "id: #{new_id}")
          Ace::Support::Markdown::Organisms::SafeFileWriter.write(
            file_path,
            updated,
            backup: true,
            validate: true
          )
        end

        def task_id_exists?(release_path, task_id)
          config = Ace::Taskflow.configuration
          # Check both active and done directories for existing task IDs
          dirs = [
            File.join(release_path, config.task_dir),
            File.join(release_path, "done")
          ]

          dirs.any? do |dir|
            next false unless File.directory?(dir)

            Dir.glob(File.join(dir, "*")).any? do |path|
              # Check if directory name contains the task ID
              dirname = File.basename(path)
              # Match task ID pattern (e.g., "001", "002", etc.) at the start of dirname
              task_number = task_id.split('.').last
              dirname.start_with?("#{task_number}-")
            end
          end
        end

        # Find parent task directory by task number
        # @param release_path [String] Path to release directory
        # @param parent_number [String] Parent task number (e.g., "121")
        # @return [String, nil] Path to parent task directory or nil
        def find_parent_task_directory(release_path, parent_number)
          task_config = Ace::Taskflow.configuration
          tasks_dir = File.join(release_path, task_config.task_dir)

          # Try new naming convention first: {number}-{slug}/
          dir = Dir.glob(File.join(tasks_dir, "#{parent_number}-*")).find { |d| File.directory?(d) }
          return dir if dir

          # Fallback to old naming convention: {number}/
          old_dir = File.join(tasks_dir, parent_number)
          return old_dir if File.directory?(old_dir)

          nil
        end

        # Check if directory contains orchestrator file or subtasks
        # @param parent_dir [String] Path to task directory
        # @param parent_number [String] Parent task number
        # @return [Boolean] true if orchestrator or has subtasks
        def is_orchestrator_directory?(parent_dir, parent_number)
          # Has .00 file (orchestrator)
          orchestrator = Dir.glob(File.join(parent_dir, "#{parent_number}.00-*.s.md")).any?
          # Has any subtask files (NN > 00)
          subtasks = Dir.glob(File.join(parent_dir, "#{parent_number}.[0-9][0-9]-*.s.md")).any?
          orchestrator || subtasks
        end

        # Get next available subtask number for a parent
        # @param parent_dir [String] Path to parent task directory
        # @param parent_number [String] Parent task number
        # @return [Integer] Next subtask number (1-99)
        def get_next_subtask_number(parent_dir, parent_number)
          # Scan for existing subtask files
          pattern = File.join(parent_dir, "#{parent_number}.[0-9][0-9]-*.s.md")
          existing = Dir.glob(pattern).map do |f|
            basename = File.basename(f)
            match = basename.match(/^\d+\.(\d{2})-/)
            match ? match[1].to_i : nil
          end.compact

          # Return next number (max + 1), skipping 00 (orchestrator)
          existing_without_zero = existing.reject { |n| n == 0 }
          existing_without_zero.empty? ? 1 : existing_without_zero.max + 1
        end

        # Resolve release name from path
        # @param release_path [String] Full path to release
        # @return [String] Release name (e.g., "v.0.9.0", "backlog")
        def resolve_release_name(release_path)
          basename = File.basename(release_path)
          if basename == "backlog"
            "backlog"
          else
            basename
          end
        end

        # Generate subtask template content
        # @param id [String] Subtask ID
        # @param title [String] Subtask title
        # @param parent_id [String] Parent task ID
        # @param dependencies [Array<String>] Dependencies list
        # @param metadata [Hash] Additional metadata
        # @return [String] Template content
        def generate_subtask_template(id, title, parent_id, dependencies, metadata)
          deps_yaml = if dependencies.empty?
            "[]"
          else
            "\n  - #{dependencies.join("\n  - ")}"
          end

          <<~TEMPLATE
            ---
            id: #{id}
            status: #{metadata[:status] || 'pending'}
            priority: #{metadata[:priority] || 'medium'}
            estimate: #{metadata[:estimate] || 'TBD'}
            dependencies: #{deps_yaml}
            parent: #{parent_id}
            ---

            # #{title}

            ## Scope

            [Describe the scope of this subtask]

            ## Deliverables

            - [ ] [Deliverable 1]
            - [ ] [Deliverable 2]

            ## Acceptance Criteria

            - [ ] [Criterion 1]
            - [ ] [Criterion 2]
          TEMPLATE
        end
      end
    end
  end
end