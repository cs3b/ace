# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Molecules
        # Worktree remover molecule
        #
        # Removes git worktrees with proper cleanup, validation, and error handling.
        # Provides options for force removal and handles various edge cases.
        #
        # @example Remove a worktree
        #   remover = WorktreeRemover.new
        #   success = remover.remove("/path/to/worktree")
        #
        # @example Force remove with changes
        #   success = remover.remove("/path/to/worktree", force: true)
        class WorktreeRemover
          # Fallback timeout for git commands
          # Used only when config is unavailable
          FALLBACK_TIMEOUT = 30

          # Initialize a new WorktreeRemover
          #
          # @param timeout [Integer, nil] Command timeout in seconds (uses config default if nil)
          def initialize(timeout: nil)
            @timeout = timeout || config_timeout
          end

          private

          # Get timeout from config or fallback
          # @return [Integer] Timeout in seconds
          def config_timeout
            Ace::Git::Worktree.remove_timeout
          rescue
            FALLBACK_TIMEOUT
          end

          public

          # Remove a worktree by path
          #
          # @param worktree_path [String] Path to the worktree directory
          # @param force [Boolean] Force removal even if there are uncommitted changes
          # @param remove_directory [Boolean] Also remove the worktree directory
          # @param delete_branch [Boolean] Also delete the associated branch
          # @param ignore_untracked [Boolean] Treat untracked files as clean for removal checks
          # @return [Hash] Result with :success, :message, :error
          #
          # @example
          #   remover = WorktreeRemover.new
          #   result = remover.remove("/project/.ace-wt/task.081")
          #   # => { success: true, message: "Worktree removed successfully", error: nil }
          def remove(
            worktree_path,
            force: false,
            remove_directory: true,
            delete_branch: false,
            ignore_untracked: false
          )
            return error_result("Worktree path is required") if worktree_path.nil? || worktree_path.empty?

            begin
              expanded_path = File.expand_path(worktree_path)

              # Check if worktree exists
              worktree_info = find_worktree_info(expanded_path)
              return error_result("Worktree not found at #{expanded_path}") unless worktree_info

              # Check for uncommitted changes
              if !force && has_uncommitted_changes?(expanded_path, ignore_untracked: ignore_untracked)
                return error_result("Worktree has uncommitted changes. Use --force to remove anyway.")
              end

              # Store branch name before removal
              branch_name = worktree_info.branch

              # Remove the worktree using git
              # When ignore_untracked is true, we've already verified there are no tracked changes,
              # so pass force: true to skip git's own untracked-file check.
              result = remove_git_worktree(expanded_path, force: force || ignore_untracked)
              return result unless result[:success]

              # Optionally remove the directory
              if remove_directory && File.exist?(expanded_path)
                directory_result = remove_worktree_directory(expanded_path)
                return directory_result unless directory_result[:success]
              end

              # Optionally delete the branch
              branch_deleted = false
              if delete_branch && branch_name && !branch_name.empty?
                delete_result = delete_branch_if_safe(branch_name, force)
                branch_deleted = delete_result[:success]
              end

              {
                success: true,
                message: "Worktree removed successfully",
                path: expanded_path,
                branch: branch_name,
                branch_deleted: branch_deleted,
                error: nil
              }
            rescue => e
              error_result("Unexpected error: #{e.message}")
            end
          end

          # Remove a worktree by branch name
          #
          # @param branch_name [String] Branch name of the worktree
          # @param force [Boolean] Force removal even if there are uncommitted changes
          # @return [Hash] Result with :success, :message, :error
          #
          # @example
          #   result = remover.remove_by_branch("081-fix-auth")
          def remove_by_branch(branch_name, force: false)
            return error_result("Branch name is required") if branch_name.nil? || branch_name.empty?

            # Find worktree by branch
            worktree_info = find_worktree_by_branch(branch_name)
            return error_result("No worktree found for branch: #{branch_name}") unless worktree_info

            remove(worktree_info.path, force: force)
          end

          # Remove a worktree by task ID
          #
          # @param task_id [String] Task ID
          # @param force [Boolean] Force removal even if there are uncommitted changes
          # @return [Hash] Result with :success, :message, :error
          #
          # @example
          #   result = remover.remove_by_task_id("081")
          def remove_by_task_id(task_id, force: false)
            return error_result("Task ID is required") if task_id.nil? || task_id.empty?

            # Find worktree by task ID
            worktree_info = find_worktree_by_task_id(task_id)
            return error_result("No worktree found for task: #{task_id}") unless worktree_info

            remove(worktree_info.path, force: force)
          end

          # Remove multiple worktrees
          #
          # @param worktree_paths [Array<String>] Array of worktree paths
          # @param force [Boolean] Force removal even if there are uncommitted changes
          # @return [Hash] Result with :success, :removed, :failed, :errors
          #
          # @example
          #   result = remover.remove_multiple(["/path1", "/path2"], force: true)
          #   # => { success: true, removed: ["/path1"], failed: ["/path2"], errors: {...} }
          def remove_multiple(worktree_paths, force: false)
            return error_result("Worktree paths array is required") if worktree_paths.nil? || worktree_paths.empty?

            results = {
              success: true,
              removed: [],
              failed: [],
              errors: {}
            }

            Array(worktree_paths).each do |path|
              result = remove(path, force: force)
              if result[:success]
                results[:removed] << path
              else
                results[:success] = false
                results[:failed] << path
                results[:errors][path] = result[:error]
              end
            end

            results
          end

          # Prune deleted worktrees (cleanup git metadata)
          #
          # @return [Hash] Result with :success, :message, :pruned_count
          #
          # @example
          #   result = remover.prune
          #   # => { success: true, message: "Pruned 2 worktrees", pruned_count: 2 }
          def prune
            result = execute_git_worktree_prune
            if result[:success]
              # Parse output to count pruned worktrees
              pruned_count = parse_prune_output(result[:output])

              {
                success: true,
                message: "Pruned #{pruned_count} worktree(s)",
                pruned_count: pruned_count,
                error: nil
              }
            else
              error_result("Failed to prune worktrees: #{result[:error]}")
            end
          rescue => e
            error_result("Unexpected error during prune: #{e.message}")
          end

          # Check if a worktree can be safely removed
          #
          # @param worktree_path [String] Path to the worktree
          # @return [Hash] Safety check result with :safe, :warnings, :errors
          #
          # @example
          #   check = remover.check_removal_safety("/path/to/worktree")
          #   if check[:safe]
          #     remover.remove("/path/to/worktree")
          #   else
          #     puts "Cannot remove: #{check[:errors].join(', ')}"
          #   end
          def check_removal_safety(worktree_path)
            expanded_path = File.expand_path(worktree_path)

            result = {
              safe: true,
              warnings: [],
              errors: []
            }

            # Check if worktree exists
            worktree_info = find_worktree_info(expanded_path)
            unless worktree_info
              result[:safe] = false
              result[:errors] << "Worktree not found"
              return result
            end

            # Check for uncommitted changes
            if has_uncommitted_changes?(expanded_path)
              result[:safe] = false
              result[:errors] << "Worktree has uncommitted changes"
            end

            # Check if it's the current worktree
            current_dir = Dir.pwd
            if File.expand_path(current_dir) == expanded_path
              result[:warnings] << "Currently in this worktree"
            end

            # Check if it's the main worktree
            if worktree_info.branch.nil || worktree_info.detached || worktree_info.bare
              result[:warnings] << "This might be the main worktree"
            end

            result
          end

          private

          # Find worktree info by path
          #
          # @param path [String] Worktree path
          # @return [WorktreeInfo, nil] Worktree info or nil
          def find_worktree_info(path)
            require_relative "worktree_lister"
            lister = WorktreeLister.new
            lister.find_by_path(path)
          end

          # Find worktree info by branch name
          #
          # @param branch_name [String] Branch name
          # @return [WorktreeInfo, nil] Worktree info or nil
          def find_worktree_by_branch(branch_name)
            require_relative "worktree_lister"
            lister = WorktreeLister.new
            lister.find_by_branch(branch_name)
          end

          # Find worktree info by task ID
          #
          # @param task_id [String] Task ID
          # @return [WorktreeInfo, nil] Worktree info or nil
          def find_worktree_by_task_id(task_id)
            require_relative "worktree_lister"
            lister = WorktreeLister.new
            lister.find_by_task_id(task_id)
          end

          # Remove worktree using git command
          #
          # @param worktree_path [String] Worktree path
          # @return [Hash] Command result
          def remove_git_worktree(worktree_path, force: false)
            require_relative "../atoms/git_command"
            args = ["remove"]
            args << "--force" if force
            args << worktree_path
            result = Atoms::GitCommand.worktree(*args, timeout: @timeout)

            if result[:success]
              {success: true, message: "Git worktree removed successfully"}
            else
              error_result("Failed to remove git worktree: #{result[:error]}")
            end
          end

          # Remove the worktree directory
          #
          # @param worktree_path [String] Worktree path
          def remove_worktree_directory(worktree_path)
            return {success: true, message: "Worktree directory already absent"} unless File.exist?(worktree_path)

            FileUtils.rm_rf(worktree_path)
            return {success: true, message: "Worktree directory removed"} unless File.exist?(worktree_path)

            error_result("Worktree directory still exists after removal: #{worktree_path}")
          rescue => e
            error_result("Failed to remove worktree directory: #{e.message}")
          end

          # Check if worktree has uncommitted changes
          #
          # @param worktree_path [String] Worktree path
          # @param ignore_untracked [Boolean] Ignore untracked files when checking cleanliness
          # @return [Boolean] true if there are uncommitted changes
          def has_uncommitted_changes?(worktree_path, ignore_untracked: false)
            return false unless File.exist?(worktree_path)

            # Change to worktree directory and check git status
            original_dir = Dir.pwd
            begin
              Dir.chdir(worktree_path)
              status_args = ["status", "--porcelain"]
              status_args << "--untracked-files=no" if ignore_untracked

              result = execute_git_command(*status_args)
              result[:success] && !result[:output].strip.empty?
            ensure
              Dir.chdir(original_dir)
            end
          end

          # Execute git worktree prune command
          #
          # @return [Hash] Command result
          def execute_git_worktree_prune
            require_relative "../atoms/git_command"
            Atoms::GitCommand.worktree("prune", "--expire", "now", timeout: @timeout)
          end

          # Parse prune output to count pruned worktrees
          #
          # @param output [String] Git prune command output
          # @return [Integer] Number of pruned worktrees
          def parse_prune_output(output)
            return 0 if output.nil? || output.empty?

            # Look for lines like "Pruning worktree /path/to/worktree"
            lines = output.split("\n")
            lines.count { |line| line.include?("Pruning worktree") }
          end

          # Execute git command
          #
          # @param args [Array<String>] Command arguments
          # @return [Hash] Command result
          def execute_git_command(*args)
            require_relative "../atoms/git_command"
            Atoms::GitCommand.execute(*args, timeout: @timeout)
          end

          # Create an error result hash
          #
          # @param message [String] Error message
          # @return [Hash] Error result hash
          def error_result(message)
            {
              success: false,
              message: nil,
              error: message
            }
          end

          public

          # Delete a branch if it's safe to do so
          #
          # @param branch_name [String] Branch name to delete
          # @param force [Boolean] Force deletion even if not merged
          # @return [Hash] Result with :success, :message, :error
          def delete_branch_if_safe(branch_name, force)
            require_relative "../atoms/git_command"

            # Check if branch is already merged (unless forcing)
            unless force
              # Check if branch is merged into current branch
              result = Atoms::GitCommand.execute("branch", "--merged", timeout: @timeout)
              if result[:success]
                merged_branches = result[:output].split("\n").map(&:strip).map { |b| b.gsub(/^\*?\s*/, "") }
                unless merged_branches.include?(branch_name)
                  # Branch is not merged, don't delete unless forced
                  warn "Warning: Branch #{branch_name} is not merged. Skipping deletion. Use --force to delete anyway."
                  return {success: false, message: "Branch not merged", error: nil}
                end
              end
            end

            # Delete the branch
            delete_flag = force ? "-D" : "-d"
            result = Atoms::GitCommand.execute("branch", delete_flag, branch_name, timeout: @timeout)

            if result[:success]
              {success: true, message: "Branch #{branch_name} deleted", error: nil}
            else
              {success: false, message: nil, error: "Failed to delete branch: #{result[:error]}"}
            end
          end
        end
      end
    end
  end
end
