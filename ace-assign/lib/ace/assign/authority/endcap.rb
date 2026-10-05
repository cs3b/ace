# frozen_string_literal: true

require "json"
require "digest"
require "securerandom"
require_relative "candidate_transfer"

module Ace
  module Assign
    module Authority
      # Business admission shares the launch origin, lifecycle exclusion and
      # journal CAS. Network transfer is completed outside those locks.
      class Endcap
        OPERATIONS = %w[submit_candidate export_candidate assign_review].freeze
        TRANSFER_OPERATIONS = {
          "submit_candidate" => {direction: :upload, purpose: :candidate, roles: %i[worker launcher]},
          "export_candidate" => {direction: :download, purpose: :candidate, roles: %i[reviewer executor]}
        }.freeze
        PARAMETERS = {
          "submit_candidate" => %w[mapping_id assignment_id attempt_id expected_generation candidate_generation head transfer],
          "export_candidate" => %w[mapping_id assignment_id attempt_id candidate_generation head purpose_id],
          "assign_review" => %w[mapping_id assignment_id attempt_id expected_generation candidate_generation head reviewer_uid reviewer_process_binding]
        }.freeze

        def initialize(deployment:, launch:, kernel: Ace::Runtime::Molecules::ProtectedLinux.new)
          @deployment, @launch, @kernel = deployment, launch, kernel
        end

        def authorize_transfer!(request:, peer:, role:)
          params, map = validate_request(request)
          @launch.with_assignment(params: params, map: map) do |journal, _registration|
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
          params, map = validate_request(request)
          admitted = nil
          if request.fetch("operation") == "submit_candidate"
            authorize_transfer!(request: request, peer: peer, role: role)
            raise ArgumentError, "candidate transfer is missing" unless transfer && transfer.count == 1
            bytes = transfer.bytes
            descriptor = params.fetch("transfer")
            project = @deployment.project(map.fetch("project_id"))
            admitted = CandidateTransfer.new(root: project.fetch("candidate_root")).admit(
              bytes: bytes, sha256: descriptor.fetch("sha256"), size: descriptor.fetch("bytes"), head: params.fetch("head"))
          end
          @launch.with_assignment(params: params, map: map) do |journal, _registration|
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
            worker_or_launcher!(peer, role, map, origin,
              launcher_only: request.fetch("operation") == "assign_review")
            journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
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
                reviewer = params.fetch("reviewer_process_binding")
                uid = params.fetch("reviewer_uid")
                project = @deployment.project(map.fetch("project_id"))
                unless uid.is_a?(Integer) && project.fetch("reviewer_uids").include?(uid) && uid != map.fetch("worker_uid") &&
                    reviewer.is_a?(Hash) && reviewer["uid"] == uid
                  raise AttemptErrors::UnauthorizedIdentity, "reviewer must be independently mapped"
                end
                @kernel.live!(reviewer)
                {data: current.slice("head", "candidate_generation").merge(
                  "review_id" => SecureRandom.hex(16), "reviewer_uid" => uid, "reviewer_process_binding" => reviewer)}
              end
            end
          end
        end

        private

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
            assignment = events.reverse.find { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "assign_review" }
            assignment = assignment&.dig("payload", "data")
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
      end
    end
  end
end
