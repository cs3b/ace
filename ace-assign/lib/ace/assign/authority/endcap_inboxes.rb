# frozen_string_literal: true

require "ace/herdr/organisms/protected_inbox"
require_relative "../molecules/execution_scope_lineage"

module Ace
  module Assign
    module Authority
      class Endcap
        INBOX_REGISTRATION_FIELDS = %w[event_id attempt_id payload_sha256 receipt_key_sha256].freeze
        INBOX_PAYLOAD_FIELDS = %w[version event_id attempt_id inbox_context_id registration state
          claim_generation binding receipt_ref signature_ref].freeze
        INBOX_BINDING_FIELDS = %w[project_id assignment_id attempt_id mapping_id inbox_context_id event_id
          registration claim_generation native_binding scope_binding_event_id native_binding_event_id
          scope_native_binding receipt_key_sha256 receipt_sha256 signature_sha256 submitter_uid submitter_role].freeze
        INBOX_REF_FIELDS = %w[artifact_id ref sha256 bytes].freeze

        private

        def inbox_request(request)
          params = request.fetch("params")
          unless params.is_a?(Hash) && params.keys.sort == PARAMETERS.fetch("reconcile_inbox").sort
            raise ArgumentError, "invalid inbox parameters"
          end
          %w[mapping_id assignment_id attempt_id event_id inbox_context_id].each { |key| result_id!(params[key]) }
          result_id!(request.fetch("mutation_id"))
          registration = params.fetch("expected_registration")
          unless inbox_registration?(registration) && registration.values_at("event_id", "attempt_id") ==
              params.values_at("event_id", "attempt_id") &&
              params["expected_generation"].is_a?(Integer) && params["expected_generation"] >= 0 &&
              %w[receipt_sha256 signature_sha256].all? { |key| params[key].is_a?(String) && DIGEST.match?(params[key]) }
            raise ArgumentError, "invalid inbox registration or digest"
          end
          map = @deployment.mapping(params.fetch("mapping_id"))
          raise AttemptErrors::UnauthorizedIdentity, "project mapping differs" unless map.fetch("project_id") == request.fetch("project_id")
          [params, map]
        end

        def inbox_registration?(value)
          value.is_a?(Hash) && value.keys.sort == INBOX_REGISTRATION_FIELDS.sort &&
            %w[event_id attempt_id].all? { |key| value[key].is_a?(String) && Molecules::JournalMutation::ID.match?(value[key]) } &&
            %w[payload_sha256 receipt_key_sha256].all? { |key| value[key].is_a?(String) && DIGEST.match?(value[key]) }
        end

        def inbox_selection(events, params, map, peer, role)
          origin = retained_origin(events, params)
          context = @deployment.inbox_context(params.fetch("mapping_id"), params.fetch("inbox_context_id"))
          @deployment.verify_inbox_context!(params.fetch("mapping_id"), params.fetch("inbox_context_id"))
          @kernel.live!(peer)
          service_policy!.visible!(project: map.fetch("project_id"), uid: peer.fetch("uid"))
          allowed = (role == :supervisor && context.fetch("supervisor_uids").include?(peer["uid"])) ||
            (role == :launcher && peer["uid"] == map.fetch("launcher_uid") && @kernel.same?(peer, origin.fetch("launcher_identity")))
          raise AttemptErrors::UnauthorizedIdentity, "inbox requires exact launcher or mapped supervisor" unless allowed
          bindings = events.select { |event| event["type"] == "inbox_binding" && event.dig("payload", "event_id") == params["event_id"] }
          raise AttemptErrors::NotFound, "inbox registration missing" if bindings.empty?
          registered = bindings.one? && bindings.first.fetch("payload")
          unless registered.is_a?(Hash) && registered.keys.sort == %w[event_id attempt_id inbox_context_id registration].sort &&
              registered.values_at("event_id", "attempt_id", "inbox_context_id") == params.values_at("event_id", "attempt_id", "inbox_context_id") &&
              inbox_registration?(registered["registration"])
            raise AttemptErrors::EvidenceUnavailable, "canonical inbox context or registration differs"
          end
          if params.key?("expected_registration") && registered.fetch("registration") != params.fetch("expected_registration")
            raise AttemptErrors::Conflict, "expected inbox registration differs"
          end
          lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
            assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
            mapping_id: context.fetch("native_mapping_id"))
          raise AttemptErrors::EvidenceUnavailable, "canonical original native stage missing" unless lineage.native_event
          native_map = @deployment.mapping(context.fetch("native_mapping_id"))
          box = Ace::Herdr::Organisms::ProtectedInbox.build(context: context, mapping: native_map,
            native: lineage.native_event.fetch("payload"), kernel: @kernel)
          current = box.retained_status(event: params.fetch("event_id"))
          unless current.slice(*INBOX_REGISTRATION_FIELDS) == registered.fetch("registration")
            raise AttemptErrors::EvidenceUnavailable, "current inbox differs from canonical registration"
          end
          [box, registered.fetch("registration"), lineage]
        rescue Ace::Herdr::Error, Ace::Runtime::RuntimeUnavailableError, KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "installed inbox or native lineage is unverifiable"
        end

        def authorize_inbox_transfer!(request:, peer:, role:)
          params, map = inbox_request(request)
          @launch.with_assignment(params: params, map: map) do |journal, _|
            protected_journal!(journal)
            inbox_selection(attempt_events(journal, params), params, map, peer, role)
          end
          true
        end

        def dispatch_inbox(request:, peer:, role:, transfer:)
          params, map = inbox_request(request)
          authorize_inbox_transfer!(request: request, peer: peer, role: role)
          unless transfer && transfer.count == 2
            raise ArgumentError, "inbox requires receipt and signature"
          end
          bytes, signature = [transfer.bytes(index: 0), transfer.bytes(index: 1)]
          unless [bytes, signature].all? { |part| part.is_a?(String) && part.bytesize.between?(1, 16 * 1024) } &&
              Digest::SHA256.hexdigest(bytes) == params.fetch("receipt_sha256") &&
              Digest::SHA256.hexdigest(signature) == params.fetch("signature_sha256")
            raise ArgumentError, "inbox proof bytes differ"
          end
          receipt = JSON.parse(bytes.dup.force_encoding(Encoding::UTF_8))
          @launch.with_assignment(params: params, map: map) do |journal, _|
            protected_journal!(journal)
            commit = journal.ref_value
            events = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
            box, registration, lineage = inbox_selection(events, params, map, peer, role)
            replay = journal.mutation_result(request.fetch("mutation_id"))
            if replay && replay["operation"] == "reconcile_inbox"
              retained = verified_inbox(journal, events, params, map, peer, role, commit)
              unless retained && inbox_projection(retained) == replay.fetch("data").slice(*inbox_projection(retained).keys)
                raise AttemptErrors::EvidenceUnavailable, "retained inbox reply differs"
              end
            end
            result = journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: "reconcile_inbox", parameters_digest: Atoms::EvidenceDigest.digest(params),
              expected_generation: params.fetch("expected_generation"), with_replay: true) do |fresh, fresh_commit, _generation|
              box, registration, lineage = inbox_selection(fresh, params, map, peer, role)
              retained = verified_inbox(journal, fresh, params, map, peer, role, fresh_commit)
              if retained
                unless retained.dig("binding", "receipt_sha256") == params.fetch("receipt_sha256") &&
                    retained.dig("binding", "signature_sha256") == params.fetch("signature_sha256")
                  raise AttemptErrors::Conflict, "canonical inbox proof already differs"
                end
                next({data: inbox_projection(retained)})
              end
              accepted = box.reconcile(event: params.fetch("event_id"), receipt: receipt, signed_bytes: bytes,
                signature: signature, expected_registration: registration)
              raise AttemptErrors::EvidenceUnavailable, "signed inbox proof refused" if accepted["reconciliation_refusal"]
              binding = inbox_binding(params, map, peer, role, registration, lineage, accepted)
              plan = Molecules::CanonicalEvidence.new(journal: journal).import_plan(**inbox_context(binding),
                admitted_after_event_digest: fresh.last.fetch("digest"), artifacts: [bytes, signature])
              refs = plan.fetch(:references).each_with_index.map do |ref, index|
                ref.merge("artifact_id" => ref.fetch("ref").delete_prefix("evidence/imports/"), "bytes" => [bytes, signature][index].bytesize)
              end
              payload = {"version" => 1, "event_id" => params.fetch("event_id"), "attempt_id" => params.fetch("attempt_id"),
                "inbox_context_id" => params.fetch("inbox_context_id"), "registration" => registration,
                "state" => accepted.fetch("state"), "claim_generation" => accepted.fetch("claim_generation"),
                "binding" => binding, "receipt_ref" => refs[0], "signature_ref" => refs[1]}
              {data: inbox_projection(payload), blobs: plan.fetch(:blobs), events: plan.fetch(:events) +
                [{type: "inbox_reconciliation", payload: payload}]}
            end
            final_commit = journal.ref_value
            final_events = journal.read_events(params.fetch("assignment_id"), commit: final_commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
            retained = verified_inbox(journal, final_events, params, map, peer, role, final_commit)
            unless retained && inbox_projection(retained) == result.fetch(:data).slice(*inbox_projection(retained).keys)
              raise AttemptErrors::EvidenceUnavailable, "accepted inbox provenance differs"
            end
            result
          end
        rescue JSON::ParserError, EncodingError, Ace::Herdr::Error
          raise AttemptErrors::EvidenceUnavailable, "inbox proof is unverifiable"
        end

        def inbox_binding(params, map, peer, role, registration, lineage, accepted)
          {"project_id" => map.fetch("project_id"), "assignment_id" => params.fetch("assignment_id"),
            "attempt_id" => params.fetch("attempt_id"), "mapping_id" => params.fetch("mapping_id"),
            "inbox_context_id" => params.fetch("inbox_context_id"), "event_id" => params.fetch("event_id"),
            "registration" => registration, "claim_generation" => accepted.fetch("claim_generation"),
            "native_binding" => accepted.fetch("binding"), "scope_binding_event_id" => lineage.binding_event.fetch("digest"),
            "native_binding_event_id" => lineage.native_event.fetch("digest"), "scope_native_binding" => lineage.native_event.fetch("payload"),
            "receipt_key_sha256" => registration.fetch("receipt_key_sha256"), "receipt_sha256" => params.fetch("receipt_sha256"),
            "signature_sha256" => params.fetch("signature_sha256"), "submitter_uid" => peer.fetch("uid"), "submitter_role" => role.to_s}
        end

        def inbox_context(binding)
          {kind: "inbox", project_id: binding.fetch("project_id"), assignment_id: binding.fetch("assignment_id"),
            attempt_id: binding.fetch("attempt_id"), peer_uid: binding.fetch("submitter_uid"), binding: binding,
            request_id_or_event_id: binding.fetch("event_id"), generation: binding.fetch("claim_generation")}
        end

        def inbox_projection(payload)
          payload.slice("event_id", "attempt_id", "inbox_context_id", "registration", "state", "receipt_ref", "signature_ref")
        end

        def verified_inbox(journal, events, params, map, peer, role, commit)
          box, registration, lineage = inbox_selection(events, params, map, peer, role)
          records = events.select { |event| event["type"] == "inbox_reconciliation" && event.dig("payload", "event_id") == params.fetch("event_id") }
          replies = events.select { |event| event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "reconcile_inbox" && event.dig("payload", "data", "event_id") == params.fetch("event_id") }
          unless replies.all? { |reply| records.any? { |record| inbox_projection(record.fetch("payload")) ==
              reply.fetch("payload").fetch("data").slice(*inbox_projection(record.fetch("payload")).keys) } }
            raise AttemptErrors::EvidenceUnavailable, "canonical inbox private provenance missing"
          end
          observed = box.retained_status(event: params.fetch("event_id"))
          current_claim = observed.fetch("claim_generation")
          unless records.all? { |record| record.fetch("payload").keys.sort == INBOX_PAYLOAD_FIELDS.sort &&
              record.dig("payload", "claim_generation").is_a?(Integer) && record.dig("payload", "claim_generation").between?(0, current_claim) } &&
              records.map { |record| record.dig("payload", "claim_generation") }.uniq.length == records.length
            raise AttemptErrors::EvidenceUnavailable, "canonical inbox claim history differs"
          end
          current = records.find { |record| record.dig("payload", "claim_generation") == current_claim }
          return nil unless current
          payload = current.fetch("payload")
          binding = payload.fetch("binding")
          unless payload.keys.sort == INBOX_PAYLOAD_FIELDS.sort && payload["version"] == 1 && binding.keys.sort == INBOX_BINDING_FIELDS.sort &&
              %w[receipt_sha256 signature_sha256].all? { |key| binding[key].is_a?(String) && DIGEST.match?(binding[key]) } &&
              binding["submitter_uid"].is_a?(Integer) && binding["submitter_uid"] > 0 && %w[launcher supervisor].include?(binding["submitter_role"]) &&
              payload.values_at("event_id", "attempt_id", "inbox_context_id") == params.values_at("event_id", "attempt_id", "inbox_context_id") &&
              payload["registration"] == registration && payload["claim_generation"] == binding["claim_generation"]
            raise AttemptErrors::EvidenceUnavailable, "canonical inbox fields differ"
          end
          retained_peer = {"uid" => binding.fetch("submitter_uid")}
          expected = inbox_binding(params.merge("receipt_sha256" => binding.fetch("receipt_sha256"),
            "signature_sha256" => binding.fetch("signature_sha256")), map, retained_peer, binding.fetch("submitter_role").to_sym,
            registration, lineage, observed)
          raise AttemptErrors::EvidenceUnavailable, "canonical inbox native/key context differs" unless binding == expected
          canonical = Molecules::CanonicalEvidence.new(journal: journal)
          raw = %w[receipt_ref signature_ref].map do |key|
            ref = payload.fetch(key)
            unless ref.is_a?(Hash) && ref.keys.sort == INBOX_REF_FIELDS.sort &&
                ref["ref"] == "evidence/imports/#{ref['artifact_id']}" && ref["bytes"].is_a?(Integer) && ref["bytes"].between?(1, 16 * 1024)
              raise AttemptErrors::EvidenceUnavailable, "canonical inbox reference differs"
            end
            bytes = canonical.read(ref.slice("ref", "sha256"), **inbox_context(binding), commit: commit)
            raise AttemptErrors::EvidenceUnavailable, "canonical inbox byte count differs" unless bytes.bytesize == ref["bytes"]
            bytes
          end
          unless raw.map { |bytes| Digest::SHA256.hexdigest(bytes) } == binding.values_at("receipt_sha256", "signature_sha256")
            raise AttemptErrors::EvidenceUnavailable, "canonical inbox raw digests differ"
          end
          receipt = JSON.parse(raw.first)
          verified = box.verify_reconciliation(event: params.fetch("event_id"), receipt: receipt,
            signed_bytes: raw.first, signature: raw.last, expected_registration: registration)
          if verified["reconciliation_refusal"] || verified["state"] != payload["state"]
            raise AttemptErrors::EvidenceUnavailable, "canonical inbox signature or settlement differs"
          end
          unless events.any? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "reconcile_inbox" &&
              event.fetch("payload").fetch("data").slice(*inbox_projection(payload).keys) == inbox_projection(payload) }
            raise AttemptErrors::EvidenceUnavailable, "canonical inbox owner reply missing"
          end
          payload
        rescue KeyError, TypeError, ArgumentError, JSON::ParserError, Ace::Herdr::Error
          raise AttemptErrors::EvidenceUnavailable, "canonical inbox evidence is unverifiable"
        end
      end
    end
  end
end
