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
        def initialize(cache_base: nil, repo_root: nil, journal: nil, identity_resolver: nil, verifier: nil)
          @manager = Molecules::AssignmentManager.new(cache_base: cache_base)
          @store = @manager.attempt_store
          @repo_root = repo_root || Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          @journal = journal
          @identity_resolver = identity_resolver || Molecules::ExecutionIdentityResolver.new
          @verifier = verifier || Molecules::ReceiptVerifier.new(identity_resolver: @identity_resolver)
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

          @store.with_lock(assignment_id) do
            journal_actives = assignment.managed? ? active_journal_attempts(assignment) : []

            existing = @store.active(assignment_id, scope) ||
              journal_actives.find { |attempt| Atoms::AssignmentScope.equal?(attempt.binding.scope, scope) }
            if existing
              if existing.binding.project_id == project && existing.binding.task_id == assignment.task_id
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
            else
              attempt = attempt.with(events: events)
            end

            @store.save(attempt)
            @store.claim(assignment_id, scope, attempt)
            attempt
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

            if attempt.terminal?
              raise AttemptErrors::InvalidState, "Attempt #{attempt_id} is terminal; accepted history is immutable"
            end

            return classify_running(attempt) if attempt.state == "running"

            identity ||= @identity_resolver.resolve
            resolve_uncertain(attempt, receipt_path, identity)
          end
        end

        private

        # Attempt IDs must be unique per assignment: records and journal
        # events are keyed by them. Allocation happens under the assignment
        # lock and also avoids IDs already present in the journal.
        def unique_attempt_id(assignment_id, taken_ids = [])
          taken = taken_ids.dup
          base = Ace::B36ts.now
          suffix = 0
          100.times do
            candidate = suffix.zero? ? base : "#{base}#{suffix.to_s(36)}"
            taken << candidate unless taken.include?(candidate)
            return candidate if @store.load(assignment_id, candidate).nil?

            suffix += 1
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
        # the local record may be missing (lost or wiped cache). Reconstructs
        # bindings from recorded intent/process_start facts.
        def active_journal_attempts(assignment)
          events = journal_for.read_events(assignment.id)
          by_attempt = events.group_by { |event| event["attempt_id"] }
          by_attempt.delete(nil)

          by_attempt.filter_map do |attempt_id, attempt_events|
            intent = attempt_events.find { |event| event["type"] == "intent" }
            next unless intent

            state = derive_journal_state(attempt_events)
            next if %w[succeeded failed stopped].include?(state)

            recover_attempt_from_events(assignment.id, attempt_id, intent["payload"], attempt_events, state)
          end
        end

        # Recover a single managed attempt by ID from the journal; nil when
        # the journal shows no such (non-terminal) attempt.
        def recover_managed_attempt(assignment_id, attempt_id)
          candidates = if assignment_id
            [@manager.load(assignment_id)].compact
          else
            # Attempt ID alone: scan recent assignments via the store.
            []
          end

          candidates.each do |assignment|
            next unless assignment.managed?

            events = journal_for.read_events(assignment.id)
            attempt_events = events.select { |event| event["attempt_id"] == attempt_id }
            intent = attempt_events.find { |event| event["type"] == "intent" }
            next unless intent

            state = derive_journal_state(attempt_events)
            attempt = recover_attempt_from_events(
              assignment.id, attempt_id, intent["payload"], attempt_events, state
            )
            return attempt if state == "running" || state == "uncertain"

            return Models::Attempt.new(binding: attempt.binding, state: state, journal_commit: journal_for.ref_value)
          end

          nil
        end

        def derive_journal_state(events)
          state = "running"
          events.each do |event|
            case event["type"]
            when "receipt_accepted"
              state = event.dig("payload", "receipt", "verdict") || state
            when "transition"
              state = event.dig("payload", "to") || state
            when "reconciliation"
              state = event.dig("payload", "resolution") || state
            end
          end
          state
        end

        def recover_attempt_from_events(assignment_id, attempt_id, intent_payload, events, state)
          process_start = events.reverse.find { |event| event["type"] == "process_start" }
          binding = Models::AttemptBinding.new(
            attempt_id: attempt_id,
            assignment_id: assignment_id,
            scope: intent_payload["scope"],
            project_id: intent_payload["project_id"],
            task_id: intent_payload["task_id"],
            actor: process_start&.dig("payload", "actor") || "recovered",
            role: process_start&.dig("payload", "role") || "coordinator",
            runtime: process_start&.dig("payload", "runtime") || "recovered",
            base_head: intent_payload["base_head"],
            evidence_git_ref: journal_for.ref,
            created_at: parse_event_time(intent_payload["recorded_at"])
          )
          Models::Attempt.new(
            binding: binding,
            state: state,
            journal_commit: journal_for.ref_value
          )
        end

        def parse_event_time(value)
          return Time.now.utc if value.nil?

          require "time"
          Time.parse(value)
        rescue ArgumentError
          Time.now.utc
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
          attempt = append_events(attempt, [reconciliation])
          accept(attempt, receipt, live_head)
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

        def accept(attempt, receipt, live_head)
          event = Models::EvidenceEvent.build(
            type: "receipt_accepted",
            attempt_id: attempt.attempt_id,
            payload: {"receipt" => receipt.to_h},
            previous_digest: last_event_digest(attempt)
          )
          attempt = append_events(attempt, [event])

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
