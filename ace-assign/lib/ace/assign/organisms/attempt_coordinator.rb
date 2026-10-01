# frozen_string_literal: true

require "json"
require "open3"

module Ace
  module Assign
    module Organisms
      # Authoritative coordinator for assignment attempts.
      #
      # The coordinator is the only authority allowed to reserve and start
      # attempts, accept authoritative receipts, transition attempt state,
      # invalidate stale candidate evidence, and write accepted journal
      # events. It composes the attempt store (local ownership), the evidence
      # journal (managed Git-ref evidence), the identity resolver (trusted
      # boundary), and the receipt verifier (acceptance rules).
      #
      # Guarantee: only one active attempt owns an assignment + subtree;
      # `base_head` is captured exactly once at start; `candidate_head` is
      # pinned only when candidate-bound evidence is accepted and any change
      # to the candidate revision invalidates prior candidate authorization;
      # `journal_commit` is tracked separately from both.
      class AttemptCoordinator
        # @param cache_base [String, nil] Assignment cache base
        # @param repo_root [String, nil] Candidate repository root (default: project root)
        # @param journal [Molecules::EvidenceJournal, nil] Evidence journal (default built per repo)
        # @param identity_resolver [Molecules::ExecutionIdentityResolver, nil] Trust boundary
        # @param verifier [Molecules::ReceiptVerifier, nil] Receipt verifier
        def initialize(cache_base: nil, repo_root: nil, journal: nil, identity_resolver: nil, verifier: nil,
          lifecycle_exclusion: nil)
          @manager = Molecules::AssignmentManager.new(cache_base: cache_base)
          @store = @manager.attempt_store
          @repo_root = repo_root || Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          @journal = journal
          @identity_resolver = identity_resolver || Molecules::ExecutionIdentityResolver.new
          @verifier = verifier || Molecules::ReceiptVerifier.new(identity_resolver: @identity_resolver)
          @lifecycle_exclusion = lifecycle_exclusion
        end

        attr_reader :store

        # Start a scoped attempt for an assignment.
        #
        # A repeated identical start returns the existing active attempt; a
        # conflicting or scope-overlapping binding raises
        # {AttemptErrors::Conflict} without ever launching a second writer.
        # Active attempts are resolved from the local store AND, for managed
        # assignments, from the authoritative journal, so a lost local record
        # cannot admit a competing writer.
        #
        # @param assignment_id [String] Assignment ID
        # @param step [String] Step/subtree scope
        # @param project_id [String] Project the attempt executes in
        # @param identity [ExecutionIdentityResolver::Identity, nil] Resolved when nil
        # @return [Models::Attempt] Active attempt (reused, recovered, or newly reserved)
        def start(assignment_id:, step:, project_id:, identity: nil)
          assignment = @manager.load(assignment_id)
          raise AssignmentErrors::NotFound, "Assignment '#{assignment_id}' not found" unless assignment

          scope = Atoms::AssignmentScope.canonicalize(step)
          project = project_id.to_s.strip
          raise Error, "attempt start requires --project ID" if project.empty?

          identity ||= @identity_resolver.resolve
          base_head = candidate_head!

          # Serialize writer registration against prune: prune holds the
          # exclusive exclusion from its final evidence reads through removal.
          # A worktree-backed task identity shares the same protocol (task
          # key first, then assignment key — the one consistent global
          # order), so a worktree prune and an attempt start cannot interleave.
          start_keys = []
          unless assignment.task_id.to_s.strip.empty?
            start_keys << lifecycle_exclusion.task_key(assignment.task_id)
          end
          start_keys << lifecycle_exclusion.assignment_key(assignment_id)
          lifecycle_exclusion.with_shared_multi(start_keys) do
            @store.with_lock(assignment_id) do
              journal_actives = assignment.managed? ? active_journal_attempts(assignment) : []

              existing = @store.active(assignment_id, scope) ||
                journal_actives.find { |attempt| Atoms::AssignmentScope.equal?(attempt.binding.scope, scope) }
              if existing
                if existing.binding.project_id == project && existing.binding.task_id == assignment.task_id &&
                    existing.binding.actor == identity.actor && existing.binding.role == identity.role
                  return existing
                end

                raise AttemptErrors::Conflict,
                  "Active attempt #{existing.attempt_id} already owns #{assignment_id}@#{scope} " \
                  "(project #{existing.binding.project_id}); refusing to launch a second writer"
              end

              active_scopes = @store.list(assignment_id).select(&:active?).map(&:binding)
              active_scopes.concat(journal_actives.map(&:binding))
              blocker = active_scopes.find { |binding| scopes_overlap?(binding.scope, scope) }
              if blocker
                raise AttemptErrors::Conflict,
                  "Active attempt scope #{blocker.scope} overlaps requested scope #{scope} on #{assignment_id}; " \
                  "refusing overlapping writers"
              end

              attempt_id = unique_attempt_id(assignment_id, journal_actives.map(&:attempt_id))
              events = start_events(assignment_id, assignment, scope, project, identity, base_head, attempt_id)
              attempt = reserve(assignment, scope, project, identity, base_head, attempt_id)
              if attempt.managed?
                commit = journal_for.append(
                  assignment_id: assignment_id,
                  attempt_id: attempt.attempt_id,
                  events: events
                )
                attempt = attempt.with(journal_commit: commit)
                attempt = yield_lost_ownership_race(attempt, assignment_id, scope)
              else
                attempt = attempt.with(events: events)
              end

              @store.save(attempt)
              @store.claim(assignment_id, scope, attempt)
              attempt
            end
          end
        end

        # Accept a receipt for an attempt and transition it.
        #
        # @param attempt_id [String] Attempt ID
        # @param receipt_path [String] Path to the receipt JSON file
        # @param identity [ExecutionIdentityResolver::Identity, nil] Resolved when nil
        # @return [Models::Attempt] Updated attempt
        def finish(attempt_id:, receipt_path:, identity: nil)
          data = read_receipt_file(receipt_path)
          assignment_id = data["assignment_id"].to_s

          # Serialize load-validate-accept so concurrent finishes observe one
          # consistent state and cannot persist contradictory terminal outcomes.
          @store.with_lock(assignment_id) do
            attempt = @store.load(assignment_id, attempt_id) || recover_managed_attempt(assignment_id, attempt_id)
            raise AttemptErrors::NotFound, "Attempt '#{attempt_id}' not found" unless attempt

            ensure_journal_consistent!(attempt) if attempt.managed?
            raise AttemptErrors::InvalidState, "Attempt #{attempt_id} is terminal; accepted history is immutable" if attempt.terminal?
            raise AttemptErrors::InvalidState, "Attempt #{attempt_id} is uncertain; reconcile before finishing" if attempt.uncertain?

            identity ||= @identity_resolver.resolve
            live_head = candidate_head!

            attempt = invalidate_stale_candidate(attempt, live_head)

            receipt = @verifier.verify!(
              data,
              attempt: attempt,
              identity: identity,
              live_head: live_head,
              repo_root: @repo_root
            )
            if @verifier.external_effect?(receipt.operation)
              unless attempt.managed?
                raise AttemptErrors::InvalidState,
                  "Taskless attempts cannot record external effects without managed evidence"
              end

              require_review_evidence(attempt, live_head)
            end

            accept(attempt, receipt, live_head)
          end
        end

        # Active-attempt projection for status surfaces.
        #
        # @param assignment_id [String] Assignment ID
        # @return [Hash, nil] Projection fields or nil when no attempt exists
        def status(assignment_id)
          attempts = @store.list(assignment_id)
          attempt = attempts.find(&:active?) || attempts.first
          return nil unless attempt

          attempt.projection
        end

        # Read accepted check evidence without transitions, locks, cache writes
        # or audit checkout creation. Managed history comes from the Git ref.
        def evidence(attempt_id:, receipt_digest:, kind: "check", check_name: "tests", historical_head: nil)
          unless %w[check review-collection review-approval].include?(kind) && check_name.is_a?(String) && !check_name.strip.empty?
            raise AttemptErrors::ReceiptRejected, "Invalid evidence kind or check name"
          end
          if !historical_head.nil? && (!%w[review-collection review-approval].include?(kind) || !historical_head.is_a?(String) ||
              !historical_head.match?(/\A[0-9a-f]{40,64}\z/))
            raise AttemptErrors::ReceiptRejected, "Historical evidence requires review collection/approval and an exact recorded head"
          end
          unless attempt_id.to_s.match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/) &&
              receipt_digest.to_s.match?(/\A[0-9a-f]{64}\z/)
            raise AttemptErrors::ReceiptRejected, "Invalid attempt ID or receipt digest"
          end
          attempt = @store.find(attempt_id) || recover_managed_attempt(nil, attempt_id)
          raise AttemptErrors::NotFound, "Attempt #{attempt_id} not found" unless attempt
          raise AttemptErrors::ReceiptRejected, "Execution evidence requires managed immutable journal history" unless attempt.managed?
          attempt = recover_managed_attempt(attempt.binding.assignment_id, attempt_id)
          raise AttemptErrors::ReceiptRejected, "No succeeded accepted attempt" unless attempt&.state == "succeeded"
          accepted = journal_for.accepted_receipts(attempt.binding.assignment_id)
          data = accepted.find { |r| r["attempt_id"] == attempt_id && r["digest"] == receipt_digest }
          raise AttemptErrors::ReceiptRejected, "Receipt was not accepted by coordinator" unless data
          if kind == "check" && (%w[review review-collect].include?(data["operation"]) || @verifier.external_effect?(data["operation"]))
            raise AttemptErrors::ReceiptRejected, "Review or external-effect operations cannot be check evidence"
          end
          expected_operation = case kind
          when "review-collection" then "review-collect"
          when "review-approval" then "review"
          else check_name == "tests" ? "test" : check_name
          end
          unless data["campaign"].nil? && data["operation"] == expected_operation
            raise AttemptErrors::ReceiptRejected, "Accepted receipt operation does not prove #{kind}: #{expected_operation}"
          end
          required_check = kind == "review-collection" ? "review-execution" : check_name
          unless kind == "review-approval" || Array(data["checks"]).any? { |check| check["name"] == required_check && check["verdict"] == "passed" }
            raise AttemptErrors::ReceiptRejected, "Accepted receipt does not prove the required check #{required_check}"
          end
          receipt = Models::ExecutionReceipt.from_h(data)
          unless receipt.digest == Atoms::EvidenceDigest.digest(receipt.digest_payload)
            raise AttemptErrors::ReceiptRejected, "Accepted receipt digest is corrupt"
          end
          evidence_head = historical_head || candidate_head!
          unless data["verdict"] == "succeeded" && data["head"] == evidence_head && attempt.candidate_head == evidence_head
            raise AttemptErrors::ReceiptRejected, "Accepted execution evidence is stale or unsuccessful"
          end
          @verifier.verify_accepted_evidence!(data, live_head: evidence_head, repo_root: @repo_root)
          {"attempt_id" => attempt_id, "receipt_digest" => receipt_digest, "head" => evidence_head, "kind" => kind,
           "historical" => !historical_head.nil?,
           "operation" => data["operation"], "checks" => data["checks"], "producer" => data["producer"], "review" => data["review"],
           "artifacts" => data["artifacts"], "assignment_id" => data["assignment_id"],
           "project_id" => data["project_id"], "scope" => data["scope"],
           "evidence_git_ref" => attempt.binding.evidence_git_ref, "journal_commit" => attempt.journal_commit}
        end

        # Reconcile an interrupted attempt.
        #
        # Running attempts are classified conservatively (stopped before
        # process start, uncertain when an effect cannot be proven either
        # way, still running only for verifiably live processes). Uncertain
        # attempts resolve only against a verified receipt attributed to the
        # recorded execution boundary. Reconciliation never replays merge,
        # publish, or deploy effects.
        #
        # @param attempt_id [String] Attempt ID
        # @param receipt_path [String, nil] Receipt JSON for resolving uncertainty
        # @param identity [ExecutionIdentityResolver::Identity, nil] Resolved when nil
        # @return [Models::Attempt] Updated attempt
        def reconcile(attempt_id:, receipt_path: nil, identity: nil)
          probe = @store.find(attempt_id) || recover_managed_attempt(nil, attempt_id)
          raise AttemptErrors::NotFound, "Attempt '#{attempt_id}' not found" unless probe

          @store.with_lock(probe.binding.assignment_id) do
            attempt = @store.load(probe.binding.assignment_id, attempt_id) ||
              recover_managed_attempt(probe.binding.assignment_id, attempt_id)
            raise AttemptErrors::NotFound, "Attempt '#{attempt_id}' not found" unless attempt

            derived = ensure_journal_consistent!(attempt, allow_uncertain: true) if attempt.managed?
            # The journal is authoritative for managed attempts: uncertainty
            # journaled after the local save drives reconciliation.
            attempt = attempt.with(state: derived.state) if derived&.state == "uncertain" && attempt.state == "running"

            if attempt.terminal?
              raise AttemptErrors::InvalidState, "Attempt #{attempt_id} is terminal; accepted history is immutable"
            end

            return classify_running(attempt) if attempt.state == "running"

            identity ||= @identity_resolver.resolve
            resolve_uncertain(attempt, receipt_path, identity)
          end
        end

        private

        # Attempt IDs must be unique per assignment AND globally: records,
        # journal events, and reconciliation lookups key on them. Allocation
        # runs under the assignment lock, avoids journal-known IDs, and
        # claims the ID atomically in the cross-assignment registry.
        def unique_attempt_id(assignment_id, taken_ids = [])
          base = Ace::B36ts.now
          suffix = 0
          100.times do
            candidate = suffix.zero? ? base : "#{base}#{suffix.to_s(36)}"
            suffix += 1
            next if taken_ids.include?(candidate)
            next unless @store.load(assignment_id, candidate).nil?
            return candidate if @store.reserve_id(candidate)
          end

          raise Error, "Failed to generate a unique attempt ID for #{assignment_id} after 100 attempts"
        end

        # Ancestors and descendants overlap: an active attempt for 010 owns
        # its 010.01 subtree, and vice versa.
        def scopes_overlap?(left, right)
          return true if Atoms::AssignmentScope.equal?(left, right)

          left.start_with?("#{right}.") || right.start_with?("#{left}.")
        end

        # Active attempts derived from the authoritative journal, used when
        # the local record may be missing (lost or wiped cache). Derivation
        # lives in the journal (owner of attempt-state interpretation).
        def active_journal_attempts(assignment)
          journal_for.active_attempts(assignment.id)
        end

        # Recover a managed attempt from the journal when the local record is
        # missing. With an assignment ID only that journal is consulted;
        # without one, assignment IDs are discovered from the evidence ref
        # itself, so a fully lost cache still reconciles.
        def recover_managed_attempt(assignment_id, attempt_id)
          if assignment_id
            assignment = @manager.load(assignment_id)
            # A surviving taskless record never consults the journal; a lost
            # record falls through to journal evidence (only managed attempts
            # are journaled).
            return nil if assignment && !assignment.managed?

            return journal_for.derived_attempts(assignment_id)
              .find { |candidate| candidate.attempt_id == attempt_id }
          end

          journal_for.assignment_ids.each do |journal_assignment_id|
            attempt = journal_for.derived_attempts(journal_assignment_id)
              .find { |candidate| candidate.attempt_id == attempt_id }
            return attempt if attempt
          end

          nil
        end

        # The journal is authoritative for managed attempts: a crash after a
        # journaled terminal/uncertain event but before the local save must
        # not admit contradictory transitions.
        def ensure_journal_consistent!(attempt, allow_uncertain: false)
          derived = journal_for.derived_attempts(attempt.binding.assignment_id)
            .find { |candidate| candidate.attempt_id == attempt.attempt_id }
          return if derived.nil?

          journal_state = derived.state
          if %w[succeeded failed stopped].include?(journal_state)
            raise AttemptErrors::InvalidState,
              "Journal shows attempt #{attempt.attempt_id} is #{journal_state}; accepted history is immutable"
          end
          return derived if allow_uncertain || journal_state != "uncertain" || attempt.uncertain?

          raise AttemptErrors::InvalidState,
            "Journal shows attempt #{attempt.attempt_id} is uncertain; reconcile before finishing"
        end

        # After appending our start events, revalidate ownership: a
        # coordinator with a separate cache directory may have claimed the
        # same scope between our read and our append (journal CAS replay
        # merges both). The loser records a stopped transition and refuses.
        def yield_lost_ownership_race(attempt, assignment_id, scope)
          rival = journal_for.active_attempts(assignment_id).find do |other|
            other.attempt_id != attempt.attempt_id && scopes_overlap?(other.binding.scope, scope)
          end
          return attempt if rival.nil?

          stopped = append_events(attempt, [transition_event(attempt, "stopped", "lost ownership race to #{rival.attempt_id}")])
          stopped = stopped.transition("stopped")
          @store.save(stopped)
          raise AttemptErrors::Conflict,
            "Active attempt #{rival.attempt_id} owns overlapping scope #{rival.binding.scope} on #{assignment_id}; " \
            "our start #{attempt.attempt_id} was recorded stopped without executing"
        end

        # Conservative classification of a running attempt after interruption.
        def classify_running(attempt)
          case reconciler.classify(attempt)
          when :live
            raise AttemptErrors::InvalidState,
              "Attempt #{attempt.attempt_id} process is verifiably live; reconcile after it exits"
          when :stopped
            attempt = append_events(attempt, [transition_event(attempt, "stopped", "interrupted before process start")])
            attempt = attempt.transition("stopped")
            @store.save(attempt)
            @store.release(attempt.binding.assignment_id, attempt.binding.scope, attempt.attempt_id)
            attempt
          else
            attempt = append_events(attempt, [transition_event(attempt, "uncertain", "effect completion cannot be proven or excluded")])
            attempt = attempt.transition("uncertain")
            @store.save(attempt)
            attempt
          end
        end

        # Resolve an uncertain attempt against a verified, boundary-attributed
        # receipt. Never resolves by assumption.
        def resolve_uncertain(attempt, receipt_path, identity)
          unless attempt.uncertain?
            raise AttemptErrors::InvalidState,
              "Attempt #{attempt.attempt_id} is #{attempt.state}; reconciliation targets uncertain attempts"
          end
          unless receipt_path
            raise AttemptErrors::InvalidState,
              "Reconciliation requires --receipt FILE; uncertain attempts are never resolved by assumption"
          end

          data = read_receipt_file(receipt_path)
          live_head = candidate_head!
          attempt = invalidate_stale_candidate(attempt, live_head)

          recorded = reconciler.recorded_runtime(attempt)
          unless data.dig("producer", "runtime") == recorded
            raise AttemptErrors::ReceiptRejected,
              "Receipt runtime #{data.dig('producer', 'runtime').inspect} does not match the recorded " \
              "execution boundary #{recorded.inspect}"
          end

          receipt = @verifier.verify!(
            data,
            attempt: attempt,
            identity: identity,
            live_head: live_head,
            repo_root: @repo_root
          )
          if @verifier.external_effect?(receipt.operation)
            unless attempt.managed?
              raise AttemptErrors::InvalidState,
                "Taskless attempts cannot record external effects without managed evidence"
            end

            require_review_evidence(attempt, live_head)
          end

          reconciliation = Models::EvidenceEvent.build(
            type: "reconciliation",
            attempt_id: attempt.attempt_id,
            payload: {"resolution" => receipt.verdict, "receipt_digest" => receipt.digest},
            previous_digest: last_event_digest(attempt)
          )
          accept(attempt, receipt, live_head, [reconciliation])
        end

        def transition_event(attempt, to, reason)
          Models::EvidenceEvent.build(
            type: "transition",
            attempt_id: attempt.attempt_id,
            payload: {"from" => attempt.state, "to" => to, "reason" => reason},
            previous_digest: last_event_digest(attempt)
          )
        end

        def reconciler
          @reconciler ||= Molecules::AttemptReconciler.new(journal: journal_for, verifier: @verifier)
        end

        def reserve(assignment, scope, project, identity, base_head, attempt_id)          binding = Models::AttemptBinding.new(
            attempt_id: attempt_id,
            assignment_id: assignment.id,
            scope: scope,
            project_id: project,
            task_id: assignment.task_id,
            actor: identity.actor,
            role: identity.role,
            runtime: identity.runtime,
            base_head: base_head,
            evidence_git_ref: assignment.managed? ? journal_for.ref : nil,
            created_at: Time.now.utc
          )
          Models::Attempt.new(binding: binding, state: "reserved").transition("running")
        end

        def start_events(assignment_id, assignment, scope, project, identity, base_head, attempt_id)
          intent = Models::EvidenceEvent.build(
            type: "intent",
            attempt_id: attempt_id,
            payload: {
              "assignment_id" => assignment_id,
              "scope" => scope,
              "project_id" => project,
              "task_id" => assignment.task_id,
              "base_head" => base_head
            }
          )
          process_start = Models::EvidenceEvent.build(
            type: "process_start",
            attempt_id: attempt_id,
            payload: {
              "actor" => identity.actor,
              "role" => identity.role,
              "runtime" => identity.runtime,
              "pid" => Process.pid
            },
            previous_digest: intent["digest"]
          )
          [intent, process_start]
        end

        # A changed candidate SHA invalidates prior candidate evidence and
        # authorizations; the change itself is journaled before anything else.
        def invalidate_stale_candidate(attempt, live_head)
          return attempt if attempt.candidate_head.nil? || attempt.candidate_head == live_head

          event = Models::EvidenceEvent.build(
            type: "candidate_invalidated",
            attempt_id: attempt.attempt_id,
            payload: {"previous_candidate_head" => attempt.candidate_head, "current_head" => live_head}
          )
          attempt = append_events(attempt, [event])
          attempt = attempt.with(candidate_head: nil, accepted_receipts: [])
          @store.save(attempt)
          attempt
        end

        def accept(attempt, receipt, live_head, pre_events = [])
          previous = pre_events.last&.dig("digest") || last_event_digest(attempt)
          event = Models::EvidenceEvent.build(
            type: "receipt_accepted",
            attempt_id: attempt.attempt_id,
            payload: {"receipt" => receipt.to_h},
            previous_digest: previous
          )
          attempt = append_events(attempt, pre_events + [event])

          receipts = attempt.accepted_receipts + [receipt.to_h]
          effects = attempt.effects
          if @verifier.external_effect?(receipt.operation)
            effects += [{"operation" => receipt.operation, "receipt_digest" => receipt.digest}]
          end

          attempt = attempt.with(
            candidate_head: attempt.candidate_head || receipt.head,
            accepted_receipts: receipts,
            effects: effects,
            state: attempt.state,
            updated_at: Time.now.utc
          )
          attempt = attempt.transition(receipt.verdict) if %w[succeeded failed].include?(receipt.verdict)

          @store.save(attempt)
          @store.release(attempt.binding.assignment_id, attempt.binding.scope, attempt.attempt_id) if attempt.terminal?

          attempt
        end

        def require_review_evidence(attempt, live_head)
          receipts = if attempt.managed?
            journal_for.read_events(attempt.binding.assignment_id)
              .select { |event| event["type"] == "receipt_accepted" }
              .map { |event| event.dig("payload", "receipt") }
              .compact
          else
            attempt.accepted_receipts
          end
          approved = receipts.any? do |candidate|
            candidate["operation"] == Molecules::ReceiptVerifier::REVIEW_OPERATION &&
              candidate["verdict"] == "succeeded" &&
              candidate["head"] == live_head &&
              candidate.dig("review", "verdict") == Molecules::ReceiptVerifier::APPROVED_VERDICT
          end
          return if approved

          raise AttemptErrors::ReceiptRejected,
            "External effect requires an executed independent review receipt for candidate #{live_head}"
        end

        def read_receipt_file(path)
          raise AttemptErrors::ReceiptRejected, "Receipt file not found: #{path}" unless File.exist?(path.to_s)

          data = JSON.parse(File.read(path))
          raise AttemptErrors::ReceiptRejected, "Receipt must be a JSON object" unless data.is_a?(Hash)

          data
        rescue JSON::ParserError => e
          raise AttemptErrors::ReceiptRejected, "Receipt file is not valid JSON: #{e.message}"
        end

        def append_events(attempt, events)
          if attempt.managed?
            commit = journal_for.append(
              assignment_id: attempt.binding.assignment_id,
              attempt_id: attempt.attempt_id,
              events: events
            )
            attempt.with(journal_commit: commit)
          else
            attempt.with(events: attempt.events + events)
          end
        end

        # Digest chain continuation: managed attempts chain through the
        # authoritative journal; taskless attempts chain through the local
        # event trail.
        def last_event_digest(attempt)
          if attempt.managed?
            journal_for.read_events(attempt.binding.assignment_id).last&.dig("digest")
          else
            attempt.events.last&.dig("digest")
          end
        end

        def journal_for
          @journal ||= Molecules::EvidenceJournal.new(repo_root: @repo_root)
          @journal
        end

        # Prune/writer exclusion shared with overseer prune (durable, outside
        # every deletion target).
        def lifecycle_exclusion
          @lifecycle_exclusion ||= Molecules::LifecycleExclusion.new(repo_root: @repo_root)
        end

        def candidate_head!
          out, status = Open3.capture2("git", "rev-parse", "HEAD", chdir: @repo_root, stdin_data: "")
          head = out.to_s.strip
          return head if status.success? && !head.empty?

          raise AttemptErrors::EvidenceUnavailable, "Cannot resolve candidate HEAD in #{@repo_root}"
        end
      end
    end
  end
end
