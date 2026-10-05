# frozen_string_literal: true

require_relative "../atoms/evidence_digest"

module Ace
  module Assign
    module Models
      # Append-only accepted evidence event.
      #
      # Evidence events are the journal trail of an attempt: intent,
      # process start, accepted receipts, state transitions, candidate
      # invalidations, and reconciliations. Each event chains to the digest
      # of its predecessor for the attempt, so accepted history cannot be
      # reordered or silently rewritten. Events carry bounded, non-secret
      # metadata only.
      module EvidenceEvent
        TYPES = %w[
          intent process_start receipt_accepted transition
          candidate_invalidated reconciliation
          service_claim service_transition recovery_observation inbox_binding inbox_reconciliation delivery
          authority_mutation evidence_import proposal_state result_submitted
        ].freeze

        # Build an event chained to a previous digest.
        #
        # @param type [String] Event type (see TYPES)
        # @param attempt_id [String] Owning attempt ID
        # @param payload [Hash] Bounded, non-secret event metadata
        # @param previous_digest [String, nil] Digest of the previous event (chain)
        # @param recorded_at [Time] Event creation time
        # @return [Hash] Serializable event with type, payload, digests, timestamp
        # @raise [ArgumentError] for unknown event types
        def self.build(type:, attempt_id:, payload:, previous_digest: nil, recorded_at: Time.now.utc)
          raise ArgumentError, "Unknown evidence event type: #{type}" unless TYPES.include?(type.to_s)

          recorded_at = recorded_at.utc
          body = {
            "type" => type.to_s,
            "attempt_id" => attempt_id,
            "payload" => payload,
            "previous_digest" => previous_digest,
            "recorded_at" => recorded_at.iso8601
          }
          body.merge("digest" => Atoms::EvidenceDigest.digest(body))
        end

        # Validate that a stored event is intact: its digest must match a
        # recomputation over its own body.
        #
        # @param event [Hash] Stored event
        # @return [Boolean] True if the event digest verifies
        def self.valid?(event)
          stored = event["digest"]
          return false if stored.nil?

          body = {
            "type" => event["type"],
            "attempt_id" => event["attempt_id"],
            "payload" => event["payload"],
            "previous_digest" => event["previous_digest"],
            "recorded_at" => event["recorded_at"]
          }
          Atoms::EvidenceDigest.digest(body) == stored
        end

        # Validate a whole chain: every event verifies and links to its
        # predecessor.
        #
        # @param events [Array<Hash>] Ordered event list
        # @return [Boolean] True if the chain is intact
        def self.chain_valid?(events)
          previous = nil
          events.all? do |event|
            return false unless valid?(event)
            return false unless event["previous_digest"] == previous

            previous = event["digest"]
            true
          end
        end
      end
    end
  end
end
