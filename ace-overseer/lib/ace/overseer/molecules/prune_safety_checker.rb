# frozen_string_literal: true

require "open3"

module Ace
  module Overseer
    module Molecules
      # Classifies one worktree candidate for prune, fail-closed.
      #
      # A candidate is safe only when ALL of the following hold:
      # - every local assignment is completed,
      # - the task is done (a missing task record alone proves nothing but
      #   never authorizes removal by itself),
      # - the checkout is clean including untracked files (dirty tracked AND
      #   untracked files are work; --force never overrides this),
      # - no local assignment step is active or pending (unreadable local
      #   work state blocks),
      # - an executed preservation proof passes (accepted ancestry or a
      #   verified declared destination).
      #
      # Local state only: assignment records under `.ace-local/assign/`, task
      # records under `.ace-tasks/`, and Git. No journal, attempt or authority
      # store participates in this classification.
      class PruneSafetyChecker
        def initialize(context_collector: nil, task_loader_factory: nil, preservation_checker: nil)
          @context_collector = context_collector || WorktreeContextCollector.new
          @task_loader_factory = task_loader_factory || -> { Ace::Task::Organisms::TaskManager.new }
          @preservation_checker = preservation_checker || GitPreservationChecker.new
        end

        attr_reader :preservation_checker

        # @param worktree_path [String] Candidate worktree
        # @param task_ref [String, nil] Task id recorded for the worktree
        # @param manifest_record [PreservationManifest::Record, nil] Declared
        #   destination claim for this worktree
        # @param accepted_base [Hash, nil] `{branch:, head:}` surviving base
        # @return [Models::PruneCandidate]
        def check(worktree_path:, task_ref:, manifest_record: nil, accepted_base: nil)
          context = @context_collector.collect(worktree_path)

          assignment_complete = assignment_complete?(context.assignments)
          work_terminal, work_reasons = work_terminal?(context.assignments)
          task_done = task_done?(worktree_path, task_ref)
          git_clean = git_clean_for_prune?(worktree_path)
          # One branch identity for the whole check: read before the proof,
          # handed to the proof as the candidate's own branch, and verified
          # downstream. A later read could name a switched-to destination.
          branch_at_check = head_branch(worktree_path)
          proof = preservation_proof(
            worktree_path: worktree_path,
            accepted_base: accepted_base,
            manifest_record: manifest_record,
            candidate_branch: branch_at_check
          )
          # The HEAD and branch whose preservation was actually proven:
          # destructive boundaries downstream must use these identities,
          # never a later re-read that was itself never proven. Detachment
          # comes from Git's symbolic HEAD state, not the branch name's
          # shape — a 40-hex branch name is a real branch.
          verified_head = proof.preserved? ? proof.head : nil
          verified_branch = proof.preserved? ? branch_at_check : nil

          reasons = []
          reasons << "assignment not complete" unless assignment_complete
          reasons << "task not done" unless task_done
          reasons << "git not clean" unless git_clean
          reasons.concat(work_reasons)
          reasons << "preservation not proven: #{proof.reason}" unless proof.preserved?

          Models::PruneCandidate.new(
            task_id: task_ref,
            worktree_path: worktree_path,
            assignment_complete: assignment_complete,
            task_done: task_done,
            git_clean: git_clean,
            work_terminal: work_terminal,
            preserved: proof.preserved?,
            verified_head: verified_head,
            verified_branch: verified_branch,
            reasons: reasons
          )
        end

        private

        # Every local assignment must be completed. A missing or unreadable
        # assignment record never proves terminality.
        def assignment_complete?(assignments)
          entries = Array(assignments)
          return false if entries.empty?

          entries.all? { |entry| entry.dig("assignment", "state") == "completed" }
        end

        # No local step may be active or pending. A summary that exists but
        # is unreadable blocks.
        def work_terminal?(assignments)
          reasons = []
          entries = Array(assignments)
          entries.each do |entry|
            summary = entry["step_summary"]
            next if summary.nil?

            unless summary.is_a?(Hash)
              reasons << "assignment step state unreadable"
              next
            end
            active = summary["active"].to_i
            pending = summary["pending"].to_i
            next if active.zero? && pending.zero?

            reasons << "assignment #{entry.dig("assignment", "id")} has #{active} active and #{pending} pending step(s)"
          end
          [reasons.empty?, reasons]
        end

        def task_done?(worktree_path, task_ref)
          paths = [project_root_from_worktree(worktree_path), worktree_path].compact.uniq
          paths.any? { |path| task_done_in_context?(path, task_ref) }
        end

        # Full cleanliness: untracked files are work too. Ignored files are
        # not dirt; local assignment state is not a deletion precondition
        # beyond the assignment-completion check above.
        def git_clean_for_prune?(worktree_path)
          stdout, status = Open3.capture2(
            "git", "-C", worktree_path, "status", "--porcelain"
          )
          return false unless status.success?

          stdout.to_s.strip.empty?
        rescue
          false
        end

        def preservation_proof(worktree_path:, accepted_base:, manifest_record:, candidate_branch: nil)
          return Models::PreservationProof.blocked("no surviving accepted base could be resolved") if accepted_base.nil?

          @preservation_checker.proof(
            worktree_path: worktree_path,
            accepted_base: accepted_base,
            manifest_record: manifest_record,
            candidate_branch: candidate_branch
          )
        rescue => e
          Models::PreservationProof.blocked("preservation proof failed: #{e.message}")
        end

        # The checked-out branch per Git's symbolic HEAD state; nil when
        # detached (or unreadable — then there is no deletable ref).
        def head_branch(worktree_path)
          stdout, _stderr, status = Open3.capture3(
            "git", "-C", worktree_path, "symbolic-ref", "-q", "HEAD"
          )
          return nil unless status.success?

          branch = stdout.to_s.strip.sub(/\Arefs\/heads\//, "")
          branch.empty? ? nil : branch
        rescue
          nil
        end

        def task_done_in_context?(path, task_ref)
          Dir.chdir(path) do
            manager = @task_loader_factory.call
            task = manager.show(task_ref.to_s)
            task && task.status == "done"
          end
        rescue
          false
        end

        def project_root_from_worktree(worktree_path)
          common_dir = project_git_common_dir(worktree_path)
          return nil if common_dir.nil?

          File.dirname(common_dir)
        end

        def project_git_common_dir(worktree_path)
          stdout, status = Open3.capture2(
            "git", "-C", worktree_path, "rev-parse", "--path-format=absolute", "--git-common-dir"
          )
          return nil unless status.success?

          common_dir = stdout.to_s.strip
          common_dir.empty? ? nil : common_dir
        rescue
          nil
        end
      end
    end
  end
end
