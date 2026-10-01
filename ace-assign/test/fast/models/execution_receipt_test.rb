# frozen_string_literal: true
require_relative "../../test_helper"

class ExecutionReceiptTest < AceAssignTestCase
  def test_absent_optional_campaign_keeps_the_ordinary_receipt_digest
    payload = {"attempt_id" => "existing-check", "assignment_id" => "assignment", "project_id" => "ace",
      "scope" => "010", "operation" => "test", "producer" => {"actor" => "worker"},
      "head" => "a" * 40, "verdict" => "succeeded", "artifacts" => [], "checks" => [], "review" => nil}
    digest = Ace::Assign::Atoms::EvidenceDigest.digest(payload)
    receipt = Ace::Assign::Models::ExecutionReceipt.from_h(payload.merge("digest" => digest))
    assert_equal payload, receipt.digest_payload
    assert_equal digest, Ace::Assign::Atoms::EvidenceDigest.digest(receipt.digest_payload)
    refute receipt.to_h.key?("campaign")
    campaign = {"id" => "campaign", "result" => {"path" => "result.json", "sha256" => "b" * 64}}
    linked = Ace::Assign::Models::ExecutionReceipt.from_h(payload.merge("campaign" => campaign))
    assert_equal campaign, linked.to_h["campaign"]
    refute_equal digest, linked.digest
  end
end
