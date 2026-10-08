# frozen_string_literal: true

module Ace
  module Herdr
    module Organisms
      # A native read is a candidate observation, never a signature or an inbox
      # transition. The retained claim selects every query input; callers cannot
      # substitute a thread, correlation ID, native endpoint or claimed outcome.
      module InboxNativeObservation
        # Only the authenticated context owner publishes this projection. The
        # canonical evidence issuer must compare native IDs with the original
        # persisted submission, never with an observer's asserted association.
        def retained_observation_status(event:, deadline: nil)
          validate_id!(event, "event")
          with_event(event, create_lock: false, deadline: deadline) do |record|
            raise ValidationError, "unknown inbox event: #{event}" unless record&.inbox
            public_record(record).merge("codex_submission" => record.inbox["codex_submission"],
              "codex_receipt" => record.inbox.dig("receipt", "codex_submission"))
          end
        rescue SystemCallError, Molecules::DeliveryRecordStore::LockUnavailable
          raise ValidationError, "retained inbox correlation is unavailable"
        end

        def observe_consumption(event:, expected_attempt:, expected_claim_generation:, deadline:)
          validate_id!(event, "event")
          validate_id!(expected_attempt, "attempt")
          unless expected_claim_generation.is_a?(Integer) && expected_claim_generation.positive? &&
              deadline.is_a?(Numeric) && deadline.finite? && deadline > Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise ValidationError, "native observation selection or deadline differs"
          end
          snapshot = with_event(event, create_lock: false, deadline: deadline) do |record|
            observation_claim!(record, expected_attempt, expected_claim_generation)
            JSON.parse(JSON.generate(record.to_h))
          end
          record = Models::DeliveryRecord.from_h(snapshot)
          result = if record.inbox.dig("binding", "agent") == "codex" && record.inbox["submission_intent"] &&
              %w[claimed uncertain delivered].include?(record.state) && record.inbox["codex_submission"].is_a?(Hash)
            intent = record.inbox.fetch("codex_submission")
            unless intent.values_at("event_id", "attempt_id", "claim_generation", "payload_sha256", "thread_id") ==
                [event, expected_attempt, expected_claim_generation, record.answer_digest, record.inbox.dig("binding", "thread")]
              raise ValidationError, "retained native submission association differs"
            end
            @native.observe(agent: "codex", thread: record.inbox.fetch("binding").fetch("thread"),
              event_id: event, digest: record.answer_digest, submission: intent,
              receipt: record.inbox.dig("receipt", "codex_submission"), deadline: deadline)
          else
            {"outcome" => "uncertain", "error" => "correlated native observation is unavailable"}
          end
          with_event(event, create_lock: false, deadline: deadline) do |current|
            observation_claim!(current, expected_attempt, expected_claim_generation)
            unless current.to_h == snapshot && deadline > Process.clock_gettime(Process::CLOCK_MONOTONIC)
              raise ValidationError, "inbox claim changed during native observation"
            end
            observation = sanitized_native_observation!(result, record)
            {"event_id" => event, "attempt_id" => expected_attempt, "claim_generation" => expected_claim_generation,
              "payload_sha256" => record.answer_digest, "binding" => record.inbox["binding"], "observation" => observation}
          end
        rescue ExecutorError, SystemCallError, Molecules::DeliveryRecordStore::LockUnavailable
          raise ValidationError, "native observation is unavailable"
        end

        private

        def observation_claim!(record, attempt, generation)
          unless record&.inbox && record.inbox.values_at("attempt_id", "claim_generation") == [attempt, generation] &&
              record.inbox.fetch("receipt_key_sha256") == key_fingerprint
            raise ValidationError, "native observation current claim differs"
          end
        end

        def sanitized_native_observation!(result, record)
          unless result.is_a?(Hash) && %w[consumed uncertain].include?(result["outcome"])
            raise ValidationError, "native observation result differs"
          end
          return {"outcome" => "uncertain"} if result.fetch("outcome") == "uncertain"
          intent = record.inbox.fetch("codex_submission")
          reference = result["native_reference"]
          fields = %w[client_user_message_id item_id payload_sha256 provider queued_submission_id thread_id turn_id version]
          unless result.keys.sort == %w[endpoint_reference_sha256 native_reference outcome server_process_binding] &&
              reference.is_a?(Hash) && reference.keys.sort == fields && reference["provider"] == "codex" &&
              reference.values_at("thread_id", "client_user_message_id", "payload_sha256", "version") ==
                intent.values_at("thread_id", "client_user_message_id", "payload_sha256", "provider_version") &&
              reference["turn_id"].is_a?(String) && Inbox::THREAD_ID.match?(reference["turn_id"]) &&
              reference["item_id"].is_a?(String) && reference["item_id"].encoding == Encoding::UTF_8 &&
              reference["item_id"].valid_encoding? && reference["item_id"].bytesize.between?(1, 256) &&
              !reference["item_id"].include?("\0") &&
              result.values_at("endpoint_reference_sha256", "server_process_binding") ==
                intent.values_at("endpoint_reference_sha256", "server_process_binding") &&
              reference["queued_submission_id"] == record.inbox.dig("receipt", "codex_submission", "queued_submission_id")
            raise ValidationError, "native observation correlation differs"
          end
          JSON.parse(JSON.generate(result))
        end
      end
    end
  end
end
