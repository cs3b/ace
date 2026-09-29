# frozen_string_literal: true

require "open3"

module Ace
  module Overseer
    module Organisms
      # Enforces the prune-safety contract on actual destructive paths.
      #
      # Preview is read-only: it classifies candidates but never mutates
      # worktree metadata or state. Apply holds the durable lifecycle
      # exclusion exclusively per candidate from its final evidence reads
      # through removal, recomputes the full safety classification under the
      # exclusion, removes the worktree without force or untracked
      # suppression, deletes the branch only after re-verifying its tip and
      # preservation, and records the removal so later starts fail closed.
      #
      # --force never bypasses preservation, dirtiness, lifecycle or
      # revalidation blocks; it only suppresses the interactive confirmation
      # for already-safe candidates.
      class PruneOrchestrator
        def initialize(worktree_manager: nil, prune_checker: nil, tmux_executor: nil, config: nil,
          assignment_prune_checker: nil, assignment_manager: nil, lifecycle_exclusion: nil,
          preservation_manifest_loader: nil)
          @worktree_manager = worktree_manager || Ace::Git::Worktree::Organisms::WorktreeManager.new
          @prune_checker = prune_checker || Molecules::PruneSafetyChecker.new
          @tmux_executor = tmux_executor || Ace::Tmux::Molecules::TmuxExecutor.new
          @config = config || Ace::Overseer.config
          @assignment_prune_checker = assignment_prune_checker || Molecules::AssignmentPruneSafetyChecker.new
          @assignment_manager = assignment_manager || Ace::Assign::Molecules::AssignmentManager.new
          @lifecycle_exclusion = lifecycle_exclusion
          @preservation_manifest_loader = preservation_manifest_loader || ->(path) {
            Molecules::PreservationManifest.load(path)
          }
        end

        def call(dry_run:, yes:, force: false, targets: [], assignment_id: nil,
          preservation_manifest: nil, input: $stdin, output: $stdout, on_progress: nil)
          if assignment_id
            return prune_assignment(assignment_id: assignment_id, dry_run: dry_run,
              yes: yes, force: force, input: input, output: output,
              on_progress: on_progress)
          end

          progress = on_progress || ->(_msg) {}

          progress.call("Scanning worktrees...")
          result = @worktree_manager.list_all(show_tasks: true)
          raise Error, result[:error] || "Failed to list worktrees" unless result[:success]

          all_worktrees = Array(result[:worktrees]).reject(&:bare)
          selection = if targets.any?
            select_by_targets(all_worktrees, targets)
          else
            all_worktrees.select(&:task_associated?)
          end

          manifest = load_manifest(preservation_manifest, selection)

          progress.call("Checking #{selection.length} worktree(s)...")
          accepted_base = accepted_base_for(selection)
          checked = selection.map do |worktree|
            check_candidate(worktree, manifest: manifest, accepted_base: accepted_base)
          end

          safe = checked.select(&:safe_to_prune?)
          unsafe = checked.reject(&:safe_to_prune?)

          if dry_run
            return {dry_run: true, safe: safe, unsafe: unsafe, forced: [], pruned: [], failed: [], blocked: []}
          end

          print_candidates(safe, unsafe, output)

          # --force suppresses only the convenience confirmation for
          # already-safe candidates; every safety block still applies.
          unless yes || force
            output.print("Continue? [y/N] ")
            answer = input.gets.to_s.strip.downcase
            unless %w[y yes].include?(answer)
              return {dry_run: false, safe: safe, unsafe: unsafe, forced: [], pruned: [],
                      failed: [], blocked: [], aborted: true}
            end
          end

          prune_stale_metadata(progress)
          apply_removals(safe, accepted_base: accepted_base, manifest: manifest, progress: progress)
            .merge(safe: safe, unsafe: unsafe, forced: [], aborted: false, dry_run: false)
        end

        private

        # Remove each safe candidate independently under its exclusion: a
        # blocked candidate never stops other safe candidates from
        # completing.
        def apply_removals(safe, accepted_base:, manifest:, progress:)
          pruned = []
          failed = []
          blocked = []

          safe.each do |candidate|
            exclusion.with_exclusive(identity_key(candidate)) do
              recheck = check_candidate(
                candidate_worktree(candidate), manifest: manifest, accepted_base: accepted_base
              )
              unless recheck.safe_to_prune?
                blocked << {candidate: candidate, reasons: recheck.reasons}
                progress.call("Blocked after recheck: task.#{candidate.task_id} — #{recheck.reasons.join(", ")}")
                next
              end

              removal = remove_worktree(candidate)
              if removal[:success]
                pruned << candidate
                record_removed(candidate)
              else
                failed << {candidate: candidate, error: removal[:error]}
              end
            end
          rescue => e
            failed << {candidate: candidate, error: e.message}
          end

          {pruned: pruned, failed: failed, blocked: blocked}
        end

        def remove_worktree(candidate)
          head = candidate_head(candidate.worktree_path)
          branch = candidate_branch(candidate.worktree_path)
          repo = candidate_repo(candidate.worktree_path)

          remove_result = @worktree_manager.remove(
            candidate.worktree_path,
            force: false,
            ignore_untracked: false,
            delete_branch: false
          )
          return remove_result unless remove_result[:success]

          close_tmux_window(candidate.worktree_path)
          branch_result = delete_branch(repo, branch: branch, head: head)
          return branch_result unless branch_result[:success]

          remove_result
        end

        # The branch deletion boundary: the branch is deleted only when its
        # tip still equals the HEAD whose preservation was just re-proven
        # under this exclusion.
        def delete_branch(repo, branch:, head:)
          return {success: true} if branch.nil? || branch.empty?
          return {success: true} if head.nil?
          return {success: false, error: "cannot resolve common repository for branch deletion"} if repo.nil?

          tip = rev_parse(repo, "--verify", "refs/heads/#{branch}")
          if tip.nil? || tip != head
            return {success: false, error: "branch #{branch} changed after preview (tip #{tip ? tip[0, 12] : "missing"}); preserving"}
          end

          _out, status = Open3.capture2("git", "-C", repo, "branch", "-D", branch)
          status.success? ? {success: true} : {success: false, error: "failed to delete branch #{branch}"}
        end

        def prune_assignment(assignment_id:, dry_run:, yes:, force:, input:, output:, on_progress:)
          progress = on_progress || ->(_msg) {}

          progress.call("Checking assignment #{assignment_id}...")
          candidate = @assignment_prune_checker.check(assignment_id: assignment_id)

          if dry_run
            return {dry_run: true, assignment_candidate: candidate, pruned_assignments: [], blocked: false}
          end

          unless candidate.safe_to_prune?
            output.puts("Cannot prune assignment #{assignment_id}: #{candidate.reasons.join(", ")}")
            return {dry_run: false, assignment_candidate: candidate, pruned_assignments: [], blocked: true}
          end

          print_assignment_candidate(candidate, output)

          unless yes
            output.print("Continue? [y/N] ")
            answer = input.gets.to_s.strip.downcase
            unless %w[y yes].include?(answer)
              return {dry_run: false, assignment_candidate: candidate, pruned_assignments: [],
                      blocked: false, aborted: true}
            end
          end

          deleted = false
          exclusion.with_exclusive(exclusion.assignment_key(assignment_id)) do
            recheck = @assignment_prune_checker.check(assignment_id: assignment_id)
            unless recheck.safe_to_prune?
              output.puts("Blocked after recheck: assignment #{assignment_id}: #{recheck.reasons.join(", ")}")
              return {dry_run: false, assignment_candidate: recheck, pruned_assignments: [], blocked: true}
            end

            exclusion.record_removed!(exclusion.assignment_key(assignment_id))
            deleted = @assignment_manager.delete(assignment_id)
          end

          pruned = deleted ? [candidate] : []
          {dry_run: false, assignment_candidate: candidate, pruned_assignments: pruned, blocked: false}
        end

        def print_assignment_candidate(candidate, output)
          output.puts("Safe to prune: assignment #{candidate.assignment_id} (#{candidate.assignment_name})")
          output.puts("  State: #{candidate.assignment_state}")
          output.puts("  Reasons: #{candidate.reasons.join(", ")}") if candidate.reasons.any?
        end

        def select_by_targets(worktrees, targets)
          selected = worktrees.select do |wt|
            targets.any? { |t| wt.task_id.to_s == t.to_s || wt.path.include?(t.to_s) }
          end
          if selected.empty?
            raise Error, "no worktree matches target(s): #{targets.join(", ")}"
          end

          unmatched = targets.reject do |t|
            selected.any? { |wt| wt.task_id.to_s == t.to_s || wt.path.include?(t.to_s) }
          end
          unless unmatched.empty?
            raise Error, "no worktree matches target(s): #{unmatched.join(", ")}"
          end

          selected
        end

        def load_manifest(preservation_manifest, selection)
          return nil if preservation_manifest.nil?

          manifest = @preservation_manifest_loader.call(preservation_manifest)
          manifest.ensure_all_match!(selection.map(&:path))
          manifest
        rescue Molecules::PreservationManifest::Invalid => e
          raise Error, e.message
        end

        def accepted_base_for(selection)
          sample = selection.first
          return nil if sample.nil?

          repo = candidate_repo(sample.path)
          return nil if repo.nil?

          branch = rev_parse(repo, "--abbrev-ref", "HEAD")
          head = rev_parse(repo, "--verify", "HEAD")
          return nil if branch.nil? || head.nil? || branch == "HEAD"

          base = {branch: branch, head: head}
          @cached_accepted_base = base
          base
        end

        def check_candidate(worktree, manifest:, accepted_base:)
          record = manifest&.for_worktree(worktree.path)
          @prune_checker.check(
            worktree_path: worktree.path,
            task_ref: worktree.task_id,
            manifest_record: record,
            accepted_base: accepted_base
          )
        rescue Errno::ENOENT, Errno::ENOTDIR
          unsafe_candidate(worktree, "worktree directory missing")
        rescue => e
          unsafe_candidate(worktree, "prune safety check failed: #{e.message}")
        end

        # A recheck needs a worktree-shaped object; the candidate model
        # carries both path and task id.
        def candidate_worktree(candidate)
          Struct.new(:path, :task_id).new(candidate.worktree_path, candidate.task_id)
        end

        def unsafe_candidate(worktree, reason)
          Models::PruneCandidate.new(
            task_id: worktree.task_id || "unknown",
            worktree_path: worktree.path,
            assignment_complete: false,
            task_done: false,
            git_clean: false,
            attempts_terminal: false,
            preserved: false,
            reasons: [reason]
          )
        end

        def identity_key(candidate)
          if candidate.task_id.to_s == "" || candidate.task_id.to_s == "unknown"
            exclusion.worktree_key(candidate.worktree_path)
          else
            exclusion.task_key(candidate.task_id)
          end
        end

        def record_removed(candidate)
          exclusion.record_removed!(identity_key(candidate))
        end

        def exclusion
          @lifecycle_exclusion ||= Ace::Assign::Molecules::LifecycleExclusion.new
        end

        def candidate_head(worktree_path)
          rev_parse(worktree_path, "--verify", "HEAD")
        end

        def candidate_branch(worktree_path)
          branch = rev_parse(worktree_path, "--abbrev-ref", "HEAD")
          branch == "HEAD" ? nil : branch
        end

        def candidate_repo(worktree_path)
          common_dir = rev_parse(worktree_path, "--path-format=absolute", "--git-common-dir")
          common_dir.nil? || common_dir.empty? ? nil : File.dirname(common_dir)
        end

        def rev_parse(repo, *args)
          stdout, _stderr, status = Open3.capture3("git", "-C", repo, "rev-parse", *args)
          status.success? ? stdout.to_s.strip : nil
        end

        def print_candidates(safe, unsafe, output)
          if safe.any?
            output.puts("Safe to prune (#{safe.length}):")
            safe.each { |c| output.puts("  task.#{c.task_id} — #{c.worktree_path}") }
          else
            output.puts("No worktrees safe to prune.")
          end
          if unsafe.any?
            output.puts("Skipping (#{unsafe.length}):")
            unsafe.each { |c| output.puts("  task.#{c.task_id} — #{c.reasons.join(", ")}") }
          end
        end

        def prune_stale_metadata(progress)
          result = @worktree_manager.prune
          return if result.nil? || result[:success]

          progress.call("Warning: failed to prune stale worktree metadata: #{result[:error]}")
        rescue => e
          progress.call("Warning: failed to prune stale worktree metadata: #{e.message}")
        end

        def close_tmux_window(worktree_path)
          window_name = File.basename(worktree_path)
          tmux_bin = @config["tmux_binary"] || "tmux"
          session_name = @tmux_executor.run([tmux_bin, "display-message", "-p", "#S"]).to_s.strip
          return false if session_name.empty?

          @tmux_executor.run([tmux_bin, "kill-window", "-t", "#{session_name}:#{window_name}"])
        rescue
          false
        end
      end
    end
  end
end
