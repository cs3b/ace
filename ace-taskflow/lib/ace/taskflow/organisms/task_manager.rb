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
require_relative "../atoms/frontmatter_parser"
require_relative "../atoms/dependency_validator"
require_relative "../molecules/llm_slug_generator"

module Ace
  module Taskflow
    module Organisms
      # Task business logic orchestration
      class TaskManager
        attr_reader :root_path

        def initialize(_config = nil)
          # Note: _config parameter retained for backward compatibility but unused
          # All configuration is accessed via Ace::Taskflow.configuration (ADR-022)
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
            FileUtils.mkdir_p(File.join(task_dir, "ux"))

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
          if parsed[:subtask]
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

          parent_context = prepare_parent_for_subtask(
            parent_dir,
            parent_number,
            parent_ref,
            release_path,
            dry_run: false
          )
          return parent_context unless parent_context[:success]

          parent_dir = parent_context[:parent_dir]
          conversion_message = parent_context[:conversion_message]
          converted_flag = parent_context[:converted_to_orchestrator]

          # 5. Get next subtask number
          # Safety: after auto-conversion the .01 file exists on disk so
          # get_next_subtask_number normally returns 2, but guard anyway.
          subtask_num = get_next_subtask_number(parent_dir, parent_number)
          if converted_flag && subtask_num == 1
            subtask_num = 2
          end

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

            creation_message = "Created subtask #{subtask_id}"
            final_message = [conversion_message, creation_message].compact.join("\n")

            {
              success: true,
              message: final_message,
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

        # Mark task as done and optionally move to _archive/
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

        # Reopen a completed task (move from _archive/ and update status)
        # For subtasks: only update status, don't move folder (folder belongs to orchestrator)
        # For orchestrators: restore folder from _archive/
        # For single tasks: restore folder from _archive/
        # @param reference [String] Task reference
        # @param status [String] Status to set (default: "in-progress")
        # @return [Hash] Result with :success and :message
        def reopen_task(reference, status: "in-progress")
          task = @task_loader.find_task_by_reference(reference)
          return { success: false, message: "Task #{reference} not found" } unless task

          archive_dir = Ace::Taskflow.configuration.done_dir

          # Check if task is in archive directory
          in_archive = task[:path].include?("/#{archive_dir}/")

          # Handle based on task type
          if task[:parent_id]
            # Subtask: only update status
            handle_subtask_reopen(task, reference, status)
          elsif task[:is_orchestrator] || !task[:parent_id]
            # Orchestrator or single task: restore from archive and update status
            handle_task_reopen(task, reference, status, in_archive)
          else
            { success: false, message: "Unknown task type for #{reference}" }
          end
        end

        private

        # Handle completion of a subtask
        # Subtasks don't move folders - they stay with the orchestrator
        # @param task [Hash] Subtask data
        # @param reference [String] Task reference
        # @return [Hash] Result with :success and :message
        def handle_subtask_completion(task, reference)
          # Clean up backup files in the subtask's parent directory
          cleanup_subtask_backup_files(task[:path])

          orchestrator_message = check_and_complete_orchestrator(task[:parent_id])
          message = "Subtask #{reference} marked as done"
          message += "\n#{orchestrator_message}" if orchestrator_message
          { success: true, message: message }
        end

        # Handle reopening a subtask
        # Subtasks don't move folders - just update status
        # @param task [Hash] Subtask data
        # @param reference [String] Task reference
        # @param status [String] New status
        # @return [Hash] Result with :success and :message
        def handle_subtask_reopen(task, reference, status)
          status_result = update_task_status(reference, status)
          return status_result unless status_result[:success]

          { success: true, message: "Subtask #{reference} reopened and set to #{status}" }
        end

        # Handle reopening a task (orchestrator or single task)
        # Restores from archive if necessary and updates status
        # @param task [Hash] Task data
        # @param reference [String] Task reference
        # @param status [String] New status
        # @param in_archive [Boolean] Whether task is currently in archive
        # @return [Hash] Result with :success and :message
        def handle_task_reopen(task, reference, status, in_archive)
          # Restore from archive if in archive directory
          if in_archive
            require_relative "../molecules/task_directory_mover"
            mover = Molecules::TaskDirectoryMover.new
            restore_result = mover.restore_from_archive(task[:path])

            return restore_result unless restore_result[:success]

            # Update status using the new path
            task_loader_temp = Molecules::TaskLoader.new(@root_path)
            restored_task = task_loader_temp.find_task_by_reference(reference)

            unless restored_task
              return { success: false, message: "Task restored but could not be found for status update" }
            end

            # task_loader.update_task_status returns Boolean, not Hash
            success = @task_loader.update_task_status(restored_task[:path], status)
            return { success: false, message: "Failed to update task status" } unless success

            archive_dir = Ace::Taskflow.configuration.done_dir
            { success: true, message: "Task #{reference} restored from #{archive_dir}/ and set to #{status}" }
          else
            # Task not in archive, just update status
            status_result = update_task_status(reference, status)
            return status_result unless status_result[:success]

            { success: true, message: "Task #{reference} set to #{status}" }
          end
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

        # Move task folder to archive directory
        # @param task [Hash] Task data
        # @return [Hash] Move result
        def move_task_to_archive(task)
          require_relative "../molecules/task_directory_mover"
          mover = Molecules::TaskDirectoryMover.new
          mover.move_to_archive(task[:path])
        end

        # Backward compatibility alias
        # @deprecated Use move_task_to_archive instead
        def move_task_to_done(task)
          move_task_to_archive(task)
        end

        # Format completion message based on status and move results
        # @param reference [String] Task reference
        # @param was_already_done [Boolean] Was already marked as done
        # @param move_result [Hash] Move operation result
        # @return [Hash] Formatted result message
        def format_completion_message(reference, was_already_done, move_result)
          archive_dir = Ace::Taskflow.configuration.done_dir
          if move_result[:success]
            was_already_moved = move_result[:message].include?("already in #{archive_dir}")

            if was_already_done && was_already_moved
              { success: true, message: "Task #{reference} already completed" }
            elsif was_already_done
              { success: true, message: "Task #{reference} already marked as done, moved to #{archive_dir}/" }
            elsif was_already_moved
              { success: true, message: "Task #{reference} marked as done (already in #{archive_dir}/)" }
            else
              { success: true, message: "Task #{reference} marked as done and moved to #{archive_dir}/" }
            end
          else
            { success: true, message: "Task #{reference} marked as done (move to #{archive_dir}/ failed: #{move_result[:message]})" }
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
          flexible_mode = !Ace::Taskflow.configuration.strict_transitions?

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

        # Promote a subtask to a standalone task
        # @param reference [String] Subtask reference (e.g., "121.01", "v.0.9.0+task.121.01")
        # @param dry_run [Boolean] If true, show what would happen without executing
        # @return [Hash] Result with :success, :message, :new_reference, :new_path
        def promote_to_standalone(reference, dry_run: false)
          # Find the subtask
          task = @task_loader.find_task_by_reference(reference)
          unless task
            return { success: false, message: "Subtask #{reference} not found" }
          end

          # Verify it's actually a subtask
          unless task[:parent_id]
            return { success: false, message: "Task #{reference} is not a subtask (no parent)" }
          end

          # Get release info
          parsed = Atoms::TaskReferenceParser.parse(reference)
          release = parsed[:qualified] ? parsed[:release] : "current"
          release_path = resolve_release_path(release)
          unless release_path
            return { success: false, message: "Release not found: #{release}" }
          end

          # Generate new standalone task number and ID
          new_number = generate_task_number(release_path)
          new_id = generate_task_id(resolve_release_name(release_path), new_number)

          # Generate slug for new task (skip LLM during dry-run for performance)
          task_title = task[:title] || "Untitled Task"
          slug_result = generate_slugs(task_title, task[:metadata] || {}, dry_run: dry_run)
          folder_slug = slug_result[:folder_slug]
          file_slug = slug_result[:file_slug]

          # Build new paths
          task_config = Ace::Taskflow.configuration
          new_dir = File.join(release_path, task_config.task_dir, "#{new_number}-#{folder_slug}")
          new_filename = "#{new_number}-#{file_slug}.s.md"
          new_path = File.join(new_dir, new_filename)

          new_reference = Atoms::TaskReferenceParser.format(resolve_release_name(release_path), new_number)

          if dry_run
            return {
              success: true,
              message: "[DRY-RUN] Would promote subtask #{reference} to standalone task #{new_reference}",
              dry_run: true,
              new_reference: new_reference,
              new_path: new_path,
              operations: [
                "Create directory: #{new_dir}",
                "Copy file: #{task[:path]} -> #{new_path}",
                "Update ID in file: #{task[:id]} -> #{new_id}",
                "Remove parent field from frontmatter",
                "Delete original: #{task[:path]}"
              ]
            }
          end

          begin
            # Create new directory
            FileUtils.mkdir_p(new_dir)
            FileUtils.mkdir_p(File.join(new_dir, "docs"))
            FileUtils.mkdir_p(File.join(new_dir, "qa"))

            # Read original content and update using YAML parsing for reliability
            content = File.read(task[:path])
            content = update_frontmatter(
              content,
              updates: { "id" => new_id },
              remove: ["parent"]
            )

            # Write to new location
            write_result = Ace::Support::Markdown::Organisms::SafeFileWriter.write(
              new_path,
              content,
              backup: false,
              validate: true
            )

            unless write_result[:success]
              return { success: false, message: "Failed to write file: #{write_result[:errors].join(', ')}" }
            end

            # Delete original subtask file
            File.delete(task[:path])

            {
              success: true,
              message: "Promoted subtask #{reference} to standalone task #{new_reference}",
              new_reference: new_reference,
              new_path: new_path
            }
          rescue StandardError => e
            { success: false, message: "Failed to promote subtask: #{e.message}" }
          end
        end

        # Convert a standalone task to a subtask under a parent task
        # @param task_ref [String] Task reference to demote (e.g., "019")
        # @param parent_ref [String] Parent task reference (e.g., "121")
        # @param dry_run [Boolean] If true, show what would happen without executing
        # @return [Hash] Result with :success, :message, :new_reference, :new_path
        def demote_to_subtask(task_ref, parent_ref, dry_run: false)
          # Prevent self-demotion (would corrupt state via auto-conversion then missing file)
          if task_ref.to_s == parent_ref.to_s
            return { success: false, message: "Task #{task_ref} cannot be demoted under itself" }
          end

          # Find the task to demote
          task = @task_loader.find_task_by_reference(task_ref)
          unless task
            return { success: false, message: "Task #{task_ref} not found" }
          end

          # Verify it's not already a subtask
          if task[:parent_id]
            return { success: false, message: "Task #{task_ref} is already a subtask of #{task[:parent_id]}" }
          end

          # Find parent task
          parent = @task_loader.find_task_by_reference(parent_ref)
          unless parent
            return { success: false, message: "Parent task #{parent_ref} not found" }
          end

          # Get parent release and path
          parent_parsed = Atoms::TaskReferenceParser.parse(parent[:id] || parent_ref)
          release = parent_parsed[:qualified] ? parent_parsed[:release] : "current"
          release_path = resolve_release_path(release)
          unless release_path
            return { success: false, message: "Release not found: #{release}" }
          end

          # Find parent directory
          parent_number = parent_parsed[:number]
          parent_dir = find_parent_task_directory(release_path, parent_number)
          unless parent_dir
            return { success: false, message: "Parent task directory not found for #{parent_ref}" }
          end

          # Prepare parent directory (auto-convert non-orchestrators)
          parent_context = prepare_parent_for_subtask(
            parent_dir,
            parent_number,
            parent[:id] || parent_ref,
            release_path,
            dry_run: dry_run
          )
          return parent_context unless parent_context[:success]

          parent_dir = parent_context[:parent_dir]
          conversion_message = parent_context[:conversion_message]
          conversion_operations = parent_context[:conversion_operations] || []
          converted_flag = parent_context[:converted_to_orchestrator]

          # Get next subtask number
          # Essential for dry-run: conversion doesn't write .01 file, so
          # get_next_subtask_number returns 1 instead of 2. Also a safety
          # net for real execution in case of filesystem timing.
          subtask_num = get_next_subtask_number(parent_dir, parent_number)
          if converted_flag && subtask_num == 1
            subtask_num = 2
          end
          if subtask_num > 99
            return { success: false, message: "Maximum subtask limit (99) reached for task #{parent_number}" }
          end

          # Generate new subtask ID
          formatted_subtask = subtask_num.to_s.rjust(2, '0')
          resolved_release = resolve_release_name(release_path)
          new_id = "#{resolved_release}+task.#{parent_number}.#{formatted_subtask}"
          parent_id = "#{resolved_release}+task.#{parent_number}"

          # Generate slug for new subtask file (skip LLM during dry-run for performance)
          task_title = task[:title] || "Untitled Task"
          slug_result = generate_slugs(task_title, task[:metadata] || {}, dry_run: dry_run)
          file_slug = slug_result[:file_slug]

          # Build new path
          new_filename = "#{parent_number}.#{formatted_subtask}-#{file_slug}.s.md"
          new_path = File.join(parent_dir, new_filename)
          new_reference = "#{resolved_release}+task.#{parent_number}.#{formatted_subtask}"

          if dry_run
            dry_run_message = [conversion_message, "[DRY-RUN] Would demote task #{task_ref} to subtask #{new_reference}"].compact.join("\n")
            operations = []
            operations.concat(conversion_operations) if conversion_operations.any?
            operations.concat([
              "Copy file: #{task[:path]} -> #{new_path}",
              "Update ID in file: #{task[:id]} -> #{new_id}",
              "Add parent field: #{parent_id}",
              "Delete original directory: #{File.dirname(task[:path])}"
            ])

            return {
              success: true,
              message: dry_run_message,
              dry_run: true,
              new_reference: new_reference,
              new_path: new_path,
              operations: operations
            }
          end

          begin
            # Read original content and update using YAML parsing for reliability
            content = File.read(task[:path])
            content = update_frontmatter(
              content,
              updates: { "id" => new_id, "parent" => parent_id }
            )

            # Write to new location
            write_result = Ace::Support::Markdown::Organisms::SafeFileWriter.write(
              new_path,
              content,
              backup: false,
              validate: true
            )

            unless write_result[:success]
              return { success: false, message: "Failed to write file: #{write_result[:errors].join(', ')}" }
            end

            # Delete original task directory (with safety checks)
            old_dir = File.dirname(task[:path])

            # Safety check: only delete directories within .ace-taskflow
            unless old_dir.include?(".ace-taskflow")
              return {
                success: false,
                message: "Safety check failed: refusing to delete directory outside .ace-taskflow: #{old_dir}"
              }
            end

            # Check for auxiliary files that would be lost
            auxiliary_files = Dir.glob(File.join(old_dir, "**", "*")).select { |f| File.file?(f) }
            auxiliary_files -= [task[:path]] # Exclude the task file itself
            if auxiliary_files.any?
              # Copy auxiliary files to new location (parent orchestrator directory)
              dest_dir = File.dirname(new_path)
              auxiliary_files.each do |aux_file|
                rel_path = aux_file.sub(old_dir + "/", "")
                dest_path = File.join(dest_dir, rel_path)
                FileUtils.mkdir_p(File.dirname(dest_path))
                FileUtils.cp(aux_file, dest_path)
              end
            end

            FileUtils.rm_rf(old_dir)

            demote_message = "Demoted task #{task_ref} to subtask #{new_reference}"
            final_message = [conversion_message, demote_message].compact.join("\n")

            {
              success: true,
              message: final_message,
              new_reference: new_reference,
              new_path: new_path
            }
          rescue StandardError => e
            { success: false, message: "Failed to demote task: #{e.message}" }
          end
        end

        # Convert a standalone task to an orchestrator with the original task as first subtask
        # @param reference [String] Task reference (e.g., "019")
        # @param dry_run [Boolean] If true, show what would happen without executing
        # @return [Hash] Result with :success, :message, :orchestrator_path, :subtask_path
        def convert_to_orchestrator(reference, dry_run: false)
          # Find the task
          task = @task_loader.find_task_by_reference(reference)
          unless task
            return { success: false, message: "Task #{reference} not found" }
          end

          # Verify it's not a subtask
          if task[:parent_id]
            return { success: false, message: "Task #{reference} is a subtask. Cannot convert subtask to orchestrator." }
          end

          # Verify it's not already an orchestrator
          if task[:is_orchestrator]
            return { success: false, message: "Task #{reference} is already an orchestrator." }
          end

          # Get task info from reference
          parsed = Atoms::TaskReferenceParser.parse(reference)
          task_number = parsed[:number]
          release = parsed[:qualified] ? parsed[:release] : "current"
          release_path = resolve_release_path(release)
          resolved_release = resolve_release_name(release_path)

          # Build paths
          task_dir = File.dirname(task[:path])
          orchestrator_filename = "#{task_number}-orchestrator.s.md"
          orchestrator_path = File.join(task_dir, orchestrator_filename)

          # Generate slug for subtask file
          task_title = task[:title] || "Untitled Task"
          slug_result = generate_slugs(task_title, task[:metadata] || {}, dry_run: dry_run)
          file_slug = slug_result[:file_slug]

          subtask_filename = "#{task_number}.01-#{file_slug}.s.md"
          subtask_path = File.join(task_dir, subtask_filename)

          # Build IDs
          orchestrator_id = "#{resolved_release}+task.#{task_number}"
          subtask_id = "#{resolved_release}+task.#{task_number}.01"

          if dry_run
            return {
              success: true,
              message: "[DRY-RUN] Would convert task #{reference} to orchestrator with first subtask",
              dry_run: true,
              orchestrator_path: orchestrator_path,
              subtask_path: subtask_path,
              subtask_id: subtask_id,
              operations: [
                "Create orchestrator: #{orchestrator_path}",
                "Move original to subtask: #{subtask_path}",
                "Update subtask ID: #{task[:id]} -> #{subtask_id}",
                "Add parent field: #{orchestrator_id}",
                "Delete original: #{task[:path]}"
              ]
            }
          end

          begin
            # Read original task content
            original_content = File.read(task[:path])

            # Create orchestrator content (minimal auto-generated)
            orchestrator_content = build_orchestrator_content(
              task: task,
              orchestrator_id: orchestrator_id,
              subtask_title: task_title
            )

            # Update original content for subtask: change ID and add parent
            subtask_content = update_frontmatter(
              original_content,
              updates: { id: subtask_id, parent: orchestrator_id },
              remove: []
            )

            # Write orchestrator file
            File.write(orchestrator_path, orchestrator_content)

            # Write subtask file
            File.write(subtask_path, subtask_content)

            # Delete original file
            File.delete(task[:path])

            {
              success: true,
              message: "Converted task #{reference} to orchestrator with subtask .01",
              orchestrator_path: orchestrator_path,
              subtask_path: subtask_path,
              subtask_id: subtask_id
            }
          rescue StandardError => e
            { success: false, message: "Failed to convert to orchestrator: #{e.message}" }
          end
        end

        # Defer a task (move to _deferred/ and update status)
        # @param reference [String] Task reference
        # @return [Hash] Result with :success and :message
        def defer_task(reference)
          task = @task_loader.find_task_by_reference(reference)
          return { success: false, message: "Task #{reference} not found" } unless task

          # Check if task is already deferred (idempotent check)
          anyday_dir_name = Ace::Taskflow.configuration.anyday_dir
          if task[:path].include?("/#{anyday_dir_name}/")
            return { success: true, message: "Task #{reference} is already deferred" }
          end

          # Update status to deferred first
          status_result = update_task_status(reference, "deferred")
          return status_result unless status_result[:success]

          # Move to deferred directory
          require_relative "../molecules/task_directory_mover"
          mover = Molecules::TaskDirectoryMover.new
          move_result = mover.move_to_anyday(task[:path])

          if move_result[:success]
            anyday_dir = Ace::Taskflow.configuration.anyday_dir
            { success: true, message: "Task #{reference} deferred and moved to #{anyday_dir}/" }
          else
            { success: true, message: "Task #{reference} status set to deferred (move to #{Ace::Taskflow.configuration.anyday_dir}/ failed: #{move_result[:message]})" }
          end
        end

        # Restore a deferred task (move from _deferred/ and update status)
        # @param reference [String] Task reference
        # @param status [String] Status to set (default: "pending")
        # @return [Hash] Result with :success and :message
        def undefer_task(reference, status: "pending")
          task = @task_loader.find_task_by_reference(reference)
          return { success: false, message: "Task #{reference} not found" } unless task

          anyday_dir_name = Ace::Taskflow.configuration.anyday_dir

          # Check if task is in deferred directory
          in_deferred = task[:path].include?("/#{anyday_dir_name}/")

          unless in_deferred
            return { success: false, message: "Task #{reference} is not in #{anyday_dir_name}/" }
          end

          # Restore from deferred directory
          require_relative "../molecules/task_directory_mover"
          mover = Molecules::TaskDirectoryMover.new
          restore_result = mover.restore_from_anyday(task[:path])

          return restore_result unless restore_result[:success]

          # Update status using the new path
          task_loader_temp = Molecules::TaskLoader.new(@root_path)
          restored_task = task_loader_temp.find_task_by_reference(reference)

          unless restored_task
            return { success: false, message: "Task restored but could not be found for status update" }
          end

          status_result = @task_loader.update_task_status(restored_task[:path], status)
          return status_result unless status_result[:success]

          { success: true, message: "Task #{reference} restored from #{anyday_dir_name}/ and set to #{status}" }
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
          # Use glob pattern from Configuration (single source of truth per ADR-022)
          # Prefixed with "tasks/" to restrict to tasks directory and avoid matching idea files
          task_globs = Ace::Taskflow.configuration.default_task_glob_pattern.map { |p| "tasks/#{p}" }
          tasks = list_tasks(release: release, glob: task_globs)

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
            File.join(@root_path, Ace::Taskflow.configuration.backlog_dir)
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

          # Extract task numbers from task IDs (not file paths)
          # File paths can be unreliable for subtasks (e.g., "17910-*.s.md" for "task.179.10")
          existing_numbers = all_tasks.map do |task|
            extract_number_from_id(task[:id])
          end.compact

          return "001" if existing_numbers.empty?

          next_number = existing_numbers.max + 1
          next_number.to_s.rjust(3, '0')
        end

        # Extract numeric part from task ID (e.g., "v.0.9.0+task.058" → 58)
        # For subtasks, extracts only parent number (e.g., "task.179.10" → 179)
        # @param id [String] Task ID
        # @return [Integer, nil] Extracted number or nil
        def extract_number_from_id(id)
          return nil unless id

          # Match only the main task number, stopping at subtask delimiter
          # "task.179" → 179, "task.179.10" → 179 (not 17910)
          match = id.match(/task\.(\d+)(?:\.|$)/)
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
          # Check both active and archive directories for existing task IDs
          dirs = [
            File.join(release_path, config.task_dir),
            File.join(release_path, config.done_dir)
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

          # Try in archive directory
          archive_dir = File.join(tasks_dir, task_config.done_dir)
          if File.directory?(archive_dir)
            dir = Dir.glob(File.join(archive_dir, "#{parent_number}-*")).find { |d| File.directory?(d) }
            return dir if dir
          end

          # Fallback to old naming convention: {number}/
          old_dir = File.join(tasks_dir, parent_number)
          return old_dir if File.directory?(old_dir)

          nil
        end

        def prepare_parent_for_subtask(parent_dir, parent_number, parent_ref, release_path, dry_run:)
          return {
            success: true,
            parent_dir: parent_dir,
            converted_to_orchestrator: false,
            conversion_message: nil,
            conversion_operations: []
          } if is_orchestrator_directory?(parent_dir, parent_number)

          convert_result = convert_to_orchestrator(parent_ref, dry_run: dry_run)
          return convert_result unless convert_result[:success]

          updated_parent_dir = find_parent_task_directory(release_path, parent_number)
          unless updated_parent_dir
            return {
              success: false,
              message: "Parent task directory not found after conversion to orchestrator"
            }
          end

          {
            success: true,
            parent_dir: updated_parent_dir,
            converted_to_orchestrator: true,
            conversion_message: convert_result[:message],
            conversion_operations: Array(convert_result[:operations])
          }
        end

        # Check if directory contains orchestrator file or subtasks
        # Orchestrators are detected by having an NNN-orchestrator.s.md file
        # OR by having subtask files (NNN.NN-*.s.md)
        # @param parent_dir [String] Path to task directory
        # @param parent_number [String] Parent task number
        # @return [Boolean] true if orchestrator or has subtasks
        def is_orchestrator_directory?(parent_dir, parent_number)
          # Has orchestrator file (new naming: NNN-orchestrator.s.md)
          orchestrator = Dir.glob(File.join(parent_dir, "#{parent_number}-orchestrator.s.md")).any?
          # Has any subtask files (NNN.NN-*.s.md)
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

          # Return next number (max + 1), starting from 1
          existing.empty? ? 1 : existing.max + 1
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

        # Factory method for creating slug generator
        # @param debug [Boolean] Enable debug output
        # @return [Molecules::LlmSlugGenerator] Slug generator instance
        def create_slug_generator(debug: false)
          Molecules::LlmSlugGenerator.new(debug: debug)
        end

        # Check if debug mode is enabled via ENV
        # @return [Boolean] true if DEBUG=true
        def debug_mode?
          ENV["DEBUG"] == "true"
        end

        # Generate slugs for a task, returning preview slugs during dry-run
        # @param task_title [String] Task title
        # @param metadata [Hash] Task metadata
        # @param dry_run [Boolean] Skip LLM for performance during dry-run
        # @return [Hash] Slug result with :folder_slug and :file_slug
        def generate_slugs(task_title, metadata, dry_run:)
          if dry_run
            { folder_slug: "preview-slug", file_slug: "preview-slug" }
          else
            slug_gen = create_slug_generator(debug: debug_mode?)
            slug_gen.generate_task_slugs(task_title, metadata)
          end
        end

        # Build orchestrator content from task data (minimal auto-generated)
        # @param task [Hash] Task data with :title, :status, :priority, :metadata
        # @param orchestrator_id [String] ID for the orchestrator
        # @param subtask_title [String] Title of the first subtask
        # @return [String] Orchestrator file content
        def build_orchestrator_content(task:, orchestrator_id:, subtask_title:)
          frontmatter = {
            "id" => orchestrator_id,
            "status" => task[:status] || "draft",
            "priority" => task[:priority] || "medium"
          }

          # Copy dependencies if present
          if task[:dependencies] && !task[:dependencies].empty?
            frontmatter["dependencies"] = task[:dependencies]
          end

          # Copy estimate if present
          if task[:metadata] && task[:metadata]["estimate"]
            frontmatter["estimate"] = task[:metadata]["estimate"]
          end

          yaml_content = frontmatter.to_yaml.sub(/\A---\n?/, "")

          body = <<~BODY

            # #{task[:title] || 'Orchestrator'}

            ## Overview

            [Add orchestrator scope and overview]

            ## Subtasks

            - **01**: #{subtask_title}
          BODY

          "---\n#{yaml_content}---\n#{body}"
        end

        # Update frontmatter fields using YAML parsing for reliable manipulation
        # @param content [String] File content with YAML frontmatter
        # @param updates [Hash] Fields to add/update (string keys)
        # @param remove [Array<String>] Fields to remove
        # @return [String] Updated content
        def update_frontmatter(content, updates: {}, remove: [])
          # Extract frontmatter and body
          result = Ace::Support::Markdown::Atoms::FrontmatterExtractor.extract(content)

          unless result[:valid]
            # If YAML parsing fails, fall back to original content
            return content
          end

          frontmatter = result[:frontmatter]
          body = result[:body]

          # Apply updates
          updates.each { |key, value| frontmatter[key.to_s] = value }

          # Remove specified fields
          remove.each { |key| frontmatter.delete(key.to_s) }

          # Rebuild content with ordered frontmatter
          rebuild_content_with_frontmatter(frontmatter, body)
        end

        # Rebuild content with ordered frontmatter
        # @param frontmatter [Hash] Frontmatter data
        # @param body [String] Body content
        # @return [String] Rebuilt content
        def rebuild_content_with_frontmatter(frontmatter, body)
          # Define preferred key order for readability
          key_order = %w[id status priority estimate dependencies parent subtasks]

          ordered_fm = {}
          key_order.each do |key|
            ordered_fm[key] = frontmatter[key] if frontmatter.key?(key)
          end
          # Add remaining keys not in preferred order
          frontmatter.each do |key, value|
            ordered_fm[key] = value unless ordered_fm.key?(key)
          end

          # Use YAML dump and clean up the output
          yaml_output = ordered_fm.to_yaml
          # Remove the leading "---\n" from YAML output (we'll add our own)
          yaml_content = yaml_output.sub(/\A---\n?/, "")

          "---\n#{yaml_content}---\n#{body}"
        end

        # Clean up backup files for a subtask's directory
        # Reuses TaskDirectoryMover's cleanup logic
        # @param subtask_path [String] Path to the subtask file
        def cleanup_subtask_backup_files(subtask_path)
          return unless subtask_path

          task_dir = File.dirname(subtask_path)
          return unless File.directory?(task_dir)

          Dir.glob(File.join(task_dir, "**", "*.backup.*")).each do |backup_file|
            File.delete(backup_file) if File.file?(backup_file)
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
