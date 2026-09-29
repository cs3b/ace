# frozen_string_literal: true

require "open3"

module Ace
  module Overseer
    module Molecules
      # Classifies one worktree candidate for prune, fail-closed.
      #
      # A candidate is safe only when ALL of the following hold:
      # - the assignment queue label is completed,
      # - the task is done (a missing task record alone proves nothing but
      #   never authorizes removal by itself),
      # - the checkout is clean including untracked files (dirty tracked AND
      #   untracked files are work; --force never overrides this),
      # - required ignored artifacts are preserved: a local evidence journal
      #   checkout must already be contained in refs/ace/execution,
      # - all recorded attempts are terminal (active or uncertain attempts
      #   and unreadable attempt state block),
      # - an executed preservation proof passes (accepted ancestry or a
      #   verified declared destination).
      class PruneSafetyChecker
        def initialize(context_collector: nil, task_loader_factory: nil, preservation_checker: nil,
          attempt_store_factory: nil)
          @context_collector = context_collector || WorktreeContextCollector.new
          @task_loader_factory = task_loader_factory || -> { Ace::Task::Organisms::TaskManager.new }
          @preservation_checker = preservation_checker || GitPreservationChecker.new
          @attempt_store_factory = attempt_store_factory || ->(cache_base) {
            Ace::Assign::Molecules::AttemptStore.new(cache_base: cache_base)
          }
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

          assignment_complete = assignment_complete?(context.assignment_status)
          task_done = task_done?(worktree_path, task_ref)
          git_clean = git_clean_for_prune?(worktree_path)
          artifacts_safe, artifact_reasons = required_ignored_artifacts_safe?(worktree_path)
          attempts_terminal, attempt_reasons, recorded_base = attempts_evidence(worktree_path, context)
          proof = preservation_proof(
            worktree_path: worktree_path,
            accepted_base: accepted_base,
            manifest_record: manifest_record,
            recorded_base: recorded_base,
            candidate_branch: context.branch
          )
          # The HEAD and branch whose preservation was actually proven:
          # destructive boundaries downstream must use these identities,
          # never a later re-read that was itself never proven.
          verified_head = proof.preserved? ? proof.head : nil
          verified_branch = proof.preserved? ? context.branch : nil

          reasons = []
          reasons << "assignment not complete" unless assignment_complete
          reasons << "task not done" unless task_done
          reasons << "git not clean" unless git_clean
          reasons.concat(artifact_reasons)
          reasons.concat(attempt_reasons)
          reasons << "preservation not proven: #{proof.reason}" unless proof.preserved?

          Models::PruneCandidate.new(
            task_id: task_ref,
            worktree_path: worktree_path,
            assignment_complete: assignment_complete,
            task_done: task_done,
            git_clean: git_clean,
            attempts_terminal: attempts_terminal && artifacts_safe,
            preserved: proof.preserved?,
            verified_head: verified_head,
            verified_branch: verified_branch,
            reasons: reasons
          )
        end

        private

        def assignment_complete?(assignment_status)
          return false unless assignment_status.is_a?(Hash)

          assignment_status.dig("assignment", "state") == "completed"
        end

        def task_done?(worktree_path, task_ref)
          paths = [project_root_from_worktree(worktree_path), worktree_path].compact.uniq
          paths.any? { |path| task_done_in_context?(path, task_ref) }
        end

        # Full cleanliness: untracked files are work too. Ignored files are
        # not dirt, but required ignored artifacts are checked separately.
        def git_clean_for_prune?(worktree_path)
          stdout, status = Open3.capture2(
            "git", "-C", worktree_path, "status", "--porcelain"
          )
          return false unless status.success?

          stdout.to_s.strip.empty?
        rescue
          false
        end

        # A journal checkout inside the worktree is a required ignored
        # artifact unless every journaled commit already lives in the
        # authoritative evidence ref.
        def required_ignored_artifacts_safe?(worktree_path)
          checkout = File.join(worktree_path, assign_cache_relative, "evidence-checkout", "journal")
          return [true, []] unless File.directory?(checkout)

          head, status = Open3.capture2("git", "-C", checkout, "rev-parse", "HEAD")
          checkout_head = head.to_s.strip
          if !status.success? || checkout_head.empty?
            return [false, ["evidence journal checkout unreadable: #{checkout}"]]
          end

          common_dir = project_git_common_dir(worktree_path)
          if common_dir.nil?
            return [false, ["cannot resolve common git dir to verify evidence journal"]]
          end

          _out, evidence_status = Open3.capture2(
            "git", "-C", common_dir, "merge-base", "--is-ancestor", checkout_head, "refs/ace/execution"
          )
          if evidence_status.success?
            [true, []]
          else
            [false, ["evidence journal checkout has commits not in refs/ace/execution"]]
          end
        end

        # Attempt evidence from the worktree's own assignment cache: any
        # active or uncertain attempt blocks; an unreadable store blocks.
        # Returns the independently recorded creation baseline (base_head)
        # for patch-range preservation proofs.
        def attempts_evidence(worktree_path, context)
          ids = Array(context.assignments).filter_map { |entry| entry.dig("assignment", "id") }
          return [true, [], nil] if ids.empty?

          cache_base = File.join(worktree_path, assign_cache_relative)
          begin
            store = @attempt_store_factory.call(cache_base)
          rescue => e
            return [false, ["attempt state unreadable: #{e.message}"], nil]
          end
          reasons = []
          recorded_base = nil
          terminal = true
          ids.each do |assignment_id|
            attempts = store.list(assignment_id)
            attempts.each do |attempt|
              recorded_base ||= attempt.binding.base_head
              next unless attempt.active? || attempt.uncertain?

              terminal = false
              reasons << "attempt #{attempt.attempt_id} on assignment #{assignment_id} is #{attempt.state}"
            end
          rescue => e
            terminal = false
            reasons << "attempt state for assignment #{assignment_id} unreadable: #{e.message}"
          end
          [terminal, reasons, recorded_base]
        end

        def preservation_proof(worktree_path:, accepted_base:, manifest_record:, recorded_base:, candidate_branch: nil)
          return Models::PreservationProof.blocked("no surviving accepted base could be resolved") if accepted_base.nil?

          @preservation_checker.proof(
            worktree_path: worktree_path,
            accepted_base: accepted_base,
            manifest_record: manifest_record,
            recorded_base: recorded_base,
            candidate_branch: candidate_branch
          )
        rescue => e
          Models::PreservationProof.blocked("preservation proof failed: #{e.message}")
        end

        def assign_cache_relative
          Ace::Assign.config["cache_dir"] || ".ace-local/assign"
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
