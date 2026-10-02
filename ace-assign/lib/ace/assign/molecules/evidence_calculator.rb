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
          attempts = assignment ? attempts_for(assignment) : []
          receipts = assignment ? accepted_receipts(assignment) : []

          review_receipt = receipt_currency(receipts, "review", head)
          release_receipt = receipt_currency(receipts, "release", head)
          unresolved_effects = collect_unresolved_effects(attempts)
          if assignment&.managed?
            requests = journal.service_requests(assignment.id)
            # A rejected effect stays unresolved when its claim had been
            # dispatched (authorization consumed): only attributable evidence
            # that no effect occurred settles it, never the bare rejection.
            unresolved_effects.concat(requests
              .select { |request| unresolved_service_state?(request) }
              .map { |request| "#{request["request_id"]}:#{request["operation"]}:#{request["state"]}" })
            # Settled requests keep their authorization only while their
            # receipt evidence remains intact in the candidate repository:
            # a deleted or modified artifact drops the outcome back to
            # unresolved instead of trusting an unverifiable receipt.
            unresolved_effects.concat(requests
              .select { |request| request["state"] == "succeeded" || request["state"] == "failed-settled" }
              .reject { |request| evidence_intact?(request) }
              .map { |request| "#{request["request_id"]}:#{request["operation"]}:evidence-unavailable" })
            unresolved_effects.uniq!
          end
          feedback_state = derive_feedback_state(attempts, receipts, head, unresolved_effects)

          # Authorization requires managed evidence, settled work (no active
          # attempts), no unresolved effects, and a current independent
          # review verdict. Taskless assignments never authorize merges.
          merge_decision = if auto_merge && assignment&.managed? &&
              review_receipt == "current" && unresolved_effects.empty? && attempts.none?(&:active?)
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
            journal_commit: assignment&.managed? ? journal.ref_value : latest&.journal_commit,
            unresolved_effects: unresolved_effects
          }
          evidence[:decision_digest] = Digest::SHA256.hexdigest(
            Atoms::EvidenceDigest.canonical_json(evidence)
          )
          evidence
        end

        private

        # Accepted, uncertain, and failed effects are unresolved by
        # definition; a rejected effect stays unresolved when its claim was
        # dispatched (authorization consumed), because the effect may have
        # happened.
        def unresolved_service_state?(request)
          %w[accepted uncertain failed].include?(request["state"]) ||
            (request["state"] == "rejected" && request["consumed"] != false)
        end

        # Every receipt evidence artifact must still exist in the candidate
        # repository with its recorded digest; evidence lives in the working
        # tree, so its integrity is re-checked on every calculation.
        def evidence_intact?(request)
          receipt = request["receipt"]
          return false unless receipt.is_a?(Hash)
          repo_root = File.realpath(@repo_root)
          Array(receipt["evidence"]).all? do |item|
            path = File.expand_path(item["ref"].to_s, repo_root)
            real = begin
              File.realpath(path)
            rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
              next false
            end
            begin
              real.start_with?(repo_root + File::SEPARATOR) &&
                Digest::SHA256.file(real).hexdigest == item["sha256"]
            rescue Errno::EACCES, Errno::ELOOP
              false
            end
          end
        end

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

        # Attempt state for evidence decisions. Managed assignments treat the
        # journal as authoritative: ALL journal-derived attempts (including
        # terminal states) replace local records with the same ID, so a crash
        # between journaling and the local save cannot leave stale open state.
        def attempts_for(assignment)
          attempts = store.list(assignment.id)
          return attempts unless assignment.managed?

          journal_by_id = {}
          journal.derived_attempts(assignment.id).each { |attempt| journal_by_id[attempt.attempt_id] = attempt }
          merged = attempts.map { |attempt| journal_by_id.delete(attempt.attempt_id) || attempt }
          merged + journal_by_id.values
        end

        # Accepted receipts for evidence currency. Managed assignments use
        # journal receipts only — the journal is the authority; local records
        # are disposable projections.
        def accepted_receipts(assignment)
          if assignment.managed?
            return journal.accepted_receipts(assignment.id).uniq { |receipt| receipt["digest"] }
          end

          store.list(assignment.id).flat_map(&:accepted_receipts)
            .uniq { |receipt| receipt["digest"] }
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

        # Feedback is derived: uncertain evidence wins, active attempts keep
        # the loop open, accepted current-head evidence closes it.
        def derive_feedback_state(attempts, receipts, head, unresolved_effects)
          return "unknown" if attempts.empty? && receipts.empty?

          return "uncertain" if unresolved_effects.any?

          return "terminal" if attempts.none?(&:active?) && receipts.any? do |receipt|
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
