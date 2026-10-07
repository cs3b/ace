# frozen_string_literal: true

require_relative "execution_scope_lineage"
require_relative "../atoms/attempt_state_machine"

module Ace
  module Assign
    module Molecules
      # Canonical state projection, not live closure or settlement authority.
      # The stopped producer and terminal consumer must additionally obtain the
      # existing owners' authenticated original-prefix evidence and fresh proof.
      module CanonicalAttemptState
        STOPPED_FIELDS = %w[project_id mapping_id assignment_id attempt_id descriptor_sha256
          scope_binding_event_id seal_event_id closed_proof_event_id service_settlement_event_digests
          inbox_settlement_event_digests].freeze
        SELECTION_FIELDS = (STOPPED_FIELDS - %w[service_settlement_event_digests inbox_settlement_event_digests]).freeze

        def self.derive(events)
          return nil unless events.any? { |event| event["type"] == "intent" }
          state = "reserved"
          stopped = false
          events.each do |event|
            if stopped && %w[process_start receipt_accepted transition reconciliation attempt_stopped].include?(event["type"])
              unavailable!("Accepted stopped attempt cannot be resurrected or replaced")
            end
            case event["type"]
            when "process_start" then state = "running"
            when "receipt_accepted" then state = event.dig("payload", "receipt", "verdict") || state
            when "transition" then state = event.dig("payload", "to") || state
            when "reconciliation" then state = event.dig("payload", "resolution") || state
            when "attempt_stopped"
              verify_stopped_acceptance!(events, event, prior_state: state)
              state = "stopped"
              stopped = true
            end
          end
          state
        end

        def self.stopped_payload!(events:, selection:, service_evidence:, inbox_evidence:, commit:)
          unless selection.is_a?(Hash) && selection.keys.sort == SELECTION_FIELDS.sort &&
              service_evidence.is_a?(Hash) && service_evidence.keys.sort == %w[commit services] &&
              inbox_evidence.is_a?(Hash) && inbox_evidence.keys.sort == %w[commit inboxes] &&
              commit.is_a?(String) && commit.match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
              service_evidence["commit"] == commit && inbox_evidence["commit"] == commit
            unavailable!("Stopped plan evidence prefix differs")
          end
          services = service_evidence.fetch("services")
          inboxes = inbox_evidence.fetch("inboxes")
          unless services.is_a?(Array) && inboxes.is_a?(Array) &&
              services.all? { |item| item.is_a?(Hash) && item.keys.sort == %w[event_digest evidence_refs receipt_digest record_digest request_id state] } &&
              inboxes.all? { |item| item.is_a?(Hash) && item.keys.sort == %w[claim_generation event_id inbox_context_id receipt_ref reconciliation_event_digest reply_event_digest signature_ref] }
            unavailable!("Stopped settlement projections are malformed")
          end
          service_ids = services.map { |item| item.fetch("request_id") }
          inbox_ids = inboxes.map { |item| item.values_at("inbox_context_id", "event_id") }
          unless service_ids == service_ids.sort && service_ids.uniq == service_ids &&
              inbox_ids == inbox_ids.sort && inbox_ids.uniq == inbox_ids
            unavailable!("Stopped settlement projection is not ordered unique owner output")
          end
          services.each do |item|
            event = events.find { |entry| entry["digest"] == item.fetch("event_digest") && entry["type"] == "service_transition" }
            unless event && event.dig("payload", "request_id") == item.fetch("request_id") &&
                event.dig("payload", "state") == item.fetch("state") && %w[succeeded failed-settled].include?(item.fetch("state")) &&
                event.dig("payload", "record_digest") == item.fetch("record_digest") &&
                event.dig("payload", "receipt_digest") == item.fetch("receipt_digest")
              unavailable!("Stopped service projection differs from canonical terminal event")
            end
          end
          inboxes.each do |item|
            reconciliation = events.find { |entry| entry["digest"] == item.fetch("reconciliation_event_digest") && entry["type"] == "inbox_reconciliation" }
            reply = events.find { |entry| entry["digest"] == item.fetch("reply_event_digest") && entry["type"] == "authority_mutation" }
            unless reconciliation && reply && reply["previous_digest"] == reconciliation["digest"] &&
                reply.dig("payload", "operation") == "reconcile_inbox" &&
                reconciliation.dig("payload", "inbox_context_id") == item.fetch("inbox_context_id") &&
                reconciliation.dig("payload", "event_id") == item.fetch("event_id") &&
                reconciliation.dig("payload", "claim_generation") == item.fetch("claim_generation") &&
                reconciliation.dig("payload", "receipt_ref") == item.fetch("receipt_ref") &&
                reconciliation.dig("payload", "signature_ref") == item.fetch("signature_ref")
              unavailable!("Stopped Inbox projection differs from canonical reconciliation")
            end
          end
          payload = selection.merge("service_settlement_event_digests" => services.map { |item| item.fetch("event_digest") }.sort,
            "inbox_settlement_event_digests" => inboxes.map { |item| item.fetch("reconciliation_event_digest") }.sort)
          validate_stopped_payload!(events, payload)
          payload
        rescue KeyError, TypeError, ArgumentError, NoMethodError
          unavailable!("Stopped plan evidence is malformed")
        end

        def self.verify_stopped_acceptance!(events, event, prior_state:)
          Atoms::AttemptStateMachine.proof_stopped_transition!(prior_state)
          unless events.count { |entry| entry["type"] == "attempt_stopped" } == 1 && Models::EvidenceEvent.chain_valid?(events)
            unavailable!("Stopped canonical chain is ambiguous or corrupt")
          end
          payload = event.fetch("payload")
          prefix = events.take_while { |entry| entry["digest"] != event.fetch("digest") }
          validate_stopped_payload!(prefix, payload)
          acceptance = events.find { |entry| entry["type"] == "authority_mutation" && entry["previous_digest"] == event.fetch("digest") }
          data = acceptance&.dig("payload", "data")
          generation = acceptance && events.take_while { |entry| entry["digest"] != acceptance["digest"] }.count { |entry| entry["type"] == "authority_mutation" } + 1
          unless acceptance && data.is_a?(Hash) && data.keys.sort == %w[attempt_id generation proof_id required_action state] &&
              data["generation"].is_a?(Integer) && data["generation"] == generation &&
              acceptance.dig("payload", "operation") == "stop_attempt" &&
              acceptance.dig("payload", "assignment_id") == payload.fetch("assignment_id") &&
              acceptance.dig("payload", "attempt_id") == payload.fetch("attempt_id") &&
              acceptance.dig("payload", "data", "attempt_id") == payload.fetch("attempt_id") &&
              acceptance.dig("payload", "data", "state") == "stopped" &&
              acceptance.dig("payload", "data", "proof_id") == payload.fetch("closed_proof_event_id") &&
              acceptance.dig("payload", "data", "required_action").nil?
            unavailable!("Stopped transition has no adjacent accepted owner mutation")
          end
          seal = prefix.find { |entry| entry["digest"] == payload.fetch("seal_event_id") }
          accepted_seal = seal && prefix.find { |entry| entry["type"] == "authority_mutation" && entry["previous_digest"] == seal["digest"] &&
            %w[close_execution_scope stop_attempt].include?(entry.dig("payload", "operation")) }
          proof = prefix.find { |entry| entry["digest"] == payload.fetch("closed_proof_event_id") }
          accepted_proof = proof && prefix.find { |entry| entry["type"] == "authority_mutation" && entry["previous_digest"] == proof["digest"] &&
            %w[close_execution_scope stop_attempt].include?(entry.dig("payload", "operation")) &&
            entry.dig("payload", "data", "proof_id") == proof["digest"] && entry.dig("payload", "data", "state") == "closed_no_writers" }
          unless accepted_seal && (accepted_proof || event["previous_digest"] == proof&.fetch("digest"))
            unavailable!("Stopped canonical seal or proof has no accepted owner")
          end
          event
        rescue KeyError, TypeError, ArgumentError, NoMethodError, AttemptErrors::InvalidTransition
          unavailable!("Stopped canonical acceptance is malformed")
        end

        def self.validate_stopped_payload!(events, payload)
          unless payload.is_a?(Hash) && payload.keys.sort == STOPPED_FIELDS.sort &&
              %w[project_id mapping_id assignment_id attempt_id].all? { |key| payload[key].is_a?(String) && ExecutionScopeLineage::ID.match?(payload[key]) } &&
              %w[descriptor_sha256 scope_binding_event_id seal_event_id closed_proof_event_id].all? { |key| digest?(payload[key]) } &&
              %w[service_settlement_event_digests inbox_settlement_event_digests].all? { |key|
                values = payload[key]
                values.is_a?(Array) && values.all? { |value| digest?(value) } && values == values.sort && values.uniq == values }
            unavailable!("Stopped canonical payload is not closed")
          end
          lineage = ExecutionScopeLineage.new(events: events, **payload.slice("project_id", "mapping_id", "assignment_id", "attempt_id").transform_keys(&:to_sym))
          provisioning = events.select { |event| event["type"] == "scope_provisioning" }
          unless provisioning.one? && provisioning.first.dig("payload", "descriptor_sha256") == payload.fetch("descriptor_sha256") &&
              lineage.native_event && lineage.child_event &&
              lineage.binding_event&.fetch("digest") == payload.fetch("scope_binding_event_id") &&
              lineage.seal_event&.fetch("digest") == payload.fetch("seal_event_id") &&
              lineage.proof_event&.fetch("digest") == payload.fetch("closed_proof_event_id")
            unavailable!("Stopped canonical original scope selectors differ")
          end
          payload.fetch("service_settlement_event_digests").each do |digest|
            unless events.any? { |event| event["digest"] == digest && event["type"] == "service_transition" &&
                %w[succeeded failed-settled].include?(event.dig("payload", "state")) }
              unavailable!("Stopped canonical service selector is not terminal evidence")
            end
          end
          payload.fetch("inbox_settlement_event_digests").each do |digest|
            unless events.any? { |event| event["digest"] == digest && event["type"] == "inbox_reconciliation" &&
                event.dig("payload", "state") == "completed" }
              unavailable!("Stopped canonical Inbox selector is not completed evidence")
            end
          end
          payload
        rescue KeyError, TypeError, ArgumentError, NoMethodError
          unavailable!("Stopped canonical scope is malformed")
        end

        def self.digest?(value) = value.is_a?(String) && ExecutionScopeLineage::DIGEST.match?(value)
        def self.unavailable!(message) = raise AttemptErrors::EvidenceUnavailable, message
        private_class_method :digest?, :unavailable!
      end
    end
  end
end
