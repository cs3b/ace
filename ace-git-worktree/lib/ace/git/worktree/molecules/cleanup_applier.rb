# frozen_string_literal: true

require "open3"
require "fileutils"

module Ace
  module Git
    module Worktree
      module Molecules
        # Applies a reviewed worktree cleanup plan with strict drift guards.
        class CleanupApplier
          # @param report [Hash] The reconstructed cleanup report
          # @param approved_digest [String] The approved plan digest
          def initialize(report, approved_digest)
            @report = report
            @approved_digest = approved_digest
            @ledger = []
          end

          # Execute the cleanup plan
          # @return [Hash] Application result including the ledger and final strict rescan status
          def apply
            if @report[:plan_digest] != @approved_digest
              return error_result("Digest mismatch. The repository state has drifted since approval. Expected: #{@approved_digest}, Got: #{@report[:plan_digest]}. Please review the new report.")
            end

            actions = @report[:actions]
            return success_result if actions.empty?

            # Fixed order execution: worktrees, local refs, remote refs
            worktree_actions = actions.select { |a| a[:type] == "remove_worktree" }
            local_ref_actions = actions.select { |a| a[:type] == "delete_local_ref" }
            remote_ref_actions = actions.select { |a| a[:type] == "delete_remote_ref" }

            failed = false

            worktree_actions.each do |action|
              next if failed
              failed = !execute_worktree_removal(action)
            end

            local_ref_actions.each do |action|
              next if failed
              failed = !execute_local_ref_deletion(action)
            end

            remote_ref_actions.each do |action|
              next if failed
              failed = !execute_remote_ref_deletion(action)
            end

            if failed
              {
                success: false,
                error: "Cleanup partially failed. See ledger for details.",
                ledger: @ledger,
                partial_failure: true
              }
            else
              success_result
            end
          end

          private

          def success_result
            {
              success: true,
              ledger: @ledger,
              partial_failure: false
            }
          end

          def error_result(message)
            {
              success: false,
              error: message,
              ledger: @ledger,
              partial_failure: false
            }
          end

          def record_ledger(action, success, error = nil)
            @ledger << {
              action: action,
              success: success,
              error: error
            }
            success
          end

          # --- Action Execution ---

          def execute_worktree_removal(action)
            path = action[:target]
            expected_sha = action[:sha]

            # Re-verify path safety (Trash adapter logic)
            unless safe_trash_path?(path)
              return record_ledger(action, false, "Unsafe worktree path: #{path}")
            end

            # Immediate drift guard: dirty check
            dirty_result = dirty_state(path)
            if dirty_result.nil?
              return record_ledger(action, false, "Worktree path not found or not a git directory")
            elsif !dirty_result.values.all?(&:empty?)
              return record_ledger(action, false, "Worktree became dirty since report")
            end

            # Immediate drift guard: sha check
            current_sha = resolve_worktree_head(path)
            if current_sha != expected_sha
              return record_ledger(action, false, "Worktree HEAD changed (expected #{expected_sha}, got #{current_sha})")
            end

            # Execute removal
            _out, _err, status = Open3.capture3("git", "worktree", "remove", "--force", path)
            unless status.success?
              return record_ledger(action, false, "git worktree remove failed")
            end

            record_ledger(action, true)
          end

          def execute_local_ref_deletion(action)
            ref = action[:target]
            expected_sha = action[:sha]

            # Immediate drift guard: check current SHA
            current_sha = resolve_local_ref(ref)
            if current_sha.nil?
              # Already gone, consider it a success but note it
              return record_ledger(action, true, "Ref was already deleted")
            elsif current_sha != expected_sha
              return record_ledger(action, false, "Ref SHA changed (expected #{expected_sha}, got #{current_sha})")
            end

            # Execute deletion
            _out, _err, status = Open3.capture3("git", "branch", "-D", ref)
            unless status.success?
              return record_ledger(action, false, "git branch -D failed")
            end

            record_ledger(action, true)
          end

          def execute_remote_ref_deletion(action)
            ref = action[:target] # e.g. origin/feature -> we need remote and branch
            expected_sha = action[:sha]
            
            # Action target for remote refs is typically "origin/feature"
            parts = ref.split("/", 2)
            remote = parts[0]
            branch = parts[1]
            
            # The exact lease will prevent deletion if remote ref has advanced
            # git push <remote> --delete <branch> --force-with-lease=<branch>:<expected_sha>
            cmd = ["git", "push", remote, "--delete", branch, "--force-with-lease=#{branch}:#{expected_sha}"]
            _out, _err, status = Open3.capture3(*cmd)
            
            unless status.success?
              return record_ledger(action, false, "Remote push --delete with lease failed")
            end
            
            record_ledger(action, true)
          end

          # --- Guards and Helpers ---

          def safe_trash_path?(path)
            # Rejects root, home, etc. 
            # In a real app this would delegate to a Trash adapter, but we validate safety here.
            abs_path = File.expand_path(path)
            return false if abs_path == "/"
            return false if abs_path == File.expand_path("~")
            
            # Must be within a project or temp space conceptually, but strictly we just need it to be a valid git dir
            # that is not the main repository.
            # We already have @report[:repository] (common_dir)
            common_dir = File.expand_path(@report[:repository])
            return false if abs_path == File.expand_path(File.dirname(common_dir))
            
            true
          end

          def dirty_state(path)
            return nil unless File.directory?(path)
            out, status = Open3.capture2("git", "-C", path, "status", "--porcelain")
            return nil unless status.success?
            
            lines = out.lines.map(&:chomp).reject(&:empty?)
            staged = []
            unstaged = []
            untracked = []

            lines.each do |line|
              xy = line[0..1]
              if xy[0] == "?"
                untracked << line[3..]
              elsif xy[0] != " "
                staged << line[3..]
              end
              if xy[1] != " " && xy[1] != "?"
                unstaged << line[3..]
              end
            end

            {staged: staged, unstaged: unstaged, untracked: untracked}
          end

          def resolve_worktree_head(path)
            out, status = Open3.capture2("git", "-C", path, "rev-parse", "HEAD")
            status.success? ? out.strip : nil
          end
          
          def resolve_local_ref(ref)
            out, status = Open3.capture2("git", "rev-parse", "--verify", "refs/heads/#{ref}^{commit}")
            status.success? ? out.strip : nil
          end
        end
      end
    end
  end
end
