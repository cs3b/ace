# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/assign/atoms/fixed_merge_schemas"

module Ace
  module Assign
    class FixedMergeSchemasTest < AceAssignTestCase
      def merge_receipt(overrides)
        receipt = valid_receipt
        overrides.each do |key, value|
          receipt[key] = if value.is_a?(Hash) && receipt[key].is_a?(Hash)
            receipt[key].merge(value)
          else
            value
          end
        end
        receipt
      end

      def valid_request
        {
          "schema" => "ace.lab.service.ordinary-merge-request/v1",
          "forge" => "forgejo",
          "pr_url" => "https://forge.example.com/acme/widget/pulls/7",
          "head_repository" => "acme/widget",
          "head_ref" => "refs/heads/feat/x",
          "candidate_head" => "a" * 40,
          "base_repository" => "acme/widget",
          "base_ref" => "refs/heads/main",
          "expected_base_head" => "b" * 40,
          "method" => "merge",
          "review_evidence" => {
            "schema" => "ace.review.acceptance-reference/v1",
            "reference" => "review-123",
            "reviewer" => "independent-reviewer",
            "verdict" => "approved",
            "reviewed_head" => "a" * 40,
            "recorded_at" => "2026-10-12T10:00:00Z",
            "record_sha256" => "c" * 64
          },
          "test_evidence" => [{
            "schema" => "ace.test.execution-reference/v1",
            "reference" => "test-run-9",
            "candidate_head" => "a" * 40,
            "command" => "bin/ace-test ace-lab fast",
            "result" => "passed",
            "recorded_at" => "2026-10-12T10:30:00Z",
            "receipt_sha256" => "d" * 64
          }]
        }
      end

      def valid_receipt(overrides = {})
        receipt = {
          "schema" => "ace.assign.fixed-effect-receipt/v1",
          "reference" => "fmr1-#{"A" * 40}",
          "request_id" => "request-1",
          "input_digest" => Atoms::FixedMergeSchemas.canonical_request_digest(
            project: "atlas", assignment: "assignment", attempt: "attempt",
            queue_entry: "010", authorization: "decision-1", request_id: "request-1",
            input: valid_request
          ),
          "terminal_status" => "succeeded",
          "request" => {
            "project" => "atlas", "assignment" => "assignment", "attempt" => "attempt",
            "queue_entry" => "010", "operation" => "merge", "authorization" => "decision-1",
            "input" => valid_request
          },
          "producer" => {"receiver_id" => "ordinary-receiver", "principal" => "13005",
                         "configuration_sha256" => "f" * 64},
          "effect" => {"started_at" => "2026-10-12T11:00:00Z", "finished_at" => "2026-10-12T11:01:00Z",
                       "outcome" => "merged", "failure_code" => nil, "no_effect_evidence" => nil},
          "remote_observation" => {
            "forge_instance" => "forgejo",
            "pr_identity_url" => "https://forge.example.com/acme/widget/pulls/7",
            "target_repository_identity" => "acme/widget",
            "target_ref_observed" => "refs/heads/main",
            "merged_candidate_head" => "a" * 40,
            "admission_target_head" => "b" * 40,
            "resulting_target_head" => "1" * 40,
            "merge_commit" => "1" * 40,
            "checkout_id" => "checkout-1", "worktree_id" => "worktree-1", "branch" => "feat/x"
          }
        }
        merge_receipt_into(receipt, overrides)
      end

      def merge_receipt_into(receipt, overrides)
        overrides.each do |key, value|
          receipt[key] = if value.is_a?(Hash) && receipt[key].is_a?(Hash)
            receipt[key].merge(value)
          else
            value
          end
        end
        receipt
      end

      def test_canonical_request_digest_follows_spec_ruling_r4
        document = valid_request
        base = digest_for(document)
        # Key-order independence: canonicalization is recursive key sorting,
        # so a differently ordered (value-identical) document digests equal.
        shuffled = deep_shuffle(document)
        assert_equal base, digest_for(shuffled)
        # Byte-identical input under any different selector, authorization or
        # request ID yields a different digest.
        refute_equal base, digest_for(document, request_id: "request-2")
        refute_equal base, digest_for(document, authorization: "decision-2")
        refute_equal base, digest_for(document, project: "borealis")
        refute_equal base, digest_for(document, queue_entry: "020")
        # Input sensitivity: a changed input document changes the digest.
        refute_equal base, digest_for(deep_copy(document).merge("forge" => "other"))
        # Stable and well-formed.
        assert_equal base, digest_for(document)
        assert_match(/\A[0-9a-f]{64}\z/, base)
        # Independent recomputation over the canonical preimage: an inline
        # recursive key-sort (written separately from the implementation).
        sort_keys = lambda do |value|
          case value
          when Hash
            value.keys.sort.each_with_object({}) { |key, out| out[key] = sort_keys.call(value[key]) }
          when Array then value.map { |item| sort_keys.call(item) }
          else value
          end
        end
        preimage = JSON.generate(sort_keys.call(
          "assignment" => "assignment", "attempt" => "attempt", "authorization" => "decision-1",
          "input" => JSON.parse(JSON.generate(document)), "operation" => "merge",
          "project" => "atlas", "queue_entry" => "010", "request_id" => "request-1"
        ))
        assert_equal Digest::SHA256.hexdigest(preimage), base
      end

      def digest_for(document, overrides = {})
        Atoms::FixedMergeSchemas.canonical_request_digest(
          project: overrides.fetch(:project, "atlas"),
          assignment: overrides.fetch(:assignment, "assignment"),
          attempt: overrides.fetch(:attempt, "attempt"),
          queue_entry: overrides.fetch(:queue_entry, "010"),
          authorization: overrides.fetch(:authorization, "decision-1"),
          request_id: overrides.fetch(:request_id, "request-1"),
          input: document
        )
      end

      def deep_copy(value)
        JSON.parse(JSON.generate(value))
      end

      def deep_shuffle(value)
        case value
        when Hash then value.keys.sort.reverse.each_with_object({}) { |key, out| out[key] = deep_shuffle(value[key]) }
        when Array then value.map { |item| deep_shuffle(item) }
        else value
        end
      end

      def test_valid_request_is_accepted
        assert Atoms::FixedMergeSchemas.validate_request!(valid_request)
      end

      def test_request_rejects_unknown_fields_at_every_nesting_level
        top = valid_request.merge("extra" => 1)
        e = assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_request!(top) }
        assert_includes e.message, "unknown fields"
        nested = valid_request
        nested["review_evidence"]["execuable"] = "/bin/sh"
        e = assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_request!(nested) }
        assert_includes e.message, "unknown fields"
        item = valid_request
        item["test_evidence"][0]["token"] = "t"
        e = assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_request!(item) }
        assert_includes e.message, "unknown fields"
      end

      def test_request_rejects_missing_fields_wrong_consts_and_patterns
        %w[schema forge pr_url head_repository head_ref candidate_head base_repository
          base_ref expected_base_head method review_evidence test_evidence].each do |key|
          document = valid_request
          document.delete(key)
          assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_request!(document) }
        end
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_request!(valid_request.merge("schema" => "other/v1"))
        end
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_request!(valid_request.merge("method" => "rebase"))
        end
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_request!(valid_request.merge("candidate_head" => "A" * 40))
        end
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_request!(valid_request.merge("candidate_head" => "a" * 39))
        end
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_request!(valid_request.merge("forge" => "-leading-dash"))
        end
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_request!(valid_request.merge("forge" => "x" * 129))
        end
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_request!(valid_request.merge("pr_url" => "not a uri"))
        end
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_request!(valid_request.merge("pr_url" => "https://x.example/#{"y" * 2100}"))
        end
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_request!(valid_request.merge("pr_url" => 7))
        end
      end

      def test_request_enforces_evidence_schemas_formats_and_uniqueness
        document = valid_request
        document["review_evidence"]["verdict"] = "approved-with-comments"
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_request!(document) }
        document = valid_request
        document["review_evidence"]["recorded_at"] = "2026-10-12 10:00:00"
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_request!(document) }
        document = valid_request
        document["review_evidence"]["recorded_at"] = "2026-10-12T10:00:00"
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_request!(document) }
        document = valid_request
        document["review_evidence"]["record_sha256"] = "z" * 64
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_request!(document) }
        document = valid_request
        document["test_evidence"] = []
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_request!(document) }
        document = valid_request
        document["test_evidence"] = [valid_request["test_evidence"].first,
          valid_request["test_evidence"].first.dup]
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_request!(document) }
        document = valid_request
        document["test_evidence"][0]["result"] = "failed"
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_request!(document) }
      end

      def test_request_requires_exact_evidence_key_sets
        document = valid_request
        document["review_evidence"].delete("reviewer")
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_request!(document) }
        document = valid_request
        document["test_evidence"][0].delete("command")
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_request!(document) }
      end

      def test_semantic_joins_bind_evidence_heads_to_the_candidate
        document = valid_request
        assert Atoms::FixedMergeSchemas.require_request_joins!(document)
        document["review_evidence"]["reviewed_head"] = "9" * 40
        error = assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.require_request_joins!(document)
        end
        assert_includes error.message, "reviewed_head"
        document = valid_request
        document["test_evidence"][0]["candidate_head"] = "9" * 40
        error = assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.require_request_joins!(document)
        end
        assert_includes error.message, "test_evidence[0].candidate_head"
      end

      def test_valid_terminal_receipts_are_accepted
        assert Atoms::FixedMergeSchemas.validate_receipt!(valid_receipt)
        failed = valid_receipt(
          "terminal_status" => "failed",
          "effect" => {"started_at" => nil, "finished_at" => "2026-10-12T11:01:00Z",
                       "outcome" => "failed_no_effect", "failure_code" => "merge_failed_no_effect",
                       "no_effect_evidence" => {"reference" => "evidence/no-effect-1", "sha256" => "0" * 64}},
          "remote_observation" => nil
        )
        assert Atoms::FixedMergeSchemas.validate_receipt!(failed)
      end

      def test_receipt_rejects_unknown_fields_at_every_nesting_level
        receipt = valid_receipt("unexpected" => 1)
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_receipt!(receipt) }
        receipt = valid_receipt
        receipt["request"]["flattened_head"] = "a" * 40
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_receipt!(receipt) }
        receipt = valid_receipt
        receipt["producer"]["uid"] = 0
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_receipt!(receipt) }
        receipt = valid_receipt
        receipt["effect"]["exit_code"] = 0
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_receipt!(receipt) }
        receipt = valid_receipt
        receipt["remote_observation"]["log_path"] = "/var/log/x"
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_receipt!(receipt) }
        receipt = valid_receipt(
          "terminal_status" => "failed",
          "effect" => {"started_at" => nil, "finished_at" => "2026-10-12T11:01:00Z",
                       "outcome" => "failed_no_effect", "failure_code" => "merge_failed_no_effect",
                       "no_effect_evidence" => {"reference" => "e", "sha256" => "0" * 64, "note" => "x"}},
          "remote_observation" => nil
        )
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_receipt!(receipt) }
      end

      def test_receipt_enforces_the_closed_terminal_oneof
        started = valid_receipt
        started["effect"]["started_at"] = nil
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_receipt!(started) }
        wrong_outcome = valid_receipt
        wrong_outcome["effect"]["outcome"] = "failed_no_effect"
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_receipt!(wrong_outcome) }
        with_failure = valid_receipt
        with_failure["effect"]["failure_code"] = "merge_failed_no_effect"
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_receipt!(with_failure) }
        no_observation = valid_receipt("remote_observation" => nil)
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_receipt!(no_observation) }
        failed = valid_receipt(
          "terminal_status" => "failed",
          "effect" => {"started_at" => nil, "finished_at" => "2026-10-12T11:01:00Z",
                       "outcome" => "failed_no_effect", "failure_code" => "merge_failed_no_effect",
                       "no_effect_evidence" => nil},
          "remote_observation" => nil
        )
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_receipt!(failed) }
        failed["effect"]["no_effect_evidence"] = {"reference" => "evidence/x", "sha256" => "0" * 64}
        failed["remote_observation"] = valid_receipt["remote_observation"]
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) { Atoms::FixedMergeSchemas.validate_receipt!(failed) }
      end

      def test_receipt_binding_against_the_canonical_record
        record = canonical_record
        assert Atoms::FixedMergeSchemas.validate_receipt_against!(valid_receipt, record)
        mismatched_id = valid_receipt("request_id" => "other")
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_receipt_against!(mismatched_id, record)
        end
        altered_input = valid_receipt
        altered_input["request"]["input"] = valid_request.merge("forge" => "other-forge")
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_receipt_against!(altered_input, record)
        end
        altered_selector = valid_receipt
        altered_selector["request"]["queue_entry"] = "020"
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_receipt_against!(altered_selector, record)
        end
        wrong_producer = valid_receipt("producer" => {"receiver_id" => "other", "principal" => "13005",
                                                      "configuration_sha256" => "f" * 64})
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_receipt_against!(wrong_producer, record)
        end
        wrong_join = valid_receipt
        wrong_join["remote_observation"]["merged_candidate_head"] = "9" * 40
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_receipt_against!(wrong_join, record)
        end
        wrong_identity = valid_receipt
        wrong_identity["remote_observation"]["checkout_id"] = "other-checkout"
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_receipt_against!(wrong_identity, record)
        end
        wrong_merge_commit = valid_receipt
        wrong_merge_commit["remote_observation"]["merge_commit"] = "2" * 40
        assert_raises(Atoms::FixedMergeSchemas::SchemaError) do
          Atoms::FixedMergeSchemas.validate_receipt_against!(wrong_merge_commit, record)
        end
      end

      private

      def canonical_record
        {
          "request_id" => "request-1",
          "reference" => "fmr1-#{"A" * 40}",
          "project_id" => "atlas", "assignment_id" => "assignment", "attempt_id" => "attempt",
          "queue_entry" => "010", "operation" => "merge", "authorization" => "decision-1",
          "input_digest" => Atoms::FixedMergeSchemas.canonical_request_digest(
            project: "atlas", assignment: "assignment", attempt: "attempt",
            queue_entry: "010", authorization: "decision-1", request_id: "request-1",
            input: valid_request
          ),
          "request" => valid_request,
          "principal" => "13005", "receiver_id" => "ordinary-receiver",
          "configuration_sha256" => "f" * 64,
          "execution_identity" => {"checkout_id" => "checkout-1", "worktree_id" => "worktree-1",
                                   "branch" => "feat/x"},
          "state" => "pending", "receipt" => nil
        }
      end
    end
  end
end
