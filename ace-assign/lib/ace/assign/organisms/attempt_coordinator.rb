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
        # conflicting binding raises {AttemptErrors::Conflict} without ever
        # launching a second writer.
        #
        # @param assignment_id [String] Assignment ID
        # @param step [String] Step/subtree scope
        # @param project_id [String] Project the attempt executes in
        # @param identity [ExecutionIdentityResolver::Identity, nil] Resolved when nil
        # @return [Models::Attempt] Active attempt (reused or newly reserved)
        def start(assignment_id:, step:, project_id:, identity: nil)
          assignment = @manager.load(assignment_id)
          raise AssignmentErrors::NotFound, "Assignment '#{assignment_id}' not found" unless assignment

          scope = Atoms::AssignmentScope.canonicalize(step)
          project = project_id.to_s.strip
          raise Error, "attempt start requires --project ID" if project.empty?

          identity ||= @identity_resolver.resolve
          base_head = candidate_head!
          attempt_id = Ace::B36ts.now
          events = start_events(assignment_id, assignment, scope, project, identity, base_head, attempt_id)

          @store.with_lock(assignment_id) do
            existing = @store.active(assignment_id, scope)
            if existing
              if existing.binding.project_id == project && existing.binding.task_id == assignment.task_id
                return existing
              end

              raise AttemptErrors::Conflict,
                "Active attempt #{existing.attempt_id} already owns #{assignment_id}@#{scope} " \
                "(project #{existing.binding.project_id}); refusing to launch a second writer"
            end

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
          attempt = @store.load(data["assignment_id"].to_s, attempt_id)
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

        private

        def reserve(assignment, scope, project, identity, base_head, attempt_id)
          binding = Models::AttemptBinding.new(
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
            payload: {"actor" => identity.actor, "role" => identity.role, "runtime" => identity.runtime},
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
