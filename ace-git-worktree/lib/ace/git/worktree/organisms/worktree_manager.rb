# frozen_string_literal: true

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
            @config = config || load_configuration

            # Initialize molecules
            @config_loader = Molecules::ConfigLoader.new(project_root)
            @worktree_creator = Molecules::WorktreeCreator.new
            @worktree_lister = Molecules::WorktreeLister.new
            @worktree_remover = Molecules::WorktreeRemover.new
            @task_fetcher = Molecules::TaskFetcher.new
            @mise_trustor = Molecules::MiseTrustor.new

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
            begin
              # Validate inputs
              return error_result("Branch name is required") if branch_name.nil? || branch_name.empty?

              # Check if worktree already exists
              existing = @worktree_lister.find_by_branch(branch_name)
              if existing
                return error_result("Worktree already exists for branch: #{branch_name}")
              end

              # Create the worktree
              result = @worktree_creator.create_traditional(
                branch_name,
                options[:path],
                git_root: @project_root
              )

              if result[:success]
                # Trust mise configuration if enabled
                if @config.mise_trust_auto?
                  mise_result = @mise_trustor.trust_worktree(result[:worktree_path])
                  unless mise_result[:success]
                    result[:warnings] = ["Failed to trust mise configuration"]
                  end
                end

                result[:message] = "Worktree created successfully"
              end

              result
            rescue StandardError => e
              error_result("Unexpected error: #{e.message}")
            end
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
            begin
              # Get worktrees
              worktrees = if options[:show_tasks]
                          @worktree_lister.list_with_tasks
                        else
                          @worktree_lister.list_all
                        end

              # Apply filters
              if options[:task_associated] || options[:usable] || options[:search]
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
              stats = @worktree_lister.get_statistics

              {
                success: true,
                worktrees: worktrees,
                formatted_output: formatted_output,
                statistics: stats,
                count: worktrees.length
              }
            rescue StandardError => e
              error_result("Failed to list worktrees: #{e.message}")
            end
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
            begin
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
            rescue StandardError => e
              error_result("Unexpected error: #{e.message}")
            end
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
          def remove(identifier, options = {})
            begin
              return error_result("Worktree identifier is required") if identifier.nil? || identifier.empty?

              # Find the worktree
              worktree = find_worktree_by_identifier(identifier)
              return error_result("Worktree not found: #{identifier}") unless worktree

              # Remove the worktree
              result = @worktree_remover.remove(
                worktree.path,
                force: options[:force],
                remove_directory: options[:remove_directory] != false
              )

              if result[:success]
                result[:message] = "Worktree removed successfully: #{worktree.description}"
              end

              result
            rescue StandardError => e
              error_result("Unexpected error: #{e.message}")
            end
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
            begin
              result = @worktree_remover.prune
              result[:message] = "Worktree pruning completed successfully" if result[:success]
              result
            rescue StandardError => e
              error_result("Failed to prune worktrees: #{e.message}")
            end
          end

          # Get worktree status and statistics
          #
          # @return [Hash] Status information
          #
          # @example
          #   status = manager.get_status
          #   puts "Total worktrees: #{status[:statistics][:total]}"
          def get_status
            begin
              # Get all worktrees with task associations
              worktrees = @worktree_lister.list_with_tasks
              stats = @worktree_lister.get_statistics

              # Get task worktree status
              task_status = @task_orchestrator.get_task_worktree_status

              {
                success: true,
                worktrees: worktrees,
                statistics: stats,
                task_status: task_status[:status] if task_status[:success],
                configuration: @config.to_h
              }
            rescue StandardError => e
              error_result("Failed to get worktree status: #{e.message}")
            end
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
            begin
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
            rescue StandardError => e
              error_result("Search failed: #{e.message}")
            end
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
            begin
              errors = @config.validate

              {
                success: errors.empty?,
                valid: errors.empty?,
                errors: errors,
                configuration: @config.to_h
              }
            rescue StandardError => e
              error_result("Configuration validation failed: #{e.message}")
            end
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
            # Try as task ID first
            if identifier.match(/^\d+$/)
              worktree = @worktree_lister.find_by_task_id(identifier)
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

            # Try as full task reference (task.081, v.0.9.0+081)
            task_id_match = identifier.match(/(?:task[-.]|^|.*\+)(\d+)/i)
            if task_id_match
              worktree = @worktree_lister.find_by_task_id(task_id_match[1])
              return worktree if worktree
            end

            nil
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