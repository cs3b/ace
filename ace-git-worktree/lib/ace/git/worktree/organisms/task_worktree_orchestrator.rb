# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Organisms
        # Task worktree orchestrator
        #
        # Orchestrates the complete workflow of creating task-aware worktrees,
        # including task status updates, metadata tracking, commits, and mise trust.
        # This is the main high-level interface for task-worktree integration.
        #
        # @example Create a complete task worktree workflow
        #   orchestrator = TaskWorktreeOrchestrator.new
        #   result = orchestrator.create_for_task("081")
        #   # => { success: true, worktree_path: "/project/.ace-wt/task.081", ... }
        class TaskWorktreeOrchestrator
          # Initialize a new TaskWorktreeOrchestrator
          #
          # @param config [WorktreeConfig, nil] Worktree configuration (loaded if nil)
          # @param project_root [String] Project root directory
          def initialize(config: nil, project_root: Dir.pwd)
            @project_root = project_root
            @config = config || load_configuration
            @task_fetcher = Molecules::TaskFetcher.new
            @task_status_updater = Molecules::TaskStatusUpdater.new
            @task_committer = Molecules::TaskCommitter.new
            @worktree_creator = Molecules::WorktreeCreator.new
          end

          # Create a worktree for a task with complete workflow
          #
          # @param task_ref [String] Task reference (081, task.081, v.0.9.0+081)
          # @param options [Hash] Options for worktree creation
          # @return [Hash] Result with workflow details
          #
          # @example
          #   orchestrator = TaskWorktreeOrchestrator.new
          #   result = orchestrator.create_for_task("081")
          #   # => {
          #   #   success: true,
          #   #   worktree_path: "/project/.ace-wt/task.081",
          #   #   branch: "081-fix-authentication-bug",
          #   #   task_id: "081",
          #   #   steps_completed: ["task_fetched", "status_updated", "worktree_created", "mise_trusted"],
          #   #   error: nil
          #   # }
          def create_for_task(task_ref, options = {})
            workflow_result = initialize_workflow_result

            begin
              # Step 1: Fetch task data
              task_data = fetch_task_data(task_ref)
              return error_workflow_result("Task not found: #{task_ref}", workflow_result) unless task_data

              task_id = extract_task_id(task_data)
              workflow_result[:task_id] = task_id
              workflow_result[:task_title] = task_data[:title]
              workflow_result[:steps_completed] << "task_fetched"

              # Step 2: Check if worktree already exists
              existing_worktree = check_existing_worktree(task_data)
              if existing_worktree
                return success_workflow_result("Worktree already exists", workflow_result.merge(
                  worktree_path: existing_worktree.path,
                  branch: existing_worktree.branch,
                  existing: true
                ))
              end

              # Step 3: Update task status if configured (and not overridden)
              should_update_status = options[:no_status_update] ? false : @config.auto_mark_in_progress?
              if should_update_status && task_data[:status] != "in-progress"
                if update_task_status(task_id, "in-progress")
                  workflow_result[:steps_completed] << "status_updated"
                else
                  return error_workflow_result("Failed to update task status", workflow_result)
                end
              end

              # Step 4: Create worktree metadata
              worktree_metadata = create_worktree_metadata(task_data)
              workflow_result[:steps_completed] << "metadata_prepared"

              # Step 5: Commit task changes if configured (and not overridden)
              should_commit = options[:no_commit] ? false : @config.auto_commit_task?
              if should_commit && should_update_status
                commit_message = options[:commit_message] || "in-progress"
                if commit_task_changes(task_data, commit_message)
                  workflow_result[:steps_completed] << "task_committed"
                else
                  # Continue even if commit fails, but note it
                  workflow_result[:warnings] << "Failed to commit task changes"
                end
              end

              # Step 6: Create the worktree
              worktree_result = create_worktree_for_task(task_data, worktree_metadata)
              return error_workflow_result(worktree_result[:error], workflow_result) unless worktree_result[:success]

              workflow_result[:worktree_path] = worktree_result[:worktree_path]
              workflow_result[:branch] = worktree_result[:branch]
              workflow_result[:directory_name] = worktree_result[:directory_name]
              workflow_result[:steps_completed] << "worktree_created"

              # Step 7: Add worktree metadata to task file
              if @config.add_worktree_metadata?
                if add_worktree_metadata_to_task(task_data, worktree_metadata)
                  workflow_result[:steps_completed] << "metadata_added"
                else
                  workflow_result[:warnings] << "Failed to add worktree metadata to task"
                end
              end

              # Step 8: Run after-create hooks if configured
              hooks = @config.after_create_hooks
              if hooks && hooks.any?
                require_relative "../molecules/hook_executor"
                hook_executor = Molecules::HookExecutor.new
                hook_result = hook_executor.execute_hooks(
                  hooks,
                  worktree_path: worktree_result[:worktree_path],
                  project_root: @project_root,
                  task_data: task_data
                )

                if hook_result[:success]
                  workflow_result[:steps_completed] << "hooks_executed"
                  workflow_result[:hooks_results] = hook_result[:results]
                else
                  # Hooks are non-blocking - failures become warnings
                  workflow_result[:warnings] ||= []
                  workflow_result[:warnings] += hook_result[:errors]
                  workflow_result[:hooks_results] = hook_result[:results]
                end
              end

              # Success!
              success_workflow_result("Task worktree created successfully", workflow_result)
            rescue StandardError => e
              error_workflow_result("Unexpected error: #{e.message}", workflow_result)
            end
          end

          # Create a worktree with dry run (no actual changes)
          #
          # @param task_ref [String] Task reference
          # @param options [Hash] Options for dry run
          # @return [Hash] Dry run result showing what would be done
          #
          # @example
          #   result = orchestrator.dry_run_create("081")
          #   # => { success: true, would_create: {...}, steps: [...] }
          def dry_run_create(task_ref, options = {})
            workflow_result = initialize_workflow_result

            begin
              # Step 1: Fetch task data
              task_data = fetch_task_data(task_ref)
              return error_workflow_result("Task not found: #{task_ref}", workflow_result) unless task_data

              task_id = extract_task_id(task_data)
              workflow_result[:task_id] = task_id
              workflow_result[:task_title] = task_data[:title]
              workflow_result[:steps_completed] << "task_fetched"

              # Step 2: Check what would be created
              directory_name = @config.format_directory(task_data)
              branch_name = @config.format_branch(task_data)
              worktree_path = File.join(@config.absolute_root_path, directory_name)

              workflow_result[:would_create] = {
                worktree_path: worktree_path,
                branch: branch_name,
                directory_name: directory_name,
                task_status_update: @config.auto_mark_in_progress? && task_data[:status] != "in-progress",
                task_commit: @config.auto_commit_task?,
                metadata_addition: @config.add_worktree_metadata?,
                hooks_count: @config.after_create_hooks.length
              }

              workflow_result[:steps_planned] = [
                "fetch_task_data",
                ("update_task_status" if workflow_result[:would_create][:task_status_update]),
                ("commit_task_changes" if workflow_result[:would_create][:task_commit]),
                "create_worktree",
                ("add_worktree_metadata" if workflow_result[:would_create][:metadata_addition]),
                ("execute_#{workflow_result[:would_create][:hooks_count]}_hooks" if workflow_result[:would_create][:hooks_count] > 0)
              ].compact

              success_workflow_result("Dry run completed", workflow_result)
            rescue StandardError => e
              error_workflow_result("Dry run error: #{e.message}", workflow_result)
            end
          end

          # Remove a task worktree with cleanup
          #
          # @param task_ref [String] Task reference
          # @param options [Hash] Options for removal
          # @return [Hash] Result of removal workflow
          #
          # @example
          #   result = orchestrator.remove_task_worktree("081", force: true)
          def remove_task_worktree(task_ref, options = {})
            workflow_result = initialize_workflow_result

            begin
              # Step 1: Fetch task data
              task_data = fetch_task_data(task_ref)

              # Step 2: Find existing worktree (with fallback for missing task)
              if task_data
                task_id = extract_task_id(task_data)
                workflow_result[:task_id] = task_id
                workflow_result[:steps_completed] << "task_fetched"
                worktree_info = find_worktree_for_task_data(task_data)
              else
                # Fallback: Try to find worktree by task reference even if task data not found
                worktree_info = find_worktree_by_task_reference(task_ref)
                if worktree_info
                  puts "Task not found, but worktree found. Removing worktree without updating task data."
                  workflow_result[:task_id] = task_ref
                  workflow_result[:task_not_found] = true
                else
                  return error_workflow_result("Task not found: #{task_ref}", workflow_result)
                end
              end

              return error_workflow_result("No worktree found for task", workflow_result) unless worktree_info

              workflow_result[:worktree_path] = worktree_info.path
              workflow_result[:branch] = worktree_info.branch

              # Step 3: Check removal safety
              worktree_remover = Molecules::WorktreeRemover.new
              safety_check = worktree_remover.check_removal_safety(worktree_info.path)
              unless options[:force] || safety_check[:safe]
                return error_workflow_result("Cannot remove worktree: #{safety_check[:errors].join(', ')}", workflow_result)
              end

              # Step 4: Remove worktree metadata from task (only if task was found)
              if task_data && remove_worktree_metadata_from_task(task_data)
                workflow_result[:steps_completed] << "metadata_removed"
              elsif workflow_result[:task_not_found]
                workflow_result[:steps_completed] << "skipped_metadata_cleanup"
              end

              # Step 5: Remove the worktree
              remove_result = worktree_remover.remove(worktree_info.path, force: options[:force])
              return error_workflow_result("Failed to remove worktree: #{remove_result[:error]}", workflow_result) unless remove_result[:success]

              workflow_result[:steps_completed] << "worktree_removed"

              success_workflow_result("Task worktree removed successfully", workflow_result)
            rescue StandardError => e
              error_workflow_result("Unexpected error: #{e.message}", workflow_result)
            end
          end

          # Get status of task worktrees
          #
          # @param task_refs [Array<String>, nil] Task references to check (all if nil)
          # @return [Hash] Status information
          #
          # @example
          #   status = orchestrator.get_task_worktree_status(["081", "082"])
          def get_task_worktree_status(task_refs = nil)
            begin
              if task_refs.nil?
                # Get all task-associated worktrees
                worktree_lister = Molecules::WorktreeLister.new
                worktrees = worktree_lister.list_all.select(&:task_associated?)
                task_ids = worktrees.map(&:task_id).compact.uniq
              else
                task_ids = Array(task_refs).map { |ref| ref.to_s.match(/(\d+)/)[1] }.compact
              end

              status_info = {
                total_tasks: task_ids.length,
                worktrees: []
              }

              task_ids.each do |task_id|
                worktree_info = @worktree_creator.find_by_task_id(task_id)
                task_metadata = @task_fetcher.fetch(task_id)

                worktree_status = {
                  task_id: task_id,
                  task_title: task_metadata&.title,
                  task_status: task_metadata&.status,
                  has_worktree: !worktree_info.nil?,
                  worktree_path: worktree_info&.path,
                  worktree_branch: worktree_info&.branch,
                  worktree_exists: worktree_info&.exists?,
                  worktree_usable: worktree_info&.usable?
                }

                status_info[:worktrees] << worktree_status
              end

              status_info[:worktrees_with_worktrees] = status_info[:worktrees].count { |w| w[:has_worktree] }
              status_info[:active_worktrees] = status_info[:worktrees].count { |w| w[:worktree_exists] && w[:worktree_usable] }

              { success: true, status: status_info }
            rescue StandardError => e
              error_result("Failed to get task worktree status: #{e.message}")
            end
          end

          private

          # Find worktree by task reference (fallback when task metadata not found)
          #
          # @param task_ref [String] Task reference (e.g., "090", "task.090")
          # @return [WorktreeInfo, nil] Worktree info or nil if not found
          def find_worktree_by_task_reference(task_ref)
            # Get all worktrees using WorktreeLister
            worktree_lister = Molecules::WorktreeLister.new
            worktrees = worktree_lister.list_all

            # Normalize task reference to match worktree IDs
            normalized_id = normalize_task_id_for_matching(task_ref)

            # Find worktree with matching task ID
            worktrees.find do |worktree|
              worktree.task_id == normalized_id
            end
          end

          # Normalize task ID for worktree matching
          #
          # @param task_ref [String] Task reference
          # @return [String] Normalized task ID
          def normalize_task_id_for_matching(task_ref)
            # Handle various formats: "090", "task.090", "v.0.9.0+task.090"
            if task_ref.match?(/\A(\d+)\z/)
              task_ref # Already numeric
            elsif task_ref.match?(/\Atask\.?(\d+)\z/)
              task_ref.match(/\Atask\.?(\d+)\z/)[1]
            elsif task_ref.match?(/\Av\.[\d.]+\+task\.(\d+)\z/)
              task_ref.match(/\Av\.[\d.]+\+task\.(\d+)\z/)[1]
            else
              # Try to extract numeric part
              task_ref.scan(/\d+/).last || task_ref
            end
          end

          # Initialize workflow result structure
          #
          # @return [Hash] Initial workflow result
          def initialize_workflow_result
            {
              success: false,
              task_id: nil,
              task_title: nil,
              worktree_path: nil,
              branch: nil,
              directory_name: nil,
              steps_completed: [],
              steps_planned: [],
              warnings: [],
              error: nil,
              existing: false
            }
          end

          # Load configuration
          #
          # @return [WorktreeConfig] Loaded configuration
          def load_configuration
            loader = Molecules::ConfigLoader.new(@project_root)
            loader.load
          end

          # Fetch task data
          #
          # @param task_ref [String] Task reference
          # @return [Hash, nil] Task data hash or nil
          def fetch_task_data(task_ref)
            @task_fetcher.fetch(task_ref)
          end

          # Check if worktree already exists for task
          #
          # @param task_data [Hash] Task data hash
          # @return [WorktreeInfo, nil] Existing worktree or nil
          def check_existing_worktree(task_data)
            @worktree_creator.worktree_exists?(task_data: task_data)
          end

          # Update task status
          #
          # @param task_id [String] Task ID
          # @param status [String] New status
          # @return [Boolean] true if successful
          def update_task_status(task_id, status)
            @task_status_updater.update_status(task_id, status)
          end

          # Create worktree metadata
          #
          # @param task_data [Hash] Task data hash from ace-taskflow
          # @return [WorktreeMetadata] Worktree metadata
          def create_worktree_metadata(task_data)
            # Generate worktree path and branch names
            directory_name = @config.format_directory(task_data)
            branch_name = @config.format_branch(task_data)
            worktree_path = File.join(@config.absolute_root_path, directory_name)

            Models::WorktreeMetadata.new(
              branch: branch_name,
              path: File.join(@config.root_path, directory_name),
              created_at: Time.now
            )
          end

          # Commit task changes
          #
          # @param task_data [Hash] Task data hash from ace-taskflow
          # @param status [String] Task status
          # @return [Boolean] true if successful
          def commit_task_changes(task_data, status)
            # Find the task file (this would need implementation)
            # For now, commit all changes
            task_id = extract_task_id(task_data)
            @task_committer.commit_all_changes(status, task_id)
          end

          # Create worktree for task
          #
          # @param task_data [Hash] Task data hash from ace-taskflow
          # @param worktree_metadata [WorktreeMetadata] Worktree metadata
          # @return [Hash] Worktree creation result
          def create_worktree_for_task(task_data, worktree_metadata)
            @worktree_creator.create_for_task(task_data, @config)
          end

          # Add worktree metadata to task
          #
          # @param task_data [Hash] Task data hash from ace-taskflow
          # @param worktree_metadata [WorktreeMetadata] Worktree metadata
          # @return [Boolean] true if successful
          def add_worktree_metadata_to_task(task_data, worktree_metadata)
            # Try to use ace-taskflow update command first
            task_id = extract_task_id(task_data)
            if @task_status_updater.add_worktree_metadata(task_id, worktree_metadata)
              return true
            end

            # Fallback to direct file manipulation
            # This would need implementation to find and update the task file
            false
          end

          # Find worktree for task
          #
          # @param task_data [Hash] Task data hash from ace-taskflow
          # @return [WorktreeInfo, nil] Worktree info or nil
          def find_worktree_for_task_data(task_data)
            task_id = extract_task_id(task_data)
            @worktree_creator.find_by_task_id(task_id)
          end

          # Remove worktree metadata from task
          #
          # @param task_data [Hash] Task data hash from ace-taskflow
          # @return [Boolean] true if successful
          def remove_worktree_metadata_from_task(task_data)
            # This would need implementation to find and update the task file
            false
          end

          # Create success workflow result
          #
          # @param message [String] Success message
          # @param workflow_result [Hash] Workflow result to update
          # @return [Hash] Updated workflow result
          def success_workflow_result(message, workflow_result)
            workflow_result.merge(
              success: true,
              message: message
            )
          end

          # Create error workflow result
          #
          # @param error_message [String] Error message
          # @param workflow_result [Hash] Workflow result to update
          # @return [Hash] Updated workflow result
          def error_workflow_result(error_message, workflow_result)
            workflow_result.merge(
              success: false,
              error: error_message
            )
          end

          # Extract task ID from task data
          #
          # @param task_data [Hash] Task data hash
          # @return [String] Task ID (e.g., "094")
          def extract_task_id(task_data)
            # Use task_number if available, otherwise extract from id
            return task_data[:task_number] if task_data[:task_number]

            # Extract from id field (e.g., "v.0.9.0+task.094" -> "094")
            if task_data[:id]
              match = task_data[:id].match(/task\.(\d+)$/)
              return match[1] if match
            end

            "unknown"
          end

          # Create error result
          #
          # @param message [String] Error message
          # @return [Hash] Error result
          def error_result(message)
            {
              success: false,
              error: message
            }
          end
        end
      end
    end
  end
end