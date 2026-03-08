# frozen_string_literal: true

module Ace
  module Overseer
    module Organisms
      class PruneOrchestrator
        def initialize(worktree_manager: nil, prune_checker: nil, tmux_executor: nil, config: nil,
                       assignment_prune_checker: nil, assignment_manager: nil)
          @worktree_manager = worktree_manager || Ace::Git::Worktree::Organisms::WorktreeManager.new
          @prune_checker = prune_checker || Molecules::PruneSafetyChecker.new
          @tmux_executor = tmux_executor || Ace::Tmux::Molecules::TmuxExecutor.new
          @config = config || Ace::Overseer.config
          @assignment_prune_checker = assignment_prune_checker || Molecules::AssignmentPruneSafetyChecker.new
          @assignment_manager = assignment_manager || Ace::Assign::Molecules::AssignmentManager.new
        end

        def call(dry_run:, yes:, force: false, targets: [], assignment_id: nil,
                 input: $stdin, output: $stdout, on_progress: nil)
          if assignment_id
            return prune_assignment(assignment_id: assignment_id, dry_run: dry_run,
                                    yes: yes, force: force, input: input, output: output,
                                    on_progress: on_progress)
          end

          progress = on_progress || ->(_msg) {}

          progress.call("Scanning worktrees...")
          prune_stale_metadata(progress)
          result = @worktree_manager.list_all(show_tasks: true)
          raise Error, result[:error] || "Failed to list worktrees" unless result[:success]

          all_worktrees = Array(result[:worktrees]).reject(&:bare)
          worktrees = if targets.any?
                        filter_by_targets(all_worktrees, targets)
                      else
                        all_worktrees.select(&:task_associated?)
                      end

          progress.call("Checking #{worktrees.length} worktree(s)...")
          checked = worktrees.map { |worktree| check_candidate(worktree) }

          safe = checked.select(&:safe_to_prune?)
          unsafe = checked.reject(&:safe_to_prune?)
          forced = force ? unsafe : []

          if dry_run
            return { dry_run: true, safe: safe, unsafe: unsafe, forced: forced, pruned: [], failed: [] }
          end

          print_candidates(safe, unsafe, force, output)

          to_prune = safe + forced
          unless yes
            output.print("Continue? [y/N] ")
            answer = input.gets.to_s.strip.downcase
            unless %w[y yes].include?(answer)
              return { dry_run: false, safe: safe, unsafe: unsafe, forced: forced, pruned: [], failed: [], aborted: true }
            end
          end

          pruned = []
          failed = []

          to_prune.each do |candidate|
            remove_result = @worktree_manager.remove(
              candidate.worktree_path,
              force: force,
              ignore_untracked: true,
              delete_branch: true
            )
            if remove_result[:success]
              close_tmux_window(candidate.worktree_path)
              pruned << candidate
            else
              failed << { candidate: candidate, error: remove_result[:error] }
            end
          end

          {
            dry_run: false,
            safe: safe,
            unsafe: unsafe,
            forced: forced,
            pruned: pruned,
            failed: failed,
            aborted: false
          }
        end

        private

        def prune_assignment(assignment_id:, dry_run:, yes:, force:, input:, output:, on_progress:)
          progress = on_progress || ->(_msg) {}

          progress.call("Checking assignment #{assignment_id}...")
          candidate = @assignment_prune_checker.check(assignment_id: assignment_id)

          if dry_run
            return { dry_run: true, assignment_candidate: candidate, pruned_assignments: [] }
          end

          unless candidate.safe_to_prune? || force
            output.puts("Cannot prune assignment #{assignment_id}: #{candidate.reasons.join(", ")}")
            return { dry_run: false, assignment_candidate: candidate, pruned_assignments: [], blocked: true }
          end

          print_assignment_candidate(candidate, force, output)

          unless yes
            output.print("Continue? [y/N] ")
            answer = input.gets.to_s.strip.downcase
            unless %w[y yes].include?(answer)
              return { dry_run: false, assignment_candidate: candidate, pruned_assignments: [], aborted: true }
            end
          end

          deleted = @assignment_manager.delete(assignment_id)
          pruned = deleted ? [candidate] : []

          { dry_run: false, assignment_candidate: candidate, pruned_assignments: pruned }
        end

        def print_assignment_candidate(candidate, force, output)
          label = candidate.safe_to_prune? ? "Safe to prune" : (force ? "Force removing" : "Blocked")
          output.puts("#{label}: assignment #{candidate.assignment_id} (#{candidate.assignment_name})")
          output.puts("  State: #{candidate.assignment_state}")
          output.puts("  Reasons: #{candidate.reasons.join(", ")}") if candidate.reasons.any?
        end

        def filter_by_targets(worktrees, targets)
          worktrees.select do |wt|
            targets.any? { |t| wt.task_id.to_s == t.to_s || wt.path.include?(t.to_s) }
          end
        end

        def print_candidates(safe, unsafe, force, output)
          if safe.any?
            output.puts("Safe to prune (#{safe.length}):")
            safe.each { |c| output.puts("  task.#{c.task_id} — #{c.worktree_path}") }
          else
            output.puts("No worktrees safe to prune.")
          end
          if unsafe.any?
            if force
              output.puts("Force removing (#{unsafe.length}):")
              unsafe.each { |c| output.puts("  task.#{c.task_id} — #{c.reasons.join(", ")}") }
            else
              output.puts("Skipping (#{unsafe.length}):")
              unsafe.each { |c| output.puts("  task.#{c.task_id} — #{c.reasons.join(", ")}") }
            end
          end
        end

        def check_candidate(worktree)
          @prune_checker.check(worktree_path: worktree.path, task_ref: worktree.task_id)
        rescue Errno::ENOENT, Errno::ENOTDIR
          unsafe_candidate(worktree, "worktree directory missing")
        rescue StandardError => e
          unsafe_candidate(worktree, "prune safety check failed: #{e.message}")
        end

        def unsafe_candidate(worktree, reason)
          Models::PruneCandidate.new(
            task_id: worktree.task_id || "unknown",
            worktree_path: worktree.path,
            assignment_complete: false,
            task_done: false,
            git_clean: false,
            reasons: [reason]
          )
        end

        def prune_stale_metadata(progress)
          result = @worktree_manager.prune
          return if result.nil? || result[:success]

          progress.call("Warning: failed to prune stale worktree metadata: #{result[:error]}")
        rescue StandardError => e
          progress.call("Warning: failed to prune stale worktree metadata: #{e.message}")
        end

        def close_tmux_window(worktree_path)
          window_name = File.basename(worktree_path)
          tmux_bin = @config["tmux_binary"] || "tmux"
          session_name = @tmux_executor.run([tmux_bin, "display-message", "-p", "#S"]).to_s.strip
          return false if session_name.empty?

          @tmux_executor.run([tmux_bin, "kill-window", "-t", "#{session_name}:#{window_name}"])
        rescue StandardError
          false
        end
      end
    end
  end
end
