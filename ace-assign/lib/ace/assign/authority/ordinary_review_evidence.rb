# frozen_string_literal: true

require_relative "candidate_transfer"
require_relative "receipt_transfer"
require_relative "ordinary_review_collection"
require_relative "../molecules/canonical_evidence"

module Ace
  module Assign
    module Authority
      # Source-owned views of the same ordinary journal used by lifecycle CAS.
      # Caller labels, filesystem reports and protected launch tickets are not
      # alternate evidence sources. Service and merge consumers share this owner.
      module OrdinaryReviewEvidence
        include OrdinaryReviewCollection

        class CandidateReferenceView
          def initialize(owner, reference, deadline)
            @owner, @reference, @deadline = owner, JSON.parse(JSON.generate(reference)), deadline
            @thread, @active = Thread.current, true
          end
          def close = @active = false
          def read!(reference:)
            unless @active && Thread.current.equal?(@thread) && reference == @reference &&
                Process.clock_gettime(Process::CLOCK_MONOTONIC) < @deadline
              raise AttemptErrors::EvidenceUnavailable, "canonical candidate view escaped its held scope"
            end
            @owner.send(:resolve_candidate_reference!, reference: @reference, deadline: @deadline)
          end
        end

        # Resolve a closed accepted reference without trusting a requester's
        # head/path. Keep the existing scope held while consumers read bytes.
        def with_candidate_reference(reference:, deadline:)
          with_candidate_reference_scope(reference: reference, deadline: deadline) do |view|
            yield(*view.read!(reference: reference))
          end
        end

        # Lock order is lifecycle scope → journal writer. The bounded reader
        # may re-resolve a new CAS prefix without reacquiring lifecycle locks.
        def with_candidate_reference_scope(reference:, deadline:)
          unless reference.is_a?(Hash) && reference.keys.sort ==
              %w[acceptance_event_digest assignment_id attempt_id candidate_generation] &&
              reference["candidate_generation"].is_a?(Integer) && reference["candidate_generation"].positive? &&
              reference["acceptance_event_digest"].is_a?(String) && reference["acceptance_event_digest"].match?(/\A[0-9a-f]{64}\z/)
            raise ArgumentError, "invalid canonical candidate reference"
          end
          with_scope(assignment: reference.fetch("assignment_id"), attempt: reference.fetch("attempt_id"), deadline: deadline) do
            reader = CandidateReferenceView.new(self, reference, deadline)
            begin
              yield reader
            ensure
              reader.close
            end
          end
        end

        private def resolve_candidate_reference!(reference:, deadline:)
          commit = @journal.ref_value
          events = @journal.read_events(reference.fetch("assignment_id"), commit: commit)
            .select { |event| event["attempt_id"] == reference.fetch("attempt_id") }
          current = ordinary_candidate_event(events)
          unless current && current.fetch("digest") == reference.fetch("acceptance_event_digest")
            raise AttemptErrors::Conflict, "canonical candidate reference was replaced"
          end
          head = current.fetch("payload").fetch("data").fetch("head")
          candidate = candidate_at!(events: events, commit: commit, head: head, generation: reference.fetch("candidate_generation"))
          unless candidate_reference_at!(events: events, commit: commit, head: head,
              generation: reference.fetch("candidate_generation")) == reference
            raise AttemptErrors::Conflict, "canonical candidate association differs"
          end
          origin = origin_at!(events: events, commit: commit)
          unless @admission.recorded_binding!(binding: origin.fetch("runtime_binding"), deadline: deadline) == origin.fetch("runtime_binding")
            raise AttemptErrors::UnauthorizedIdentity, "candidate producer native binding differs"
          end
          bytes = @journal.bounded_blob(candidate.fetch("bundle_ref"), commit: commit, max_bytes: CandidateTransfer::MAX_BYTES)
          [candidate, origin, commit, bytes]
        end

        def with_scope(assignment:, attempt:, deadline:)
          token!(assignment)
          token!(attempt)
          selected = registration(assignment, commit: @journal.ref_value)
          raise AttemptErrors::NotFound, "ordinary assignment is not registered" unless selected
          if ordinary_evidence_scope(assignment: assignment, attempt: attempt, task_id: selected.fetch("task_id"))
            return yield @journal, selected
          end
          @exclusion.with_shared_multi([@exclusion.task_key(selected.fetch("task_id")),
            @exclusion.assignment_key(assignment)], deadline: deadline) do
            with_ordinary_evidence_scope(assignment: assignment, attempt: attempt, task_id: selected.fetch("task_id"), mode: :shared) do
              yield @journal, selected
            end
          end
        end

        private def ordinary_evidence_scope(assignment:, attempt:, task_id:)
          @ordinary_scope_mutex.synchronize do
            held = @ordinary_scopes[Thread.current]
            if held && held.values_at(:assignment, :attempt, :task_id) != [assignment, attempt, task_id]
              raise AttemptErrors::EvidenceUnavailable, "ordinary evidence scope association differs"
            end
            held
          end
        end

        private def with_ordinary_evidence_scope(assignment:, attempt:, task_id:, mode:)
          raise AttemptErrors::EvidenceUnavailable, "ordinary evidence scope already held" if ordinary_evidence_scope(
            assignment: assignment, attempt: attempt, task_id: task_id)
          @ordinary_scope_mutex.synchronize do
            @ordinary_scopes[Thread.current] = {assignment: assignment, attempt: attempt, task_id: task_id, mode: mode}.freeze
          end
          begin
            yield
          ensure
            @ordinary_scope_mutex.synchronize { @ordinary_scopes.delete(Thread.current) }
          end
        end

        private def ordinary_candidate_reference(request, peer, role, deadline)
          params = request.fetch("params")
          strict!(params, %w[assignment_id attempt_id])
          raise ArgumentError, "candidate reference read mutation must be null" unless request.fetch("mutation_id").nil?
          with_scope(assignment: params.fetch("assignment_id"), attempt: params.fetch("attempt_id"), deadline: deadline) do
            commit = @journal.ref_value
            events = result_events(params, commit)
            current = ordinary_candidate_event(events)&.dig("payload", "data")
            raise AttemptErrors::NotFound, "ordinary candidate is unavailable" unless current
            reference = candidate_reference_at!(events: events, commit: commit, head: current.fetch("head"),
              generation: current.fetch("candidate_generation"))
            with_candidate_reference(reference: reference, deadline: deadline) do
              authorize!(request, peer, role, deadline)
              {data: reference, replayed: false}
            end
          end
        end

        def origin_at!(events:, commit:)
          ordinary_origin_at!(events, commit, running: true)
        end

        def candidate_at!(events:, commit:, head:, generation:)
          origin_at!(events: events, commit: commit)
          selected = ordinary_candidate_event(events)&.dig("payload", "data")
          unless selected && selected.values_at("head", "candidate_generation") == [head, generation]
            raise AttemptErrors::Conflict, "ordinary candidate changed"
          end
          bytes = @journal.bounded_blob(selected.fetch("bundle_ref"), commit: commit, max_bytes: CandidateTransfer::MAX_BYTES)
          unless bytes.bytesize == selected.fetch("bytes") && Digest::SHA256.hexdigest(bytes) == selected.fetch("sha256")
            raise AttemptErrors::EvidenceUnavailable, "ordinary canonical candidate is corrupt"
          end
          selected.slice("head", "tree", "candidate_generation", "bundle_ref", "sha256", "bytes")
        end

        def candidate_reference_at!(events:, commit:, head:, generation:)
          candidate_at!(events: events, commit: commit, head: head, generation: generation)
          origin = origin_at!(events: events, commit: commit)
          origin.slice("assignment_id", "attempt_id").merge("candidate_generation" => generation,
            "acceptance_event_digest" => ordinary_candidate_event(events).fetch("digest"))
        end

        def review_at!(events:, commit:, head:, generation:)
          current = candidate_at!(events: events, commit: commit, head: head, generation: generation)
          assigned = ordinary_review_assignment!(events, current)
          ordinary_review_receipt_at!(events: events, commit: commit, assigned: assigned)
        end

        # Historical campaign consumption selects the original review without
        # calling it a current candidate approval. Cancellation is still current.
        def review_at_reference!(events:, commit:, review_id:, head:)
          assigned = ordinary_review_selection!(events, review_id).fetch("payload").fetch("data")
          raise AttemptErrors::ReceiptRejected, "ordinary historical reviewed head differs" unless assigned.fetch("head") == head
          ordinary_review_receipt_at!(events: events, commit: commit, assigned: assigned)
        end

        private def ordinary_review_receipt_at!(events:, commit:, assigned:)
          ordinary_review_origins!(events, commit, assigned)
          accepted = events.reverse.find { |event| event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "accept_review" && event.dig("payload", "data", "review_id") == assigned.fetch("review_id") }
          data = accepted && accepted.dig("payload", "data")
          unless data && data.fetch("review_binding") == assigned.except("generation", "journal_commit")
            raise AttemptErrors::ReceiptRejected, "ordinary candidate has no accepted independent review"
          end
          canonical = Molecules::CanonicalEvidence.new(journal: @journal)
          reader = ->(_receipt, artifact) { canonical.read({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
            **ordinary_review_context(data.fetch("review_binding")), commit: commit) }
          receipt = data.fetch("review_receipt")
          verified = ordinary_verify_review!(receipt, events, commit, assigned, reader)
          original = canonical.read({"ref" => data.fetch("original_receipt_ref"), "sha256" => data.fetch("uploaded_receipt_sha256")},
            **ordinary_review_context(data.fetch("review_binding")), commit: commit)
          unless Digest::SHA256.hexdigest(original) == data.fetch("uploaded_receipt_sha256") &&
              verified.digest == data.fetch("receipt_digest")
            raise AttemptErrors::EvidenceUnavailable, "ordinary accepted review bytes differ"
          end
          original_data = JSON.parse(original)
          original_receipt = Models::ExecutionReceipt.from_h(original_data)
          unless original_receipt.digest == Atoms::EvidenceDigest.digest(original_receipt.digest_payload) &&
              original_data.except("digest", "recorded_at", "artifacts") == receipt.except("digest", "recorded_at", "artifacts") &&
              original_data.fetch("artifacts").map { |value| value.fetch("sha256") } == receipt.fetch("artifacts").map { |value| value.fetch("sha256") }
            raise AttemptErrors::EvidenceUnavailable, "ordinary review original and canonical receipt differ"
          end
          data.merge("acceptance_event_digest" => accepted.fetch("digest"), "recorded_at" => accepted.fetch("recorded_at"))
        rescue JSON::ParserError, KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "ordinary accepted review is incomplete"
        end

        private

        def ordinary_origin_at!(events, commit, running:)
          raise AttemptErrors::Conflict, "ordinary evidence prefix changed" unless commit && @journal.ref_value == commit
          intent = events.select { |event| event["type"] == "intent" }
          starts = events.select { |event| event["type"] == "process_start" }
          accepted = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "start_attempt" }
          unless Models::EvidenceEvent.chain_valid?(events) && intent.one? && starts.one? && accepted.one?
            raise AttemptErrors::EvidenceUnavailable, "ordinary native origin is unavailable"
          end
          assignment, attempt = intent.first.dig("payload", "assignment_id"), intent.first.fetch("attempt_id")
          token!(assignment)
          token!(attempt)
          registered = registration(assignment, commit: commit)
          retained = @journal.read_events(assignment, commit: commit).select { |event| event["attempt_id"] == attempt }
          start, data = starts.first.fetch("payload"), accepted.first.fetch("payload").fetch("data")
          unless registered && retained == events && data.values_at("authority", "project_id", "assignment_id", "attempt_id", "runtime_binding") ==
              ["ordinary", @project, assignment, attempt, start.fetch("runtime_binding")] &&
              intent.first.dig("payload", "project_id") == @project
            raise AttemptErrors::EvidenceUnavailable, "ordinary native origin differs from accepted start"
          end
          if running && Molecules::CanonicalAttemptState.derive(events) != "running"
            raise AttemptErrors::Conflict, "ordinary delivery requires its original running attempt"
          end
          {"authority" => "ordinary", "project_id" => @project, "assignment_id" => assignment, "attempt_id" => attempt,
            "intent_digest" => intent.first.fetch("digest"), "process_start_digest" => starts.first.fetch("digest"),
            "runtime_binding" => start.fetch("runtime_binding"), "scope" => intent.first.dig("payload", "scope"),
            "base_head" => intent.first.dig("payload", "base_head")}
        end

        def ordinary_candidate_event(events)
          events.reverse.find { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "submit_candidate" }
        end

        def ordinary_review_assignment!(events, candidate)
          selected = events.reverse.find { |event| event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "assign_review" &&
            event.dig("payload", "data", "candidate_generation") == candidate.fetch("candidate_generation") }
          data = selected && selected.dig("payload", "data")
          cancelled = selected && events.any? { |event| event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "cancel_review" && event.dig("payload", "data", "review_id") == data.fetch("review_id") }
          unless data && data.fetch("head") == candidate.fetch("head") && !cancelled
            raise AttemptErrors::ReceiptRejected, "ordinary independent review assignment is absent or revoked"
          end
          data
        end

        def ordinary_review_selection!(events, review_id)
          token!(review_id)
          selected = events.select { |event| event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "assign_review" && event.dig("payload", "data", "review_id") == review_id }
          if !selected.one? || events.any? { |event| event["type"] == "authority_mutation" &&
              event.dig("payload", "operation") == "cancel_review" && event.dig("payload", "data", "review_id") == review_id }
            raise AttemptErrors::ReceiptRejected, "ordinary review selection is absent or revoked"
          end
          selected.first
        end

        def ordinary_review_origins!(events, commit, assigned, reviewer_running: false)
          producer = origin_at!(events: events, commit: commit)
          reviewer_events = @journal.read_events(assigned.fetch("reviewer_assignment_id"), commit: commit)
            .select { |event| event["attempt_id"] == assigned.fetch("reviewer_attempt_id") }
          reviewer = ordinary_origin_at!(reviewer_events, commit, running: reviewer_running)
          unless producer == assigned.fetch("producer_origin") && reviewer == assigned.fetch("reviewer_origin")
            raise AttemptErrors::EvidenceUnavailable, "ordinary review origins differ"
          end
          ordinary_independent_agents!(producer.fetch("runtime_binding"), reviewer.fetch("runtime_binding"))
          [producer, reviewer]
        end

        def ordinary_independent_agents!(producer, reviewer)
          sessions = [producer, reviewer].map { |binding|
            Ace::Herdr::Atoms::NativeAgentSession.normalize(binding.fetch("agent_session"), agent: binding.fetch("agent")) }
          identities = [producer, reviewer].map { |binding|
            identity = binding.fetch("process_identity")
            unless identity.is_a?(Hash) && %w[pid uid started_at host].all? { |key| identity.key?(key) }
              raise AttemptErrors::EvidenceUnavailable, "ordinary agent process generation is missing"
            end
            identity.values_at("pid", "uid", "started_at", "host") }
          unless sessions.all? && sessions[0].fetch("value").downcase != sessions[1].fetch("value").downcase && identities[0] != identities[1] && producer.fetch("pane") != reviewer.fetch("pane")
            raise AttemptErrors::ReceiptRejected, "review requires an independently started native agent and session"
          end
          true
        rescue KeyError
          raise AttemptErrors::EvidenceUnavailable, "ordinary agent identity is incomplete"
        end

        def ordinary_review_context(binding)
          {kind: "review", project_id: @project, assignment_id: binding.fetch("producer_origin").fetch("assignment_id"),
            attempt_id: binding.fetch("producer_origin").fetch("attempt_id"), peer_uid: binding.fetch("reviewer_uid"),
            binding: binding, request_id_or_event_id: binding.fetch("review_id"), generation: binding.fetch("candidate_generation")}
        end

        def ordinary_verify_review!(receipt, events, commit, assigned, reader)
          origin = origin_at!(events: events, commit: commit)
          producer = events.find { |event| event["type"] == "process_start" }.fetch("payload").slice("actor", "role", "runtime")
          unless receipt["operation"] == "review" && receipt["verdict"] == "succeeded" && !receipt["campaign"] &&
              receipt["producer"] == producer && receipt.dig("review", "reviewer", "actor") == assigned.fetch("reviewer_actor")
            raise AttemptErrors::ReceiptRejected, "ordinary review receipt attribution differs"
          end
          attempt = @journal.derived_attempts(origin.fetch("assignment_id"), commit: commit)
            .find { |value| value.attempt_id == origin.fetch("attempt_id") }
          independence = ->(_data) { ordinary_review_origins!(events, commit, assigned); true }
          Molecules::ReceiptVerifier.new(artifact_reader: reader, review_independence_verifier: independence)
            .verify_result!(receipt, attempt: attempt, live_head: assigned.fetch("head"), repo_root: @journal.repo_root)
        end
      end
    end
  end
end
