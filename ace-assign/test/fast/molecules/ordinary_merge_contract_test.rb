# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/ordinary_merge_fixture"

module Ace
  module Assign
    module Molecules
      class OrdinaryMergeContractTest < AceAssignTestCase
        include OrdinaryMergeFixture

        def test_accepts_the_closed_request_input
          document = valid_input
          assert_same document, OrdinaryMergeContract.validate_request_input!(document)
        end

        def test_input_digest_is_stable_lowercase_sha256_of_canonical_json
          first = OrdinaryMergeContract.input_digest(valid_input)
          reordered = deep_dup(valid_input)
          reordered["test_evidence"] = reordered["test_evidence"].reverse
          assert_match(/\A[0-9a-f]{64}\z/, first)
          assert_equal first, OrdinaryMergeContract.input_digest(reordered)
        end

        def test_request_input_rejects_unknown_missing_and_invalid_fields
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_request_input!(valid_input.merge("extra" => 1)) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_request_input!(without_deep_key(valid_input, ["forge"])) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, ["schema"], "other/v1")) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, ["method"], "rebase")) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, ["forge"], "-bad")) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, ["candidate_head"], "a" * 39)) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, ["expected_base_head"], "B" * 40)) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, ["pr_url"], "not a uri")) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, ["pr_url"], "javascript:alert(1)")) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, ["head_ref"], "")) }
        end

        def test_request_input_rejects_unknown_fields_at_every_nesting_level
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, %w[review_evidence token], "x"))
          end
          assert_raises(ArgumentError) do
            document = valid_input
            document["test_evidence"].first["artifact_path"] = "/tmp/evidence"
            OrdinaryMergeContract.validate_request_input!(document)
          end
        end

        def test_request_input_enforces_evidence_semantic_join
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, %w[review_evidence reviewed_head], "e" * 40))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, %w[test_evidence 0 candidate_head], "f" * 40))
          end
        end

        def test_request_input_rejects_empty_or_duplicate_test_evidence
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, ["test_evidence"], []))
          end
          duplicated = valid_input
          duplicated["test_evidence"] = [duplicated["test_evidence"].first, deep_dup(duplicated["test_evidence"].first)]
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_request_input!(duplicated) }
        end

        def test_request_input_rejects_invalid_evidence_results_and_datetimes
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, %w[review_evidence verdict], "approved-with-nits"))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, %w[test_evidence 0 result], "flaky"))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_request_input!(with_deep_value(valid_input, %w[review_evidence recorded_at], "2026-10-12 not a time"))
          end
        end

        def test_accepts_the_exact_acknowledgment_and_rejects_mismatched_acks
          digest = OrdinaryMergeContract.input_digest(valid_input)
          ack = valid_ack(digest)
          assert_same ack, OrdinaryMergeContract.validate_ack!(ack, request_id: REQUEST_ID, input_digest: digest)
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_ack!(valid_ack(digest, request_id: "other"), request_id: REQUEST_ID, input_digest: digest) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_ack!(valid_ack("e" * 64), request_id: REQUEST_ID, input_digest: digest) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_ack!(valid_ack(digest, reference: "r" * 257), request_id: REQUEST_ID, input_digest: digest) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_ack!(valid_ack(digest).merge("refused" => true), request_id: REQUEST_ID, input_digest: digest) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_ack!(valid_ack(digest, reference: nil), request_id: REQUEST_ID, input_digest: digest) }
        end

        def test_refusal_envelope_is_closed_and_never_carries_a_reference
          OrdinaryMergeContract::REFUSAL_CODES.each do |code|
            refusal = valid_refusal(code)
            assert_same refusal, OrdinaryMergeContract.validate_refusal!(refusal)
          end
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_refusal!(valid_refusal("ordinary_merge_refused")) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_refusal!(valid_refusal("ordinary_merge_forbidden").merge("reference" => "leaked")) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_refusal!(valid_refusal("ordinary_merge_forbidden", message: "")) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_refusal!(valid_refusal("ordinary_merge_forbidden", message: "m" * 513)) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_refusal!(valid_refusal("ordinary_merge_forbidden", input_digest: "xyz")) }
          assert_equal valid_refusal("ordinary_merge_invalid_request", input_digest: nil),
            OrdinaryMergeContract.validate_refusal!(valid_refusal("ordinary_merge_invalid_request"))
        end

        def test_outer_envelope_branch_is_closed
          ack = valid_ack(HEX64)
          assert_equal({status: "ok", payload: ack},
            OrdinaryMergeContract.validate_envelope_branch!({"status" => "ok", "data" => ack}))
          refusal = valid_refusal("ordinary_merge_forbidden")
          assert_equal({status: "error", payload: refusal},
            OrdinaryMergeContract.validate_envelope_branch!({"status" => "error", "error" => refusal}))
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_envelope_branch!({"status" => "ok", "data" => ack, "error" => refusal})
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_envelope_branch!({"status" => "pending", "error" => refusal})
          end
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_envelope_branch!({"status" => "ok"}) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_envelope_branch!({"status" => "error"}) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_envelope_branch!("garbage") }
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_envelope_branch!({"status" => "ok", "data" => "scalar"})
          end
        end

        def test_status_envelope_enforces_the_closed_state_model
          selectors = {reference: REQUEST_REFERENCE, request_id: REQUEST_ID, input_digest: HEX64}
          assert_equal({state: "pending", receipt: nil},
            OrdinaryMergeContract.validate_status!(valid_status("pending", selectors: selectors), **selectors))
          assert_equal({state: "uncertain", receipt: nil},
            OrdinaryMergeContract.validate_status!(valid_status("uncertain", selectors: selectors), **selectors))
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_status!(valid_status("refused", selectors: selectors), **selectors) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_status!(valid_status("pending", receipt: {}, selectors: selectors), **selectors) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_status!(valid_status("pending", selectors: selectors).merge("refused" => "no"), **selectors) }
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_status!(valid_status("pending", selectors: selectors.merge(input_digest: "e" * 64)), **selectors)
          end
        end

        def test_terminal_status_requires_the_exact_embedded_receipt
          selectors = {reference: REQUEST_REFERENCE, request_id: REQUEST_ID, input_digest: HEX64}
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_status!(valid_status("succeeded", receipt: nil, selectors: selectors), **selectors) }
          binding_document = {reference: REQUEST_REFERENCE, request_id: REQUEST_ID, input_digest: HEX64,
                              request: {project: PROJECT, assignment: "a1", attempt: "t1", queue_entry: QUEUE_ENTRY,
                                        authorization: AUTHORIZATION, input: valid_input}}
          receipt = valid_receipt(binding_document)
          assert_same receipt, OrdinaryMergeContract.validate_receipt!(receipt, binding: binding_document)
        end

        def test_receipt_accepts_merged_already_merged_and_failed_no_effect
          base = {reference: REQUEST_REFERENCE, request_id: REQUEST_ID, input_digest: HEX64,
                  request: {project: PROJECT, assignment: "a1", attempt: "t1", queue_entry: QUEUE_ENTRY,
                            authorization: AUTHORIZATION, input: valid_input}}
          %w[merged already_merged failed_no_effect].each do |outcome|
            receipt = valid_receipt(base, outcome: outcome)
            assert_same receipt, OrdinaryMergeContract.validate_receipt!(receipt, binding: base)
          end
        end

        def test_receipt_rejects_unknown_flattened_or_missing_fields
          base = {reference: REQUEST_REFERENCE, request_id: REQUEST_ID, input_digest: HEX64,
                  request: {project: PROJECT, assignment: "a1", attempt: "t1", queue_entry: QUEUE_ENTRY,
                            authorization: AUTHORIZATION, input: valid_input}}
          flattened = valid_receipt(base)
          flattened["forge"] = flattened["request"]["input"]["forge"]
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_receipt!(flattened) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_receipt!(without_deep_key(valid_receipt(base), %w[request queue_entry])) }
          assert_raises(ArgumentError) { OrdinaryMergeContract.validate_receipt!(with_deep_value(valid_receipt(base), ["terminal_status"], "refused")) }
        end

        def test_receipt_embedded_request_must_equal_the_recorded_binding
          base = {reference: REQUEST_REFERENCE, request_id: REQUEST_ID, input_digest: HEX64,
                  request: {project: PROJECT, assignment: "a1", attempt: "t1", queue_entry: QUEUE_ENTRY,
                            authorization: AUTHORIZATION, input: valid_input}}
          receipt = valid_receipt(base)
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(receipt, binding: base.merge(request: base[:request].merge(project: "other")))
          end
          assert_raises(ArgumentError) do
            altered_input = with_deep_value(valid_input, ["pr_url"], "https://forgejo.example/ace/other/pulls/7")
            OrdinaryMergeContract.validate_receipt!(receipt, binding: base.merge(request: base[:request].merge(input: altered_input)))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(receipt, binding: base.merge(input_digest: "e" * 64))
          end
        end

        def test_succeeded_and_failed_are_mutually_exclusive
          base = {reference: REQUEST_REFERENCE, request_id: REQUEST_ID, input_digest: HEX64,
                  request: {project: PROJECT, assignment: "a1", attempt: "t1", queue_entry: QUEUE_ENTRY,
                            authorization: AUTHORIZATION, input: valid_input}}
          succeeded = valid_receipt(base, outcome: "merged")
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(with_deep_value(succeeded, %w[effect no_effect_evidence], {"reference" => "x", "sha256" => HEX64}))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(with_deep_value(succeeded, %w[effect failure_code], "merge_failed_no_effect"))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(with_deep_value(succeeded, ["remote_observation"], nil))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(with_deep_value(succeeded, %w[effect started_at], nil))
          end
          failed = valid_receipt(base, outcome: "failed_no_effect")
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(with_deep_value(failed, %w[effect failure_code], nil))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(with_deep_value(failed, %w[effect no_effect_evidence], nil))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(with_deep_value(failed, ["remote_observation"], {"forge_instance" => "x"}))
          end
        end

        def test_remote_observation_must_join_back_to_the_embedded_request
          base = {reference: REQUEST_REFERENCE, request_id: REQUEST_ID, input_digest: HEX64,
                  request: {project: PROJECT, assignment: "a1", attempt: "t1", queue_entry: QUEUE_ENTRY,
                            authorization: AUTHORIZATION, input: valid_input}}
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(with_deep_value(valid_receipt(base), %w[remote_observation target_repository_identity], "other/repo"))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(with_deep_value(valid_receipt(base), %w[remote_observation merged_candidate_head], "e" * 40))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(with_deep_value(valid_receipt(base), %w[remote_observation admission_target_head], "e" * 40))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(with_deep_value(valid_receipt(base), %w[remote_observation pr_identity_url], "https://forgejo.example/ace/other/pulls/7"))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(with_deep_value(valid_receipt(base), %w[remote_observation merge_commit], "e" * 40))
          end
          assert_raises(ArgumentError) do
            OrdinaryMergeContract.validate_receipt!(with_deep_value(valid_receipt(base), %w[remote_observation target_ref_observed], "refs/heads/other"))
          end
        end
      end
    end
  end
end
