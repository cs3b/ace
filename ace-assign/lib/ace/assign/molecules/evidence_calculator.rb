# frozen_string_literal: true

require "digest"
require "open3"
require "ace/support/fs"

module Ace
  module Assign
    module Molecules
      # Computes delivery evidence for an assignment from accepted,
      # current-head execution evidence.
      #
      # Decisions are derived exclusively from accepted receipts recorded in
      # the evidence journal (managed attempts) or the durable attempt store
      # (taskless attempts). Report files on disk, exit codes, and prose never
      # establish review or merge authorization, and no feedback state is
      # hardcoded: an attempt that may have completed without a durable
      # receipt yields `uncertain`, never success.
      class EvidenceCalculator
        def self.calculate(pr_number: nil, auto_merge: false, assignment_id: nil)
          new.calculate(pr_number: pr_number, auto_merge: auto_merge, assignment_id: assignment_id)
        end

        # @param cache_base [String, nil] Assignment cache base (default config)
        # @param repo_root [String, nil] Candidate repository root (default project root)
        # @param journal [EvidenceJournal, nil] Evidence journal (default built lazily)
        def initialize(cache_base: nil, repo_root: nil, journal: nil)
          @cache_base = cache_base
          @repo_root = repo_root || Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          @journal = journal
        end

        def calculate(pr_number: nil, auto_merge: false, assignment_id: nil)
          head, tree, changed_scope_digest = git_facts
          assignment = find_assignment(assignment_id)
          attempts = assignment ? store.list(assignment.id) : []
          receipts = assignment ? accepted_receipts(assignment, attempts) : []

          review_receipt = receipt_currency(receipts, "review", head)
          release_receipt = receipt_currency(receipts, "release", head)
          unresolved_effects = collect_unresolved_effects(attempts)
          feedback_state = derive_feedback_state(attempts, receipts, head, unresolved_effects)

          merge_decision = if auto_merge && review_receipt == "current" && unresolved_effects.empty?
            "authorized"
          else
            "approval-required"
          end

          latest = attempts.first
          active = attempts.find(&:active?)
          evidence = {
            pr: pr_number || "none",
            head: head,
            tree: tree,
            changed_scope_digest: changed_scope_digest,
            review_receipt: review_receipt,
            release_receipt: release_receipt,
            feedback_state: feedback_state,
            merge_decision: merge_decision,
            decision_digest: nil,
            attempt: latest ? attempt_summary(latest, active: active) : nil,
            base_head: latest&.binding&.base_head,
            candidate_head: latest&.candidate_head,
            evidence_git_ref: evidence_git_ref(assignment),
            journal_commit: latest&.journal_commit,
            unresolved_effects: unresolved_effects
          }
          evidence[:decision_digest] = Digest::SHA256.hexdigest(
            Atoms::EvidenceDigest.canonical_json(evidence)
          )
          evidence
        end

        private

        def git_facts
          head, _s = Open3.capture2("git", "rev-parse", "HEAD", chdir: @repo_root, stdin_data: "")
          tree, _s = Open3.capture2("git", "rev-parse", "HEAD^{tree}", chdir: @repo_root, stdin_data: "")
          diff_output, _s = Open3.capture2("git", "diff", "HEAD", chdir: @repo_root, stdin_data: "")

          [head.to_s.strip, tree.to_s.strip, Digest::SHA256.hexdigest(diff_output.to_s)]
        end

        def find_assignment(assignment_id)
          manager = Molecules::AssignmentManager.new(cache_base: @cache_base)
          assignment_id ? manager.load(assignment_id) : manager.find_active
        end

        def store
          @store ||= Molecules::AssignmentManager.new(cache_base: @cache_base).attempt_store
        end

        def journal
          @journal ||= Molecules::EvidenceJournal.new(repo_root: @repo_root)
        end

        # Accepted receipts span the managed journal and the durable local
        # attempt records, deduplicated by digest.
        def accepted_receipts(assignment, attempts)
          receipts = attempts.flat_map(&:accepted_receipts)
          receipts += journal.accepted_receipts(assignment.id) if assignment.managed?
          receipts.uniq { |receipt| receipt["digest"] }
        end

        # Currency against the current head. Review approval requires an
        # executed independent reviewer verdict; receipts were verified at
        # acceptance and the independence guard is re-checked here defensively
        # (a review receipt without a reviewer verdict is not review evidence
        # at all).
        def receipt_currency(receipts, operation, head)
          succeeded = receipts.select do |receipt|
            next false unless receipt["operation"] == operation && receipt["verdict"] == "succeeded"
            next false if operation == "review" && receipt.dig("review", "reviewer", "actor").nil?

            true
          end

          current = succeeded.any? { |receipt| receipt["head"] == head }

          return "missing" if succeeded.empty?
          return "current" if current

          "stale"
        end

        def collect_unresolved_effects(attempts)
          attempts.flat_map { |attempt| attempt.unresolved_effects.map { |effect| effect["operation"] } }
            .concat(attempts.select(&:uncertain?).map { |attempt| "#{attempt.attempt_id}:uncertain" })
            .uniq
        end

        # Feedback is derived: uncertain evidence wins, accepted current-head
        # evidence closes the loop, anything else stays open.
        def derive_feedback_state(attempts, receipts, head, unresolved_effects)
          return "unknown" if attempts.empty? && receipts.empty?

          return "uncertain" if unresolved_effects.any?

          return "terminal" if receipts.any? do |receipt|
            receipt["verdict"] == "succeeded" && receipt["head"] == head
          end

          "open"
        end

        def attempt_summary(attempt, active: nil)
          {
            "attempt_id" => attempt.attempt_id,
            "state" => attempt.state,
            "scope" => attempt.binding.scope,
            "recovery_mode" => attempt.recovery_mode,
            "active" => active ? active.attempt_id == attempt.attempt_id : false
          }
        end

        def evidence_git_ref(assignment)
          return nil unless assignment&.managed?

          journal.ref
        end
      end
    end
  end
end
