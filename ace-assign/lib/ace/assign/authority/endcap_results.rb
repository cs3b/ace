# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class Endcap
        RESULT_FIELDS = %w[result_id head candidate_generation verdict uploaded_receipt_sha256
          original_receipt_digest receipt_digest artifacts].freeze
        RESULT_PAYLOAD_FIELDS = %w[version result_id binding uploaded_receipt_sha256
          original_receipt_digest receipt_digest receipt artifacts].freeze
        RESULT_BINDING_FIELDS = %w[mapping_id project_id assignment_id attempt_id result_id worker_uid
          worker_actor launch_ticket process_binding head candidate_generation uploaded_receipt_sha256
          original_receipt_digest].freeze
        DIGEST = /\A[0-9a-f]{64}\z/

        # Attached to the existing launch status owner, never a second route.
        def result_status(journal:, events:, params:, map:, peer:, role:, commit:)
          protected_journal!(journal)
          @kernel.live!(peer)
          service_policy!.visible!(project: map.fetch("project_id"), uid: peer.fetch("uid"))
          raise AttemptErrors::UnauthorizedIdentity, "executor result discovery is unauthorized" if role == :executor
          origin = retained_origin(events, params)
          selected = params.fetch("result_candidate_generation")
          current = selected.nil? ? candidate(events) : retained_candidate(events, selected)
          if !current && events.any? { |event| event["type"] == "result_submitted" &&
              (selected.nil? || event.dig("payload", "binding", "candidate_generation") == selected) }
            raise AttemptErrors::EvidenceUnavailable, "submitted result candidate is missing"
          end
          raise AttemptErrors::NotFound, "candidate not found" if !selected.nil? && !current
          purpose_peer!(events, params, map, origin, peer, role, kind: "result", current: current)
          result = current && verified_result(journal, events, params, map, origin, current, commit)
          {"result_candidate_generation" => current && current.fetch("candidate_generation"),
            "submitted_result" => result && result_projection(result),
            "authority_generation" => journal.authority_generation(events)}
        end

        private

        def result_request(request)
          operation = request.fetch("operation")
          params = request.fetch("params")
          unless params.is_a?(Hash) && params.keys.sort == PARAMETERS.fetch(operation).sort
            raise ArgumentError, "result authority fields differ"
          end
          %w[mapping_id assignment_id attempt_id].each { |key| result_id!(params[key]) }
          if operation == "submit_result"
            result_id!(request.fetch("mutation_id"))
            unless params["head"].is_a?(String) && params["head"].match?(CandidateTransfer::SHA) &&
                %w[expected_generation candidate_generation].all? { |key| params[key].is_a?(Integer) && params[key] >= 0 } &&
                params["receipt_sha256"].is_a?(String) && params["receipt_sha256"].match?(DIGEST)
              raise ArgumentError, "invalid result candidate or digest"
            end
          else
            raise ArgumentError, "fetch mutation ID must be null" unless request.fetch("mutation_id").nil?
            raise ArgumentError, "unknown evidence kind" unless Molecules::CanonicalEvidence::ROLES.key?(params["kind"])
            %w[purpose_id artifact_id].each { |key| result_id!(params[key]) }
          end
          map = @deployment.mapping(params.fetch("mapping_id"))
          raise AttemptErrors::UnauthorizedIdentity, "project mapping differs" unless map.fetch("project_id") == request.fetch("project_id")
          [params, map]
        end

        def result_id!(value)
          raise ArgumentError, "invalid result identifier" unless value.is_a?(String) && value.match?(Molecules::JournalMutation::ID)
        end

        def retained_origin(events, params)
          raise AttemptErrors::EvidenceUnavailable, "canonical attempt chain differs" unless Models::EvidenceEvent.chain_valid?(events)
          @launch.origin(events, assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
            mapping_id: params.fetch("mapping_id"))
        end

        def retained_candidate(events, generation)
          candidates = events.filter_map do |event|
            event.dig("payload", "data") if event["type"] == "authority_mutation" &&
              event.dig("payload", "operation") == "submit_candidate" &&
              event.dig("payload", "data", "candidate_generation") == generation
          end
          raise AttemptErrors::EvidenceUnavailable, "duplicate candidate generation" if candidates.length > 1
          candidates.first
        end

        def submitting_worker!(events, params, map, peer, role)
          origin = retained_origin(events, params)
          unless %w[bound issued].include?(origin["phase"]) &&
              !events.any? { |event| %w[receipt_accepted transition reconciliation].include?(event["type"]) &&
                %w[succeeded failed stopped uncertain].include?(event.dig("payload", "to") ||
                  event.dig("payload", "resolution") || event.dig("payload", "receipt", "verdict")) }
            raise AttemptErrors::EvidenceUnavailable, "result attempt is no longer live and active"
          end
          raise AttemptErrors::UnauthorizedIdentity, "result requires owning worker" unless role == :worker && peer["uid"] == map.fetch("worker_uid")
          @kernel.live!(peer)
          @kernel.live!(origin.fetch("process_binding").fetch("process_identity"))
          @kernel.live!(origin.fetch("process_binding").fetch("native_origin").fetch("server_identity"))
          unless @kernel.descendant?(peer, origin.fetch("process_binding").fetch("process_identity"))
            raise AttemptErrors::UnauthorizedIdentity, "result worker incarnation differs"
          end
          service_policy!.visible!(project: map.fetch("project_id"), uid: peer.fetch("uid"))
          origin
        end

        def authorize_result_transfer!(request:, peer:, role:)
          params, map = result_request(request)
          with_inbox_read_contexts(params, map) { authorize_admitted_result_transfer!(request: request, peer: peer, role: role) }
        end

        def authorize_admitted_result_transfer!(request:, peer:, role:)
          params, map = result_request(request)
          @launch.with_assignment(params: params, map: map) do |journal, _|
            protected_journal!(journal)
            commit = journal.ref_value
            events = journal.read_events(params.fetch("assignment_id"), commit: commit)
              .select { |event| event["attempt_id"] == params.fetch("attempt_id") }
            if request.fetch("operation") == "submit_result"
              submitting_worker!(events, params, map, peer, role)
            else
              fetch_plan(journal, events, params, map, peer, role, commit)
            end
          end
          true
        end

        def dispatch_result(request:, peer:, role:, transfer: nil)
          params, map = result_request(request)
          with_inbox_read_contexts(params, map) { dispatch_admitted_result(request: request, peer: peer, role: role, transfer: transfer) }
        end

        def dispatch_admitted_result(request:, peer:, role:, transfer: nil)
          params, map = result_request(request)
          admitted = if request.fetch("operation") == "submit_result"
            authorize_result_transfer!(request: request, peer: peer, role: role)
            ReceiptTransfer.decode(input: transfer, receipt_sha256: params.fetch("receipt_sha256"),
              artifact_field: "artifacts", reference_key: "path")
          end
          @launch.with_assignment(params: params, map: map) do |journal, _|
            protected_journal!(journal)
            commit = journal.ref_value
            events = journal.read_events(params.fetch("assignment_id"), commit: commit)
              .select { |event| event["attempt_id"] == params.fetch("attempt_id") }
            return fetch_plan(journal, events, params, map, peer, role, commit) unless admitted
            origin = submitting_worker!(events, params, map, peer, role)
            replay = journal.mutation_result(request.fetch("mutation_id"))
            if replay && replay["operation"] == "submit_result"
              current = retained_candidate(events, replay.dig("data", "candidate_generation"))
              raise AttemptErrors::EvidenceUnavailable, "result candidate is missing" unless current
              retained = verified_result(journal, events, params, map, origin, current, commit)
              unless retained && result_projection(retained) == replay.fetch("data").slice(*RESULT_FIELDS)
                raise AttemptErrors::EvidenceUnavailable, "result replay provenance differs"
              end
            end
            result = journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: "submit_result",
              parameters_digest: Atoms::EvidenceDigest.digest(params), expected_generation: params.fetch("expected_generation"),
              with_replay: true) do |fresh_events, fresh_commit, generation|
              origin = submitting_worker!(fresh_events, params, map, peer, role)
              current = exact_candidate!(candidate(fresh_events), params)
              if verified_result(journal, fresh_events, params, map, origin, current, fresh_commit)
                raise AttemptErrors::Conflict, "candidate already has a result"
              end
              result_plan(journal, fresh_events, params, map, origin, current, admitted, fresh_commit, generation)
            end
            # A CAS loser may return a competing accepted same-ID reply. It
            # still needs exact canonical private provenance outside callback.
            read_commit = journal.ref_value
            retained_events = journal.read_events(params.fetch("assignment_id"), commit: read_commit)
              .select { |event| event["attempt_id"] == params.fetch("attempt_id") }
            current = retained_candidate(retained_events, result.dig(:data, "candidate_generation"))
            retained = current && verified_result(journal, retained_events, params, map, origin, current, read_commit)
            unless retained && result_projection(retained) == result.fetch(:data).slice(*RESULT_FIELDS)
              raise AttemptErrors::EvidenceUnavailable, "accepted result provenance differs"
            end
            result
          end
        rescue KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "canonical result binding is incomplete"
        end

        def result_context(binding)
          {kind: "result", project_id: binding.fetch("project_id"), assignment_id: binding.fetch("assignment_id"),
            attempt_id: binding.fetch("attempt_id"), peer_uid: binding.fetch("worker_uid"), binding: binding,
            request_id_or_event_id: binding.fetch("result_id"), generation: binding.fetch("candidate_generation")}
        end

        def result_attempt(journal, events, params)
          intent = events.find { |event| event["type"] == "intent" }
          raise AttemptErrors::EvidenceUnavailable, "result attempt intent missing" unless intent
          journal.send(:build_attempt, params.fetch("assignment_id"), params.fetch("attempt_id"),
            intent.fetch("payload"), events, "running")
        end

        def verify_result_receipt(journal, events, params, map, head, receipt, reader)
          unless receipt["producer"] == {"actor" => map.fetch("worker_actor"), "role" => "worker", "runtime" => "herdr"}
            raise AttemptErrors::ReceiptRejected, "result producer differs from mapped worker"
          end
          raise AttemptErrors::EvidenceUnavailable, "protected campaigns require their canonical owner" if receipt["campaign"]
          allowed = Models::ExecutionReceipt.from_h(receipt).to_h.keys
          raise AttemptErrors::ReceiptRejected, "result receipt fields differ" unless (receipt.keys - allowed).empty?
          # Failed receipts can omit artifacts, but every declared artifact still
          # needs canonical byte/provenance validation.
          Array(receipt["artifacts"]).each { |artifact| reader.call(receipt, artifact) }
          Molecules::ReceiptVerifier.new(artifact_reader: reader).verify_result!(receipt,
            attempt: result_attempt(journal, events, params), live_head: head, repo_root: journal.repo_root)
        end

        def result_plan(journal, events, params, map, origin, current, admitted, commit, generation)
          receipt = admitted.fetch(:receipt)
          original = Models::ExecutionReceipt.from_h(receipt)
          unless original.digest == Atoms::EvidenceDigest.digest(original.digest_payload)
            raise AttemptErrors::ReceiptRejected, "original result digest differs"
          end
          id = SecureRandom.hex(16)
          binding = params.slice("mapping_id", "assignment_id", "attempt_id").merge(
            "project_id" => map.fetch("project_id"), "result_id" => id, "worker_uid" => map.fetch("worker_uid"),
            "worker_actor" => map.fetch("worker_actor"), "launch_ticket" => origin.fetch("launch_ticket"),
            "process_binding" => origin.fetch("process_binding"), "head" => current.fetch("head"),
            "candidate_generation" => current.fetch("candidate_generation"),
            "uploaded_receipt_sha256" => admitted.fetch(:receipt_sha256), "original_receipt_digest" => original.digest)
          canonical = Molecules::CanonicalEvidence.new(journal: journal)
          plan = admitted.fetch(:artifacts).empty? ? {events: [], blobs: {}, references: []} :
            canonical.import_plan(**result_context(binding), artifacts: admitted.fetch(:artifacts),
              admitted_after_event_digest: events.last.fetch("digest"))
          normalized = JSON.parse(JSON.generate(receipt)).except("digest", "recorded_at")
          normalized["artifacts"] = plan.fetch(:references).map { |ref| {"path" => ref.fetch("ref"), "sha256" => ref.fetch("sha256")} }
          pending = journal.send(:chain_mutation_events, params.fetch("attempt_id"), events.last.fetch("digest"), plan.fetch(:events))
          reader = ->(_data, artifact) { canonical.read_pending({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
            **result_context(binding), current_events: events, pending_events: pending, blobs: plan.fetch(:blobs), commit: commit) }
          verified = verify_result_receipt(journal, events, params, map, current.fetch("head"), normalized, reader)
          payload = {"version" => 1, "result_id" => id, "binding" => binding,
            "uploaded_receipt_sha256" => admitted.fetch(:receipt_sha256), "original_receipt_digest" => original.digest,
            "receipt_digest" => verified.digest, "receipt" => verified.to_h, "artifacts" => verified.artifacts}
          data = result_projection(payload)
          @launch.send(:bounded_reply!, data, generation + 1)
          plan.merge(events: plan.fetch(:events) + [{type: "result_submitted", payload: payload}], data: data)
        end

        def result_projection(payload)
          payload.slice("result_id", "uploaded_receipt_sha256", "original_receipt_digest", "receipt_digest", "artifacts")
            .merge(payload.fetch("binding").slice("head", "candidate_generation"), "verdict" => payload.fetch("receipt").fetch("verdict"))
        end

        def verified_result(journal, events, params, map, origin, current, commit, result_id: nil)
          raise AttemptErrors::EvidenceUnavailable, "result chain differs" unless Models::EvidenceEvent.chain_valid?(events)
          records = events.select { |event| event["type"] == "result_submitted" &&
            (event.dig("payload", "binding", "candidate_generation") == current.fetch("candidate_generation") ||
              (result_id && event.dig("payload", "result_id") == result_id)) }
          replies = events.select { |event| event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "submit_result" &&
            event.dig("payload", "data", "candidate_generation") == current.fetch("candidate_generation") }
          return nil if records.empty? && replies.empty?
          raise AttemptErrors::EvidenceUnavailable, "result record is missing or duplicated" unless records.length == 1 && replies.length == 1
          payload = records.first.fetch("payload")
          binding = payload.fetch("binding")
          expected = params.slice("mapping_id", "assignment_id", "attempt_id").merge(
            "project_id" => map.fetch("project_id"), "worker_uid" => map.fetch("worker_uid"),
            "worker_actor" => map.fetch("worker_actor"), "launch_ticket" => origin.fetch("launch_ticket"),
            "process_binding" => origin.fetch("process_binding"), "head" => current.fetch("head"),
            "candidate_generation" => current.fetch("candidate_generation"), "result_id" => payload.fetch("result_id"),
            "uploaded_receipt_sha256" => payload.fetch("uploaded_receipt_sha256"),
            "original_receipt_digest" => payload.fetch("original_receipt_digest"))
          unless payload.keys.sort == RESULT_PAYLOAD_FIELDS.sort && payload["version"] == 1 &&
              binding.keys.sort == RESULT_BINDING_FIELDS.sort && binding == expected &&
              payload["result_id"].is_a?(String) && payload["result_id"].match?(/\A[0-9a-f]{32}\z/) &&
              %w[uploaded_receipt_sha256 original_receipt_digest receipt_digest].all? { |key| payload[key].is_a?(String) && payload[key].match?(DIGEST) } &&
              events.count { |event| event["type"] == "result_submitted" && event.dig("payload", "result_id") == payload["result_id"] } == 1 &&
              payload["artifacts"] == payload.dig("receipt", "artifacts") &&
              replies.first.fetch("payload").fetch("data").slice(*RESULT_FIELDS) == result_projection(payload)
            raise AttemptErrors::EvidenceUnavailable, "private result provenance differs"
          end
          canonical = Molecules::CanonicalEvidence.new(journal: journal)
          reader = ->(_data, artifact) { canonical.read({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
            **result_context(binding), commit: commit) }
          receipt = verify_result_receipt(journal, events, params, map, current.fetch("head"), payload.fetch("receipt"), reader)
          raise AttemptErrors::EvidenceUnavailable, "normalized result digest differs" unless receipt.digest == payload.fetch("receipt_digest")
          payload
        rescue KeyError, ArgumentError, TypeError, AttemptErrors::ReceiptRejected
          raise AttemptErrors::EvidenceUnavailable, "canonical result is unverifiable"
        end

        def purpose_peer!(events, params, map, origin, peer, role, kind:, current: nil, purpose_id: nil, record: nil)
          @kernel.live!(peer)
          service_policy!.visible!(project: map.fetch("project_id"), uid: peer.fetch("uid"))
          permitted = case role
          when :supervisor
            @deployment.project(map.fetch("project_id")).fetch("supervisor_uids").include?(peer["uid"])
          when :launcher
            peer["uid"] == map.fetch("launcher_uid") && @kernel.same?(peer, origin.fetch("launcher_identity"))
          when :worker
            kind == "result" && peer["uid"] == map.fetch("worker_uid") &&
              @kernel.descendant?(peer, origin.fetch("process_binding").fetch("process_identity"))
          when :reviewer
            review = assigned_review(events)
            %w[result review].include?(kind) && review && current && review["head"] == current["head"] &&
              review["candidate_generation"] == current["candidate_generation"] && review["reviewer_uid"] == peer["uid"] &&
              (kind != "review" || review["review_id"] == purpose_id) && @kernel.descendant?(peer, review.fetch("reviewer_process_binding"))
          when :executor
            kind == "service" && record && record["executor_uid"] == peer["uid"] && record["request_id"] == purpose_id
          else
            false
          end
          raise AttemptErrors::UnauthorizedIdentity, "canonical evidence purpose is unauthorized" unless permitted
        end

        def fetch_plan(journal, events, params, map, peer, role, commit)
          @kernel.live!(peer)
          service_policy!.visible!(project: map.fetch("project_id"), uid: peer.fetch("uid"))
          origin = retained_origin(events, params)
          kind, id = params.values_at("kind", "purpose_id")
          if (role == :worker && kind != "result") || (role == :reviewer && !%w[result review].include?(kind)) ||
              (role == :executor && kind != "service")
            raise AttemptErrors::UnauthorizedIdentity, "canonical evidence kind is unauthorized"
          end
          context, references = case kind
          when "result"
            event = events.find { |item| item["type"] == "result_submitted" && item.dig("payload", "result_id") == id }
            unless event
              raise AttemptErrors::EvidenceUnavailable, "result record is missing" if events.any? { |item| item.dig("payload", "operation") == "submit_result" && item.dig("payload", "data", "result_id") == id }
              raise AttemptErrors::NotFound, "result purpose not found"
            end
            current = retained_candidate(events, event.dig("payload", "binding", "candidate_generation"))
            raise AttemptErrors::EvidenceUnavailable, "result candidate missing" unless current
            purpose_peer!(events, params, map, origin, peer, role, kind: kind, current: current, purpose_id: id)
            result = verified_result(journal, events, params, map, origin, current, commit, result_id: id)
            [result_context(result.fetch("binding")), result.fetch("artifacts")]
          when "review"
            accepted = events.filter_map { |item| item.dig("payload", "data") if item["type"] == "authority_mutation" &&
              item.dig("payload", "operation") == "accept_review" && item.dig("payload", "data", "review_id") == id }
            raise AttemptErrors::NotFound, "review purpose not found" if accepted.empty?
            raise AttemptErrors::EvidenceUnavailable, "duplicate review purpose" unless accepted.length == 1
            review = accepted.first
            current = retained_candidate(events, review.fetch("candidate_generation"))
            purpose_peer!(events, params, map, origin, peer, role, kind: kind, current: current, purpose_id: id)
            ctx = {kind: kind, project_id: map.fetch("project_id"), assignment_id: params.fetch("assignment_id"),
              attempt_id: params.fetch("attempt_id"), peer_uid: review.fetch("reviewer_uid"), binding: review.fetch("review_binding"),
              request_id_or_event_id: id, generation: review.fetch("candidate_generation")}
            verify_retained_review!(journal, events, params, map, current, review, ctx, commit)
            [ctx, review.fetch("review_receipt").fetch("artifacts")]
          when "inbox"
            registrations = events.select { |entry| entry["type"] == "inbox_binding" && entry.dig("payload", "event_id") == id }
            raise AttemptErrors::NotFound, "inbox purpose not found" if registrations.empty?
            raise AttemptErrors::EvidenceUnavailable, "inbox registration differs" unless registrations.one?
            selected = params.merge("event_id" => id, "inbox_context_id" => registrations.first.dig("payload", "inbox_context_id"))
            retained = verified_inbox(journal, events, selected, map, peer, role, commit)
            raise AttemptErrors::EvidenceUnavailable, "canonical inbox proof missing" unless retained
            [inbox_context(retained.fetch("binding")), %w[receipt_ref signature_ref].map { |key| retained.fetch(key).slice("sha256").merge("path" => retained.fetch(key).fetch("ref")) }]
          when "service"
            record = journal.service_request(id, commit: commit)
            raise AttemptErrors::NotFound, "service purpose not found" unless record
            unless record["assignment_id"] == params["assignment_id"] && record["attempt_id"] == params["attempt_id"] && record["project_id"] == map["project_id"]
              raise AttemptErrors::UnauthorizedIdentity, "service attempt differs"
            end
            purpose_peer!(events, params, map, origin, peer, role, kind: kind, purpose_id: id, record: record)
            raise AttemptErrors::EvidenceUnavailable, "service completion evidence unavailable" unless record["receipt"]
            ctx = ServiceEvidence.new(journal: journal).context(record, no_effect: record["state"] == "failed-settled")
            [ctx, record.fetch("receipt").fetch("evidence").map { |ref| {"path" => ref.fetch("ref"), "sha256" => ref.fetch("sha256")} }]
          else
            purpose_peer!(events, params, map, origin, peer, role, kind: kind, purpose_id: id)
            raise AttemptErrors::EvidenceUnavailable, "canonical signer or observer provenance unavailable"
          end
          reference = references.find { |ref| ref["path"] == "evidence/imports/#{params.fetch('artifact_id')}" }
          raise AttemptErrors::NotFound, "artifact not found in exact purpose" unless reference
          canonical = Molecules::CanonicalEvidence.new(journal: journal)
          bytes = canonical.read({"ref" => reference.fetch("path"), "sha256" => reference.fetch("sha256")}, **context, commit: commit)
          descriptor = events.find { |event| event["type"] == "evidence_import" && event.dig("payload", "artifact_id") == params["artifact_id"] }.fetch("payload")
          {data: {"descriptor" => descriptor, "generation" => journal.authority_generation(events), "journal_commit" => commit},
            replayed: false, transfer_parts: [bytes]}
        rescue KeyError, TypeError, ArgumentError, AttemptErrors::ReceiptRejected
          raise AttemptErrors::EvidenceUnavailable, "canonical evidence purpose is unverifiable"
        end

        def verify_retained_review!(journal, events, params, map, current, accepted, context, commit)
          assignments = events.filter_map { |event| event.dig("payload", "data") if event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "assign_review" && event.dig("payload", "data", "review_id") == accepted["review_id"] }
          review = assignments.first
          unless assignments.length == 1 && current && review["reviewer_uid"] != map.fetch("worker_uid") &&
              accepted["head"] == current["head"] && accepted["reviewer_uid"] == review["reviewer_uid"] &&
              accepted["review_binding"] == review.slice("review_id", "head", "candidate_generation", "reviewer_uid", "reviewer_process_binding") &&
              accepted.dig("review_receipt", "review", "reviewer", "actor") == review["reviewer_actor"]
            raise AttemptErrors::EvidenceUnavailable, "retained review binding differs"
          end
          canonical = Molecules::CanonicalEvidence.new(journal: journal)
          reader = ->(_data, artifact) { canonical.read({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")}, **context, commit: commit) }
          receipt = verify_result_receipt(journal, events, params, map, current.fetch("head"), accepted.fetch("review_receipt"), reader)
          unless receipt.operation == "review" && receipt.verdict == "succeeded" && receipt.digest == accepted.fetch("receipt_digest")
            raise AttemptErrors::EvidenceUnavailable, "retained review receipt differs"
          end
        end
      end
    end
  end
end
