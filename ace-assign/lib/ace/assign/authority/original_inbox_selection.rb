# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      # Original descriptor selection shared by canonical Inbox consumers.
      # The held historical manifest/key owner supplies the exact artifact.
      class OriginalInboxSelection
        def initialize(history:, authority_id:)
          @history, @authority_id = history, authority_id
        end

        def load!(events:, params:, map:, journal:, commit:)
          provisioning = events.select { |event| event["type"] == "scope_provisioning" }
          reservations = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "reserve_attempt" }
          unless provisioning.one? && reservations.one?
            raise AttemptErrors::EvidenceUnavailable, "context completion original selection is ambiguous"
          end
          identity = provisioning.first.fetch("payload")
          reserved = reservations.first.fetch("payload").fetch("data")
          original = @history.descriptor!(sha256: identity.fetch("descriptor_sha256"))
          selected = original.mapping(params.fetch("mapping_id"))
          unless identity.keys.sort == %w[deployment_digest descriptor_sha256 reservation_generation slot_id] &&
              reserved.values_at("project_id", "assignment_id", "attempt_id", "mapping_id") ==
                [map.fetch("project_id"), params.fetch("assignment_id"), params.fetch("attempt_id"), params.fetch("mapping_id")] &&
              identity.fetch("reservation_generation") == reserved.fetch("reservation_generation") &&
              identity.fetch("deployment_digest") == original.mapping_digest(params.fetch("mapping_id")) &&
              selected.fetch("project_id") == map.fetch("project_id") && selected.fetch("authority_id") == @authority_id &&
              identity.fetch("slot_id") == selected.fetch("execution_scope").fetch("slot_id") &&
              original.project(selected.fetch("project_id")).values_at("journal_repository", "evidence_git_ref", "evidence_checkout_root") ==
                [journal.repo_root, journal.ref, journal.checkout_root]
            raise AttemptErrors::EvidenceUnavailable, "context completion original association differs"
          end
          journal.event_commit!(assignment_id: params.fetch("assignment_id"), event_digest: provisioning.first.fetch("digest"), commit: commit)
          [original, selected]
        end

      end
    end
  end
end
