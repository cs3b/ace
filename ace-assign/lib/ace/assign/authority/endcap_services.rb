# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class Endcap
        SERVICE_IDENTITY = %w[request_id assignment_id attempt_id project_id operation input_digest target
          authorization service_id caller_uid candidate_head candidate_generation executor_uid transport policy_digest
          worker_process_binding launch_ticket reservation_generation].freeze

        private

        def authorize_service_transfer!(request, params, map, peer, role)
          service_policy!
          service_policy!.visible!(project: map.fetch("project_id"), uid: map.fetch("worker_uid"))
          @launch.with_assignment(params: params, map: map) do |journal, _registration|
            protected_journal!(journal)
            if request.fetch("operation") == "request_service"
              events = attempt_events(journal, params)
              origin = active_origin(events, params)
              worker_or_launcher!(params.fetch("worker_process_binding"), :worker, map, origin)
              service_receiver!(peer, role, map, params.fetch("service_id"))
            else
              record = journal.service_request(params.fetch("request_id"))
              raise AttemptErrors::NotFound, "service request is unavailable" unless record
              service_receiver!(peer, role, map, record.fetch("service_id"))
              service_ticket!(record, params, map, peer)
            end
          end
          true
        end

        def dispatch_service(request, params, map, peer, role, transfer)
          authorize_service_transfer!(request, params, map, peer, role)
          raise ArgumentError, "structured service input transfer is missing" unless transfer && transfer.count == 1
          bytes = transfer.bytes.dup.freeze
          @launch.with_assignment(params: params, map: map) do |journal, _registration|
            protected_journal!(journal)
            # Admission also runs outside mutate: an exact mutation replay
            # skips its callback and cannot bypass the authenticated ticket.
            service_policy!.visible!(project: map.fetch("project_id"), uid: map.fetch("worker_uid"))
            if request.fetch("operation") == "begin_dispatch"
              record = journal.service_request(params.fetch("request_id"))
              service_receiver!(peer, role, map, record.fetch("service_id"))
              service_ticket!(record, params, map, peer)
            else
              origin = active_origin(attempt_events(journal, params), params)
              worker_or_launcher!(params.fetch("worker_process_binding"), :worker, map, origin)
              service_receiver!(peer, role, map, params.fetch("service_id"))
            end
            result = journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: request.fetch("operation"),
              parameters_digest: Atoms::EvidenceDigest.digest(params), expected_generation: params.fetch("expected_generation"),
              with_replay: true) do |events, _commit, _generation|
              if request.fetch("operation") == "request_service"
                service_claim_plan(journal, events, params, map, peer, role, bytes)
              else
                service_begin_plan(journal, events, params, map, peer, role, bytes)
              end
            end
            if request.fetch("operation") == "begin_dispatch" && result.fetch(:replayed)
              result = result.merge(data: result.fetch(:data).merge("invocation" => "already_started"))
            end
            result
          end
        end

        def service_policy!
          @service_policy || raise(ArgumentError, "full-service authority requires its installed policy owner")
        end

        def service_receiver!(peer, role, map, service_id)
          project = @deployment.project(map.fetch("project_id"))
          receiver = project.fetch("service_receivers").fetch(service_id)
          unless role == :executor && peer["uid"] == receiver.fetch("executor_uid") &&
              project.fetch("service_executor_uids").include?(peer["uid"]) &&
              !project.fetch("worker_uids").include?(peer["uid"])
            raise AttemptErrors::UnauthorizedIdentity, "service requires its fixed independent receiver"
          end
          @kernel.live!(peer)
          receiver
        rescue KeyError
          raise AttemptErrors::UnauthorizedIdentity, "fixed service receiver is unavailable"
        end

        def service_claim_plan(journal, events, params, map, peer, role, input_bytes)
          origin = active_origin(events, params)
          worker = params.fetch("worker_process_binding")
          worker_or_launcher!(worker, :worker, map, origin)
          current = exact_candidate!(candidate(events), params)
          approved_review!(journal, events, params, map, current)
          receiver = service_receiver!(peer, role, map, params.fetch("service_id"))
          binding = params.slice("request_id", "assignment_id", "attempt_id", "operation", "input_digest", "target",
            "authorization", "service_id").merge("project_id" => map.fetch("project_id"),
              "caller_uid" => map.fetch("worker_uid"), "candidate_head" => current.fetch("head"),
              "candidate_generation" => current.fetch("candidate_generation"),
              "worker_process_binding" => origin.fetch("process_binding").fetch("process_identity"),
              "launch_ticket" => origin.fetch("launch_ticket"), "reservation_generation" => origin.fetch("reservation_generation"))
          prepared = service_policy!.prepare!(binding, input_bytes: input_bytes)
          binding = prepared.fetch(:binding).merge("policy_digest" => prepared.fetch(:policy_digest))
          unless binding["executor_uid"] == receiver.fetch("executor_uid")
            raise AttemptErrors::UnauthorizedIdentity, "policy and fixed receiver disagree"
          end
          existing = journal.service_request(binding.fetch("request_id"))
          if existing
            unless existing.slice(*SERVICE_IDENTITY) == binding.slice(*SERVICE_IDENTITY)
              raise AttemptErrors::Conflict, "service request immutable identity differs"
            end
            return {data: service_projection(existing)}
          end
          ticket = SecureRandom.hex(16)
          record = binding.merge("dispatch_ticket_id" => ticket,
            "claim_binding" => Atoms::EvidenceDigest.digest(binding.merge("dispatch_ticket_id" => ticket)),
            "claim_generation" => 1, "dispatch_phase" => "issued", "state" => "uncertain",
            "claimed_at" => Time.now.utc.iso8601(9))
          {data: service_projection(record), service_updates: [{request_id: record.fetch("request_id"),
            expected: nil, replacement: record, event_type: "service_claim"}]}
        end

        def service_begin_plan(journal, events, params, map, peer, role, input_bytes)
          record = journal.service_request(params.fetch("request_id"))
          raise AttemptErrors::NotFound, "service request is unavailable" unless record
          service_receiver!(peer, role, map, record.fetch("service_id"))
          service_ticket!(record, params, map, peer)
          # A repeated begin never grants a second invocation, including after
          # lease expiry or terminality. It reports only retained ticket truth.
          return {data: service_projection(record).merge("invocation" => "already_started")} unless record["dispatch_phase"] == "issued"
          origin = active_origin(events, params)
          unless record["worker_process_binding"] == origin.fetch("process_binding").fetch("process_identity") &&
              record["launch_ticket"] == origin.fetch("launch_ticket") && record["reservation_generation"] == origin.fetch("reservation_generation")
            raise AttemptErrors::UnauthorizedIdentity, "dispatch launch origin differs"
          end
          current = exact_candidate!(candidate(events), params)
          unless record["candidate_head"] == current["head"] && record["candidate_generation"] == current["candidate_generation"]
            raise AttemptErrors::Conflict, "dispatch candidate changed"
          end
          approved_review!(journal, events, params, map, current)
          service_policy!.prepare!(record, input_bytes: input_bytes)
          replacement = record.merge("dispatch_phase" => "dispatch_started")
          {data: service_projection(replacement).merge("invocation" => "permitted"),
            service_updates: [{request_id: record.fetch("request_id"), expected: record,
              replacement: replacement, event_type: "service_transition"}]}
        end

        def service_ticket!(record, params, map, peer)
          unless record["assignment_id"] == params["assignment_id"] && record["attempt_id"] == params["attempt_id"] &&
              record["project_id"] == map["project_id"] && record["executor_uid"] == peer["uid"] &&
              record["claim_binding"] == params["claim_binding"]
            raise AttemptErrors::UnauthorizedIdentity, "dispatch ticket binding differs"
          end
          true
        end

        def service_projection(record)
          record.slice("request_id", "assignment_id", "attempt_id", "project_id", "operation", "service_id", "target",
            "candidate_head", "candidate_generation", "state", "dispatch_ticket_id", "claim_binding", "claim_generation", "dispatch_phase")
        end
      end
    end
  end
end
