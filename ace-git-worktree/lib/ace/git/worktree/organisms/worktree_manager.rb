# frozen_string_literal: true

require_relative "../atoms/task_id_extractor"

module Ace
  module Git
    module Worktree
      module Organisms
        # Worktree manager organism
        #
        # High-level manager for all worktree operations, providing a unified interface
        # for creating, listing, switching between, removing, and managing worktrees.
        # Integrates both task-aware and traditional worktree operations.
        #
        # @example Create a worktree
        #   manager = WorktreeManager.new
        #   result = manager.create("feature-branch")
        #
        # @example Create a task-aware worktree
        #   result = manager.create_task("081")
        #
        # @example List all worktrees
        #   worktrees = manager.list_all
        class WorktreeManager
          # Initialize a new WorktreeManager
          #
          # @param config [WorktreeConfig, nil] Worktree configuration (loaded if nil)
          # @param project_root [String] Project root directory
          def initialize(config: nil, project_root: Dir.pwd)
            @project_root = project_root

            # Initialize molecules
            @config_loader = Molecules::ConfigLoader.new(project_root)
            @config = config || load_configuration
            @worktree_creator = Molecules::WorktreeCreator.new(config: @config)
            @worktree_lister = Molecules::WorktreeLister.new
            @worktree_remover = Molecules::WorktreeRemover.new
            @task_fetcher = Molecules::TaskFetcher.new

            # Initialize orchestrator
            @task_orchestrator = Organisms::TaskWorktreeOrchestrator.new(config: @config, project_root: project_root)
          end

          # Create a traditional worktree (not task-aware)
          #
          # @param branch_name [String] Branch name
          # @param options [Hash] Options for creation
          # @return [Hash] Creation result
          #
          # @example
          #   manager = WorktreeManager.new
          #   result = manager.create("feature-branch", path: "/tmp/worktree")
          #   # => { success: true, worktree_path: "/tmp/worktree", branch: "feature-branch" }
          def create(branch_name, options = {})
            # Validate inputs
            return error_result("Branch name is required") if branch_name.nil? || branch_name.empty?

            # Check if worktree already exists
            existing = @worktree_lister.find_by_branch(branch_name)
            if existing
              return error_result("Worktree already exists for branch: #{branch_name}")
            end

            # Handle dry run
            if options[:dry_run]
              return dry_run_traditional_creation(branch_name, options)
            end

            # Create the worktree
            result = @worktree_creator.create_traditional(
              branch_name,
              options[:path],
              git_root: @project_root,
              source: options[:source]
            )

            if result[:success]
              result[:message] = "Worktree created successfully"

              # Execute after-create hooks if configured
              hooks = @config.after_create_hooks
              if hooks && hooks.any?
                require_relative "../molecules/hook_executor"
                hook_executor = Molecules::HookExecutor.new
                hook_result = hook_executor.execute_hooks(
                  hooks,
                  worktree_path: result[:worktree_path],
                  project_root: @project_root,
                  task_data: nil  # No task data for traditional worktrees
                )

                if hook_result[:success]
                  result[:hooks_results] = hook_result[:results]
                else
                  # Hooks are non-blocking - failures become warnings
                  result[:warnings] = hook_result[:errors] if hook_result[:errors]&.any?
                  result[:hooks_results] = hook_result[:results]
                end
              end
            end

            result
          rescue => e
            error_result("Unexpected error: #{e.message}")
          end

          # Create a task-aware worktree
          #
          # @param task_ref [String] Task reference
          # @param options [Hash] Options for creation
          # @return [Hash] Creation result
          #
          # @example
          #   result = manager.create_task("081")
          #   result = manager.create_task("081", dry_run: true)
          def create_task(task_ref, options = {})
            if options[:dry_run]
              @task_orchestrator.dry_run_create(task_ref, options)
            else
              @task_orchestrator.create_for_task(task_ref, options)
            end
          end

          # Create a worktree for a Pull Request
          #
          # @param pr_number [Integer] PR number
          # @param pr_data [Hash] PR data from Ace::Git::Molecules::PrMetadataFetcher
          # @param options [Hash] Options for creation
          # @return [Hash] Creation result
          #
          # @example
          #   manager = WorktreeManager.new
          #   pr_data = { number: 26, title: "Add feature", head_branch: "feature/auth" }
          #   result = manager.create_pr(26, pr_data)
          def create_pr(pr_number, pr_data, options = {})
            return error_result("PR number is required") if pr_number.nil?
            return error_result("PR data is required") if pr_data.nil?

            # Check if worktree already exists for this PR's branch
            head_branch = pr_data[:head_branch]
            existing = @worktree_lister.find_by_branch("pr-#{pr_number}") ||
              @worktree_lister.find_by_branch(head_branch)

            if existing && !options[:force]
              return error_result("Worktree already exists at: #{existing.path}")
            end

            # Handle dry run
            if options[:dry_run]
              return dry_run_pr_creation(pr_number, pr_data, options)
            end

            # Create the worktree
            result = @worktree_creator.create_for_pr(
              pr_data,
              @config,
              git_root: @project_root
            )

            if result[:success]
              result[:pr_number] = pr_number
              result[:pr_title] = pr_data[:title]
              result[:message] = "PR worktree created successfully"

              # Execute after-create hooks if configured
              hooks = @config.after_create_hooks
              if hooks && hooks.any?
                require_relative "../molecules/hook_executor"
                hook_executor = Molecules::HookExecutor.new
                hook_result = hook_executor.execute_hooks(
                  hooks,
                  worktree_path: result[:worktree_path],
                  project_root: @project_root,
                  task_data: pr_data
                )

                if hook_result[:success]
                  result[:hooks_results] = hook_result[:results]
                else
                  result[:warnings] = hook_result[:errors] if hook_result[:errors]&.any?
                  result[:hooks_results] = hook_result[:results]
                end
              end
            end

            result
          rescue => e
            error_result("Unexpected error: #{e.message}")
          end

          # Create a worktree for a branch (local or remote)
          #
          # @param branch_name [String] Branch name (e.g., "feature" or "origin/feature")
          # @param options [Hash] Options for creation
          # @return [Hash] Creation result
          #
          # @example Remote branch
          #   result = manager.create_branch("origin/feature/auth")
          #
          # @example Local branch
          #   result = manager.create_branch("my-feature")
          def create_branch(branch_name, options = {})
            return error_result("Branch name is required") if branch_name.nil? || branch_name.empty?

            # Check if worktree already exists for this branch
            # Extract just the branch name (remove remote prefix if present)
            local_branch_name = branch_name.include?("/") ? branch_name.split("/").last : branch_name
            existing = @worktree_lister.find_by_branch(local_branch_name) ||
              @worktree_lister.find_by_branch(branch_name)

            if existing && !options[:force]
              return error_result("Worktree already exists at: #{existing.path}")
            end

            # Handle dry run
            if options[:dry_run]
              return dry_run_branch_creation(branch_name, options)
            end

            # Create the worktree
            result = @worktree_creator.create_for_branch(
              branch_name,
              @config,
              git_root: @project_root
            )

            if result[:success]
              result[:message] = "Branch worktree created successfully"

              # Execute after-create hooks if configured
              hooks = @config.after_create_hooks
              if hooks && hooks.any?
                require_relative "../molecules/hook_executor"
                hook_executor = Molecules::HookExecutor.new
                hook_result = hook_executor.execute_hooks(
                  hooks,
                  worktree_path: result[:worktree_path],
                  project_root: @project_root,
                  task_data: nil
                )

                if hook_result[:success]
                  result[:hooks_results] = hook_result[:results]
                else
                  result[:warnings] = hook_result[:errors] if hook_result[:errors]&.any?
                  result[:hooks_results] = hook_result[:results]
                end
              end
            end

            result
          rescue => e
            error_result("Unexpected error: #{e.message}")
          end

          # List all worktrees
          #
          # @param options [Hash] Listing options
          # @return [Hash] Listing result
          #
          # @example
          #   result = manager.list_all
          #   result = manager.list_all(format: :json, show_tasks: true)
          #
          # @option options [Symbol] :format Output format (:table, :json, :simple)
          # @option options [Boolean] :show_tasks Include task associations
          # @option options [Boolean] :task_associated Filter by task association
          # @option options [Boolean] :usable Filter by usability
          # @option options [String] :search Filter by search pattern
          def list_all(options = {})
            task_filter_requested = !options[:task_associated].nil?

            # Get worktrees
            worktrees = if options[:show_tasks] || task_filter_requested
              @worktree_lister.list_with_tasks
            else
              @worktree_lister.list_all
            end

            # Apply filters
            if !options[:task_associated].nil? || !options[:usable].nil? || options[:search]
              worktrees = @worktree_lister.filter(
                worktrees,
                task_associated: options[:task_associated],
                usable: options[:usable],
                branch_pattern: options[:search]
              )
            end

            # Format output
            formatted_output = @worktree_lister.format_for_display(
              worktrees,
              options[:format] || :table
            )

            # Get statistics
            stats = @worktree_lister.get_statistics(worktrees)

            {
              success: true,
              worktrees: worktrees,
              formatted_output: formatted_output,
              statistics: stats,
              count: worktrees.length
            }
          rescue => e
            error_result("Failed to list worktrees: #{e.message}")
          end

          # Switch to a worktree
          #
          # @param identifier [String] Worktree identifier (task ID, branch name, directory, or path)
          # @return [Hash] Switch result
          #
          # @example
          #   result = manager.switch("081")        # By task ID
          #   result = manager.switch("feature-branch")  # By branch name
          #   result = manager.switch("task.081")  # By directory name
          #   result = manager.switch("/path/to/worktree")  # By path
          def switch(identifier)
            return error_result("Worktree identifier is required") if identifier.nil? || identifier.empty?

            # Try different ways to find the worktree
            worktree = find_worktree_by_identifier(identifier)
            return error_result("Worktree not found: #{identifier}") unless worktree

            # Check if worktree exists and is usable
            unless worktree.exists?
              return error_result("Worktree directory does not exist: #{worktree.path}")
            end

            unless worktree.usable?
              return error_result("Worktree is not usable: #{worktree.description}")
            end

            # Return the path for the caller to use
            {
              success: true,
              message: "Found worktree: #{worktree.description}",
              worktree_path: worktree.path,
              branch: worktree.branch,
              task_id: worktree.task_id,
              description: worktree.description
            }
          rescue => e
            error_result("Unexpected error: #{e.message}")
          end

          # Remove a worktree
          #
          # @param identifier [String] Worktree identifier
          # @param options [Hash] Removal options
          # @return [Hash] Removal result
          #
          # @example
          #   result = manager.remove("081")           # By task ID
          #   result = manager.remove("feature-branch") # By branch name
          #   result = manager.remove("/path/to/worktree", force: true)
          #
          # @option options [Boolean] :force Force removal even with changes
          # @option options [Boolean] :remove_directory Also remove the directory
          # @option options [Boolean] :ignore_untracked Ignore untracked files when checking changes
          def remove(identifier, options = {})
            return error_result("Worktree identifier is required") if identifier.nil? || identifier.empty?

            # Find the worktree
            worktree = find_worktree_by_identifier(identifier)

            unless worktree
              # Worktree not found - check if we should try branch-only deletion
              if options[:delete_branch]
                result = attempt_branch_only_deletion(identifier, options[:force])
                return result if result[:success]
              end

              return error_result("Worktree not found: #{identifier}")
            end

            # Remove the worktree
            result = @worktree_remover.remove(
              worktree.path,
              force: options[:force],
              remove_directory: options[:remove_directory] != false,
              delete_branch: options[:delete_branch] == true,
              ignore_untracked: options[:ignore_untracked] == true
            )

            if result[:success]
              result[:message] = "Worktree removed successfully: #{worktree.description}"
            end

            result
          rescue => e
            error_result("Unexpected error: #{e.message}")
          end

          # Remove a task worktree with full cleanup
          #
          # @param task_ref [String] Task reference
          # @param options [Hash] Removal options
          # @return [Hash] Removal result
          #
          # @example
          #   result = manager.remove_task("081", force: true)
          def remove_task(task_ref, options = {})
            @task_orchestrator.remove_task_worktree(task_ref, options)
          end

          # Prune deleted worktrees
          #
          # @return [Hash] Prune result
          #
          # @example
          #   result = manager.prune
          #   # => { success: true, message: "Pruned 2 worktrees", pruned_count: 2 }
          def prune
            result = @worktree_remover.prune
            result[:message] = "Worktree pruning completed successfully" if result[:success]
            result
          rescue => e
            error_result("Failed to prune worktrees: #{e.message}")
          end

          # Get worktree status and statistics
          #
          # @return [Hash] Status information
          #
          # @example
          #   status = manager.get_status
          #   puts "Total worktrees: #{status[:statistics][:total]}"
          def get_status
            # Get all worktrees with task associations
            worktrees = @worktree_lister.list_with_tasks
            stats = @worktree_lister.get_statistics

            # Get task worktree status
            task_status = @task_orchestrator.get_task_worktree_status

            result = {
              success: true,
              worktrees: worktrees,
              statistics: stats,
              configuration: @config.to_h
            }
            result[:task_status] = task_status[:status] if task_status[:success]
            result
          rescue => e
            error_result("Failed to get worktree status: #{e.message}")
          end

          # Search for worktrees
          #
          # @param query [String] Search query
          # @param options [Hash] Search options
          # @return [Hash] Search result
          #
          # @example
          #   result = manager.search("auth", search_in: [:branch, :task_id])
          def search(query, options = {})
            return error_result("Search query is required") if query.nil? || query.empty?

            search_in = options[:search_in] || [:branch, :path, :task_id]
            worktrees = @worktree_lister.search(query, search_in: search_in)

            {
              success: true,
              query: query,
              search_in: search_in,
              results: worktrees,
              count: worktrees.length
            }
          rescue => e
            error_result("Search failed: #{e.message}")
          end

          # Validate worktree configuration
          #
          # @return [Hash] Validation result
          #
          # @example
          #   validation = manager.validate_configuration
          #   if validation[:valid]
          #     puts "Configuration is valid"
          #   else
          #     puts "Errors: #{validation[:errors].join(', ')}"
          #   end
          def validate_configuration
            errors = @config.validate

            {
              success: errors.empty?,
              valid: errors.empty?,
              errors: errors,
              configuration: @config.to_h
            }
          rescue => e
            error_result("Configuration validation failed: #{e.message}")
          end

          # Get configuration
          #
          # @return [WorktreeConfig] Current configuration
          def configuration
            @config
          end

          # Reload configuration
          #
          # @return [WorktreeConfig] Reloaded configuration
          def reload_configuration
            @config = load_configuration
            @config_loader.reset_cache!
            @task_orchestrator = Organisms::TaskWorktreeOrchestrator.new(config: @config, project_root: @project_root)
            @config
          end

          private

          # Load configuration
          #
          # @return [WorktreeConfig] Loaded configuration
          def load_configuration
            @config_loader.load
          end

          # Find worktree by various identifiers
          #
          # @param identifier [String] Worktree identifier
          # @return [WorktreeInfo, nil] Worktree info or nil
          def find_worktree_by_identifier(identifier)
            # Try as task ID first (handles subtasks like "121.01")
            normalized_task_id = Atoms::TaskIDExtractor.normalize(identifier)
            if normalized_task_id
              worktree = @worktree_lister.find_by_task_id(normalized_task_id)
              return worktree if worktree
            end

            # Try as branch name
            worktree = @worktree_lister.find_by_branch(identifier)
            return worktree if worktree

            # Try as directory name
            worktree = @worktree_lister.find_by_directory(identifier)
            return worktree if worktree

            # Try as path
            worktree = @worktree_lister.find_by_path(identifier)
            return worktree if worktree

            nil
          end

          # Create error result
          #
          # Dry run PR worktree creation
          #
          # @param pr_number [Integer] PR number
          # @param pr_data [Hash] PR data
          # @param options [Hash] Options
          # @return [Hash] Dry run result
          def dry_run_pr_creation(pr_number, pr_data, options)
            # Simulate what would be created
            pr_config = @config.pr_config || {}
            directory_format = pr_config[:directory_format] || "ace-pr-{number}"
            branch_format = pr_config[:branch_format] || "pr-{number}-{slug}"
            remote_name = pr_config[:remote_name] || "origin"

            # Use the format_pr_name logic for proper variable substitution
            require_relative "../atoms/slug_generator"

            directory_name = directory_format.dup
            directory_name.gsub!("{number}", pr_number.to_s)
            if pr_data[:title]
              slug = Atoms::SlugGenerator.from_title(pr_data[:title])
              directory_name.gsub!("{slug}", slug)
              directory_name.gsub!("{title_slug}", slug)
            end
            directory_name.gsub!("{base_branch}", pr_data[:base_branch].to_s) if pr_data[:base_branch]

            branch_name = branch_format.dup
            branch_name.gsub!("{number}", pr_number.to_s)
            if pr_data[:title]
              slug = Atoms::SlugGenerator.from_title(pr_data[:title])
              branch_name.gsub!("{slug}", slug)
              branch_name.gsub!("{title_slug}", slug)
            end
            branch_name.gsub!("{base_branch}", pr_data[:base_branch].to_s) if pr_data[:base_branch]
            worktree_path = File.join(@config.absolute_root_path, directory_name)
            tracking = "#{remote_name}/#{pr_data[:head_branch]}"

            {
              success: true,
              pr_number: pr_number,
              pr_title: pr_data[:title],
              would_create: {
                worktree_path: worktree_path,
                branch: branch_name,
                tracking: tracking,
                directory_name: directory_name
              }
            }
          end

          # Dry run branch worktree creation
          #
          # @param branch_name [String] Branch name
          # @param options [Hash] Options
          # @return [Hash] Dry run result
          def dry_run_branch_creation(branch_name, options)
            # Detect remote info
            remote_info = @worktree_creator.send(:detect_remote_branch, branch_name)

            local_branch = if remote_info
              remote_info[:branch].split("/").last
            else
              branch_name
            end

            require_relative "../atoms/slug_generator"
            directory_name = Atoms::SlugGenerator.to_directory_name(local_branch)
            worktree_path = File.join(@config.absolute_root_path, directory_name)
            tracking = remote_info ? branch_name : nil

            {
              success: true,
              would_create: {
                worktree_path: worktree_path,
                branch: local_branch,
                tracking: tracking,
                directory_name: directory_name
              }
            }
          end

          # Dry run traditional worktree creation
          #
          # @param branch_name [String] Branch name
          # @param options [Hash] Options
          # @return [Hash] Dry run result
          def dry_run_traditional_creation(branch_name, options)
            # Check if branch exists (locally or remotely)
            branch_exists = @worktree_creator.send(:branch_exists?, branch_name)

            # Determine worktree path
            worktree_path = if options[:path]
              options[:path]
            else
              require_relative "../atoms/slug_generator"
              directory_name = Atoms::SlugGenerator.to_directory_name(branch_name)
              File.join(@config.absolute_root_path, directory_name)
            end

            {
              success: true,
              would_create: {
                worktree_path: worktree_path,
                branch: branch_name,
                branch_exists: branch_exists,
                source: options[:source] || "current branch"
              }
            }
          end

          # @param message [String] Error message
          # @return [Hash] Error result
          def error_result(message)
            {
              success: false,
              error: message
            }
          end

          # Attempt to delete an orphaned branch (when worktree doesn't exist)
          #
          # @param identifier [String] Branch name or identifier
          # @param force [Boolean] Force deletion even if unmerged
          # @return [Hash] Deletion result
          def attempt_branch_only_deletion(identifier, force)
            require_relative "../atoms/git_command"

            # Get list of all branches
            branches_result = Atoms::GitCommand.execute("branch", "--format=%(refname:short)", timeout: 5)
            unless branches_result[:success]
              return error_result("Worktree not found: #{identifier}")
            end

            # Check if identifier matches a branch name
            branches = branches_result[:output].split("\n").map(&:strip)
            unless branches.include?(identifier)
              return error_result("Worktree not found: #{identifier}")
            end

            # Branch exists but no worktree - delete the orphaned branch
            delete_result = @worktree_remover.delete_branch_if_safe(identifier, force)

            if delete_result[:success]
              {
                success: true,
                message: "Deleted orphaned branch: #{identifier}",
                branch: identifier,
                branch_deleted: true,
                path: nil
              }
            else
              # Include detailed message from delete_result for better troubleshooting
              reason = delete_result[:message] || delete_result[:error] || "unknown reason"
              error_result("Branch '#{identifier}' exists but could not be deleted: #{reason}")
            end
          end
        end
      end
    end
  end
end
