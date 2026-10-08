# frozen_string_literal: true

require "ace/herdr/molecules/inbox_context_client"
require "ace/herdr/molecules/inbox_context_effect_binding"

module Ace
  module Assign
    module Authority
      # The same authority process retains one real context admission across
      # its existing qjl transaction. This object stores no delivery outcome.
      class InboxContextSession
        attr_reader :effect_binding

        def initialize(client:, params:, map:, mutation_id:, authority_peer:)
          @client, @params, @map, @mutation_id = client, params, map, mutation_id
          @operation = @client.request("begin_context_operation", {"context_id" => params.fetch("inbox_context_id"),
            "purpose" => "reconcile", "event_id" => params.fetch("event_id"), "process_binding" => authority_peer})
          unless @operation.keys.sort == %w[fingerprint key_generation operation_id state] &&
              @operation["fingerprint"].is_a?(String) && @operation["fingerprint"].match?(/\A[0-9a-f]{64}\z/) &&
              @operation["operation_id"].is_a?(String) && @operation["operation_id"].match?(/\A[0-9a-f]{32}\z/) &&
              @operation["key_generation"].is_a?(Integer) && @operation["key_generation"].positive? && %w[admitted unknown].include?(@operation["state"])
            raise AttemptErrors::EvidenceUnavailable, "context admission response differs"
          end
        end

        def receipt_key_sha256 = @operation.fetch("fingerprint")

        def pending? = @operation.fetch("state") == "unknown"

        def resume_completion!(binding:, registration:, reconciliation_digest:)
          selected = Ace::Herdr::Molecules::InboxContextEffectBinding.verify!(binding)
          expected = {"project_id" => @map.fetch("project_id"), "mutation_id" => @mutation_id,
            "operation_id" => @operation.fetch("operation_id"), "key_generation" => @operation.fetch("key_generation"),
            "registration" => registration}.merge(@params.slice("assignment_id", "attempt_id", "mapping_id",
              "inbox_context_id", "event_id", "receipt_sha256", "signature_sha256"))
          unless pending? && expected.all? { |key, value| selected.fetch(key) == value }
            raise AttemptErrors::EvidenceUnavailable, "retained context completion selection differs"
          end
          @effect_binding = selected
          confirm!(reconciliation_digest: reconciliation_digest)
        end

        def retained_status(event:)
          raise AttemptErrors::EvidenceUnavailable, "context admitted event differs" unless event == @params.fetch("event_id")
          result = @client.request("snapshot_context", {"operation_id" => @operation.fetch("operation_id"),
            "key_generation" => @operation.fetch("key_generation"), "event_id" => event})
          unless result.keys.sort == %w[context_id key_generation operation_id record] &&
              result.values_at("context_id", "key_generation", "operation_id") ==
                [@params.fetch("inbox_context_id"), @operation.fetch("key_generation"), @operation.fetch("operation_id")] && result["record"].is_a?(Hash)
            raise AttemptErrors::EvidenceUnavailable, "context snapshot differs"
          end
          result.fetch("record")
        end

        def require_idle!
          unless @operation.fetch("state") == "admitted" && @effect_binding.nil?
            raise AttemptErrors::InboxContextPending, "pending context effect cannot authorize settlement"
          end
          true
        end

        def reconcile(event:, receipt:, signed_bytes:, signature:, expected_registration:)
          unless event == @params.fetch("event_id") && Digest::SHA256.hexdigest(signed_bytes) == @params.fetch("receipt_sha256") &&
              Digest::SHA256.hexdigest(signature) == @params.fetch("signature_sha256")
            raise AttemptErrors::EvidenceUnavailable, "context reconciliation selection differs"
          end
          @effect_binding = Ace::Herdr::Molecules::InboxContextEffectBinding.verify!({"schema" => "ace.herdr.inbox-context-effect/v1",
            "project_id" => @map.fetch("project_id"), "assignment_id" => @params.fetch("assignment_id"), "attempt_id" => @params.fetch("attempt_id"),
            "mapping_id" => @params.fetch("mapping_id"), "inbox_context_id" => @params.fetch("inbox_context_id"), "event_id" => event,
            "mutation_id" => @mutation_id, "operation_id" => @operation.fetch("operation_id"), "key_generation" => @operation.fetch("key_generation"),
            "registration" => expected_registration, "receipt_sha256" => @params.fetch("receipt_sha256"), "signature_sha256" => @params.fetch("signature_sha256")})
          result = @client.request("reconcile_context", {"effect_binding" => @effect_binding}, proof: [signed_bytes, signature])
          unless result.keys.sort == %w[binding claim_generation effect_binding effect_binding_digest registration state] &&
              result["effect_binding"] == @effect_binding && result["effect_binding_digest"] == Ace::Herdr::Molecules::InboxContextEffectBinding.digest(@effect_binding) &&
              result["registration"] == expected_registration && result["claim_generation"].is_a?(Integer) && result["claim_generation"].positive? &&
              %w[completed queued].include?(result["state"]) && result["binding"] == receipt["binding"]
            raise AttemptErrors::EvidenceUnavailable, "context accepted proof response differs"
          end
          result
        end

        def verify_reconciliation(event:, receipt:, signed_bytes:, signature:, expected_registration:)
          raise AttemptErrors::EvidenceUnavailable, "context proof read selection differs" unless event == @params.fetch("event_id")
          result = @client.request("verify_context_reconciliation", {"operation_id" => @operation.fetch("operation_id"),
            "key_generation" => @operation.fetch("key_generation"), "event_id" => event, "expected_registration" => expected_registration},
            proof: [signed_bytes, signature])
          unless result["registration"] == expected_registration && result["binding"] == receipt["binding"] &&
              result["claim_generation"].is_a?(Integer) && result["claim_generation"] == receipt["claim_generation"] &&
              %w[queued completed].include?(result["state"])
            raise AttemptErrors::EvidenceUnavailable, "context retained proof response differs"
          end
          result
        end

        def confirm!(reconciliation_digest:)
          raise AttemptErrors::EvidenceUnavailable, "context effect was not produced" unless @effect_binding
          result = @client.request("confirm_context_completion", {"effect_binding" => @effect_binding, "reconciliation_digest" => reconciliation_digest})
          unless result.keys.sort == %w[completion effect_binding_digest operation_id state] && result["state"] == "confirmed" &&
              result["operation_id"] == @operation.fetch("operation_id") &&
              result["effect_binding_digest"] == Ace::Herdr::Molecules::InboxContextEffectBinding.digest(@effect_binding)
            raise AttemptErrors::EvidenceUnavailable, "context canonical completion differs"
          end
          @operation = @operation.merge("state" => "admitted")
          result
        end

        def end!
          result = @client.request("end_context_operation", {"operation_id" => @operation.fetch("operation_id")})
          unless result == {"operation_id" => @operation.fetch("operation_id"), "state" => "ended"}
            raise AttemptErrors::EvidenceUnavailable, "context operation end is unconfirmed"
          end
          result
        end
      end
    end
  end
end
