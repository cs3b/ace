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
        INSPECT_FIELDS = (FIELDS + %w[challenge_ref]).freeze

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

        def connection_group!(gid)
          authority = @deployment.authority(@authority_id)
          map = @deployment.mapping(@mapping_id)
          project = @deployment.project(map.fetch("project_id"))
          receiver = project.fetch("service_receivers").fetch(@service_id)
          credentials = project.fetch("peer_credentials").fetch(receiver.fetch("executor_uid").to_s)
          unless gid.is_a?(Integer) && gid.positive? && [authority, credentials].all? { |principal| principal.fetch("gid") == gid || principal.fetch("groups").include?(gid) }
            raise SecurityError, "cleanup connection group differs from installed principals"
          end
          true
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
          admit_original!(frame: frame, peer: peer, operation_owner_binding: operation_owner_binding, journal: journal, purpose: :execute)
        end

        def inspect!(frame:, peer:, operation_owner_binding:, journal:)
          context = admit_original!(frame: frame, peer: peer, operation_owner_binding: operation_owner_binding, journal: journal, purpose: :inspect)
          reference = frame.fetch("challenge_ref")
          Atoms::ProtectedWorkspacePruneInput.object!(reference, %w[challenge_event_digest])
          Atoms::ProtectedWorkspacePruneInput.digest!(reference.fetch("challenge_event_digest"))
          challenge = Ace::Assign::Authority::ServiceEvidence.new(journal: journal).challenge!(context.fetch("record"), pending: {commit: context.fetch("commit")})
          unless challenge.fetch("digest") == reference.fetch("challenge_event_digest")
            raise SecurityError, "cleanup inspection challenge differs"
          end
          Atoms::ProtectedWorkspacePruneInput.freeze_value(context.merge("challenge" => challenge))
        end

        private

        def admit_original!(frame:, peer:, operation_owner_binding:, journal:, purpose:)
          receiver!(peer)
          Atoms::ProtectedWorkspacePruneInput.object!(frame, purpose == :execute ? FIELDS : INSPECT_FIELDS)
          unless frame.values_at("schema", "kind") == [ProtectedCleanupOwnerClient::SCHEMA, purpose.to_s]
            raise SecurityError, "cleanup invocation kind differs"
          end
          Atoms::ProtectedWorkspacePruneInput.token!(frame.fetch("request_id"))
          (FIELDS - %w[schema kind request_id input]).each do |key|
            Atoms::ProtectedWorkspacePruneInput.digest!(frame.fetch(key))
          end
          input = Atoms::ProtectedWorkspacePruneInput.parse(JSON.generate(frame.fetch("input")))
          unless Atoms::ServiceInput.digest(input) == frame.fetch("input_digest") &&
              (purpose == :inspect || digest(operation_owner_binding) == frame.fetch("operation_owner_binding_digest"))
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
              record.values_at("operation", "dispatch_phase") == ["prune-preserved-workspace", "dispatch_started"] &&
              (purpose == :execute ? record["state"] == "uncertain" : %w[uncertain failed].include?(record["state"])) &&
              record.slice("request_id", "input_digest", "claim_binding") == frame.slice("request_id", "input_digest", "claim_binding") &&
              record.fetch("target") == Atoms::ServiceInput.target(input) &&
              digest(record.fetch("operation_owner_binding")) == frame.fetch("operation_owner_binding_digest") &&
              (purpose == :inspect || digest(record.fetch("executor_process_binding")) == digest(peer))
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
          proof = Ace::Assign::Authority::ServiceEvidence.new(journal: journal).cleanup_dispatch_context!(
            record, commit: commit, selectors: frame.slice("request_event_digest", "dispatch_event_digest"))
          if purpose == :execute && proof.fetch("dispatch_record") != record
            raise SecurityError, "cleanup original executable record differs"
          end
          Atoms::ProtectedWorkspacePruneInput.freeze_value(JSON.parse(JSON.generate({"commit" => commit,
            "record" => record, "input" => input, "operation_owner_binding" => operation_owner_binding,
            "request_event_digest" => frame.fetch("request_event_digest"), "dispatch_event_digest" => frame.fetch("dispatch_event_digest")})))
        rescue KeyError, TypeError, ArgumentError
          raise SecurityError, "cleanup canonical admission is unavailable"
        end

        def digest(value) = Ace::Assign::Atoms::EvidenceDigest.digest(value)
      end
    end
  end
end
