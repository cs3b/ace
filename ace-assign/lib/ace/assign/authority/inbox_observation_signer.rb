# frozen_string_literal: true

require "json"
require "digest"
require "ace/herdr/molecules/inbox_context_client"
require_relative "inbox_signing_key"
require_relative "../molecules/canonical_evidence"
require_relative "../atoms/evidence_digest"
require_relative "native_observation"

module Ace
  module Assign
    module Authority
      # A signer consumes authority-issued evidence only. No caller supplies
      # receipt bytes, outcome, observer identity, key or native endpoint.
      class InboxObservationSigner
        REGISTRATION = %w[event_id attempt_id payload_sha256 receipt_key_sha256].freeze

        def initialize(client:, deployment:, kernel:, context_client_factory: nil, signing_key_factory: nil)
          @client, @deployment, @kernel = client, deployment, kernel
          @context_client_factory = context_client_factory || ->(context_id, fixed) {
            Ace::Herdr::Molecules::InboxContextClient.selected(context_id: context_id,
              socket_path: fixed.fetch("control_socket_path"), owner_credentials: fixed.fetch("owner_credentials"), kernel: kernel)
          }
          @signing_key_factory = signing_key_factory || ->(uid) { InboxSigningKey.new(signer_uid: uid) }
        end

        def settle(assignment_id:, attempt_id:, event_id:, inbox_context_id:, evidence_id:, mutation_id:, expected_generation:)
          ids = [assignment_id, attempt_id, event_id, inbox_context_id, evidence_id, mutation_id]
          unless ids.all? { |id| id.is_a?(String) && Molecules::CanonicalEvidence::ID.match?(id) } &&
              expected_generation.is_a?(Integer) && expected_generation >= 0
            unavailable!("signer selectors differ")
          end
          map = @deployment.mapping(@client.mapping_id)
          project = @deployment.project(map.fetch("project_id"))
          fixed = project.fetch("inbox_contexts").fetch(inbox_context_id)
          caller = @kernel.capture(Process.pid)
          uid = caller.fetch("uid")
          authority = @deployment.authority(map.fetch("authority_id"))
          excluded = fixed.fetch("observer_uids") + [fixed.dig("owner_credentials", "uid"),
            map.fetch("worker_uid"), map.fetch("launcher_uid"), authority.fetch("uid")]
          unless uid.positive? && fixed.fetch("signer_uids").include?(uid) &&
              project.fetch("signer_uids").include?(uid) && !excluded.include?(uid) &&
              fixed.fetch("native_mapping_id") == @client.mapping_id
            unavailable!("caller is not the distinct installed signer")
          end
          context = @context_client_factory.call(inbox_context_id, fixed)
          grant = context.request("begin_context_operation", {"context_id" => inbox_context_id,
            "purpose" => "observe_to_sign", "event_id" => event_id, "process_binding" => caller})
          unless grant.is_a?(Hash) && grant.keys.sort == %w[fingerprint key_generation operation_id state] &&
              grant["state"] == "admitted" && grant["operation_id"].is_a?(String) &&
              grant["operation_id"].match?(/\A[0-9a-f]{32}\z/) && grant["key_generation"].is_a?(Integer) &&
              grant["key_generation"].positive? && grant["fingerprint"].is_a?(String) && grant["fingerprint"].match?(/\A[0-9a-f]{64}\z/)
            unavailable!("signing admission is unavailable")
          end
          begin
            selection = {"operation_id" => grant.fetch("operation_id"),
              "key_generation" => grant.fetch("key_generation"), "event_id" => event_id}
            snapshot = snapshot!(context, selection, inbox_context_id)
            registration = snapshot.slice(*REGISTRATION)
            unless registration.keys.sort == REGISTRATION.sort &&
                registration.values_at("event_id", "attempt_id", "receipt_key_sha256") == [event_id, attempt_id, grant.fetch("fingerprint")]
              unavailable!("current registration differs")
            end
            params = {"assignment_id" => assignment_id, "attempt_id" => attempt_id,
              "event_id" => event_id, "inbox_context_id" => inbox_context_id, "evidence_id" => evidence_id}
            fetched = @client.call("fetch_observation", params, download: true, purpose: :artifacts)
            bytes, observation, binding = verify_evidence!(fetched, params, map, fixed, snapshot)
            result = @signing_key_factory.call(uid).with(reference: fixed.fetch("receipt_private_key"), fingerprint: grant.fetch("fingerprint")) do |key, artifacts|
              @kernel.live!(caller)
              current = snapshot!(context, selection, inbox_context_id)
              unavailable!("event changed before signing") unless current == snapshot
              # Revalidate native semantics at the final snapshot, under the
              # retained shared admission which excludes key rotation.
              NativeObservation.decode!(bytes, snapshot: current, runtime: binding.fetch("runtime_binding"))
              artifacts.verify_unchanged!
              receipt = observation.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
                "outcome" => "consumed", "observer" => {"role" => "supervisor", "id" => "uid:#{binding.fetch('observer_uid')}"},
                "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => JSON.generate(observation.fetch("native_reference")),
                  "observation" => "completed native turn; authority evidence #{evidence_id}"})
              signed_bytes = JSON.generate(receipt)
              signature = key.sign(OpenSSL::Digest::SHA256.new, signed_bytes)
              artifacts.verify_unchanged!
              @client.call("reconcile_inbox", params.reject { |field, _| field == "evidence_id" }.merge(
                "expected_generation" => expected_generation, "expected_registration" => registration,
                "receipt_sha256" => Digest::SHA256.hexdigest(signed_bytes), "signature_sha256" => Digest::SHA256.hexdigest(signature)),
                mutation_id: mutation_id, upload_parts: [signed_bytes, signature], purpose: :inbox_proof).data
            end
            result
          ensure
            ended = context.request("end_context_operation", {"operation_id" => grant.fetch("operation_id")})
            unavailable!("signing admission end is unconfirmed") unless ended == {"operation_id" => grant.fetch("operation_id"), "state" => "ended"}
          end
        rescue KeyError, TypeError
          unavailable!("installed signing selection is incomplete")
        end

        private

        def snapshot!(context, selection, context_id)
          response = context.request("snapshot_context", selection)
          unless response.is_a?(Hash) && response.keys.sort == %w[context_id key_generation operation_id record] &&
              response.values_at("context_id", "key_generation", "operation_id") ==
                [context_id, selection.fetch("key_generation"), selection.fetch("operation_id")] && response["record"].is_a?(Hash)
            unavailable!("authenticated context snapshot differs")
          end
          response.fetch("record")
        end

        def verify_evidence!(reply, params, map, fixed, snapshot)
          data, parts = reply.data, reply.parts
          unless data.is_a?(Hash) && data["eligible"] == true && parts.is_a?(Array) && parts.size == 1 && parts.first.is_a?(String)
            unavailable!("canonical observation is not eligible")
          end
          descriptor, binding, bytes = data["descriptor"], data["binding"], parts.first
          expected = params.slice("assignment_id", "attempt_id").merge("project_id" => map.fetch("project_id"),
            "artifact_id" => params.fetch("evidence_id"), "request_id_or_event_id" => params.fetch("event_id"),
            "kind" => "observation", "role" => "observer")
          unless Molecules::CanonicalEvidence.valid_descriptor?(descriptor) && binding.is_a?(Hash) &&
              expected.all? { |field, value| descriptor[field] == value } &&
              descriptor["sha256"] == Digest::SHA256.hexdigest(bytes) && descriptor["bytes"] == bytes.bytesize &&
              descriptor["binding_digest"] == Atoms::EvidenceDigest.digest(binding) &&
              data["journal_commit"].is_a?(String) && data["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
              data["generation"].is_a?(Integer) && data["generation"] >= 0 &&
              data["current_claim_generation"] == snapshot["claim_generation"] &&
              descriptor["candidate_generation_or_claim_generation"] == snapshot["claim_generation"]
            unavailable!("canonical observation descriptor differs")
          end
          fields = %w[project_id mapping_id assignment_id attempt_id event_id inbox_context_id registration claim_generation
            native_binding codex_submission codex_receipt runtime_id runtime_binding native_event_digest observer_uid]
          scope = params.reject { |field, _| field == "evidence_id" }.merge("project_id" => map.fetch("project_id"), "mapping_id" => @client.mapping_id)
          unless binding.keys.sort == fields.sort && scope.all? { |field, value| binding[field] == value } &&
              binding["native_event_digest"].is_a?(String) && binding["native_event_digest"].match?(/\A[0-9a-f]{64}\z/)
            unavailable!("observation canonical scope differs")
          end
          runtime = fixed.fetch("runtime_bindings").fetch(binding.fetch("runtime_id"))
          uid = binding.fetch("observer_uid")
          unless binding.fetch("runtime_binding") == runtime && uid == runtime.fetch("observer_uid") &&
              fixed.fetch("observer_uids").include?(uid) && descriptor.fetch("peer_uid") == uid &&
              runtime.values_at("assignment_id", "attempt_id") == params.values_at("assignment_id", "attempt_id") &&
              binding.fetch("registration") == snapshot.slice(*REGISTRATION) &&
              binding.fetch("claim_generation") == snapshot.fetch("claim_generation") &&
              binding.fetch("native_binding") == snapshot.fetch("binding") &&
              %w[codex_submission codex_receipt].all? { |field| binding[field] == snapshot[field] }
            unavailable!("observation provenance or current binding differs")
          end
          observation = NativeObservation.decode!(bytes, snapshot: snapshot, runtime: runtime)
          unavailable!("unsupported signer observation outcome") unless observation["outcome"] == "consumed"
          [bytes, observation, binding]
        end

        def unavailable!(message)
          raise AttemptErrors::EvidenceUnavailable, message
        end
      end
    end
  end
end
