# frozen_string_literal: true

require_relative "ordinary_review_evidence"

module Ace
  module Assign
    module Authority
      module OrdinaryReviews
        include OrdinaryReviewEvidence
        REVIEW_OPERATIONS = %w[submit_candidate assign_review cancel_review export_candidate accept_review review_status].freeze
        REVIEW_TRANSFERS = {
          "submit_candidate" => {direction: :upload, purpose: :candidate, roles: %i[worker supervisor]},
          "export_candidate" => {direction: :download, purpose: :candidate, roles: %i[worker supervisor]},
          "accept_review" => {direction: :upload, purpose: :receipt_artifacts, roles: %i[worker supervisor]}
        }.freeze
        REVIEW_COMMON = %w[assignment_id attempt_id head candidate_generation pane].freeze
        REVIEW_PARAMETERS = {
          "submit_candidate" => REVIEW_COMMON + %w[expected_generation transfer],
          "assign_review" => REVIEW_COMMON + %w[expected_generation reviewer_assignment_id reviewer_attempt_id],
          "cancel_review" => REVIEW_COMMON + %w[expected_generation review_id],
          "export_candidate" => REVIEW_COMMON + %w[review_id],
          "accept_review" => REVIEW_COMMON + %w[expected_generation review_id receipt_sha256 transfer],
          "review_status" => %w[assignment_id attempt_id head candidate_generation]
        }.freeze

        private

        def validate_ordinary_review!(request)
          operation, params = request.values_at("operation", "params")
          strict!(params, REVIEW_PARAMETERS.fetch(operation))
          %w[assignment_id attempt_id reviewer_assignment_id reviewer_attempt_id review_id].each { |key| token!(params[key]) if params.key?(key) }
          unless params["head"].is_a?(String) && CandidateTransfer::SHA.match?(params["head"]) &&
              params["candidate_generation"].is_a?(Integer) && params["candidate_generation"] >= 0
            raise ArgumentError, "ordinary candidate selection is invalid"
          end
          if %w[export_candidate review_status].include?(operation)
            raise ArgumentError, "ordinary review read mutation must be null" unless request["mutation_id"].nil?
          else
            token!(request["mutation_id"])
            unless params["expected_generation"].is_a?(Integer) && params["expected_generation"].positive?
              raise ArgumentError, "ordinary review generation is invalid"
            end
          end
        end

        def authorize_ordinary_review!(request, peer, role, deadline, events: nil, commit: nil)
          authorize!(request, peer, role, deadline)
          validate_ordinary_review!(request)
          params = request.fetch("params")
          commit ||= @journal.ref_value
          events ||= result_events(params, commit)
          origin = origin_at!(events: events, commit: commit)
          operation = request.fetch("operation")
          return origin if operation == "review_status"
          identity = @admission.identity!(peer: peer, pane: params.fetch("pane"), deadline: deadline)
          case operation
          when "submit_candidate"
            unless identity.runtime_binding == origin.fetch("runtime_binding")
              raise AttemptErrors::UnauthorizedIdentity, "candidate belongs to its original native producer"
            end
          when "assign_review", "cancel_review"
            registered = registration(params.fetch("assignment_id"), commit: commit)
            unless role == :supervisor && identity.role == "coordinator" && identity.runtime_binding == supervisor_selection(registered, commit).fetch("binding")
              raise AttemptErrors::UnauthorizedIdentity, "review selection belongs to the current canonical supervisor"
            end
          when "export_candidate", "accept_review"
            candidate = candidate_at!(events: events, commit: commit, head: params.fetch("head"), generation: params.fetch("candidate_generation"))
            assigned = ordinary_review_assignment!(events, candidate)
            _, reviewer = ordinary_review_origins!(events, commit, assigned, reviewer_running: true)
            unless assigned.fetch("review_id") == params.fetch("review_id") && identity.runtime_binding == reviewer.fetch("runtime_binding") &&
                identity.actor == assigned.fetch("reviewer_actor") && peer.fetch("uid") == assigned.fetch("reviewer_uid")
              raise AttemptErrors::UnauthorizedIdentity, "review belongs to its assigned native agent"
            end
          end
          origin
        end

        def ordinary_review_operation(request, peer, role, deadline, transfer)
          params, operation = request.values_at("params", "operation")
          authorize_ordinary_review!(request, peer, role, deadline)
          admitted = if operation == "submit_candidate"
            raise ArgumentError, "ordinary candidate requires one bundle" unless transfer && transfer.count == 1
            descriptor = params.fetch("transfer")
            CandidateTransfer.new(root: @input_root).admit(bytes: transfer.bytes, sha256: descriptor.fetch("sha256"),
              size: descriptor.fetch("bytes"), head: params.fetch("head"), deadline: deadline)
          elsif operation == "accept_review"
            ReceiptTransfer.decode(input: transfer, receipt_sha256: params.fetch("receipt_sha256"), artifact_field: "artifacts", reference_key: "path")
          elsif transfer
            raise ArgumentError, "ordinary review operation forbids upload"
          end
          with_scope(assignment: params.fetch("assignment_id"), attempt: params.fetch("attempt_id"), deadline: deadline) do
            commit = @journal.ref_value
            events = result_events(params, commit)
            authorize_ordinary_review!(request, peer, role, deadline, events: events, commit: commit)
            if %w[export_candidate review_status].include?(operation)
              current = candidate_at!(events: events, commit: commit, head: params.fetch("head"), generation: params.fetch("candidate_generation"))
              assigned = ordinary_review_assignment!(events, current)
              if operation == "export_candidate"
                bytes = @journal.bounded_blob(current.fetch("bundle_ref"), commit: commit, max_bytes: CandidateTransfer::MAX_BYTES)
                return {data: current.merge("review_id" => assigned.fetch("review_id")), transfer_parts: [bytes], replayed: false}
              end
              accepted = events.any? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "accept_review" && event.dig("payload", "data", "review_id") == assigned.fetch("review_id") }
              value = accepted ? review_at!(events: events, commit: commit, head: params.fetch("head"), generation: params.fetch("candidate_generation")) : assigned
              return {data: value.merge("accepted" => accepted, "journal_commit" => commit), replayed: false}
            end
            digest = Atoms::EvidenceDigest.digest({"params" => params, "project_id" => @project, "peer_uid" => peer.fetch("uid")})
            replay = lambda do
              authorize_ordinary_review!(request, peer, role, deadline)
              if operation == "submit_candidate"
                ordinary_candidate_replay!(request, admitted)
              elsif operation == "accept_review"
                prefix = @journal.ref_value
                review_at!(events: result_events(params, prefix), commit: prefix, head: params.fetch("head"), generation: params.fetch("candidate_generation"))
              end
            end
            @journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: operation, parameters_digest: digest,
              expected_generation: params.fetch("expected_generation"), with_replay: true, deadline: deadline,
              replay_authorizer: replay) do |current_events, prefix, _generation|
              authorize_ordinary_review!(request, peer, role, deadline, events: current_events, commit: prefix)
              ordinary_review_plan(operation, params, peer, deadline, current_events, prefix, admitted, transfer)
            end
          end
        end

        def ordinary_review_plan(operation, params, peer, deadline, events, commit, admitted, transfer)
          if operation == "submit_candidate"
            current = ordinary_candidate_event(events)&.dig("payload", "data")
            unless (current && current.fetch("candidate_generation") || 0) == params.fetch("candidate_generation")
              raise AttemptErrors::Conflict, "ordinary candidate generation changed"
            end
            observed = @admission.execution!(peer: peer, pane: params.fetch("pane"), head: params.fetch("head"), deadline: deadline)
            unless observed.fetch(:identity).runtime_binding == origin_at!(events: events, commit: commit).fetch("runtime_binding")
              raise AttemptErrors::UnauthorizedIdentity, "ordinary candidate worker changed"
            end
            path = "candidates/bundles/#{SecureRandom.hex(16)}"
            return {events: [], blobs: {path => admitted.fetch("bundle")}, data: admitted.except("bundle").merge(
              "bundle_ref" => path, "candidate_generation" => params.fetch("candidate_generation") + 1,
              "producer_origin" => origin_at!(events: events, commit: commit))}
          end
          if operation == "cancel_review"
            assigned = ordinary_review_selection!(events, params.fetch("review_id")).fetch("payload").fetch("data")
            unless assigned.values_at("head", "candidate_generation") == params.values_at("head", "candidate_generation")
              raise AttemptErrors::Conflict, "ordinary revocation must select the original review candidate"
            end
            return {events: [], data: assigned.slice("head", "candidate_generation", "review_id")}
          end
          current = candidate_at!(events: events, commit: commit, head: params.fetch("head"), generation: params.fetch("candidate_generation"))
          if operation == "assign_review"
            prior = events.reverse.find { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "assign_review" &&
              event.dig("payload", "data", "candidate_generation") == current.fetch("candidate_generation") }
            if prior && !events.any? { |event| event.dig("payload", "operation") == "cancel_review" && event.dig("payload", "data", "review_id") == prior.dig("payload", "data", "review_id") }
              raise AttemptErrors::Conflict, "ordinary review is already assigned"
            end
            producer = origin_at!(events: events, commit: commit)
            reviewer_events = @journal.read_events(params.fetch("reviewer_assignment_id"), commit: commit)
              .select { |event| event["attempt_id"] == params.fetch("reviewer_attempt_id") }
            reviewer = ordinary_origin_at!(reviewer_events, commit, running: true)
            ordinary_independent_agents!(producer.fetch("runtime_binding"), reviewer.fetch("runtime_binding"))
            observed = @admission.recorded_binding!(binding: reviewer.fetch("runtime_binding"), deadline: deadline)
            unless observed == reviewer.fetch("runtime_binding")
              raise AttemptErrors::UnauthorizedIdentity, "ordinary reviewer native binding changed"
            end
            start = reviewer_events.find { |event| event["type"] == "process_start" }.fetch("payload")
            return {events: [], data: current.slice("head", "candidate_generation").merge(
              "review_id" => SecureRandom.hex(16), "reviewer_assignment_id" => params.fetch("reviewer_assignment_id"),
              "reviewer_attempt_id" => params.fetch("reviewer_attempt_id"), "reviewer_actor" => start.fetch("actor"),
              "reviewer_uid" => reviewer.dig("runtime_binding", "process_identity", "uid"),
              "reviewer_runtime_binding" => reviewer.fetch("runtime_binding"), "producer_origin" => producer, "reviewer_origin" => reviewer)}
          end
          assigned = ordinary_review_assignment!(events, current)
          raise AttemptErrors::Conflict, "ordinary review selection changed" unless assigned.fetch("review_id") == params.fetch("review_id")
          if events.any? { |event| event.dig("payload", "operation") == "accept_review" && event.dig("payload", "data", "review_id") == assigned.fetch("review_id") }
            raise AttemptErrors::Conflict, "ordinary review already accepted; retain original request"
          end
          observed = @admission.execution!(peer: peer, pane: params.fetch("pane"), head: current.fetch("head"), deadline: deadline)
          unless observed.fetch(:identity).runtime_binding == assigned.fetch("reviewer_runtime_binding") &&
              observed.fetch(:identity).actor == assigned.fetch("reviewer_actor")
            raise AttemptErrors::UnauthorizedIdentity, "ordinary reviewer changed before receipt acceptance"
          end
          ordinary_accept_review_plan(params, events, commit, assigned, admitted, transfer.bytes(index: 0))
        end

        def ordinary_candidate_replay!(request, admitted)
          retained = @journal.mutation_result(request.fetch("mutation_id"))
          data = retained.fetch("data")
          bytes = @journal.bounded_blob(data.fetch("bundle_ref"), commit: retained.fetch("journal_commit"), max_bytes: CandidateTransfer::MAX_BYTES)
          unless data.values_at("head", "tree", "sha256", "bytes") == admitted.values_at("head", "tree", "sha256", "bytes") &&
              bytes.bytesize == data.fetch("bytes") && Digest::SHA256.hexdigest(bytes) == data.fetch("sha256")
            raise AttemptErrors::EvidenceUnavailable, "ordinary retained candidate bytes differ"
          end
        end

        def ordinary_accept_review_plan(params, events, commit, assigned, admitted, original_bytes)
          original = admitted.fetch(:receipt)
          original_model = Models::ExecutionReceipt.from_h(original)
          unless (original.keys - original_model.to_h.keys).empty? &&
              original_model.digest == Atoms::EvidenceDigest.digest(original_model.digest_payload)
            raise AttemptErrors::ReceiptRejected, "ordinary uploaded review digest differs"
          end
          binding = assigned.except("generation", "journal_commit")
          canonical = Molecules::CanonicalEvidence.new(journal: @journal)
          plan = canonical.import_plan(**ordinary_review_context(binding), artifacts: [original_bytes] + admitted.fetch(:artifacts),
            admitted_after_event_digest: events.last.fetch("digest"))
          normalized = original.except("digest", "recorded_at").merge("artifacts" => plan.fetch(:references).drop(1).map { |ref| {"path" => ref.fetch("ref"), "sha256" => ref.fetch("sha256")} })
          pending = @journal.send(:chain_mutation_events, params.fetch("attempt_id"), events.last.fetch("digest"), plan.fetch(:events))
          reader = ->(_receipt, artifact) { canonical.read_pending({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
            **ordinary_review_context(binding), current_events: events, pending_events: pending, blobs: plan.fetch(:blobs), commit: commit) }
          verified = ordinary_verify_review!(normalized, events, commit, assigned, reader)
          path = plan.fetch(:references).first.fetch("ref")
          data = binding.slice("head", "candidate_generation", "review_id", "reviewer_uid", "reviewer_actor", "reviewer_runtime_binding", "producer_origin")
            .merge("review_binding" => binding, "review_receipt" => verified.to_h, "receipt_digest" => verified.digest,
              "original_receipt_ref" => path, "uploaded_receipt_sha256" => admitted.fetch(:receipt_sha256))
          raise AttemptErrors::ReceiptRejected, "ordinary review reply is oversized" if JSON.generate(data).bytesize > 12_000
          plan.merge(data: data)
        end
      end
    end
  end
end
