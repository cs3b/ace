# frozen_string_literal: true
require "json"
require "digest"
require_relative "observation_trust"

module Ace
  module Assign
    module Authority
      # The source schema is shared by the issuer and independent signer reader.
      # Neither caller JSON nor its digest replaces retained owner correlation.
      module NativeObservation
        FIELDS = %w[schema provider provider_version event_id attempt_id claim_generation payload_sha256 binding runtime_process_binding outcome native_reference source_sha256 source_bytes source_excerpt].freeze
        REFERENCE = %w[provider version thread_id queued_submission_id client_user_message_id turn_id item_id payload_sha256].freeze
        INTENT = %w[schema provider_version endpoint_reference_sha256 server_process_binding thread_id event_id attempt_id claim_generation payload_sha256 client_user_message_id].freeze
        module_function

        def decode!(bytes, snapshot:, runtime:)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, 65_536)
            raise AttemptErrors::EvidenceUnavailable, "observation bytes exceed bounds"
          end
          value = JSON.parse(bytes.dup.force_encoding(Encoding::UTF_8), max_nesting: 16)
          intent, receipt = snapshot.values_at("codex_submission", "codex_receipt")
          unless value.is_a?(Hash) && value.keys.sort == FIELDS.sort && JSON.generate(value).b == bytes.b &&
              value.values_at("schema", "provider", "provider_version", "outcome") == ["ace.native-observation.v1", "codex", "0.159.3", "consumed"] &&
              value.values_at("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding") ==
                snapshot.values_at("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding") &&
              value["claim_generation"].is_a?(Integer) && value["claim_generation"].positive? &&
              intent.is_a?(Hash) && intent.keys.sort == INTENT.sort &&
              intent["schema"] == "ace.herdr.codex-submission/v1" &&
              intent.values_at("provider_version", "endpoint_reference_sha256", "server_process_binding", "thread_id") ==
                [runtime.fetch("provider_version"), runtime.fetch("endpoint_reference_sha256"), runtime.fetch("runtime_process_binding"), runtime.dig("native_target", "thread")] &&
              intent.values_at("event_id", "attempt_id", "claim_generation", "payload_sha256") ==
                snapshot.values_at("event_id", "attempt_id", "claim_generation", "payload_sha256") &&
              value["runtime_process_binding"] == runtime.fetch("runtime_process_binding") &&
              snapshot.fetch("binding").slice(*ObservationTrust::TARGET) == runtime.fetch("native_target")
            raise AttemptErrors::EvidenceUnavailable, "observation current private correlation differs"
          end
          if receipt
            expected = intent.slice("provider_version", "endpoint_reference_sha256", "server_process_binding", "thread_id", "client_user_message_id", "payload_sha256")
            unless receipt.is_a?(Hash) && receipt.keys.sort == (expected.keys + ["queued_submission_id"]).sort &&
                receipt.slice(*expected.keys) == expected && receipt["queued_submission_id"].is_a?(String) && ObservationTrust::UUID.match?(receipt["queued_submission_id"])
              raise AttemptErrors::EvidenceUnavailable, "retained observation queue receipt differs"
            end
          end
          reference = value.fetch("native_reference")
          unless reference.is_a?(Hash) && reference.keys.sort == REFERENCE.sort &&
              reference.values_at("provider", "version", "thread_id", "client_user_message_id", "payload_sha256", "queued_submission_id") ==
                ["codex", "0.159.3", intent.fetch("thread_id"), intent.fetch("client_user_message_id"), intent.fetch("payload_sha256"), receipt && receipt.fetch("queued_submission_id")] &&
              reference["client_user_message_id"].is_a?(String) && reference["client_user_message_id"].match?(/\Aace-[0-9a-f]{32}\z/) &&
              reference["turn_id"].is_a?(String) && ObservationTrust::UUID.match?(reference["turn_id"]) &&
              reference["item_id"].is_a?(String) && reference["item_id"].valid_encoding? && reference["item_id"].bytesize.between?(1, 256) && !reference["item_id"].include?("\0") &&
              value["source_excerpt"] == {"status" => "completed", "native_reference" => reference}
            raise AttemptErrors::EvidenceUnavailable, "observation native reference or sanitized source differs"
          end
          source = JSON.generate(value.fetch("source_excerpt"))
          unless value["source_bytes"].is_a?(Integer) && value["source_bytes"] == source.bytesize &&
              value["source_sha256"] == Digest::SHA256.hexdigest(source)
            raise AttemptErrors::EvidenceUnavailable, "observation sanitized source digest differs"
          end
          value
        rescue JSON::ParserError, KeyError, TypeError, EncodingError, ArgumentError
          raise AttemptErrors::EvidenceUnavailable, "observation schema is unavailable"
        end
      end
    end
  end
end
