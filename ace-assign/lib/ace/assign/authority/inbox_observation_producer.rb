# frozen_string_literal: true

require "json"
require "digest"
require "ace/herdr/molecules/inbox_context_client"
require_relative "native_observation"
require_relative "observation_trust"

module Ace
  module Assign
    module Authority
      # Reads the installed context, then imports through the existing journal
      # owner. A query candidate alone never becomes a reconciliation proof.
      class InboxObservationProducer
        def initialize(client:, deployment:, kernel:, context_client_factory: Ace::Herdr::Molecules::InboxContextClient.method(:selected))
          @client, @deployment, @kernel, @context_client_factory = client, deployment, kernel, context_client_factory
        end

        def observe(assignment_id:, attempt_id:, event_id:, inbox_context_id:, claim_generation:, mutation_id:, expected_generation:)
          unless [assignment_id, attempt_id, event_id, inbox_context_id, mutation_id].all? { |id| id.is_a?(String) && Deployment::TOKEN.match?(id) } &&
              claim_generation.is_a?(Integer) && claim_generation.positive? && expected_generation.is_a?(Integer) && expected_generation >= 0
            raise ArgumentError, "observation requires original IDs and exact generations"
          end
          map = @deployment.mapping(@client.mapping_id)
          context = @deployment.inbox_context(@client.mapping_id, inbox_context_id)
          peer = @kernel.capture(Process.pid)
          @kernel.live!(peer)
          unless context.fetch("observer_uids", []).include?(peer.fetch("uid"))
            raise AttemptErrors::UnauthorizedIdentity, "native observation requires the configured observer"
          end
          client = @context_client_factory.call(context_id: inbox_context_id,
            socket_path: context.fetch("control_socket_path"), owner_credentials: context.fetch("owner_credentials"), kernel: @kernel)
          original = {"project_id" => map.fetch("project_id"), "mapping_id" => @client.mapping_id,
            "assignment_id" => assignment_id, "inbox_context_id" => inbox_context_id}
          status = client.request("status_context", {"event_id" => event_id, "attempt_id" => attempt_id, "original" => original}).fetch("record")
          unless status.values_at("event_id", "attempt_id", "claim_generation") == [event_id, attempt_id, claim_generation]
            raise AttemptErrors::EvidenceUnavailable, "observation original claim differs"
          end
          operation = client.request("begin_context_operation", {"context_id" => inbox_context_id,
            "purpose" => "observe_to_sign", "event_id" => event_id, "process_binding" => peer})
          verify_admission!(operation, status)
          params = operation.slice("operation_id", "key_generation").merge("event_id" => event_id)
          before = snapshot!(client, params, inbox_context_id)
          result = client.request("observe_context", params.merge("attempt_id" => attempt_id, "claim_generation" => claim_generation))
          unless result.is_a?(Hash) && result.keys.sort == %w[attempt_id binding claim_generation context_id event_id key_generation observation operation_id payload_sha256] &&
              result.slice(*params.keys) == params && result["context_id"] == inbox_context_id &&
              result.values_at("attempt_id", "claim_generation", "payload_sha256", "binding") ==
                before.values_at("attempt_id", "claim_generation", "payload_sha256", "binding")
            raise AttemptErrors::EvidenceUnavailable, "native observation candidate association differs"
          end
          after = snapshot!(client, params, inbox_context_id)
          raise AttemptErrors::EvidenceUnavailable, "native observation record changed" unless before == after
          observation = result.fetch("observation")
          if observation == {"outcome" => "uncertain"}
            end_operation!(client, operation)
            return {"event_id" => event_id, "attempt_id" => attempt_id, "claim_generation" => claim_generation, "outcome" => "uncertain"}
          end
          runtimes = context.fetch("runtime_bindings").select { |_id, row|
            row.values_at("assignment_id", "attempt_id", "native_target", "observer_uid") ==
              [assignment_id, attempt_id, before.fetch("binding").slice(*ObservationTrust::TARGET), peer.fetch("uid")] }
          raise AttemptErrors::EvidenceUnavailable, "native observation runtime is ambiguous or unavailable" unless runtimes.one?
          runtime_id, runtime = runtimes.first
          bytes = artifact(result)
          NativeObservation.decode!(bytes, snapshot: before, runtime: runtime)
          registration = before.slice("event_id", "attempt_id", "payload_sha256", "receipt_key_sha256")
          reply = @client.call("import_observation", {"assignment_id" => assignment_id, "attempt_id" => attempt_id,
            "event_id" => event_id, "inbox_context_id" => inbox_context_id, "expected_registration" => registration,
            "expected_generation" => expected_generation, "observation_sha256" => Digest::SHA256.hexdigest(bytes)},
            mutation_id: mutation_id, upload_parts: [bytes], purpose: :observation, timeout: 30)
          data = reply.data
          verify_import!(data, bytes, registration, map, before, peer.fetch("uid"), inbox_context_id, assignment_id, runtime_id, runtime, expected_generation)
          raise AttemptErrors::EvidenceUnavailable, "native observation record changed after import" unless snapshot!(client, params, inbox_context_id) == before
          end_operation!(client, operation)
          data.slice("evidence_id", "event_id", "claim_generation", "outcome", "reference")
        rescue KeyError, TypeError, Ace::Herdr::Error
          raise AttemptErrors::EvidenceUnavailable, "native observation is unconfirmed; retain original mutation and admission"
        end

        private

        def artifact(result)
          observation = result.fetch("observation")
          reference = observation.fetch("native_reference")
          excerpt = {"status" => "completed", "native_reference" => reference}
          source = JSON.generate(excerpt)
          JSON.generate({"schema" => "ace.native-observation.v1", "provider" => reference.fetch("provider"),
            "provider_version" => reference.fetch("version"),
            **result.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding"),
            "runtime_process_binding" => observation.fetch("server_process_binding"), "outcome" => observation.fetch("outcome"),
            "native_reference" => reference, "source_sha256" => Digest::SHA256.hexdigest(source),
            "source_bytes" => source.bytesize, "source_excerpt" => excerpt})
        end

        def verify_admission!(operation, status)
          unless operation.is_a?(Hash) && operation.keys.sort == %w[fingerprint key_generation operation_id state] &&
              operation["state"] == "admitted" && operation["operation_id"].is_a?(String) && operation["operation_id"].match?(/\A[0-9a-f]{32}\z/) &&
              operation["key_generation"].is_a?(Integer) && operation["key_generation"].positive? &&
              operation["fingerprint"] == status.fetch("receipt_key_sha256")
            raise AttemptErrors::EvidenceUnavailable, "native observation admission differs"
          end
        end

        def snapshot!(client, params, context_id)
          response = client.request("snapshot_context", params)
          unless response.is_a?(Hash) && response.keys.sort == %w[context_id key_generation operation_id record] &&
              response.slice(*params.except("event_id").keys) == params.except("event_id") && response["context_id"] == context_id &&
              response["record"].is_a?(Hash) && response.dig("record", "event_id") == params.fetch("event_id")
            raise AttemptErrors::EvidenceUnavailable, "native observation snapshot differs"
          end
          response.fetch("record")
        end

        def end_operation!(client, operation)
          ended = client.request("end_context_operation", operation.slice("operation_id"))
          unless ended == {"operation_id" => operation.fetch("operation_id"), "state" => "ended"}
            raise AttemptErrors::EvidenceUnavailable, "native observation admission end is unconfirmed"
          end
        end

        def verify_import!(data, bytes, registration, map, snapshot, uid, context_id, assignment_id, runtime_id, runtime, generation)
          unless data.is_a?(Hash) && data.keys.sort == %w[binding claim_generation event_id evidence_id generation journal_commit outcome reference] &&
              data["evidence_id"].is_a?(String) && data["evidence_id"].match?(/\A[0-9a-f]{32}\z/) &&
              data["generation"] == generation + 1 && data["journal_commit"].is_a?(String) && data["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
              data.values_at("event_id", "claim_generation", "outcome") == [snapshot.fetch("event_id"), snapshot.fetch("claim_generation"), "consumed"] &&
              data["reference"] == {"ref" => "evidence/imports/#{data['evidence_id']}", "sha256" => Digest::SHA256.hexdigest(bytes)} &&
              data["binding"].is_a?(Hash) && data.fetch("binding").slice("project_id", "mapping_id", "assignment_id", "attempt_id", "event_id",
                "inbox_context_id", "registration", "claim_generation", "native_binding", "codex_submission", "codex_receipt", "observer_uid", "runtime_id", "runtime_binding") ==
                {"project_id" => map.fetch("project_id"), "mapping_id" => @client.mapping_id, "assignment_id" => assignment_id,
                  "attempt_id" => snapshot.fetch("attempt_id"), "event_id" => snapshot.fetch("event_id"), "inbox_context_id" => context_id,
                  "registration" => registration, "claim_generation" => snapshot.fetch("claim_generation"), "native_binding" => snapshot.fetch("binding"),
                  "codex_submission" => snapshot.fetch("codex_submission"), "codex_receipt" => snapshot["codex_receipt"], "observer_uid" => uid,
                  "runtime_id" => runtime_id, "runtime_binding" => runtime}
            raise AttemptErrors::EvidenceUnavailable, "native observation canonical import differs"
          end
        end
      end
    end
  end
end
