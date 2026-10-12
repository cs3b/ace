# frozen_string_literal: true

require "time"
require "uri"
require "ace/git/atoms/delivery_parameters"
require_relative "../atoms/evidence_digest"

module Ace
  module Assign
    module Molecules
      # Closed wire contract for the ordinary fixed merge producer
      # (`8x3.t.xz9.4`) consumed by the qkb.1 ordinary merge consumer through
      # `ace-lab service request/status --mode ordinary-merge`.
      #
      # The consumer invokes and validates the maintained envelopes without
      # translation or flattening. Every validator rejects unknown fields at
      # every nesting level and enforces the published patterns, formats and
      # semantic joins. The terminal receipt stays embedded: request
      # selectors live only under the single `request` object, and succeeded
      # (merged/already_merged) versus proven-no-effect failed are mutually
      # exclusive.
      module OrdinaryMergeContract
        REQUEST_SCHEMA = "ace.lab.service.ordinary-merge-request/v1"
        ACK_SCHEMA = "ace.lab.service.ordinary-merge-ack/v1"
        REFUSAL_SCHEMA = "ace.lab.service.ordinary-merge-refusal/v1"
        STATUS_SCHEMA = "ace.lab.service.ordinary-merge-status/v1"
        STATUS_ERROR_SCHEMA = "ace.lab.service.ordinary-merge-status-error/v1"
        RECEIPT_SCHEMA = "ace.assign.fixed-effect-receipt/v1"
        REVIEW_SCHEMA = "ace.review.acceptance-reference/v1"
        TEST_SCHEMA = "ace.test.execution-reference/v1"

        REFUSAL_CODES = %w[
          ordinary_merge_invalid_request
          ordinary_merge_unauthenticated
          ordinary_merge_forbidden
          ordinary_merge_selection_mismatch
          ordinary_merge_authorization_invalid
          ordinary_merge_provenance_mismatch
          ordinary_merge_target_changed
          ordinary_merge_evidence_invalid
          ordinary_merge_request_conflict
          ordinary_merge_unavailable
        ].freeze

        # A caller-side blocker: never a proven refusal, never authorization
        # for resubmission. Every other code is an authenticated receiver
        # refusal that proves no effect began.
        UNAVAILABLE_CODE = "ordinary_merge_unavailable"
        PROVEN_NO_EFFECT_CODES = (REFUSAL_CODES - [UNAVAILABLE_CODE]).freeze

        STATES = %w[pending uncertain succeeded failed].freeze
        TERMINAL_STATES = %w[succeeded failed].freeze
        OUTCOMES = %w[merged already_merged failed_no_effect].freeze

        HEX64 = /\A[0-9a-f]{64}\z/
        SHA40 = /\A[0-9a-f]{40}\z/
        FORGE_NAME = /\A[A-Za-z0-9][A-Za-z0-9._:-]{0,127}\z/
        DATETIME = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})\z/

        REQUEST_KEYS = %w[schema forge pr_url head_repository head_ref candidate_head
          base_repository base_ref expected_base_head method review_evidence test_evidence].freeze
        REVIEW_KEYS = %w[schema reference reviewer verdict reviewed_head recorded_at record_sha256].freeze
        TEST_KEYS = %w[schema reference candidate_head command result recorded_at receipt_sha256].freeze
        ACK_KEYS = %w[schema type request_id input_digest reference].freeze
        REFUSAL_KEYS = %w[schema code message request_id input_digest].freeze
        STATUS_KEYS = %w[schema state reference request_id input_digest receipt].freeze
        RECEIPT_KEYS = %w[schema reference request_id input_digest terminal_status request
          producer effect remote_observation].freeze
        RECEIPT_REQUEST_KEYS = %w[project assignment attempt queue_entry operation authorization input].freeze
        PRODUCER_KEYS = %w[receiver_id principal configuration_sha256].freeze
        EFFECT_KEYS = %w[started_at finished_at outcome failure_code no_effect_evidence].freeze
        OBSERVATION_KEYS = %w[forge_instance pr_identity_url target_repository_identity target_ref_observed
          merged_candidate_head admission_target_head resulting_target_head merge_commit
          checkout_id worktree_id branch].freeze

        class << self
          # Validates and returns the closed ordinary-merge request input.
          # Both packages enforce `format` and reject unknown fields at every
          # nesting level; evidence heads must equal the candidate head.
          def validate_request_input!(document)
            exact_object!(document, REQUEST_KEYS, "request input")
            const!(document.fetch("schema"), REQUEST_SCHEMA, "request input schema")
            pattern!(document.fetch("forge"), FORGE_NAME, "forge")
            url!(document.fetch("pr_url"))
            bounded!(document.fetch("head_repository"), 1024, "head_repository")
            bounded!(document.fetch("head_ref"), 255, "head_ref")
            pattern!(document.fetch("candidate_head"), SHA40, "candidate_head")
            bounded!(document.fetch("base_repository"), 1024, "base_repository")
            bounded!(document.fetch("base_ref"), 255, "base_ref")
            pattern!(document.fetch("expected_base_head"), SHA40, "expected_base_head")
            const!(document.fetch("method"), "merge", "method")
            review = document.fetch("review_evidence")
            exact_object!(review, REVIEW_KEYS, "review_evidence")
            const!(review.fetch("schema"), REVIEW_SCHEMA, "review_evidence schema")
            bounded!(review.fetch("reference"), 256, "review_evidence.reference")
            bounded!(review.fetch("reviewer"), 128, "review_evidence.reviewer")
            const!(review.fetch("verdict"), "approved", "review_evidence.verdict")
            pattern!(review.fetch("reviewed_head"), SHA40, "review_evidence.reviewed_head")
            datetime!(review.fetch("recorded_at"), "review_evidence.recorded_at")
            pattern!(review.fetch("record_sha256"), HEX64, "review_evidence.record_sha256")
            tests = document.fetch("test_evidence")
            raise ArgumentError, "request input test_evidence must be a non-empty array" unless tests.is_a?(Array) && !tests.empty?
            seen = []
            tests.each_with_index do |item, index|
              exact_object!(item, TEST_KEYS, "test_evidence[#{index}]")
              const!(item.fetch("schema"), TEST_SCHEMA, "test_evidence[#{index}] schema")
              bounded!(item.fetch("reference"), 256, "test_evidence[#{index}].reference")
              pattern!(item.fetch("candidate_head"), SHA40, "test_evidence[#{index}].candidate_head")
              bounded!(item.fetch("command"), 2048, "test_evidence[#{index}].command")
              const!(item.fetch("result"), "passed", "test_evidence[#{index}].result")
              datetime!(item.fetch("recorded_at"), "test_evidence[#{index}].recorded_at")
              pattern!(item.fetch("receipt_sha256"), HEX64, "test_evidence[#{index}].receipt_sha256")
              entry = Atoms::EvidenceDigest.digest(item)
              raise ArgumentError, "request input test_evidence entries must be unique" if seen.include?(entry)
              seen << entry
            end
            unless review.fetch("reviewed_head") == document.fetch("candidate_head") &&
                tests.all? { |item| item.fetch("candidate_head") == document.fetch("candidate_head") }
              raise ArgumentError, "request input evidence heads must equal the candidate head"
            end
            document
          end

          # Canonical lowercase SHA-256 input digest of a validated document.
          # Canonical request digest — spec ruling r4: lowercase hex SHA-256
          # over canonical JSON (recursive code-point key sort, compact
          # UTF-8) of the full eight-field immutable binding: project,
          # assignment, attempt, queue_entry, operation (constant merge),
          # authorization, request_id and the complete validated input
          # document. Byte-identical input under any different selector,
          # authorization or request ID yields a different digest; the
          # document alone is never the digest.
          def binding_digest(project:, assignment:, attempt:, queue_entry:, authorization:, request_id:, input:)
            Atoms::EvidenceDigest.digest(
              "project" => project, "assignment" => assignment, "attempt" => attempt,
              "queue_entry" => queue_entry, "operation" => "merge",
              "authorization" => authorization, "request_id" => request_id,
              "input" => input
            )
          end

          # Admission acknowledgment: exact keys, exact selector echo, opaque
          # reference with no parseable structure implied.
          def validate_ack!(data, request_id:, input_digest:)
            exact_object!(data, ACK_KEYS, "acknowledgment")
            const!(data.fetch("schema"), ACK_SCHEMA, "acknowledgment schema")
            const!(data.fetch("type"), "accepted", "acknowledgment type")
            selector!(data.fetch("request_id"), "acknowledgment request_id")
            pattern!(data.fetch("input_digest"), HEX64, "acknowledgment input_digest")
            selector!(data.fetch("reference"), "acknowledgment reference")
            unless data.fetch("request_id") == request_id && data.fetch("input_digest") == input_digest
              raise ArgumentError, "acknowledgment selectors differ from the recorded binding"
            end
            data
          end

          # Closed outer response envelope: status "ok" carries exactly the
          # data object; status "error" carries exactly the error object. The
          # outer objects reject unknown fields; the returned branch payload
          # is validated by the inner contract validators. Any other outer
          # status or shape is malformed. Returns {status:, payload:}.
          def validate_envelope_branch!(envelope)
            unless envelope.is_a?(Hash) && %w[ok error].include?(envelope["status"])
              raise ArgumentError, "response envelope status must be ok or error"
            end
            if envelope["status"] == "ok"
              exact_object!(envelope, %w[status data], "response envelope")
              payload = envelope.fetch("data")
            else
              exact_object!(envelope, %w[status error], "response envelope")
              payload = envelope.fetch("error")
            end
            raise ArgumentError, "response envelope branch must be a JSON object" unless payload.is_a?(Hash)
            {status: envelope["status"], payload: payload}
          end

          # Pre-admission refusal envelope. Refusal is request-time only; it
          # never carries a reference and is never a read-only status value.
          def validate_refusal!(error, schema: REFUSAL_SCHEMA)
            exact_object!(error, REFUSAL_KEYS, "refusal")
            const!(error.fetch("schema"), schema, "refusal schema")
            unless REFUSAL_CODES.include?(error.fetch("code"))
              raise ArgumentError, "refusal code is outside the closed set"
            end
            message = error.fetch("message")
            unless message.is_a?(String) && !message.empty? && message.length <= 512
              raise ArgumentError, "refusal message must be a sanitized non-empty string of at most 512 characters"
            end
            selector!(error.fetch("request_id"), "refusal request_id")
            digest = error.fetch("input_digest")
            valid_digest = digest.nil? || (digest.is_a?(String) && digest.match?(HEX64))
            unless valid_digest
              raise ArgumentError, "refusal input_digest must be a lowercase SHA-256 string or null"
            end
            error
          end

          # Read-only status success envelope. Reports only pending,
          # uncertain, succeeded or failed; succeeded/failed carry the one
          # embedded terminal receipt, pending/uncertain a null receipt.
          def validate_status!(envelope, reference:, request_id:, input_digest:)
            exact_object!(envelope, %w[status data], "status envelope")
            const!(envelope.fetch("status"), "ok", "status envelope")
            data = envelope.fetch("data")
            exact_object!(data, STATUS_KEYS, "status data")
            const!(data.fetch("schema"), STATUS_SCHEMA, "status schema")
            unless STATES.include?(data.fetch("state"))
              raise ArgumentError, "status state is outside the closed model"
            end
            selector!(data.fetch("reference"), "status reference")
            selector!(data.fetch("request_id"), "status request_id")
            pattern!(data.fetch("input_digest"), HEX64, "status input_digest")
            unless data.fetch("reference") == reference && data.fetch("request_id") == request_id &&
                data.fetch("input_digest") == input_digest
              raise ArgumentError, "status identifiers differ from the recorded binding"
            end
            receipt = data.fetch("receipt")
            if TERMINAL_STATES.include?(data.fetch("state"))
              raise ArgumentError, "terminal status requires the embedded receipt" unless receipt.is_a?(Hash)
              validated = validate_receipt!(receipt)
              raise ArgumentError, "receipt terminal_status differs from the status state" unless validated.fetch("terminal_status") == data.fetch("state")
            else
              raise ArgumentError, "pending/uncertain status must carry a null receipt" unless receipt.nil?
              validated = nil
            end
            {state: data.fetch("state"), receipt: validated}
          end

          # Terminal receipt: embedded request, never flattened. When
          # `binding` is given, every command selector and the complete input
          # document must equal the recorded binding; success additionally
          # joins the remote observation back to the embedded request.
          def validate_receipt!(receipt, binding: nil)
            exact_object!(receipt, RECEIPT_KEYS, "terminal receipt")
            const!(receipt.fetch("schema"), RECEIPT_SCHEMA, "receipt schema")
            selector!(receipt.fetch("reference"), "receipt reference")
            selector!(receipt.fetch("request_id"), "receipt request_id")
            pattern!(receipt.fetch("input_digest"), HEX64, "receipt input_digest")
            unless %w[succeeded failed].include?(receipt.fetch("terminal_status"))
              raise ArgumentError, "receipt terminal_status is outside the closed set"
            end
            request = receipt.fetch("request")
            exact_object!(request, RECEIPT_REQUEST_KEYS, "receipt request")
            bounded!(request.fetch("project"), 128, "receipt request.project")
            bounded!(request.fetch("assignment"), 128, "receipt request.assignment")
            bounded!(request.fetch("attempt"), 128, "receipt request.attempt")
            bounded!(request.fetch("queue_entry"), 128, "receipt request.queue_entry")
            const!(request.fetch("operation"), "merge", "receipt request.operation")
            selector!(request.fetch("authorization"), "receipt request.authorization")
            input = validate_request_input!(request.fetch("input"))
            producer = receipt.fetch("producer")
            exact_object!(producer, PRODUCER_KEYS, "receipt producer")
            bounded!(producer.fetch("receiver_id"), 128, "receipt producer.receiver_id")
            bounded!(producer.fetch("principal"), 256, "receipt producer.principal")
            pattern!(producer.fetch("configuration_sha256"), HEX64, "receipt producer.configuration_sha256")
            unless binding_digest(project: request.fetch("project"), assignment: request.fetch("assignment"),
              attempt: request.fetch("attempt"), queue_entry: request.fetch("queue_entry"),
              authorization: request.fetch("authorization"), request_id: receipt.fetch("request_id"),
              input: input) == receipt.fetch("input_digest")
              raise ArgumentError, "receipt input_digest is not the canonical digest of the embedded binding"
            end
            validate_effect!(receipt.fetch("effect"))
            validate_observation!(receipt.fetch("remote_observation"), input)
            enforce_exclusivity!(receipt)
            join_observation!(receipt, input)
            join_binding!(receipt, binding, input) if binding
            receipt
          end

          private

          def validate_effect!(effect)
            exact_object!(effect, EFFECT_KEYS, "receipt effect")
            started_at = effect.fetch("started_at")
            datetime!(started_at, "receipt effect.started_at") unless started_at.nil?
            datetime!(effect.fetch("finished_at"), "receipt effect.finished_at")
            unless OUTCOMES.include?(effect.fetch("outcome"))
              raise ArgumentError, "receipt effect.outcome is outside the closed set"
            end
            failure_code = effect.fetch("failure_code")
            unless failure_code.nil? || failure_code == "merge_failed_no_effect"
              raise ArgumentError, "receipt effect.failure_code must be null or merge_failed_no_effect"
            end
            evidence = effect.fetch("no_effect_evidence")
            valid_evidence = evidence.nil? || (evidence.is_a?(Hash) &&
              evidence.keys.sort == %w[reference sha256].sort &&
              bounded?(evidence["reference"], 256) &&
              evidence["sha256"].is_a?(String) && evidence["sha256"].match?(HEX64))
            unless valid_evidence
              raise ArgumentError, "receipt effect.no_effect_evidence must be null or a bounded reference/sha256 object"
            end
          end

          def validate_observation!(observation, input)
            return if observation.nil?
            exact_object!(observation, OBSERVATION_KEYS, "receipt remote_observation")
            pattern!(observation.fetch("forge_instance"), FORGE_NAME, "remote_observation.forge_instance")
            url!(observation.fetch("pr_identity_url"), "remote_observation.pr_identity_url")
            bounded!(observation.fetch("target_repository_identity"), 1024, "remote_observation.target_repository_identity")
            bounded!(observation.fetch("target_ref_observed"), 255, "remote_observation.target_ref_observed")
            %w[merged_candidate_head admission_target_head resulting_target_head merge_commit].each do |key|
              pattern!(observation.fetch(key), SHA40, "remote_observation.#{key}")
            end
            bounded!(observation.fetch("checkout_id"), 256, "remote_observation.checkout_id")
            bounded!(observation.fetch("worktree_id"), 256, "remote_observation.worktree_id")
            bounded!(observation.fetch("branch"), 255, "remote_observation.branch")
          end

          # Succeeded (merged/already_merged) versus proven-no-effect failed
          # are mutually exclusive; failure is terminal only with immutable
          # no-effect evidence.
          def enforce_exclusivity!(receipt)
            effect = receipt.fetch("effect")
            case receipt.fetch("terminal_status")
            when "succeeded"
              unless %w[merged already_merged].include?(effect.fetch("outcome")) &&
                  effect.fetch("failure_code").nil? && effect.fetch("no_effect_evidence").nil? &&
                  effect.fetch("started_at").is_a?(String) && receipt.fetch("remote_observation").is_a?(Hash)
                raise ArgumentError, "succeeded receipt must describe a verified remote outcome without failure evidence"
              end
            when "failed"
              unless effect.fetch("outcome") == "failed_no_effect" &&
                  effect.fetch("failure_code") == "merge_failed_no_effect" &&
                  effect.fetch("no_effect_evidence").is_a?(Hash) && receipt.fetch("remote_observation").nil?
                raise ArgumentError, "failed receipt must prove no effect and carry no remote observation"
              end
            end
          end

          # `remote_observation` uses distinct observation keys whose values
          # are joined back to the embedded request; the fixed merge method
          # additionally requires merge_commit == resulting_target_head.
          def join_observation!(receipt, input)
            observation = receipt.fetch("remote_observation")
            return if observation.nil?
            unless observation.fetch("forge_instance") == input.fetch("forge") &&
                observation.fetch("pr_identity_url") == input.fetch("pr_url") &&
                observation.fetch("target_repository_identity") == input.fetch("base_repository") &&
                observation.fetch("target_ref_observed") == input.fetch("base_ref") &&
                observation.fetch("merged_candidate_head") == input.fetch("candidate_head") &&
                observation.fetch("admission_target_head") == input.fetch("expected_base_head") &&
                observation.fetch("merge_commit") == observation.fetch("resulting_target_head")
              raise ArgumentError, "remote observation does not join back to the embedded request"
            end
          end

          def join_binding!(receipt, binding, input)
            request = receipt.fetch("request")
            expected = binding.fetch(:request)
            unless receipt.fetch("reference") == binding.fetch(:reference) &&
                receipt.fetch("request_id") == binding.fetch(:request_id) &&
                receipt.fetch("input_digest") == binding.fetch(:input_digest) &&
                request.fetch("project") == expected.fetch(:project) &&
                request.fetch("assignment") == expected.fetch(:assignment) &&
                request.fetch("attempt") == expected.fetch(:attempt) &&
                request.fetch("queue_entry") == expected.fetch(:queue_entry) &&
                request.fetch("authorization") == expected.fetch(:authorization) &&
                input == expected.fetch(:input)
              raise ArgumentError, "embedded request selectors differ from the recorded binding"
            end
          end

          def exact_object!(value, keys, label)
            raise ArgumentError, "#{label} must be a JSON object" unless value.is_a?(Hash)
            unless value.keys.sort == keys.sort
              raise ArgumentError, "#{label} must have exactly the closed field set"
            end
          end

          def const!(value, expected, label)
            return value if value == expected
            raise ArgumentError, "#{label} must be #{expected.inspect}"
          end

          def pattern!(value, regex, label)
            return value if value.is_a?(String) && value.match?(regex)
            raise ArgumentError, "#{label} does not match the closed pattern"
          end

          def bounded?(value, max)
            value.is_a?(String) && !value.empty? && value.length <= max
          end

          def bounded!(value, max, label)
            return value if bounded?(value, max)
            raise ArgumentError, "#{label} must be a non-empty string of at most #{max} characters"
          end

          def selector!(value, label)
            bounded!(value, 256, label)
          end

          def datetime!(value, label)
            unless value.is_a?(String) && value.match?(DATETIME) &&
                Time.iso8601(value)
              raise ArgumentError, "#{label} must be an RFC 3339 date-time"
            end
          rescue ArgumentError
            raise ArgumentError, "#{label} must be an RFC 3339 date-time"
          end

          # `format: uri` plus the maintained neutral PR URL validation: the
          # normalized URL produced by the selected forge adapter.
          def url!(value, label = "pr_url")
            unless value.is_a?(String) && !value.empty? && value.length <= 2048 &&
                !value.match?(/\s/) && URI.parse(value).absolute? &&
                %w[http https].include?(URI.parse(value).scheme)
              raise ArgumentError, "#{label} must be an absolute http(s) URI"
            end
            Ace::Git::Atoms::DeliveryParameters.validate_url!(value)
            value
          rescue URI::InvalidURIError, Ace::Git::Error
            raise ArgumentError, "#{label} must be a normalized forge PR URL"
          end
        end
      end
    end
  end
end
