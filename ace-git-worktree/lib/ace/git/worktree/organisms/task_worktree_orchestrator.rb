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
            @task_metadata_writer = Molecules::TaskMetadataWriter.new
            @task_committer = Molecules::TaskCommitter.new
            @worktree_creator = Molecules::WorktreeCreator.new
            @mise_trustor = Molecules::MiseTrustor.new
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
              # Step 1: Fetch task metadata
              task_metadata = fetch_task_metadata(task_ref)
              return error_workflow_result("Task not found: #{task_ref}", workflow_result) unless task_metadata

              workflow_result[:task_id] = task_metadata.id
              workflow_result[:task_title] = task_metadata.title
              workflow_result[:steps_completed] << "task_fetched"

              # Step 2: Check if worktree already exists
              existing_worktree = check_existing_worktree(task_metadata)
              if existing_worktree
                return success_workflow_result("Worktree already exists", workflow_result.merge(
                  worktree_path: existing_worktree.path,
                  branch: existing_worktree.branch,
                  existing: true
                ))
              end

              # Step 3: Update task status if configured
              if @config.auto_mark_in_progress? && !task_metadata.in_progress?
                if update_task_status(task_metadata.id, "in-progress")
                  workflow_result[:steps_completed] << "status_updated"
                else
                  return error_workflow_result("Failed to update task status", workflow_result)
                end
              end

              # Step 4: Create worktree metadata
              worktree_metadata = create_worktree_metadata(task_metadata)
              workflow_result[:steps_completed] << "metadata_prepared"

              # Step 5: Commit task changes if configured
              if @config.auto_commit_task? && @config.auto_mark_in_progress?
                if commit_task_changes(task_metadata, "in-progress")
                  workflow_result[:steps_completed] << "task_committed"
                else
                  # Continue even if commit fails, but note it
                  workflow_result[:warnings] << "Failed to commit task changes"
                end
              end

              # Step 6: Create the worktree
              worktree_result = create_worktree_for_task(task_metadata, worktree_metadata)
              return error_workflow_result(worktree_result[:error], workflow_result) unless worktree_result[:success]

              workflow_result[:worktree_path] = worktree_result[:worktree_path]
              workflow_result[:branch] = worktree_result[:branch]
              workflow_result[:directory_name] = worktree_result[:directory_name]
              workflow_result[:steps_completed] << "worktree_created"

              # Step 7: Add worktree metadata to task file
              if @config.add_worktree_metadata?
                if add_worktree_metadata_to_task(task_metadata, worktree_metadata)
                  workflow_result[:steps_completed] << "metadata_added"
                else
                  workflow_result[:warnings] << "Failed to add worktree metadata to task"
                end
              end

              # Step 8: Trust mise configuration if enabled
              if @config.mise_trust_auto?
                mise_result = @mise_trustor.trust_worktree(worktree_result[:worktree_path])
                if mise_result[:success]
                  workflow_result[:steps_completed] << "mise_trusted"
                else
                  workflow_result[:warnings] << "Failed to trust mise configuration"
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
              # Step 1: Fetch task metadata
              task_metadata = fetch_task_metadata(task_ref)
              return error_workflow_result("Task not found: #{task_ref}", workflow_result) unless task_metadata

              workflow_result[:task_id] = task_metadata.id
              workflow_result[:task_title] = task_metadata.title
              workflow_result[:steps_completed] << "task_fetched"

              # Step 2: Check what would be created
              directory_name = @config.format_directory(task_metadata)
              branch_name = @config.format_branch(task_metadata)
              worktree_path = File.join(@config.absolute_root_path, directory_name)

              workflow_result[:would_create] = {
                worktree_path: worktree_path,
                branch: branch_name,
                directory_name: directory_name,
                task_status_update: @config.auto_mark_in_progress? && !task_metadata.in_progress?,
                task_commit: @config.auto_commit_task?,
                metadata_addition: @config.add_worktree_metadata?,
                mise_trust: @config.mise_trust_auto?
              }

              workflow_result[:steps_planned] = [
                "fetch_task_metadata",
                ("update_task_status" if workflow_result[:would_create][:task_status_update]),
                ("commit_task_changes" if workflow_result[:would_create][:task_commit]),
                "create_worktree",
                ("add_worktree_metadata" if workflow_result[:would_create][:metadata_addition]),
                ("trust_mise_config" if workflow_result[:would_create][:mise_trust])
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
              # Step 1: Fetch task metadata
              task_metadata = fetch_task_metadata(task_ref)
              return error_workflow_result("Task not found: #{task_ref}", workflow_result) unless task_metadata

              workflow_result[:task_id] = task_metadata.id
              workflow_result[:steps_completed] << "task_fetched"

              # Step 2: Find existing worktree
              worktree_info = find_worktree_for_task(task_metadata)
              return error_workflow_result("No worktree found for task", workflow_result) unless worktree_info

              workflow_result[:worktree_path] = worktree_info.path
              workflow_result[:branch] = worktree_info.branch

              # Step 3: Check removal safety
              safety_check = @worktree_creator.check_removal_safety(worktree_info.path)
              unless options[:force] || safety_check[:safe]
                return error_workflow_result("Cannot remove worktree: #{safety_check[:errors].join(', ')}", workflow_result)
              end

              # Step 4: Remove worktree metadata from task
              if remove_worktree_metadata_from_task(task_metadata)
                workflow_result[:steps_completed] << "metadata_removed"
              end

              # Step 5: Remove the worktree
              remove_result = @worktree_creator.remove(worktree_info.path, force: options[:force])
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
                worktrees = @worktree_creator.list_all.select(&:task_associated?)
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

          # Fetch task metadata
          #
          # @param task_ref [String] Task reference
          # @return [TaskMetadata, nil] Task metadata or nil
          def fetch_task_metadata(task_ref)
            @task_fetcher.fetch(task_ref)
          end

          # Check if worktree already exists for task
          #
          # @param task_metadata [TaskMetadata] Task metadata
          # @return [WorktreeInfo, nil] Existing worktree or nil
          def check_existing_worktree(task_metadata)
            @worktree_creator.worktree_exists?(task_metadata: task_metadata)
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
          # @param task_metadata [TaskMetadata] Task metadata
          # @return [WorktreeMetadata] Worktree metadata
          def create_worktree_metadata(task_metadata)
            # Generate worktree path and branch names
            directory_name = @config.format_directory(task_metadata)
            branch_name = @config.format_branch(task_metadata)
            worktree_path = File.join(@config.absolute_root_path, directory_name)

            Models::WorktreeMetadata.new(
              branch: branch_name,
              path: File.join(@config.root_path, directory_name),
              created_at: Time.now
            )
          end

          # Commit task changes
          #
          # @param task_metadata [TaskMetadata] Task metadata
          # @param status [String] Task status
          # @return [Boolean] true if successful
          def commit_task_changes(task_metadata, status)
            # Find the task file (this would need implementation)
            # For now, commit all changes
            @task_committer.commit_all_changes(status, task_metadata.id)
          end

          # Create worktree for task
          #
          # @param task_metadata [TaskMetadata] Task metadata
          # @param worktree_metadata [WorktreeMetadata] Worktree metadata
          # @return [Hash] Worktree creation result
          def create_worktree_for_task(task_metadata, worktree_metadata)
            @worktree_creator.create_for_task(task_metadata, @config)
          end

          # Add worktree metadata to task
          #
          # @param task_metadata [TaskMetadata] Task metadata
          # @param worktree_metadata [WorktreeMetadata] Worktree metadata
          # @return [Boolean] true if successful
          def add_worktree_metadata_to_task(task_metadata, worktree_metadata)
            # Try to use ace-taskflow update command first
            if @task_status_updater.add_worktree_metadata(task_metadata.id, worktree_metadata)
              return true
            end

            # Fallback to direct file manipulation
            # This would need implementation to find and update the task file
            false
          end

          # Find worktree for task
          #
          # @param task_metadata [TaskMetadata] Task metadata
          # @return [WorktreeInfo, nil] Worktree info or nil
          def find_worktree_for_task(task_metadata)
            @worktree_creator.find_by_task_id(task_metadata.id)
          end

          # Remove worktree metadata from task
          #
          # @param task_metadata [TaskMetadata] Task metadata
          # @return [Boolean] true if successful
          def remove_worktree_metadata_from_task(task_metadata)
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