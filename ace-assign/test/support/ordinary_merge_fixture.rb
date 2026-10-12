# frozen_string_literal: true

# Deterministic wire-document builders for the ordinary fixed merge
# consumer slice (qkb.1). Every builder returns a fresh, mutable document
# matching the closed xz9.4 schemas exactly.
module OrdinaryMergeFixture
  CANDIDATE = "a" * 40
  BASE_HEAD = "b" * 40
  MERGE_COMMIT = "c" * 40
  HEX64 = "d" * 64
  REQUEST_REFERENCE = "receiver/ordinary/ref-1"
  REQUEST_ID = "req-0001"
  AUTHORIZATION = "auth/ordinary/0001"
  PROJECT = "ace"
  QUEUE_ENTRY = "queue-1"

  def valid_input
    {
      "schema" => "ace.lab.service.ordinary-merge-request/v1",
      "forge" => "forgejo-lab",
      "pr_url" => "https://forgejo.example/ace/repo/pulls/7",
      "head_repository" => "ace/repo",
      "head_ref" => "refs/heads/feat/qkb1",
      "candidate_head" => CANDIDATE,
      "base_repository" => "ace/repo",
      "base_ref" => "refs/heads/main",
      "expected_base_head" => BASE_HEAD,
      "method" => "merge",
      "review_evidence" => {
        "schema" => "ace.review.acceptance-reference/v1",
        "reference" => "review/8wr.t.qkb.1/r3",
        "reviewer" => "reviewer-1",
        "verdict" => "approved",
        "reviewed_head" => CANDIDATE,
        "recorded_at" => "2026-10-12T10:00:00Z",
        "record_sha256" => HEX64
      },
      "test_evidence" => [
        {
          "schema" => "ace.test.execution-reference/v1",
          "reference" => "assign/test-run-1",
          "candidate_head" => CANDIDATE,
          "command" => "bin/ace-test ace-assign fast",
          "result" => "passed",
          "recorded_at" => "2026-10-12T10:05:00Z",
          "receipt_sha256" => HEX64
        }
      ]
    }
  end

  def valid_ack(input_digest, request_id: REQUEST_ID, reference: REQUEST_REFERENCE)
    {
      "schema" => "ace.lab.service.ordinary-merge-ack/v1",
      "type" => "accepted",
      "request_id" => request_id,
      "input_digest" => input_digest,
      "reference" => reference
    }
  end

  def valid_refusal(code, request_id: REQUEST_ID, input_digest: nil, message: "receiver refused the request")
    {
      "schema" => "ace.lab.service.ordinary-merge-refusal/v1",
      "code" => code,
      "message" => message,
      "request_id" => request_id,
      "input_digest" => input_digest
    }
  end

  def valid_receipt(selectors, outcome: "merged")
    request = selectors.fetch(:request)
    input = request.fetch(:input)
    effect, observation =
      if outcome == "failed_no_effect"
        [{"started_at" => nil, "finished_at" => "2026-10-12T10:30:00Z", "outcome" => "failed_no_effect",
          "failure_code" => "merge_failed_no_effect",
          "no_effect_evidence" => {"reference" => "assign/no-effect-1", "sha256" => HEX64}}, nil]
      else
        [{"started_at" => "2026-10-12T10:20:00Z", "finished_at" => "2026-10-12T10:30:00Z", "outcome" => outcome,
          "failure_code" => nil, "no_effect_evidence" => nil},
          {"forge_instance" => input.fetch("forge"), "pr_identity_url" => input.fetch("pr_url"),
           "target_repository_identity" => input.fetch("base_repository"),
           "target_ref_observed" => input.fetch("base_ref"),
           "merged_candidate_head" => input.fetch("candidate_head"),
           "admission_target_head" => input.fetch("expected_base_head"),
           "resulting_target_head" => MERGE_COMMIT, "merge_commit" => MERGE_COMMIT,
           "checkout_id" => "checkout-1", "worktree_id" => "wt-1", "branch" => "refs/heads/main"}]
      end
    {
      "schema" => "ace.assign.fixed-effect-receipt/v1",
      "reference" => REQUEST_REFERENCE,
      "request_id" => REQUEST_ID,
      "input_digest" => selectors.fetch(:input_digest),
      "terminal_status" => (outcome == "failed_no_effect") ? "failed" : "succeeded",
      "request" => {
        "project" => request.fetch(:project),
        "assignment" => request.fetch(:assignment),
        "attempt" => request.fetch(:attempt),
        "queue_entry" => request.fetch(:queue_entry),
        "operation" => "merge",
        "authorization" => request.fetch(:authorization),
        "input" => input
      },
      "producer" => {"receiver_id" => "receiver-1", "principal" => "overseer-ace",
                     "configuration_sha256" => HEX64},
      "effect" => effect,
      "remote_observation" => observation
    }
  end

  def valid_status(state, selectors:, receipt: nil)
    {
      "status" => "ok",
      "data" => {
        "schema" => "ace.lab.service.ordinary-merge-status/v1",
        "state" => state,
        "reference" => REQUEST_REFERENCE,
        "request_id" => REQUEST_ID,
        "input_digest" => selectors.fetch(:input_digest),
        "receipt" => receipt
      }
    }
  end

  def status_error(code, message: "status command failed")
    {
      "status" => "error",
      "error" => {
        "schema" => "ace.lab.service.ordinary-merge-status-error/v1",
        "code" => code,
        "message" => message,
        "request_id" => REQUEST_ID,
        "input_digest" => nil
      }
    }
  end

  # Deep-mutates a nested document via a path of keys for negative tests.
  # Array segments accept stringified indices ("0").
  def with_deep_value(document, path, value)
    document = deep_dup(document)
    container = document
    path[0...-1].each { |key| container = fetch_segment(container, key) }
    if container.is_a?(Array)
      container[Integer(path.last)] = value
    else
      container[path.last] = value
    end
    document
  end

  def without_deep_key(document, path)
    document = deep_dup(document)
    container = document
    path[0...-1].each { |key| container = fetch_segment(container, key) }
    container.delete(path.last)
    document
  end

  def fetch_segment(container, key)
    key = Integer(key) if container.is_a?(Array)
    container.fetch(key)
  end

  def deep_dup(value)
    case value
    when Hash then value.each_with_object({}) { |(key, item), copy| copy[key] = deep_dup(item) }
    when Array then value.map { |item| deep_dup(item) }
    else value
    end
  end
end
