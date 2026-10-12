# frozen_string_literal: true

require "digest"
require "json"
require "time"
require "uri"

module Ace
  module Assign
    module Atoms
      # Closed wire schemas for the ordinary fixed merge service (spec
      # 8x3.t.xz9.4). One owner for the exact request document, the terminal
      # fixed-effect receipt, and their semantic joins; both ace-assign
      # admission and the ace-lab producer enforce this exact module instead
      # of two dialects. Unknown fields are rejected at every nesting level,
      # formats (uri, date-time) are enforced, and every pattern/bound below
      # is the reviewed spec text — never widened.
      module FixedMergeSchemas
        REQUEST_SCHEMA_ID = "ace.lab.service.ordinary-merge-request/v1"
        RECEIPT_SCHEMA_ID = "ace.assign.fixed-effect-receipt/v1"
        ACK_SCHEMA_ID = "ace.lab.service.ordinary-merge-ack/v1"
        REFUSAL_SCHEMA_ID = "ace.lab.service.ordinary-merge-refusal/v1"
        STATUS_SCHEMA_ID = "ace.lab.service.ordinary-merge-status/v1"
        STATUS_ERROR_SCHEMA_ID = "ace.lab.service.ordinary-merge-status-error/v1"

        SHA256 = /\A[0-9a-f]{64}\z/
        HEAD = /\A[0-9a-f]{40}\z/
        FORGE = /\A[A-Za-z0-9][A-Za-z0-9._:-]{0,127}\z/
        TERMINAL_STATUSES = %w[succeeded failed].freeze
        EFFECT_OUTCOMES = %w[merged already_merged failed_no_effect].freeze
        FAILURE_CODES = [nil, "merge_failed_no_effect"].freeze

        # Every key must be an exact String with no unknown siblings.
        class SchemaError < ::StandardError; end

        module_function

        # The only admitted ordinary merge request document.
        def validate_request!(document)
          require_object!(document, "request")
          require_exact_keys!(document, "request", %w[schema forge pr_url head_repository head_ref
            candidate_head base_repository base_ref expected_base_head method review_evidence test_evidence])
          const!(document, "schema", REQUEST_SCHEMA_ID)
          string_bound!(document, "forge", 1, 128, pattern: FORGE)
          string_bound!(document, "pr_url", 1, 2048)
          uri_format!(document.fetch("pr_url"))
          string_bound!(document, "head_repository", 1, 1024)
          string_bound!(document, "head_ref", 1, 255)
          pattern!(document, "candidate_head", HEAD)
          string_bound!(document, "base_repository", 1, 1024)
          string_bound!(document, "base_ref", 1, 255)
          pattern!(document, "expected_base_head", HEAD)
          const!(document, "method", "merge")
          validate_review_evidence!(document.fetch("review_evidence"))
          validate_test_evidence!(document.fetch("test_evidence"))
          true
        end

        # The semantic join schema validity alone never waives: the reviewed
        # head and every test receipt head must equal the exact candidate.
        def require_request_joins!(document)
          candidate = document.fetch("candidate_head")
          unless document.dig("review_evidence", "reviewed_head") == candidate
            raise SchemaError, "review_evidence.reviewed_head does not equal candidate_head"
          end
          document.fetch("test_evidence").each_with_index do |item, index|
            unless item.fetch("candidate_head") == candidate
              raise SchemaError, "test_evidence[#{index}].candidate_head does not equal candidate_head"
            end
          end
          true
        end

        def validate_review_evidence!(evidence)
          require_object!(evidence, "review_evidence")
          require_exact_keys!(evidence, "review_evidence", %w[schema reference reviewer verdict
            reviewed_head recorded_at record_sha256])
          const!(evidence, "schema", "ace.review.acceptance-reference/v1")
          string_bound!(evidence, "reference", 1, 256)
          string_bound!(evidence, "reviewer", 1, 128)
          const!(evidence, "verdict", "approved")
          pattern!(evidence, "reviewed_head", HEAD)
          date_time!(evidence.fetch("recorded_at"))
          pattern!(evidence, "record_sha256", SHA256)
          true
        end

        def validate_test_evidence!(items)
          unless items.is_a?(Array) && !items.empty?
            raise SchemaError, "test_evidence must be a non-empty array"
          end
          items.each_with_index do |item, index|
            require_object!(item, "test_evidence[#{index}]")
            require_exact_keys!(item, "test_evidence[#{index}]", %w[schema reference candidate_head
              command result recorded_at receipt_sha256])
            const!(item, "schema", "ace.test.execution-reference/v1")
            string_bound!(item, "reference", 1, 256)
            pattern!(item, "candidate_head", HEAD)
            string_bound!(item, "command", 1, 2048)
            const!(item, "result", "passed")
            date_time!(item.fetch("recorded_at"))
            pattern!(item, "receipt_sha256", SHA256)
          end
          # uniqueItems: deep equality over the whole closed document
          unless items.map { |item| JSON.generate(item) }.uniq.size == items.size
            raise SchemaError, "test_evidence items are not unique"
          end
          true
        end

        # The exact terminal receipt document. Structural pass only; binding
        # against the canonical admitted record is validate_receipt_against!
        def validate_receipt!(document)
          require_object!(document, "receipt")
          require_exact_keys!(document, "receipt", %w[schema reference request_id input_digest
            terminal_status request producer effect remote_observation])
          const!(document, "schema", RECEIPT_SCHEMA_ID)
          string_bound!(document, "reference", 1, 256)
          string_bound!(document, "request_id", 1, 256)
          pattern!(document, "input_digest", SHA256)
          unless TERMINAL_STATUSES.include?(document.fetch("terminal_status"))
            raise SchemaError, "terminal_status must be succeeded or failed"
          end
          validate_receipt_request!(document.fetch("request"))
          validate_receipt_producer!(document.fetch("producer"))
          validate_receipt_effect!(document.fetch("effect"))
          validate_receipt_observation!(document.fetch("remote_observation"))
          require_terminal_invariant!(document)
          true
        end

        # Embedded, never flattened: all selectors and the complete validated
        # input document live under the single request object.
        def validate_receipt_request!(request)
          require_object!(request, "request")
          require_exact_keys!(request, "request", %w[project assignment attempt queue_entry
            operation authorization input])
          string_bound!(request, "project", 1, 128)
          string_bound!(request, "assignment", 1, 128)
          string_bound!(request, "attempt", 1, 128)
          string_bound!(request, "queue_entry", 1, 128)
          const!(request, "operation", "merge")
          string_bound!(request, "authorization", 1, 256)
          validate_request!(request.fetch("input"))
          true
        end

        def validate_receipt_producer!(producer)
          require_object!(producer, "producer")
          require_exact_keys!(producer, "producer", %w[receiver_id principal configuration_sha256])
          string_bound!(producer, "receiver_id", 1, 128)
          string_bound!(producer, "principal", 1, 256)
          pattern!(producer, "configuration_sha256", SHA256)
          true
        end

        def validate_receipt_effect!(effect)
          require_object!(effect, "effect")
          require_exact_keys!(effect, "effect", %w[started_at finished_at outcome failure_code no_effect_evidence])
          unless effect.fetch("started_at").nil? || effect.fetch("started_at").is_a?(String)
            raise SchemaError, "effect.started_at must be a date-time or null"
          end
          date_time!(effect.fetch("started_at")) unless effect.fetch("started_at").nil?
          date_time!(effect.fetch("finished_at"))
          unless EFFECT_OUTCOMES.include?(effect.fetch("outcome"))
            raise SchemaError, "effect.outcome must be merged, already_merged or failed_no_effect"
          end
          unless FAILURE_CODES.include?(effect.fetch("failure_code"))
            raise SchemaError, "effect.failure_code must be null or merge_failed_no_effect"
          end
          evidence = effect.fetch("no_effect_evidence")
          return true if evidence.nil?
          require_object!(evidence, "no_effect_evidence")
          require_exact_keys!(evidence, "no_effect_evidence", %w[reference sha256])
          string_bound!(evidence, "reference", 1, 256)
          pattern!(evidence, "sha256", SHA256)
          true
        end

        def validate_receipt_observation!(observation)
          return true if observation.nil?
          require_object!(observation, "remote_observation")
          require_exact_keys!(observation, "remote_observation", %w[forge_instance pr_identity_url
            target_repository_identity target_ref_observed merged_candidate_head admission_target_head
            resulting_target_head merge_commit checkout_id worktree_id branch])
          pattern!(observation, "forge_instance", FORGE)
          string_bound!(observation, "pr_identity_url", 1, 2048)
          uri_format!(observation.fetch("pr_identity_url"))
          string_bound!(observation, "target_repository_identity", 1, 1024)
          string_bound!(observation, "target_ref_observed", 1, 255)
          %w[merged_candidate_head admission_target_head resulting_target_head merge_commit].each do |key|
            pattern!(observation, key, HEAD)
          end
          string_bound!(observation, "checkout_id", 1, 256)
          string_bound!(observation, "worktree_id", 1, 256)
          string_bound!(observation, "branch", 1, 255)
          true
        end

        # The closed terminal oneOf: exactly one branch may hold.
        def require_terminal_invariant!(document)
          succeeded = document.fetch("terminal_status") == "succeeded"
          effect = document.fetch("effect")
          if succeeded
            raise SchemaError, "succeeded receipt needs effect.started_at" if effect.fetch("started_at").nil?
            unless %w[merged already_merged].include?(effect.fetch("outcome"))
              raise SchemaError, "succeeded receipt outcome must be merged or already_merged"
            end
            unless effect.fetch("failure_code").nil? && effect.fetch("no_effect_evidence").nil?
              raise SchemaError, "succeeded receipt cannot carry a failure code or no-effect evidence"
            end
            unless document.fetch("remote_observation").is_a?(Hash)
              raise SchemaError, "succeeded receipt requires remote_observation"
            end
          else
            unless effect.fetch("outcome") == "failed_no_effect"
              raise SchemaError, "failed receipt outcome must be failed_no_effect"
            end
            unless effect.fetch("failure_code") == "merge_failed_no_effect"
              raise SchemaError, "failed receipt requires the immutable failure code"
            end
            unless effect.fetch("no_effect_evidence").is_a?(Hash)
              raise SchemaError, "failed receipt is terminal only with immutable no_effect_evidence"
            end
            unless document.fetch("remote_observation").nil?
              raise SchemaError, "failed receipt cannot observe a remote merge"
            end
          end
          true
        end

        # The producer-side binding: every embedded request value and top-level
        # ID/digest must match the canonical admitted record, and the remote
        # observation must join back to the embedded request and the
        # registered execution identity.
        def validate_receipt_against!(receipt, record)
          validate_receipt!(receipt)
          request = receipt.fetch("request")
          embedded = request.fetch("input")
          unless receipt.fetch("request_id") == record.fetch("request_id") &&
              receipt.fetch("input_digest") == record.fetch("input_digest") &&
              receipt.fetch("reference") == record.fetch("reference")
            raise SchemaError, "receipt identity does not match the canonical admitted record"
          end
          selector_map = {
            "project" => "project_id", "assignment" => "assignment_id", "attempt" => "attempt_id",
            "queue_entry" => "queue_entry", "operation" => "operation", "authorization" => "authorization"
          }
          joined = selector_map.all? { |request_key, record_key|
            request.fetch(request_key) == record.fetch(record_key)
          }
          unless joined
            raise SchemaError, "embedded request selectors do not match the canonical admitted record"
          end
          unless embedded == record.fetch("request")
            raise SchemaError, "embedded input does not equal the canonical admitted request document"
          end
          producer = receipt.fetch("producer")
          unless producer.fetch("receiver_id") == record.fetch("receiver_id") &&
              producer.fetch("principal") == record.fetch("principal") &&
              producer.fetch("configuration_sha256") == record.fetch("configuration_sha256")
            raise SchemaError, "receipt producer does not match the canonical admitted record"
          end
          observation = receipt.fetch("remote_observation")
          if observation
            unless observation.fetch("forge_instance") == embedded.fetch("forge") &&
                observation.fetch("pr_identity_url") == embedded.fetch("pr_url") &&
                observation.fetch("target_repository_identity") == embedded.fetch("base_repository") &&
                observation.fetch("target_ref_observed") == embedded.fetch("base_ref") &&
                observation.fetch("merged_candidate_head") == embedded.fetch("candidate_head") &&
                observation.fetch("admission_target_head") == embedded.fetch("expected_base_head")
              raise SchemaError, "remote_observation does not join back to the embedded request"
            end
            identity = record.fetch("execution_identity")
            unless identity && observation.fetch("checkout_id") == identity.fetch("checkout_id") &&
                observation.fetch("worktree_id") == identity.fetch("worktree_id") &&
                observation.fetch("branch") == identity.fetch("branch")
              raise SchemaError, "remote_observation does not match the registered execution identity"
            end
            unless observation.fetch("merge_commit") == observation.fetch("resulting_target_head")
              raise SchemaError, "merge_commit must equal resulting_target_head for the fixed merge method"
            end
          end
          true
        end

        # ---- closed primitive validators ------------------------------------

        def require_object!(value, name)
          raise SchemaError, "#{name} must be an object" unless value.is_a?(Hash)
          true
        end

        def require_exact_keys!(object, name, keys)
          unknown = object.keys - keys
          unless unknown.empty?
            raise SchemaError, "#{name} has unknown fields: #{unknown.sort.join(", ")}"
          end
          missing = keys - object.keys
          unless missing.empty?
            raise SchemaError, "#{name} is missing fields: #{missing.sort.join(", ")}"
          end
          true
        end

        def const!(object, key, value)
          unless object.fetch(key) == value
            raise SchemaError, "#{key} must be #{value.to_s.inspect}"
          end
          true
        end

        def pattern!(object, key, pattern)
          value = object.fetch(key)
          unless value.is_a?(String) && value.match?(pattern)
            raise SchemaError, "#{key} has an invalid format"
          end
          true
        end

        def string_bound!(object, key, min, max, pattern: nil)
          value = object.fetch(key)
          unless value.is_a?(String) && value.length.between?(min, max)
            raise SchemaError, "#{key} must be a string of #{min}..#{max} characters"
          end
          return true if pattern.nil? || value.match?(pattern)
          raise SchemaError, "#{key} has an invalid format"
        end

        def date_time!(value)
          unless value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})\z/)
            raise SchemaError, "date-time must be an RFC 3339 timestamp"
          end
          begin
            Time.iso8601(value)
          rescue ArgumentError
            raise SchemaError, "date-time is not a valid timestamp"
          end
          true
        end

        def uri_format!(value)
          begin
            uri = URI.parse(value)
          rescue URI::Error
            raise SchemaError, "uri format is invalid"
          end
          unless uri.is_a?(URI::Generic) && !uri.scheme.to_s.empty? && !uri.host.to_s.empty? &&
              value.match?(/\A\p{ASCII}+\z/) && !value.match?(/[\\\s<>"]|\A\//)
            raise SchemaError, "uri format is invalid"
          end
          true
        end
      end
    end
  end
end
