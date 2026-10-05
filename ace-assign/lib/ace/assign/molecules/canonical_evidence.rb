# frozen_string_literal: true

require "digest"
require "securerandom"
require "time"

module Ace
  module Assign
    module Molecules
      # One import/verification contract for protected review, service and
      # inbox evidence. Filesystem projections never supply accepted bytes.
      class CanonicalEvidence
        MAX_ARTIFACT_BYTES = 64 * 1024
        MAX_TOTAL_BYTES = 256 * 1024
        MAX_ARTIFACTS = 16
        ID = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/
        ROLES = {"service" => "executor", "review" => "reviewer", "inbox" => "signer",
                 "observation" => "observer", "result" => "worker"}.freeze
        DESCRIPTOR_FIELDS = %w[version artifact_id kind project_id assignment_id attempt_id peer_uid role
          binding_digest sha256 bytes admitted_at admitted_after_event_digest request_id_or_event_id
          candidate_generation_or_claim_generation].freeze

        def initialize(journal:)
          @journal = journal
        end

        # Construct the immutable bytes/events for EvidenceJournal#mutate.
        # peer_uid comes from the accepted kernel-authenticated connection;
        # callers of the wire API cannot supply provenance or artifact IDs.
        def import_plan(kind:, project_id:, assignment_id:, attempt_id:, peer_uid:, binding:,
          request_id_or_event_id:, generation:, admitted_after_event_digest:, artifacts:)
          role = ROLES.fetch(kind) { raise ArgumentError, "invalid evidence kind" }
          ids = [project_id, assignment_id, attempt_id, request_id_or_event_id]
          unless ids.all? { |id| id.is_a?(String) && id.match?(ID) } && binding.is_a?(Hash) &&
              admitted_after_event_digest.is_a?(String) && admitted_after_event_digest.match?(/\A[0-9a-f]{64}\z/) &&
              peer_uid.is_a?(Integer) && peer_uid >= 0 && generation.is_a?(Integer) && generation >= 0 &&
              artifacts.is_a?(Array) && !artifacts.empty? && artifacts.length <= MAX_ARTIFACTS &&
              artifacts.all? { |bytes| bytes.is_a?(String) && bytes.bytesize <= MAX_ARTIFACT_BYTES } &&
              artifacts.sum(&:bytesize) <= MAX_TOTAL_BYTES
            raise ArgumentError, "invalid or oversized canonical evidence import"
          end
          events = []
          blobs = {}
          references = artifacts.map do |bytes|
            artifact_id = SecureRandom.hex(16)
            artifact_id += "-no-effect" if kind == "service" && binding["no_effect_challenge"]
            digest = Digest::SHA256.hexdigest(bytes.b)
            path = "evidence/imports/#{artifact_id}"
            descriptor = {"version" => 1, "artifact_id" => artifact_id, "kind" => kind,
                          "project_id" => project_id, "assignment_id" => assignment_id,
                          "attempt_id" => attempt_id, "peer_uid" => peer_uid, "role" => role,
                          "binding_digest" => Atoms::EvidenceDigest.digest(binding), "sha256" => digest,
                          "bytes" => bytes.bytesize, "admitted_at" => Time.now.utc.iso8601(9),
                          "admitted_after_event_digest" => admitted_after_event_digest,
                          "request_id_or_event_id" => request_id_or_event_id,
                          "candidate_generation_or_claim_generation" => generation}
            events << {type: "evidence_import", payload: descriptor}
            blobs[path] = bytes.b
            {"ref" => path, "sha256" => digest}
          end
          {events: events, blobs: blobs, references: references}
        end

        def read(reference, kind:, project_id:, assignment_id:, attempt_id:, peer_uid:, binding:,
          request_id_or_event_id:, generation:)
          # One immutable commit supplies both provenance events and bytes.
          commit = @journal.ref_value
          events = @journal.read_events(assignment_id, commit: commit)
            .select { |event| event["attempt_id"] == attempt_id }
          verified_bytes(reference, events: events, kind: kind, project_id: project_id,
            assignment_id: assignment_id, attempt_id: attempt_id, peer_uid: peer_uid, binding: binding,
            request_id_or_event_id: request_id_or_event_id, generation: generation) do |path|
            @journal.blob(path, commit: commit)
          end
        end

        # Only the journal writer supplies this transient pre-CAS view. It
        # validates the exact same provenance/chain/bytes as committed reads;
        # it does not accept a receipt or advance the canonical ref itself.
        def read_pending(reference, current_events:, pending_events:, blobs:, commit:,
          kind:, project_id:, assignment_id:, attempt_id:, peer_uid:, binding:,
          request_id_or_event_id:, generation:)
          events = current_events + pending_events
          unless events.all? { |event| event["attempt_id"] == attempt_id } && blobs.is_a?(Hash)
            unavailable!
          end
          verified_bytes(reference, events: events, kind: kind, project_id: project_id,
            assignment_id: assignment_id, attempt_id: attempt_id, peer_uid: peer_uid, binding: binding,
            request_id_or_event_id: request_id_or_event_id, generation: generation) do |path|
            blobs.key?(path) ? blobs.fetch(path) : @journal.blob(path, commit: commit)
          end
        end

        private

        def verified_bytes(reference, events:, kind:, project_id:, assignment_id:, attempt_id:, peer_uid:, binding:,
          request_id_or_event_id:, generation:)
          unless reference.is_a?(Hash) && reference.keys.sort == %w[ref sha256] &&
              reference["ref"].is_a?(String) && reference["ref"].match?(%r{\Aevidence/imports/[a-z0-9-]+\z})
            unavailable!
          end
          unavailable! unless Models::EvidenceEvent.chain_valid?(events)
          artifact_id = reference.fetch("ref").delete_prefix("evidence/imports/")
          imports = events.select do |event|
            event["type"] == "evidence_import" && event.dig("payload", "artifact_id") == artifact_id
          end
          unavailable! unless imports.length == 1
          event = imports.first
          descriptor = event.fetch("payload")
          expected = {"version" => 1, "artifact_id" => artifact_id, "kind" => kind,
                      "project_id" => project_id, "assignment_id" => assignment_id,
                      "attempt_id" => attempt_id, "peer_uid" => peer_uid, "role" => ROLES.fetch(kind),
                      "binding_digest" => Atoms::EvidenceDigest.digest(binding),
                      "sha256" => reference.fetch("sha256"), "request_id_or_event_id" => request_id_or_event_id,
                      "candidate_generation_or_claim_generation" => generation}
          unavailable! unless descriptor.keys.sort == DESCRIPTOR_FIELDS.sort &&
            expected.all? { |key, value| descriptor[key] == value }
          before = events.take_while { |entry| entry["digest"] != event["digest"] }
          unavailable! unless before.any? { |entry| entry["digest"] == descriptor["admitted_after_event_digest"] }
          Time.iso8601(descriptor.fetch("admitted_at"))
          bytes = yield(reference.fetch("ref"))
          unavailable! unless bytes.is_a?(String) && bytes.bytesize <= MAX_ARTIFACT_BYTES && bytes.bytesize == descriptor["bytes"] &&
            Digest::SHA256.hexdigest(bytes) == descriptor["sha256"]
          bytes
        rescue ArgumentError, KeyError, TypeError
          unavailable!
        end

        def unavailable!
          raise AttemptErrors::EvidenceUnavailable, "Canonical evidence import or binding is unverifiable"
        end
      end
    end
  end
end
