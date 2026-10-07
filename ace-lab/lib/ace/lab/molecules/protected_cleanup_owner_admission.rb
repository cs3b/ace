# frozen_string_literal: true

require "ace/assign/authority/service_evidence"
require_relative "protected_cleanup_owner_client"

module Ace
  module Lab
    module Molecules
      # Only the fixed listener supplies the installed journal snapshot and its
      # independently observed self binding. A frame selects neither owner.
      class ProtectedCleanupOwnerAdmission
        FIELDS = %w[schema kind request_id input_digest claim_binding request_event_digest
          dispatch_event_digest input operation_owner_binding_digest].freeze

        def initialize(deployment:, authority_id:, mapping_id:, service_id:, kernel:)
          @deployment, @authority_id, @kernel = deployment, authority_id, kernel
          @mapping_id, @service_id = mapping_id, service_id
        end

        def identity_reader!(peer)
          authority = @deployment.authority(@authority_id)
          if peer.slice("uid", "gid", "groups") == authority.slice("uid", "gid", "groups")
            @kernel.live!(peer)
            return true
          end
          receiver!(peer)
        end

        def receiver!(peer)
          map = @deployment.mapping(@mapping_id)
          project = @deployment.project(map.fetch("project_id"))
          receiver = project.fetch("service_receivers").fetch(@service_id)
          credentials = project.fetch("peer_credentials").fetch(receiver.fetch("executor_uid").to_s)
          unless map.fetch("authority_id") == @authority_id && peer.fetch("uid").is_a?(Integer) && peer.fetch("uid").positive? &&
              peer.fetch("uid") == receiver.fetch("executor_uid") && peer.fetch("gid") == credentials.fetch("gid") &&
              peer.fetch("groups") == credentials.fetch("groups")
            raise SecurityError, "cleanup installed receiver differs"
          end
          @kernel.live!(peer)
          true
        rescue KeyError, TypeError
          raise SecurityError, "cleanup installed receiver unavailable"
        end

        def admit!(frame:, peer:, operation_owner_binding:, journal:)
          receiver!(peer)
          Atoms::ProtectedWorkspacePruneInput.object!(frame, FIELDS)
          unless frame.values_at("schema", "kind") == [ProtectedCleanupOwnerClient::SCHEMA, "execute"]
            raise SecurityError, "cleanup invocation kind differs"
          end
          Atoms::ProtectedWorkspacePruneInput.token!(frame.fetch("request_id"))
          (FIELDS - %w[schema kind request_id input]).each do |key|
            Atoms::ProtectedWorkspacePruneInput.digest!(frame.fetch(key))
          end
          input = Atoms::ProtectedWorkspacePruneInput.parse(JSON.generate(frame.fetch("input")))
          unless Atoms::ServiceInput.digest(input) == frame.fetch("input_digest") &&
              digest(operation_owner_binding) == frame.fetch("operation_owner_binding_digest")
            raise SecurityError, "cleanup original input or owner differs"
          end
          maintenance = input.fetch("maintenance")
          map = @deployment.mapping(maintenance.fetch("mapping_id"))
          unless maintenance.fetch("mapping_id") == @mapping_id && map.fetch("authority_id") == @authority_id && map.fetch("project_id") == maintenance.fetch("project_id")
            raise SecurityError, "cleanup installed scope differs"
          end
          unless journal.evidence_mode == :protected
            raise SecurityError, "cleanup requires the installed protected service evidence owner"
          end
          commit = journal.ref_value
          journal.verify_canonical_prefix!(commit: commit)
          record = journal.service_request(frame.fetch("request_id"), commit: commit)
          unless record && record.fetch("service_id") == @service_id && record.slice("project_id", "mapping_id", "assignment_id", "attempt_id") == maintenance &&
              record.values_at("operation", "dispatch_phase", "state") == ["prune-preserved-workspace", "dispatch_started", "uncertain"] &&
              record.slice("request_id", "input_digest", "claim_binding") == frame.slice("request_id", "input_digest", "claim_binding") &&
              record.fetch("target") == Atoms::ServiceInput.target(input) &&
              digest(record.fetch("operation_owner_binding")) == digest(operation_owner_binding) &&
              digest(record.fetch("executor_process_binding")) == digest(peer)
            raise SecurityError, "cleanup canonical original dispatch differs"
          end
          Ace::Assign::Authority::ServiceEvidence.new(journal: journal).context(record, pending: {commit: commit})
          receiver = @deployment.project(map.fetch("project_id")).fetch("service_receivers").fetch(record.fetch("service_id"))
          credentials = @deployment.project(map.fetch("project_id")).fetch("peer_credentials").fetch(receiver.fetch("executor_uid").to_s)
          unless peer.fetch("uid") == record.fetch("executor_uid") && peer.fetch("uid") == receiver.fetch("executor_uid") &&
              peer.fetch("gid") == credentials.fetch("gid") && peer.fetch("groups") == credentials.fetch("groups")
            raise SecurityError, "cleanup original executor differs"
          end
          @kernel.live!(peer)
          events = journal.read_events(record.fetch("assignment_id"), commit: commit)
            .select { |event| event.fetch("attempt_id") == record.fetch("attempt_id") }
          selectors = frame.values_at("request_event_digest", "dispatch_event_digest")
          raise SecurityError, "cleanup original acceptance selectors are not distinct" unless selectors.uniq.size == 2
          introductions = journal.event_commits!(assignment_id: record.fetch("assignment_id"), event_digests: selectors, commit: commit)
          selectors.zip(%w[request_service begin_dispatch]).each do |selector, operation|
            matches = events.select { |event| event.fetch("digest") == selector }
            event = matches.one? && matches.first
            payload = event && event.fetch("payload")
            unless event && event.fetch("type") == "authority_mutation" && payload.fetch("operation") == operation &&
                payload.slice("assignment_id", "attempt_id") == maintenance.slice("assignment_id", "attempt_id") &&
                payload.fetch("data").slice("request_id", "claim_binding") == record.slice("request_id", "claim_binding") &&
                payload.fetch("data").fetch(operation == "request_service" ? "claim" : "invocation") == (operation == "request_service" ? "created" : "permitted")
              raise SecurityError, "cleanup original acceptance differs"
            end
            prefix = journal.read_events(record.fetch("assignment_id"), commit: introductions.fetch(selector))
              .select { |entry| entry.fetch("attempt_id") == record.fetch("attempt_id") }
            original_record = journal.service_request(record.fetch("request_id"), commit: introductions.fetch(selector))
            expected_record = operation == "request_service" ? original_record&.merge(
              "dispatch_phase" => "dispatch_started", "operation_owner_binding" => operation_owner_binding,
              "executor_process_binding" => peer) : original_record
            unless expected_record == record && prefix.last == event &&
                prefix[-2] && prefix[-2].fetch("type") == (operation == "request_service" ? "service_claim" : "service_transition") &&
                prefix[-2].dig("payload", "record_digest") == digest(original_record) &&
                event.fetch("previous_digest") == prefix[-2].fetch("digest")
              raise SecurityError, "cleanup acceptance is not its original canonical introduction"
            end
          end
          Atoms::ProtectedWorkspacePruneInput.freeze_value(JSON.parse(JSON.generate({"commit" => commit,
            "record" => record, "input" => input, "operation_owner_binding" => operation_owner_binding,
            "request_event_digest" => frame.fetch("request_event_digest"), "dispatch_event_digest" => frame.fetch("dispatch_event_digest")})))
        rescue KeyError, TypeError, ArgumentError
          raise SecurityError, "cleanup canonical admission is unavailable"
        end

        private

        def digest(value) = Ace::Assign::Atoms::EvidenceDigest.digest(value)
      end
    end
  end
end
