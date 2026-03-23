# frozen_string_literal: true

require_relative "../atoms/task_id_extractor"
require_relative "../molecules/current_task_linker"
require_relative "../molecules/parent_task_resolver"

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
            @task_pusher = Molecules::TaskPusher.new
            @worktree_creator = Molecules::WorktreeCreator.new
            @pr_creator = Molecules::PrCreator.new
            @parent_task_resolver = Molecules::ParentTaskResolver.new(project_root: project_root)
          end

          # Create a worktree for a task with complete workflow
          #
          # @param task_ref [String] Task reference (081, task.081, v.0.9.0+081)
          # @param options [Hash] Options for worktree creation
          # @option options [String] :source Git ref to use as branch start-point (default: current branch)
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
          #
          # @example With explicit source
          #   result = orchestrator.create_for_task("081", source: "main")
          #   # => Creates branch based on 'main' instead of current branch
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
                status_result = update_task_status(task_id, "in-progress")
                if status_result[:success]
                  workflow_result[:steps_completed] << "status_updated"
                else
                  error_message = status_result[:message] || "Failed to update task status"
                  hint = "\n\nHint: Use --no-status-update to create worktree without changing task status"
                  return error_workflow_result(error_message + hint, workflow_result)
                end
              end

              # Step 4: Create worktree metadata
              # Determine target branch for PR (parent's branch for subtasks, or main)
              target_branch = resolve_target_branch(task_data, options)
              workflow_result[:target_branch] = target_branch
              worktree_metadata = create_worktree_metadata(task_data, target_branch: target_branch)
              workflow_result[:steps_completed] << "metadata_prepared"

              # Step 5: Add worktree metadata to task file (BEFORE commit so it's included)
              if @config.add_worktree_metadata?
                if add_worktree_metadata_to_task(task_data, worktree_metadata)
                  workflow_result[:steps_completed] << "metadata_added"
                else
                  workflow_result[:warnings] << "Failed to add worktree metadata to task"
                end
              end

              # Step 6: Commit task changes if configured (includes status + metadata)
              # Commit when either status was updated or metadata was added
              should_commit = options[:no_commit] ? false : @config.auto_commit_task?
              metadata_was_added = workflow_result[:steps_completed].include?("metadata_added")
              has_changes_to_commit = should_update_status || metadata_was_added
              if should_commit && has_changes_to_commit
                commit_message = options[:commit_message] || "in-progress"
                if commit_task_changes(task_data, commit_message)
                  workflow_result[:steps_completed] << "task_committed"
                else
                  # Continue even if commit fails, but note it
                  workflow_result[:warnings] << "Failed to commit task changes"
                end
              end

              # Step 7: Push task changes if configured (so PR shows updates)
              should_push = options[:no_push] ? false : @config.auto_push_task?
              if should_push && should_commit && workflow_result[:steps_completed].include?("task_committed")
                push_remote = options[:push_remote] || @config.push_remote
                if push_task_changes(push_remote)
                  workflow_result[:steps_completed] << "task_pushed"
                  workflow_result[:pushed_to] = push_remote
                else
                  # Continue even if push fails, but note it
                  workflow_result[:warnings] << "Failed to push task changes"
                end
              end

              # Step 8: Create the worktree
              worktree_result = create_worktree_for_task(task_data, worktree_metadata, source: options[:source])
              return error_workflow_result(worktree_result[:error], workflow_result) unless worktree_result[:success]

              workflow_result[:worktree_path] = worktree_result[:worktree_path]
              workflow_result[:branch] = worktree_result[:branch]
              workflow_result[:directory_name] = worktree_result[:directory_name]
              workflow_result[:start_point] = worktree_result[:start_point]
              workflow_result[:steps_completed] << "worktree_created"

              # Step 8.5: Create _current symlink in worktree if configured
              if @config.create_current_symlink?
                current_linker = Molecules::CurrentTaskLinker.new(
                  project_root: worktree_result[:worktree_path],
                  symlink_name: @config.current_symlink_name
                )
                # Task directory relative to worktree (same structure as main repo)
                # task_data[:path] is the task file path, we need the parent directory
                worktree_task_dir = File.dirname(File.join(worktree_result[:worktree_path], relative_task_path(task_data[:path])))
                link_result = current_linker.link(worktree_task_dir)
                if link_result[:success]
                  workflow_result[:steps_completed] << "current_symlink_created"
                  workflow_result[:current_symlink] = link_result[:symlink_path]
                else
                  # Symlink creation is non-blocking - failure becomes warning
                  workflow_result[:warnings] ||= []
                  workflow_result[:warnings] << "Failed to create _current symlink: #{link_result[:error]}"
                end
              end

              # Step 9: Setup upstream for worktree branch if configured
              should_setup_upstream = @config.auto_setup_upstream? && !options[:no_upstream]
              if should_setup_upstream
                upstream_result = setup_upstream_for_worktree(worktree_result, options)
                if upstream_result[:success]
                  workflow_result[:steps_completed] << "upstream_setup"
                  workflow_result[:pushed_branch] = upstream_result[:branch]
                else
                  # Upstream setup is non-blocking - failure becomes warning
                  workflow_result[:warnings] ||= []
                  workflow_result[:warnings] << "Failed to setup upstream: #{upstream_result[:error]}"
                end
              end

              # Step 9.5: Add started_at timestamp to task IN WORKTREE (creates initial commit for PR)
              # Only do this if we're going to create a PR and upstream succeeded
              upstream_succeeded = workflow_result[:steps_completed].include?("upstream_setup")
              should_create_pr = @config.auto_create_pr? && !options[:no_pr]
              if should_create_pr && upstream_succeeded
                started_result = add_started_timestamp_in_worktree(task_data, worktree_result, options)
                if started_result[:success]
                  workflow_result[:steps_completed] << "started_at_added"
                else
                  # Non-blocking - PR creation may still work if branch already has commits
                  workflow_result[:warnings] ||= []
                  workflow_result[:warnings] << "Failed to add started_at: #{started_result[:error]}"
                end
              end

              # Step 10: Create draft PR if configured
              if should_create_pr && upstream_succeeded
                pr_result = create_pr_for_task(task_data, worktree_result, options)
                if pr_result[:success]
                  workflow_result[:steps_completed] << "pr_created"
                  workflow_result[:pr_number] = pr_result[:pr_number]
                  workflow_result[:pr_url] = pr_result[:pr_url]
                  workflow_result[:pr_existing] = pr_result[:existing]

                  # Step 11: Save PR metadata to task
                  save_pr_result = save_pr_to_task(task_data, pr_result)
                  if save_pr_result
                    workflow_result[:steps_completed] << "pr_saved_to_task"
                  else
                    workflow_result[:warnings] ||= []
                    workflow_result[:warnings] << "Failed to save PR metadata to task"
                  end
                else
                  # PR creation is non-blocking - failure becomes warning
                  workflow_result[:warnings] ||= []
                  workflow_result[:warnings] << "Failed to create PR: #{pr_result[:error]}"
                end
              elsif should_create_pr && !upstream_succeeded
                # Skip PR creation if upstream setup failed
                workflow_result[:warnings] ||= []
                workflow_result[:warnings] << "Skipped PR creation: branch not pushed to remote"
              end

              # Step 12: Run after-create hooks if configured
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
            rescue => e
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
              options[:source] || "main"

              # Determine target branch for PR (parent's branch for subtasks, or main)
              target_branch = resolve_target_branch(task_data, options)

              # Determine upstream/PR settings (considering options)
              should_setup_upstream = @config.auto_setup_upstream? && !options[:no_upstream]
              should_create_pr = @config.auto_create_pr? && !options[:no_pr] && should_setup_upstream

              # Determine if there will be changes to commit
              # Commit when either status would be updated or metadata would be added
              would_update_status = @config.auto_mark_in_progress? && task_data[:status] != "in-progress"
              would_add_metadata = @config.add_worktree_metadata?
              has_changes_to_commit = would_update_status || would_add_metadata
              would_commit = @config.auto_commit_task? && has_changes_to_commit

              # Determine if current symlink would be created (in worktree)
              would_create_current_symlink = @config.create_current_symlink?
              current_symlink_path = would_create_current_symlink ? File.join(worktree_path, @config.current_symlink_name) : nil
              # Task directory relative to worktree (same structure as main repo)
              # task_data[:path] is the task file path, we need the parent directory
              relative_task = would_create_current_symlink ? relative_task_path(task_data[:path]) : nil
              worktree_task_dir = would_create_current_symlink ? File.dirname(File.join(worktree_path, relative_task)) : nil

              workflow_result[:would_create] = {
                worktree_path: worktree_path,
                branch: branch_name,
                directory_name: directory_name,
                target_branch: target_branch,
                task_status_update: would_update_status,
                metadata_addition: would_add_metadata,
                task_commit: would_commit,
                task_push: @config.auto_push_task? && would_commit,
                push_remote: @config.push_remote,
                current_symlink: would_create_current_symlink,
                current_symlink_path: current_symlink_path,
                current_symlink_target: worktree_task_dir,
                upstream_push: should_setup_upstream,
                add_started_at: should_create_pr && should_setup_upstream,
                create_pr: should_create_pr,
                pr_title: should_create_pr ? @config.format_pr_title(task_data) : nil,
                pr_base: should_create_pr ? target_branch : nil,
                hooks_count: @config.after_create_hooks.length
              }

              workflow_result[:steps_planned] = [
                "fetch_task_data",
                ("update_task_status" if workflow_result[:would_create][:task_status_update]),
                ("add_worktree_metadata" if workflow_result[:would_create][:metadata_addition]),
                ("commit_task_changes" if workflow_result[:would_create][:task_commit]),
                ("push_to_#{workflow_result[:would_create][:push_remote]}" if workflow_result[:would_create][:task_push]),
                "create_worktree",
                ("create_current_symlink" if workflow_result[:would_create][:current_symlink]),
                ("setup_upstream_tracking" if should_setup_upstream),
                ("add_started_at_in_worktree" if workflow_result[:would_create][:add_started_at]),
                ("create_draft_pr" if should_create_pr),
                ("save_pr_metadata" if should_create_pr),
                ("execute_#{workflow_result[:would_create][:hooks_count]}_hooks" if workflow_result[:would_create][:hooks_count] > 0)
              ].compact

              success_workflow_result("Dry run completed", workflow_result)
            rescue => e
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
                return error_workflow_result("Cannot remove worktree: #{safety_check[:errors].join(", ")}", workflow_result)
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
            rescue => e
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
            if task_refs.nil?
              # Get all task-associated worktrees
              worktree_lister = Molecules::WorktreeLister.new
              worktrees = worktree_lister.list_all.select(&:task_associated?)
              task_ids = worktrees.map(&:task_id).compact.uniq
            else
              task_ids = Array(task_refs).map { |ref| Atoms::TaskIDExtractor.normalize(ref) }.compact
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

            {success: true, status: status_info}
          rescue => e
            error_result("Failed to get task worktree status: #{e.message}")
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
          # @param task_ref [String] Task reference (e.g., "090", "121.01", "task.121.01")
          # @return [String] Normalized task ID (preserves subtask suffix)
          def normalize_task_id_for_matching(task_ref)
            # Use shared extractor that preserves subtask IDs (e.g., "121.01")
            Atoms::TaskIDExtractor.normalize(task_ref) || task_ref
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

          # Resolve target branch for PR
          #
          # Uses CLI-provided target_branch if present, otherwise auto-detects from parent task.
          # For subtasks, returns parent's worktree branch. For orchestrators, returns "main".
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @param options [Hash] Options hash (may contain :target_branch)
          # @return [String] Target branch name
          def resolve_target_branch(task_data, options)
            options[:target_branch] || @parent_task_resolver.resolve_target_branch(task_data)
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
          # @return [Hash] Result with :success and :message keys
          def update_task_status(task_id, status)
            @task_status_updater.update_status(task_id, status)
          end

          # Create worktree metadata
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @param target_branch [String, nil] PR target branch (for subtasks)
          # @return [WorktreeMetadata] Worktree metadata
          def create_worktree_metadata(task_data, target_branch: nil)
            # Generate worktree path and branch names
            directory_name = @config.format_directory(task_data)
            branch_name = @config.format_branch(task_data)
            File.join(@config.absolute_root_path, directory_name)

            Models::WorktreeMetadata.new(
              branch: branch_name,
              path: File.join(@config.root_path, directory_name),
              target_branch: target_branch,
              created_at: Time.now
            )
          end

          # Commit task changes
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @param status [String] Task status
          # @return [Boolean] true if successful
          def commit_task_changes(task_data, status)
            # Find the task file (this would need implementation)
            # For now, commit all changes
            task_id = extract_task_id(task_data)
            @task_committer.commit_all_changes(status, task_id)
          end

          # Push task changes to remote
          #
          # @param remote [String] Remote name (default: "origin")
          # @return [Boolean] true if successful
          def push_task_changes(remote = "origin")
            result = @task_pusher.push(remote: remote)
            result[:success]
          end

          # Create worktree for task
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @param worktree_metadata [WorktreeMetadata] Worktree metadata
          # @param source [String, nil] Git ref to use as branch start-point
          # @return [Hash] Worktree creation result
          def create_worktree_for_task(task_data, worktree_metadata, source: nil)
            @worktree_creator.create_for_task(
              task_data,
              @config,
              source: source,
              target_branch: worktree_metadata.target_branch
            )
          end

          # Add worktree metadata to task
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @param worktree_metadata [WorktreeMetadata] Worktree metadata
          # @return [Boolean] true if successful
          def add_worktree_metadata_to_task(task_data, worktree_metadata)
            # Try to use ace-task update command first
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
          # @param task_data [Hash] Task data hash from ace-task
          # @return [WorktreeInfo, nil] Worktree info or nil
          def find_worktree_for_task_data(task_data)
            task_id = extract_task_id(task_data)
            @worktree_creator.find_by_task_id(task_id)
          end

          # Remove worktree metadata from task
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @return [Boolean] true if successful
          def remove_worktree_metadata_from_task(task_data)
            # This would need implementation to find and update the task file
            false
          end

          # Setup upstream tracking for worktree branch
          #
          # Pushes the new branch to remote with -u flag to setup upstream tracking.
          # If push fails but remote branch exists, falls back to git branch --set-upstream-to.
          # Uses the worktree path to run git commands from within the worktree.
          #
          # @param worktree_result [Hash] Worktree creation result with :worktree_path, :branch
          # @param options [Hash] Options hash (may include :push_remote)
          # @return [Hash] Result with :success, :branch, :remote, :error, :method
          def setup_upstream_for_worktree(worktree_result, options)
            worktree_path = worktree_result[:worktree_path]
            branch = worktree_result[:branch]
            remote = options[:push_remote] || @config.push_remote || "origin"

            begin
              Dir.chdir(worktree_path) do
                # Try push with -u first
                result = @task_pusher.push(remote: remote, set_upstream: true)

                if result[:success]
                  return {
                    success: true,
                    branch: branch,
                    remote: remote,
                    error: nil,
                    method: :push
                  }
                end

                # Push failed - check if remote branch exists and set upstream directly
                if remote_branch_exists?(remote, branch)
                  upstream_result = @task_pusher.set_upstream(branch: branch, remote: remote)
                  if upstream_result[:success]
                    return {
                      success: true,
                      branch: branch,
                      remote: remote,
                      error: nil,
                      method: :set_upstream
                    }
                  end
                end

                # Both methods failed
                {
                  success: false,
                  branch: branch,
                  remote: remote,
                  error: result[:error] || "Failed to setup upstream"
                }
              end
            rescue => e
              {
                success: false,
                branch: branch,
                remote: remote,
                error: e.message
              }
            end
          end

          # Check if a branch exists on the remote
          #
          # @param remote [String] Remote name (e.g., "origin")
          # @param branch [String] Branch name to check
          # @return [Boolean] true if remote branch exists
          def remote_branch_exists?(remote, branch)
            result = Atoms::GitCommand.execute("ls-remote", "--heads", remote, branch, timeout: 10)
            result[:success] && result[:output]&.include?(branch)
          end

          # Create draft PR for task
          #
          # Creates a draft PR targeting the source branch (start_point) from which
          # the worktree branch was created.
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @param worktree_result [Hash] Worktree creation result with :branch, :start_point
          # @param options [Hash] Options (may include :source for base branch override)
          # @return [Hash] Result with :success, :pr_number, :pr_url, :existing, :error
          def create_pr_for_task(task_data, worktree_result, options)
            branch = worktree_result[:branch]
            # Use target_branch from metadata if available (for subtasks)
            # Otherwise fall back to source option or start_point
            start_point = worktree_result[:target_branch] || options[:source] || worktree_result[:start_point]
            title = @config.format_pr_title(task_data)

            # Resolve base branch - handle SHA vs branch name
            base = resolve_pr_base(start_point, options)

            # Create draft PR
            @pr_creator.create_draft(
              branch: branch,
              base: base,
              title: title
            )
          end

          # Resolve PR base branch from start_point
          #
          # If start_point is a commit SHA (not a branch name), creates a branch
          # on remote for that SHA to use as PR base.
          #
          # @param start_point [String, nil] Branch name or commit SHA
          # @param options [Hash] Options (may include :push_remote)
          # @return [String] Branch name to use as PR base
          def resolve_pr_base(start_point, options)
            return "main" unless start_point

            # SHA patterns: 40 hex chars (full) or 7+ hex chars (abbreviated)
            if start_point.match?(/\A[0-9a-f]{7,40}\z/i)
              # start_point is a commit SHA - create a branch on remote for it
              create_remote_branch_for_sha(start_point, options)
            else
              start_point
            end
          end

          # Create a branch on remote for a commit SHA
          #
          # @param sha [String] Commit SHA
          # @param options [Hash] Options (may include :push_remote)
          # @return [String] Branch name (either new branch or "main" on failure)
          def create_remote_branch_for_sha(sha, options)
            base_branch = "base-#{sha[0..6]}"
            remote = options[:push_remote] || @config.push_remote || "origin"

            # Push the SHA as a new branch: git push origin SHA:refs/heads/base-abc1234
            result = Atoms::GitCommand.execute("push", remote, "#{sha}:refs/heads/#{base_branch}")

            if result[:success]
              base_branch
            else
              warn "Warning: Failed to create base branch for SHA #{sha}, using 'main' as PR base"
              "main"
            end
          end

          # Save PR metadata to task file
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @param pr_result [Hash] PR creation result with :pr_number, :pr_url
          # @return [Boolean] true if successful
          def save_pr_to_task(task_data, pr_result)
            task_id = extract_task_id(task_data)

            pr_data = {
              number: pr_result[:pr_number],
              url: pr_result[:pr_url],
              created_at: Time.now
            }

            @task_status_updater.add_pr_metadata(task_id, pr_data)
          end

          # Add started_at timestamp to task file IN WORKTREE
          #
          # This creates an initial commit in the worktree branch, enabling PR creation
          # (GitHub requires at least one commit difference between branches for a PR).
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @param worktree_result [Hash] Worktree creation result with :worktree_path
          # @param options [Hash] Options (may include :push_remote)
          # @return [Hash] Result with :success, :error
          def add_started_timestamp_in_worktree(task_data, worktree_result, options)
            worktree_path = worktree_result[:worktree_path]
            task_id = extract_task_id(task_data)
            remote = options[:push_remote] || @config.push_remote || "origin"

            Dir.chdir(worktree_path) do
              # Set PROJECT_ROOT_PATH to worktree so TaskManager updates the right files
              # (otherwise it finds and updates the main project's task files)
              original_project_root = ENV["PROJECT_ROOT_PATH"]
              ENV["PROJECT_ROOT_PATH"] = worktree_path

              begin
                # Update task file with started_at
                if @task_status_updater.add_started_at_timestamp(task_id)
                  # Commit the change
                  if @task_committer.commit_all_changes("started", task_id)
                    # Push to remote
                    result = @task_pusher.push(remote: remote)
                    return result
                  else
                    return {success: false, error: "Failed to commit started_at change"}
                  end
                else
                  return {success: false, error: "Failed to update task file with started_at"}
                end
              ensure
                # Restore original PROJECT_ROOT_PATH
                if original_project_root
                  ENV["PROJECT_ROOT_PATH"] = original_project_root
                else
                  ENV.delete("PROJECT_ROOT_PATH")
                end
              end
            end
          rescue => e
            {success: false, error: e.message}
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
            # Use shared extractor that preserves subtask IDs (e.g., "121.01")
            Atoms::TaskIDExtractor.extract(task_data)
          end

          # Get relative task path from absolute path
          #
          # Extracts the relative path portion from an absolute task path.
          # E.g., "/project/.ace-task/v.0.9.0/tasks/145-feat/" -> ".ace-task/v.0.9.0/tasks/145-feat/"
          #
          # @param absolute_path [String] Absolute path to task directory
          # @return [String] Relative path from project root
          def relative_task_path(absolute_path)
            return absolute_path unless absolute_path&.start_with?("/")

            Pathname.new(absolute_path).relative_path_from(Pathname.new(@project_root)).to_s
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
