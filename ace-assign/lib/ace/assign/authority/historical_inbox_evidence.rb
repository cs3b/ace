# frozen_string_literal: true

require "ace/herdr/molecules/inbox_receipt_authentication"
require_relative "../molecules/canonical_evidence"

module Ace
  module Assign
    module Authority
      # Historical half of the existing inbox settlement owner. Every input is
      # canonical at the release prefix; current retained inventory is separate.
      class HistoricalInboxEvidence
        def initialize(journal:, deployment:, history:)
          @journal, @deployment, @history = journal, deployment, history
        end

        def verify!(events:, params:, map:, commit:)
          settlement_evidence!(events: events, params: params, map: map, commit: commit)
          true
        end

        def settlement_evidence!(events:, params:, map:, commit:)
          @journal.verify_commit!(commit)
          retained = @journal.read_events(params.fetch("assignment_id"), commit: commit)
            .select { |event| event["attempt_id"] == params.fetch("attempt_id") }
          unless retained == events && Models::EvidenceEvent.chain_valid?(events)
            raise AttemptErrors::EvidenceUnavailable, "historical inbox requires exact canonical prefix"
          end
          verify_records!(events: events, params: params, map: map, commit: commit)
        rescue KeyError, TypeError, ArgumentError, NoMethodError
          raise AttemptErrors::EvidenceUnavailable, "historical inbox settlement is unverifiable"
        end

        # Authentication of one accepted source effect is independent of final
        # all-Inbox consumption. Superseded input may legitimately remain queued.
        # This query never reads the current Inbox or calls its context endpoint.
        def verify_selected!(events:, params:, map:, commit:, reconciliation_digest:, mutation_id: nil)
          unless reconciliation_digest.is_a?(String) && reconciliation_digest.match?(/\A[0-9a-f]{64}\z/)
            raise AttemptErrors::EvidenceUnavailable, "selected inbox reconciliation is invalid"
          end
          @journal.verify_commit!(commit)
          retained = @journal.read_events(params.fetch("assignment_id"), commit: commit)
            .select { |event| event["attempt_id"] == params.fetch("attempt_id") }
          unless retained == events && Models::EvidenceEvent.chain_valid?(events)
            raise AttemptErrors::EvidenceUnavailable, "selected inbox requires exact canonical prefix"
          end
          selected = events.find { |event| event["digest"] == reconciliation_digest && event["type"] == "inbox_reconciliation" }
          unless selected && selected.dig("payload", "event_id") == params.fetch("event_id") &&
              selected.dig("payload", "inbox_context_id") == params.fetch("inbox_context_id")
            raise AttemptErrors::EvidenceUnavailable, "selected inbox reconciliation differs"
          end
          result = verify_records!(events: events, params: params, map: map, commit: commit, selected: selected, mutation_id: mutation_id)
          @journal.event_commits!(assignment_id: params.fetch("assignment_id"),
            event_digests: %w[reconciliation reply].map { |kind| result.fetch(kind).fetch("digest") }, commit: commit)
          result
        rescue KeyError, TypeError, ArgumentError, NoMethodError
          raise AttemptErrors::EvidenceUnavailable, "selected inbox evidence is unverifiable"
        end

        private

        def verify_records!(events:, params:, map:, commit:, selected: nil, mutation_id: nil)
          raise AttemptErrors::EvidenceUnavailable, "historical inbox requires protected journal" unless @journal.evidence_mode == :protected
          registrations = events.select { |event| event["type"] == "inbox_binding" }
          identities = registrations.map { |event| event.dig("payload", "event_id") }
          raise AttemptErrors::EvidenceUnavailable, "historical inbox registration repeated" unless identities.uniq == identities
          if selected
            registrations = registrations.select { |event| event.dig("payload", "event_id") == selected.dig("payload", "event_id") }
            raise AttemptErrors::EvidenceUnavailable, "selected inbox registration missing" unless registrations.size == 1
          end
          result = nil
          settled = []
          registrations.each do |registered|
            payload = registered.fetch("payload")
            registration = payload.fetch("registration")
            unless payload.keys.sort == %w[attempt_id event_id inbox_context_id registration] &&
                registration.is_a?(Hash) && registration.keys.sort == Endcap::INBOX_REGISTRATION_FIELDS.sort &&
                payload["attempt_id"] == params.fetch("attempt_id") &&
                registration.values_at("event_id", "attempt_id") == payload.values_at("event_id", "attempt_id") &&
                %w[payload_sha256 receipt_key_sha256].all? { |key| registration[key].is_a?(String) && registration[key].match?(/\A[0-9a-f]{64}\z/) }
              raise AttemptErrors::EvidenceUnavailable, "historical inbox registration differs"
            end
            context_id = payload.fetch("inbox_context_id")
            context = @deployment.inbox_context(params.fetch("mapping_id"), context_id)
            lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
              assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mapping_id: context.fetch("native_mapping_id"))
            raise AttemptErrors::EvidenceUnavailable, "historical native inbox identity missing" unless lineage.native_event
            reconciliations = events.select { |event| event["type"] == "inbox_reconciliation" && event.dig("payload", "event_id") == payload.fetch("event_id") }
            if selected
              position = reconciliations.index(selected)
              raise AttemptErrors::EvidenceUnavailable, "selected inbox claim missing" unless position
              reconciliations = reconciliations.take(position + 1)
            end
            proof = reconciliations.last&.fetch("payload")
            unless proof && proof.keys.sort == Endcap::INBOX_PAYLOAD_FIELDS.sort && proof["version"] == 1 &&
                (selected || proof["state"] == "completed") && proof["registration"] == registration &&
                proof.values_at("event_id", "attempt_id", "inbox_context_id") == payload.values_at("event_id", "attempt_id", "inbox_context_id") &&
                reconciliations.map { |event| event.dig("payload", "claim_generation") }.uniq.size == reconciliations.size &&
                reconciliations.all? { |event| event.dig("payload", "claim_generation").is_a?(Integer) && event.dig("payload", "claim_generation").between?(0, proof.fetch("claim_generation")) }
              raise AttemptErrors::EvidenceUnavailable, "historical inbox settlement incomplete"
            end
            # The retained store owner increments claims on delivery; reconcile
            # accepts only its current claim and replay appends no proof event.
            unless reconciliations.each_cons(2).all? { |left, right| left.dig("payload", "claim_generation") < right.dig("payload", "claim_generation") }
              raise AttemptErrors::EvidenceUnavailable, "historical inbox claim order differs"
            end
            replies = events.select { |event| event["type"] == "authority_mutation" &&
              event.dig("payload", "operation") == "reconcile_inbox" && event.dig("payload", "data", "event_id") == payload.fetch("event_id") }
            if selected
              replies = replies.select { |reply| reconciliations.any? { |record|
                reply.dig("payload", "data", "receipt_ref") == record.dig("payload", "receipt_ref") } }
            end
            unless replies.all? { |reply| reconciliations.any? { |record|
              projection = record.fetch("payload").slice("event_id", "attempt_id", "inbox_context_id", "registration", "state", "receipt_ref", "signature_ref")
              reply.fetch("payload").fetch("data").slice(*projection.keys) == projection } }
              raise AttemptErrors::EvidenceUnavailable, "historical inbox private reply differs"
            end
            reconciliations.each do |reconciliation|
              proof = reconciliation.fetch("payload")
              unless proof.keys.sort == Endcap::INBOX_PAYLOAD_FIELDS.sort && proof["version"] == 1 &&
                  proof["registration"] == registration && proof.values_at("event_id", "attempt_id", "inbox_context_id") ==
                    payload.values_at("event_id", "attempt_id", "inbox_context_id")
                raise AttemptErrors::EvidenceUnavailable, "historical inbox claim payload differs"
              end
              binding = proof.fetch("binding")
              native = binding.fetch("native_binding")
              expected = params.slice("assignment_id", "attempt_id", "mapping_id").merge(
                "project_id" => map.fetch("project_id"), "event_id" => payload.fetch("event_id"), "inbox_context_id" => context_id,
                "registration" => registration, "claim_generation" => proof.fetch("claim_generation"), "native_binding" => native,
                "scope_binding_event_id" => lineage.binding_event.fetch("digest"), "native_binding_event_id" => lineage.native_event.fetch("digest"),
                "scope_native_binding" => lineage.native_event.fetch("payload"), "receipt_key_sha256" => registration.fetch("receipt_key_sha256"),
                "receipt_sha256" => binding.fetch("receipt_sha256"), "signature_sha256" => binding.fetch("signature_sha256"),
                "submitter_uid" => binding.fetch("submitter_uid"), "submitter_role" => binding.fetch("submitter_role"))
              allowed = (binding["submitter_role"] == "launcher" && binding["submitter_uid"] == map.fetch("launcher_uid")) ||
                (binding["submitter_role"] == "supervisor" && context.fetch("supervisor_uids").include?(binding["submitter_uid"])) ||
                (binding["submitter_role"] == "signer" && context.fetch("signer_uids", []).include?(binding["submitter_uid"]))
              unless binding.keys.sort == Endcap::INBOX_BINDING_FIELDS.sort && binding == expected && allowed &&
                  native.is_a?(Hash) && native["session"] == lineage.native_event.dig("payload", "workspace_id")
                raise AttemptErrors::EvidenceUnavailable, "historical inbox native or submitter identity differs"
              end
              canonical = Molecules::CanonicalEvidence.new(journal: @journal)
              imported_context = {kind: "inbox", project_id: map.fetch("project_id"), assignment_id: params.fetch("assignment_id"),
                attempt_id: params.fetch("attempt_id"), peer_uid: binding.fetch("submitter_uid"), binding: binding,
                request_id_or_event_id: payload.fetch("event_id"), generation: proof.fetch("claim_generation")}
              raw, signature = %w[receipt_ref signature_ref].map do |field|
                reference = proof.fetch(field)
                unless reference.is_a?(Hash) && reference.keys.sort == Endcap::INBOX_REF_FIELDS.sort &&
                    reference["ref"] == "evidence/imports/#{reference['artifact_id']}" && reference["bytes"].is_a?(Integer) && reference["bytes"].between?(1, 16_384)
                  raise AttemptErrors::EvidenceUnavailable, "historical inbox reference differs"
                end
                bytes = canonical.read(reference.slice("ref", "sha256"), **imported_context, commit: commit)
                raise AttemptErrors::EvidenceUnavailable, "historical inbox byte count differs" unless bytes.bytesize == reference.fetch("bytes")
                bytes
              end
              unless [raw, signature].map { |bytes| Digest::SHA256.hexdigest(bytes) } == binding.values_at("receipt_sha256", "signature_sha256")
                raise AttemptErrors::EvidenceUnavailable, "historical inbox raw digests differ"
              end
              receipt = JSON.parse(raw.dup.force_encoding(Encoding::UTF_8), create_additions: false, max_nesting: 32,
                allow_duplicate_key: false, allow_comments: false)
              auth = Ace::Herdr::Molecules::InboxReceiptAuthentication
              signed_state = receipt["outcome"] == "consumed" ? "completed" : "queued"
              replacement = receipt["replacement_target"]
              unless proof["state"] == signed_state && (!receipt.key?("replacement_target") ||
                  (replacement.is_a?(Hash) && replacement["session"] == lineage.native_event.dig("payload", "workspace_id"))) && receipt.values_at("event_id", "attempt_id", "payload_sha256") ==
                  registration.values_at("event_id", "attempt_id", "payload_sha256") &&
                  receipt["claim_generation"] == proof.fetch("claim_generation") && receipt["binding"] == native &&
                  !auth.proof_refusal(receipt) && !auth.signature_refusal(key: @history.public_key!(sha256: registration.fetch("receipt_key_sha256")),
                    key_sha256: registration.fetch("receipt_key_sha256"), receipt: receipt, signed_bytes: raw, signature: signature)
                raise AttemptErrors::EvidenceUnavailable, "historical signed consumption proof differs"
              end
              projection = proof.slice("event_id", "attempt_id", "inbox_context_id", "registration", "state", "receipt_ref", "signature_ref")
              reply = events.find { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "reconcile_inbox" &&
                events.index(event) > events.index(reconciliation) &&
                (!(selected == reconciliation && mutation_id) || event.dig("payload", "mutation_id") == mutation_id) &&
                event.dig("payload", "data")&.slice(*projection.keys) == projection }
              raise AttemptErrors::EvidenceUnavailable, "historical inbox owner reply missing" unless reply
              unless selected || reconciliation != reconciliations.last
                settled << {"inbox_context_id" => context_id, "event_id" => payload.fetch("event_id"),
                  "claim_generation" => proof.fetch("claim_generation"),
                  "reconciliation_event_digest" => reconciliation.fetch("digest"), "reply_event_digest" => reply.fetch("digest"),
                  "receipt_ref" => proof.fetch("receipt_ref"), "signature_ref" => proof.fetch("signature_ref")}
              end
              if selected && reconciliation == selected
                result = {"commit" => commit, "reconciliation" => reconciliation, "reply" => reply}
              end
            end
          end
          unknown = events.select { |event| event["type"] == "inbox_reconciliation" }.map { |event| event.dig("payload", "event_id") } - identities
          raise AttemptErrors::EvidenceUnavailable, "historical inbox proof lacks registration" unless selected || unknown.empty?
          unless selected || settled.empty?
            @journal.event_commits!(assignment_id: params.fetch("assignment_id"), commit: commit,
              event_digests: settled.flat_map { |row| row.values_at("reconciliation_event_digest", "reply_event_digest") })
          end
          selected ? immutable(result) : immutable({"commit" => commit, "inboxes" => settled.sort_by { |row| row.values_at("inbox_context_id", "event_id") }})
        rescue KeyError, TypeError, ArgumentError, NoMethodError, JSON::ParserError, OpenSSL::PKey::PKeyError
          raise AttemptErrors::EvidenceUnavailable, "historical inbox evidence is unverifiable"
        end
        def immutable(value)
          case value
          when Hash then value.each_with_object({}) { |(key, item), result| result[key.dup.freeze] = immutable(item) }.freeze
          when Array then value.map { |item| immutable(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end
      end
    end
  end
end
