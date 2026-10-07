# frozen_string_literal: true

require "json"
require "digest"
require "securerandom"
require_relative "candidate_transfer"
require_relative "receipt_transfer"
require_relative "service_evidence"
require_relative "../molecules/canonical_evidence"

module Ace
  module Assign
    module Authority
      # Business admission shares the launch origin, lifecycle exclusion and
      # journal CAS. Network transfer is completed outside those locks.
      class Endcap
        OPERATIONS = %w[submit_candidate export_candidate request_review review_status assign_review cancel_review accept_review request_service begin_dispatch complete_service claim_service_settlement complete_no_effect service_authorization service_status submit_result evidence_fetch reconcile_inbox].freeze
        TRANSFER_OPERATIONS = {
          "reconcile_inbox" => {direction: :upload, purpose: :inbox_proof, roles: %i[launcher supervisor]},
          "submit_result" => {direction: :upload, purpose: :receipt_artifacts, roles: [:worker]},
          "evidence_fetch" => {direction: :download, purpose: :artifacts, roles: %i[worker reviewer executor launcher supervisor]},
          "submit_candidate" => {direction: :upload, purpose: :candidate, roles: %i[worker launcher]},
          "export_candidate" => {direction: :download, purpose: :candidate, roles: %i[reviewer executor]},
          "accept_review" => {direction: :upload, purpose: :receipt_artifacts, roles: [:reviewer]},
          "request_service" => {direction: :upload, purpose: :service_input, roles: [:executor]},
          "begin_dispatch" => {direction: :upload, purpose: :service_input, roles: [:executor]},
          "service_authorization" => {direction: :upload, purpose: :service_input, roles: [:executor]},
          "complete_service" => {direction: :upload, purpose: :receipt_artifacts, roles: [:executor]},
          "complete_no_effect" => {direction: :upload, purpose: :receipt_artifacts, roles: [:executor]}
        }.freeze
        PARAMETERS = {
          "reconcile_inbox" => %w[mapping_id assignment_id attempt_id expected_generation event_id inbox_context_id expected_registration receipt_sha256 signature_sha256 transfer],
          "submit_result" => %w[mapping_id assignment_id attempt_id expected_generation candidate_generation head receipt_sha256 transfer],
          "evidence_fetch" => %w[mapping_id assignment_id attempt_id kind purpose_id artifact_id],
          "submit_candidate" => %w[mapping_id assignment_id attempt_id expected_generation candidate_generation head transfer],
          "export_candidate" => %w[mapping_id assignment_id attempt_id candidate_generation head purpose_id],
          "request_review" => %w[mapping_id assignment_id attempt_id expected_generation candidate_generation head],
          "assign_review" => %w[mapping_id assignment_id attempt_id expected_generation candidate_generation head reviewer_uid reviewer_process_binding],
          "cancel_review" => %w[mapping_id assignment_id attempt_id head candidate_generation review_event_id expected_generation],
          "accept_review" => %w[mapping_id assignment_id attempt_id expected_generation candidate_generation head purpose_id receipt_sha256 transfer],
          "request_service" => %w[mapping_id assignment_id attempt_id expected_generation candidate_generation head request_id operation input_digest target authorization service_id worker_process_binding transfer],
          "begin_dispatch" => %w[mapping_id assignment_id attempt_id expected_generation candidate_generation head request_id claim_binding transfer],
          "service_status" => %w[mapping_id assignment_id attempt_id candidate_generation head request_id],
          "service_authorization" => %w[mapping_id assignment_id attempt_id candidate_generation head request_id claim_binding input_digest transfer],
          "complete_service" => %w[mapping_id assignment_id attempt_id candidate_generation head request_id claim_binding receipt_sha256 transfer],
          "claim_service_settlement" => %w[mapping_id assignment_id attempt_id candidate_generation head request_id expected_generation],
          "complete_no_effect" => %w[mapping_id assignment_id attempt_id candidate_generation head request_id claim_binding reconciliation_challenge receipt_sha256 transfer]
        }.freeze

        def initialize(deployment:, launch:, kernel: Ace::Runtime::Molecules::ProtectedLinux.new, service_policy: nil, inbox_context_clients: nil, deployment_history: nil)
          @deployment, @launch, @kernel, @service_policy = deployment, launch, kernel, service_policy
          @inbox_context_clients = inbox_context_clients
          @deployment_history = deployment_history
          launch.attach_result_owner(self) if launch.respond_to?(:attach_result_owner)
        end

        def authorize_transfer!(request:, peer:, role:)
          return dispatch_prepared_fetch(request: request, peer: peer, role: role, body: false) if prepared_fetch?(request)
          return authorize_inbox_transfer!(request: request, peer: peer, role: role) if request.fetch("operation") == "reconcile_inbox"
          return authorize_result_transfer!(request: request, peer: peer, role: role) if %w[submit_result evidence_fetch].include?(request.fetch("operation"))
          params, map = validate_request(request)
          return authorize_service_settlement!(request, params, map, peer, role) if request.fetch("operation") == "complete_no_effect"
          return authorize_service_transfer!(request, params, map, peer, role) if %w[request_service begin_dispatch complete_service service_authorization].include?(request.fetch("operation"))
          @launch.with_assignment(params: params, map: map) do |journal, _registration|
            protected_journal!(journal)
            events = attempt_events(journal, params)
            origin = active_origin(events, params)
            if request.fetch("operation") == "submit_candidate"
              worker_or_launcher!(peer, role, map, origin)
              candidate_generation!(candidate(events), params)
            else
              export_admission!(journal, events, params, map, origin, peer, role)
            end
          end
          true
        end

        def dispatch(request:, peer:, role:, transfer: nil)
          if prepared_fetch?(request)
            raise ArgumentError, "prepared fetch forbids upload" unless transfer.nil?
            return dispatch_prepared_fetch(request: request, peer: peer, role: role)
          end
          return dispatch_inbox(request: request, peer: peer, role: role, transfer: transfer) if request.fetch("operation") == "reconcile_inbox"
          return dispatch_result(request: request, peer: peer, role: role, transfer: transfer) if %w[submit_result evidence_fetch].include?(request.fetch("operation"))
          return review_status(request, peer, role, transfer) if request.fetch("operation") == "review_status"
          params, map = validate_request(request)
          return request_review(request, params, map, peer, role, transfer) if request.fetch("operation") == "request_review"
          return cancel_review(request, params, map, peer, role, transfer) if request.fetch("operation") == "cancel_review"
          return dispatch_service_settlement(request, params, map, peer, role, transfer) if %w[claim_service_settlement complete_no_effect].include?(request.fetch("operation"))
          return service_status(request, params, map, peer, role) if request.fetch("operation") == "service_status"
          return dispatch_service(request, params, map, peer, role, transfer) if %w[request_service begin_dispatch complete_service service_authorization].include?(request.fetch("operation"))
          admitted = nil
          if request.fetch("operation") == "submit_candidate"
            authorize_transfer!(request: request, peer: peer, role: role)
            raise ArgumentError, "candidate transfer is missing" unless transfer && transfer.count == 1
            bytes = transfer.bytes
            descriptor = params.fetch("transfer")
            project = @deployment.project(map.fetch("project_id"))
            admitted = CandidateTransfer.new(root: project.fetch("candidate_root")).admit(
              bytes: bytes, sha256: descriptor.fetch("sha256"), size: descriptor.fetch("bytes"), head: params.fetch("head"))
          elsif request.fetch("operation") == "accept_review"
            authorize_transfer!(request: request, peer: peer, role: role)
            admitted = ReceiptTransfer.decode(input: transfer, receipt_sha256: params.fetch("receipt_sha256"),
              artifact_field: "artifacts", reference_key: "path")
          end
          @launch.with_assignment(params: params, map: map) do |journal, _registration|
            protected_journal!(journal)
            events = attempt_events(journal, params)
            origin = active_origin(events, params)
            if request.fetch("operation") == "export_candidate"
              current = export_admission!(journal, events, params, map, origin, peer, role)
              bytes = journal.blob(current.fetch("bundle_ref"))
              unless bytes.bytesize == current.fetch("bytes") && Digest::SHA256.hexdigest(bytes) == current.fetch("sha256")
                raise AttemptErrors::EvidenceUnavailable, "canonical candidate bundle differs"
              end
              return {data: current.slice("head", "tree", "candidate_generation", "sha256", "bytes"),
                replayed: false, transfer_parts: [bytes]}
            end
            # Journal replay skips its callback. Authenticate the caller here
            # as well as on every fresh/CAS-retried mutation below.
            if request.fetch("operation") == "accept_review"
              export_admission!(journal, events, params, map, origin, peer, role)
            else
              worker_or_launcher!(peer, role, map, origin,
                launcher_only: request.fetch("operation") == "assign_review")
            end
            delegated_review_request!(journal, events, request, params, peer, role) if request.fetch("operation") == "assign_review"
            result = journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: request.fetch("operation"),
              parameters_digest: Atoms::EvidenceDigest.digest(params), expected_generation: params.fetch("expected_generation"),
              with_replay: true) do |events, _commit, _generation|
              origin = active_origin(events, params)
              case request.fetch("operation")
              when "submit_candidate"
                worker_or_launcher!(peer, role, map, origin)
                current = candidate(events)
                candidate_generation!(current, params)
                path = "candidates/bundles/#{SecureRandom.hex(16)}"
                data = admitted.except("bundle").merge("bundle_ref" => path,
                  "candidate_generation" => params.fetch("candidate_generation") + 1,
                  "worker_uid" => map.fetch("worker_uid"))
                {data: data, blobs: {path => admitted.fetch("bundle")}}
              when "assign_review"
                worker_or_launcher!(peer, role, map, origin, launcher_only: true)
                current = exact_candidate!(candidate(events), params)
                delegated = delegated_review_request!(journal, events, request, params, peer, role)
                reservation = active_review_reservation(events, current)
                if delegated
                  unless reservation && reservation.fetch("digest") == delegated.fetch("digest") && !active_review_event(events, current)
                    raise AttemptErrors::Conflict, "delegated review reservation is no longer assignable"
                  end
                elsif reservation
                  raise AttemptErrors::Conflict, "candidate review reservation is active"
                end
                reviewer = params.fetch("reviewer_process_binding")
                uid = params.fetch("reviewer_uid")
                project = @deployment.project(map.fetch("project_id"))
                unless uid.is_a?(Integer) && project.fetch("reviewer_uids").include?(uid) && uid != map.fetch("worker_uid") &&
                    reviewer.is_a?(Hash) && reviewer["uid"] == uid
                  raise AttemptErrors::UnauthorizedIdentity, "reviewer must be independently mapped"
                end
                @kernel.live!(reviewer)
                {data: current.slice("head", "candidate_generation").merge(
                  "review_id" => SecureRandom.hex(16), "reviewer_uid" => uid, "reviewer_actor" => "uid-#{uid}",
                  "reviewer_process_binding" => reviewer)}
              when "accept_review"
                current = export_admission!(journal, events, params, map, origin, peer, role)
                review = assigned_review(events)
                accept_review_plan(journal, events, params, map, current, review, admitted)
              end
            end
            if request.fetch("operation") == "assign_review"
              review_event_reply(journal, result, request, params, "assignment_event_id")
            else
              result
            end
          end
        end

        private

        def protected_journal!(journal)
          unless journal.evidence_mode == :protected
            raise ArgumentError, "full-service Endcap requires canonical protected evidence composition"
          end
        end

        def validate_request(request)
          operation = request.fetch("operation")
          params = request.fetch("params")
          unless params.is_a?(Hash) && params.keys.sort == PARAMETERS.fetch(operation).sort
            raise ArgumentError, "invalid Endcap parameters"
          end
          %w[mapping_id assignment_id attempt_id].each do |key|
            raise ArgumentError, "invalid Endcap identifier" unless params[key].is_a?(String) && params[key].match?(Molecules::JournalMutation::ID)
          end
          unless params["head"].is_a?(String) && params["head"].match?(CandidateTransfer::SHA) &&
              params["candidate_generation"].is_a?(Integer) && params["candidate_generation"] >= 0
            raise ArgumentError, "invalid candidate binding"
          end
          if %w[service_authorization service_status].include?(operation) && !request.fetch("mutation_id").nil?
            raise ArgumentError, "authorization read must not supply a mutation ID"
          end
          map = @deployment.mapping(params.fetch("mapping_id"))
          raise AttemptErrors::UnauthorizedIdentity, "project mapping differs" unless map.fetch("project_id") == request.fetch("project_id")
          [params, map]
        end

        def attempt_events(journal, params)
          journal.read_events(params.fetch("assignment_id")).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
        end

        def active_origin(events, params)
          unless Models::EvidenceEvent.chain_valid?(events) &&
              !events.any? { |event| %w[receipt_accepted transition reconciliation].include?(event["type"]) &&
                %w[succeeded failed stopped].include?(event.dig("payload", "to") || event.dig("payload", "resolution") || event.dig("payload", "receipt", "verdict")) }
            raise AttemptErrors::InvalidState, "attempt is not active"
          end
          origin = @launch.origin(events, assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
            mapping_id: params.fetch("mapping_id"))
          raise AttemptErrors::InvalidState, "exact bound launch is required" unless %w[bound issued].include?(origin["phase"])
          @kernel.live!(origin.fetch("process_binding").fetch("process_identity"))
          origin
        end

        def worker_or_launcher!(peer, role, map, origin, launcher_only: false)
          anchor = if role == :worker && !launcher_only && peer["uid"] == map.fetch("worker_uid")
            origin.fetch("process_binding").fetch("process_identity")
          elsif role == :launcher && peer["uid"] == map.fetch("launcher_uid")
            origin.fetch("launcher_identity")
          else
            raise AttemptErrors::UnauthorizedIdentity, "operation requires owning worker or launcher"
          end
          unless @kernel.descendant?(peer, anchor)
            raise AttemptErrors::UnauthorizedIdentity, "peer does not descend from exact launch binding"
          end
        end

        def candidate(events)
          event = events.reverse.find { |entry| entry["type"] == "authority_mutation" && entry.dig("payload", "operation") == "submit_candidate" }
          event&.dig("payload", "data")
        end

        def candidate_generation!(current, params)
          unless (current && current.fetch("candidate_generation") || 0) == params.fetch("candidate_generation")
            raise AttemptErrors::Conflict, "candidate generation changed"
          end
        end

        def exact_candidate!(current, params)
          candidate_generation!(current, params)
          raise AttemptErrors::Conflict, "candidate head differs" unless current && current.fetch("head") == params.fetch("head")
          current
        end

        def export_admission!(journal, events, params, map, _origin, peer, role)
          current = exact_candidate!(candidate(events), params)
          @kernel.live!(peer)
          if role == :reviewer
            assignment = active_review_event(events, current)&.dig("payload", "data")
            unless assignment && assignment["review_id"] == params["purpose_id"] && assignment["head"] == current["head"] &&
                assignment["candidate_generation"] == current["candidate_generation"] && assignment["reviewer_uid"] == peer["uid"] &&
                @kernel.descendant?(peer, assignment.fetch("reviewer_process_binding"))
              raise AttemptErrors::UnauthorizedIdentity, "candidate export requires assigned independent reviewer"
            end
          elsif role == :executor
            record = journal.service_request(params.fetch("purpose_id"))
            unless record && record["assignment_id"] == params["assignment_id"] && record["attempt_id"] == params["attempt_id"] &&
                record["executor_uid"] == peer["uid"] && record["candidate_head"] == current["head"] &&
                record["candidate_generation"] == current["candidate_generation"] && record["dispatch_phase"] == "issued"
              raise AttemptErrors::UnauthorizedIdentity, "candidate export requires current executor ticket"
            end
          else
            raise AttemptErrors::UnauthorizedIdentity, "candidate export purpose is unauthorized"
          end
          current
        end

        def assigned_review(events)
          events.reverse.find { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "assign_review" }&.dig("payload", "data")
        end

        # A retained approval grants permission only while its original imported
        # bytes, independent reviewer and exact candidate still verify. An old
        # successful mutation reply is not a substitute for canonical evidence.
        def approved_review!(journal, events, params, map, current)
          accepted = events.reverse.find { |event| event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "accept_review" }&.dig("payload", "data")
          review = active_review_event(events, current)&.dig("payload", "data")
          unless accepted && review && accepted["head"] == current["head"] &&
              accepted["candidate_generation"] == current["candidate_generation"] &&
              accepted["review_id"] == review["review_id"] && accepted["reviewer_uid"] == review["reviewer_uid"] &&
              accepted["review_binding"] == review.slice("review_id", "head", "candidate_generation", "reviewer_uid", "reviewer_process_binding") &&
              review["reviewer_uid"] != map.fetch("worker_uid")
            raise AttemptErrors::ReceiptRejected, "current candidate requires its exact independent review"
          end
          context = {kind: "review", project_id: map.fetch("project_id"), assignment_id: params.fetch("assignment_id"),
            attempt_id: params.fetch("attempt_id"), peer_uid: review.fetch("reviewer_uid"),
            binding: accepted.fetch("review_binding"), request_id_or_event_id: review.fetch("review_id"),
            generation: current.fetch("candidate_generation")}
          canonical = Molecules::CanonicalEvidence.new(journal: journal)
          commit = journal.ref_value
          reader = ->(_data, artifact) { canonical.read({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
            **context, commit: commit) }
          intent = events.find { |event| event["type"] == "intent" }
          attempt = journal.send(:build_attempt, params.fetch("assignment_id"), params.fetch("attempt_id"),
            intent.fetch("payload"), events, "running")
          identity = Molecules::ExecutionIdentityResolver::Identity.new(actor: "protected-authority", role: "service", runtime: "unix")
          receipt = Molecules::ReceiptVerifier.new(artifact_reader: reader).verify!(accepted.fetch("review_receipt"),
            attempt: attempt, identity: identity, live_head: current.fetch("head"), repo_root: journal.repo_root)
          unless receipt.digest == accepted.fetch("receipt_digest") && receipt.operation == "review" &&
              receipt.to_h.dig("review", "reviewer", "actor") == review.fetch("reviewer_actor")
            raise AttemptErrors::ReceiptRejected, "canonical review receipt differs"
          end
          accepted
        rescue KeyError
          raise AttemptErrors::ReceiptRejected, "canonical review binding is incomplete"
        end

        def accept_review_plan(journal, events, params, map, current, review, admitted)
          receipt = admitted.fetch(:receipt)
          raise AttemptErrors::EvidenceUnavailable, "protected campaigns require their canonical owner" if receipt["campaign"]
          unless receipt["operation"] == "review" && receipt["verdict"] == "succeeded" &&
              receipt["producer"] == {"actor" => map.fetch("worker_actor"), "role" => "worker", "runtime" => "herdr"} &&
              receipt.dig("review", "reviewer", "actor") == review.fetch("reviewer_actor")
            raise AttemptErrors::ReceiptRejected, "review attribution must match authenticated candidate and reviewer"
          end
          original = Models::ExecutionReceipt.from_h(receipt)
          unless original.digest == Atoms::EvidenceDigest.digest(original.digest_payload)
            raise AttemptErrors::ReceiptRejected, "uploaded review receipt digest differs"
          end
          context = {kind: "review", project_id: map.fetch("project_id"), assignment_id: params.fetch("assignment_id"),
            attempt_id: params.fetch("attempt_id"), peer_uid: review.fetch("reviewer_uid"),
            binding: review.slice("review_id", "head", "candidate_generation", "reviewer_uid", "reviewer_process_binding"),
            request_id_or_event_id: review.fetch("review_id"), generation: current.fetch("candidate_generation")}
          canonical = Molecules::CanonicalEvidence.new(journal: journal)
          plan = canonical.import_plan(**context, artifacts: admitted.fetch(:artifacts),
            admitted_after_event_digest: events.last.fetch("digest"))
          original_refs = receipt.fetch("artifacts")
          normalized = JSON.parse(JSON.generate(receipt)).except("digest", "recorded_at")
          normalized["artifacts"] = plan.fetch(:references).map { |reference| {"path" => reference.fetch("ref"), "sha256" => reference.fetch("sha256")} }
          if normalized["campaign"]
            index = original_refs.index(normalized.fetch("campaign").fetch("result"))
            raise AttemptErrors::ReceiptRejected, "campaign result must name an uploaded artifact" unless index
            normalized["campaign"]["result"] = normalized.fetch("artifacts").fetch(index)
          end
          pending = journal.send(:chain_mutation_events, params.fetch("attempt_id"), events.last.fetch("digest"), plan.fetch(:events))
          reader = lambda do |_data, artifact|
            canonical.read_pending({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
              **context, current_events: events, pending_events: pending, blobs: plan.fetch(:blobs), commit: journal.ref_value)
          end
          intent = events.find { |event| event["type"] == "intent" }
          attempt = journal.send(:build_attempt, params.fetch("assignment_id"), params.fetch("attempt_id"),
            intent.fetch("payload"), events, "running")
          identity = Molecules::ExecutionIdentityResolver::Identity.new(actor: "protected-authority", role: "service", runtime: "unix")
          verified = Molecules::ReceiptVerifier.new(artifact_reader: reader).verify!(normalized,
            attempt: attempt, identity: identity, live_head: current.fetch("head"), repo_root: journal.repo_root)
          plan.merge(data: {"head" => current.fetch("head"), "candidate_generation" => current.fetch("candidate_generation"),
            "review_id" => review.fetch("review_id"), "reviewer_uid" => review.fetch("reviewer_uid"),
            "review_binding" => context.fetch(:binding), "review_receipt" => verified.to_h,
            "receipt_digest" => verified.digest, "uploaded_receipt_sha256" => admitted.fetch(:receipt_sha256)})
        rescue KeyError
          raise AttemptErrors::ReceiptRejected, "review receipt binding is incomplete"
        end
      end
    end
  end
end

require_relative "endcap_services"
require_relative "endcap_service_settlement"

require_relative "endcap_results"

require_relative "endcap_inboxes"

require_relative "endcap_contexts"
require_relative "endcap_prepared_work"

require_relative "endcap_reviews"

require_relative "endcap_review_requests"
