# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      # Publication-specific facts remain artifacts of the existing service
      # record and canonical import owner, not a second publication journal.
      module ServicePublicationEvidence
        PUBLICATION_NEED_FIELDS = %w[schema classification request_id input_digest claim_binding
          candidate_generation head registry gem_name version artifact_digest dispatch_event_digest previous_challenge_digest].freeze
        PUBLICATION_FIELDS = %w[publication_challenge_digest publication_challenge_ref publication_challenge_event_digest
          publication_challenge_generation publication_issuing_event_digest].freeze

        def publication_result!(bytes, record, state:)
          value = JSON.parse(bytes, allow_duplicate_key: false, allow_nan: false, max_nesting: 16)
          fields = %w[schema publication target classification code request_id input_digest claim_binding]
          publication = value.fetch("publication")
          allowed = state == "succeeded" ? ["registry_exact_artifact"] :
            %w[provider_rejected_non_otp executor_credentials_unavailable registry_artifact_conflict]
          unless bytes.bytesize.between?(1, 65536) && value.is_a?(Hash) && value.keys.sort == fields.sort &&
              value["schema"] == "ace.publication-result/v1" && value["classification"] == state && allowed.include?(value["code"]) &&
              %w[request_id input_digest claim_binding target].all? { |key| value[key] == record[key] } &&
              publication.is_a?(Hash) && publication.keys.sort == %w[gem_name version head registry artifact_relative_path].sort &&
              publication["head"] == record.fetch("candidate_head") && publication["registry"] == "https://rubygems.org" &&
              publication["gem_name"].is_a?(String) && publication["gem_name"].match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/) &&
              publication["version"].is_a?(String) && publication["version"].bytesize.between?(1, 128) &&
              publication["version"].match?(/\A[0-9]+(?:\.[0-9A-Za-z]+)*(?:-[0-9A-Za-z]+(?:\.[0-9A-Za-z]+)*)?\z/) &&
              "rubygems:#{publication['gem_name']}:#{publication['version']}" == record.dig("target", "resource") &&
              publication["artifact_relative_path"].is_a?(String) && publication["artifact_relative_path"].bytesize.between?(1, 4096) &&
              publication["artifact_relative_path"].end_with?(".gem") &&
              publication["artifact_relative_path"].split("/", -1).all? { |part| part.match?(/\A[a-zA-Z0-9_.-]+\z/) && !%w[. ..].include?(part) }
            raise AttemptErrors::ReceiptRejected, "publication result differs from original artifact"
          end
          value
        rescue JSON::ParserError, KeyError, TypeError, NoMethodError
          raise AttemptErrors::ReceiptRejected, "publication result is invalid"
        end

        def publication_collection!(references, record, state, pending)
          unless %w[succeeded failed].include?(state) && references.size == 1
            raise AttemptErrors::ReceiptRejected, "publication requires one exact result artifact"
          end
          expected = context(record, pending: pending)
          bytes = if pending && pending[:pending_events]
            @canonical.read_pending(references.first, **expected, **pending.slice(:current_events, :pending_events, :blobs, :commit))
          else
            @canonical.read(references.first, **expected, commit: pending && pending[:commit] || @journal.ref_value)
          end
          publication_result!(bytes, record, state: state)
          [bytes].freeze
        end

        def publication_need!(bytes, record, previous:)
          value = JSON.parse(bytes, allow_duplicate_key: false, allow_comments: false,
            allow_nan: false, create_additions: false, max_nesting: 16)
          unless bytes.bytesize.between?(1, 65536) && value.is_a?(Hash) &&
              value.keys.sort == PUBLICATION_NEED_FIELDS.sort && value["schema"] == "ace.publication-otp-need/v1" &&
              %w[otp-required otp-rejected otp-expired].include?(value["classification"]) &&
              %w[request_id input_digest claim_binding candidate_generation].all? { |key| value[key] == record[key] } &&
              value["head"] == record["candidate_head"] && value["registry"] == "https://rubygems.org" &&
              value["previous_challenge_digest"] == previous && value["artifact_digest"] == record.dig("target", "artifact_digest") &&
              "rubygems:#{value['gem_name']}:#{value['version']}" == record.dig("target", "resource") &&
              value["dispatch_event_digest"].is_a?(String) && value["dispatch_event_digest"].match?(/\A[0-9a-f]{64}\z/)
            raise AttemptErrors::ReceiptRejected, "publication OTP need differs from original dispatch"
          end
          value
        rescue JSON::ParserError, KeyError, TypeError
          raise AttemptErrors::ReceiptRejected, "publication OTP need is invalid"
        end

        def publication_challenge!(record, pending: nil)
          context(record)
          commit = pending && pending[:commit] || @journal.ref_value
          events = pending && pending[:pending_events] ? pending.fetch(:current_events) + pending.fetch(:pending_events) :
            @journal.read_events(record.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == record.fetch("attempt_id") }
          unless Models::EvidenceEvent.chain_valid?(events)
            raise AttemptErrors::EvidenceUnavailable, "publication challenge chain is corrupt"
          end
          event = events.find { |row| row["digest"] == record["publication_challenge_event_digest"] }
          unless event && event["type"] == "service_publication_challenge" &&
              event.dig("payload", "challenge_digest") == record["publication_challenge_digest"] &&
              event.dig("payload", "request_id") == record["request_id"] &&
              event.dig("payload", "generation") == record["publication_challenge_generation"]
            raise AttemptErrors::EvidenceUnavailable, "publication challenge introduction is unavailable"
          end
          reference = record.fetch("publication_challenge_ref")
          bytes = if pending && pending[:pending_events]
            @canonical.read_pending(reference, **context(record), current_events: pending.fetch(:current_events),
              pending_events: pending.fetch(:pending_events), blobs: pending.fetch(:blobs), commit: commit)
          else
            @canonical.read(reference, **context(record), commit: commit)
          end
          unless Digest::SHA256.hexdigest(bytes) == record.fetch("publication_challenge_digest")
            raise AttemptErrors::EvidenceUnavailable, "publication challenge digest differs"
          end
          need = publication_need!(bytes, record, previous: event.dig("payload", "previous_challenge_digest"))
          dispatch = events.find { |row| row["digest"] == need.fetch("dispatch_event_digest") }
          unless dispatch && dispatch["type"] == "authority_mutation" && dispatch.dig("payload", "operation") == "begin_dispatch" &&
              dispatch.dig("payload", "data", "request_id") == record.fetch("request_id") &&
              dispatch.dig("payload", "data", "executor_process_binding") == record.fetch("executor_process_binding")
            raise AttemptErrors::EvidenceUnavailable, "publication need has no original executor dispatch"
          end
          need
        rescue KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "publication challenge evidence is incomplete"
        end
      end
    end
  end
end
