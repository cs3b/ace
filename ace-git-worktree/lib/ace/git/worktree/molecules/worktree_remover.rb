# frozen_string_literal: true

require_relative "../atoms/git_command"
require_relative "worktree_lister"
require_relative "task_status_updater"

module Ace
  module Git
    module Worktree
      module Molecules
        # Removes worktrees with cleanup
        class WorktreeRemover
          # Remove a worktree by identifier
          # @param identifier [String] Worktree identifier (path, branch, task ID)
          # @param options [Hash] Options
          # @return [Hash] Result with :success, :output, :error
          def self.remove(identifier, options = {})
            return error_result("Identifier cannot be empty") if identifier.nil? || identifier.empty?

            # Find the worktree
            worktree = WorktreeLister.find(identifier)
            unless worktree
              return error_result("Worktree not found: #{identifier}")
            end

            # Check for uncommitted changes unless forced
            unless options[:force]
              check_result = check_uncommitted_changes(worktree.path)
              if check_result[:has_changes]
                return error_result("Worktree has uncommitted changes. Use --force to remove anyway.")
              end
            end

            # Remove worktree metadata from task if associated
            if worktree.task? && options[:cleanup_task] != false
              cleanup_task_metadata(worktree.task_id)
            end

            # Remove the worktree
            remove_result = execute_removal(worktree.path, options[:force])

            if remove_result[:success]
              {
                success: true,
                output: "Worktree removed: #{worktree.path}",
                removed_path: worktree.path,
                removed_branch: worktree.branch
              }
            else
              error_result(remove_result[:error])
            end
          end

          # Remove multiple worktrees
          # @param identifiers [Array<String>] List of identifiers
          # @param options [Hash] Options
          # @return [Hash] Result with successes and failures
          def self.remove_multiple(identifiers, options = {})
            results = {
              successes: [],
              failures: []
            }

            identifiers.each do |identifier|
              result = remove(identifier, options)
              if result[:success]
                results[:successes] << {
                  identifier: identifier,
                  path: result[:removed_path]
                }
              else
                results[:failures] << {
                  identifier: identifier,
                  error: result[:error]
                }
              end
            end

            {
              success: results[:failures].empty?,
              successes: results[:successes],
              failures: results[:failures]
            }
          end

          # Prune deleted worktrees
          # @return [Hash] Result with :success, :output, :error
          def self.prune
            result = Atoms::GitCommand.execute("worktree", "prune", "--verbose")

            if result[:success]
              # Parse output to see what was pruned
              pruned = []
              result[:output].lines.each do |line|
                if line =~ /Removing worktree for '(.+)'/
                  pruned << $1
                end
              end

              {
                success: true,
                output: result[:output],
                pruned_count: pruned.size,
                pruned_paths: pruned
              }
            else
              error_result("Failed to prune worktrees: #{result[:error]}")
            end
          end

          # Clean up worktrees for completed tasks
          # @param options [Hash] Options
          # @return [Hash] Result with cleaned up worktrees
          def self.cleanup_completed(options = {})
            task_worktrees = WorktreeLister.task_worktrees
            cleaned = []

            task_worktrees.each do |worktree|
              # Check if task is done
              if task_done?(worktree.task_id)
                result = remove(worktree.path, options)
                if result[:success]
                  cleaned << worktree.path
                end
              end
            end

            {
              success: true,
              cleaned_count: cleaned.size,
              cleaned_paths: cleaned
            }
          end

          private

          def self.error_result(message)
            {
              success: false,
              error: message
            }
          end

          # Check for uncommitted changes in worktree
          def self.check_uncommitted_changes(worktree_path)
            # Run git status in the worktree
            result = Atoms::GitCommand.execute("status", "--porcelain", chdir: worktree_path)

            if result[:success]
              has_changes = !result[:output].strip.empty?
              {
                has_changes: has_changes,
                changes: result[:output]
              }
            else
              # If we can't check, assume there might be changes
              {
                has_changes: true,
                error: result[:error]
              }
            end
          end

          # Execute the actual removal
          def self.execute_removal(path, force = false)
            args = ["worktree", "remove", path]
            args << "--force" if force

            result = Atoms::GitCommand.execute(*args)

            if result[:success]
              {
                success: true,
                output: result[:output]
              }
            else
              {
                success: false,
                error: result[:error]
              }
            end
          end

          # Clean up task metadata
          def self.cleanup_task_metadata(task_id)
            # Remove worktree metadata from task
            TaskStatusUpdater.remove_worktree_metadata(task_id)
          rescue => e
            # Don't fail the removal if metadata cleanup fails
            warn "Failed to remove worktree metadata from task: #{e.message}"
          end

          # Check if a task is done
          def self.task_done?(task_id)
            # Would need to query ace-taskflow for task status
            # For now, return false to be safe
            false
          end
        end
      end
    end
  end
end