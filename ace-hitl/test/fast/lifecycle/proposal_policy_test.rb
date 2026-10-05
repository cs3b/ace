# frozen_string_literal: true
require "test_helper"
require "ace/hitl/lifecycle/store"

class ProposalPolicyTest < AceHitlTestCase
  Policy = Ace::Hitl::Proposals::Policy

  def record
    {"proposal_id" => "proposal-#{'a' * 24}", "request_id" => "proposal-#{'a' * 24}-r1",
     "revision_id" => "proposal-#{'a' * 24}-r1", "state" => "awaiting-delivery"}
  end

  def checkpoint(value)
    {"schema" => "ace.hitl.hermes.ingress-checkpoint/v1", "request" => value["request_id"],
     "revision" => value["revision_id"], "healthy" => true, "drained" => true,
     "checkpoint" => {"through" => value["deadline"], "sequence" => 0}}
  end

  def test_sixteen_hours_are_measured_from_acknowledgement
    value = Policy.acknowledge(record, "2026-10-05T01:00:00Z")
    assert_equal "2026-10-05T17:00:00Z", value["deadline"]
    assert_equal "awaiting-decision", Policy.resolve(value, checkpoint: checkpoint(value), now: "2026-10-05T16:59:59Z")["state"]
    assert_equal "approved-by-silence", Policy.resolve(value, checkpoint: checkpoint(value), now: value["deadline"])["state"]
    assert_equal "approved-by-silence", Policy.resolve(value, checkpoint: checkpoint(value), now: "2026-10-06T01:00:00Z")["state"]
    assert_equal record, Policy.resolve(record, checkpoint: {}, now: "2026-10-06T01:00:00Z")
  end

  def test_unknown_backlog_and_wrong_revision_cannot_authorize
    value = Policy.acknowledge(record, "2026-10-05T01:00:00Z")
    [{"healthy" => false}, {"drained" => false}, {"revision" => "wrong"}, {"checkpoint" => nil}].each do |change|
      assert_equal value, Policy.resolve(value, checkpoint: checkpoint(value).merge(change), now: value["deadline"])
    end
  end

  def test_reply_and_late_veto_do_not_rewrite_claimed_effect
    value = Policy.acknowledge(record, "2026-10-05T01:00:00Z")
    reply = ->(body, claimed) { Policy.reply(value, answer: body, received_at: "2026-10-05T02:00:00Z", sequence: 1, claimed: claimed) }
    assert_equal "approved-explicitly", reply.call("approve tested", false)["state"]
    assert_equal "tested", reply.call("approve tested", false)["captain_rationale"]
    refute reply.call("veto", false).key?("captain_rationale")
    assert_equal "denied", reply.call("veto", false)["state"]
    assert_equal "superseded", reply.call("clarify scope", false)["state"]
    assert_equal "superseded", reply.call("use a different target", false)["state"]
    result = reply.call("veto", true)
    assert_equal value["state"], result["state"]
    assert result["stop_requested"]
  end

  def test_all_precisely_presented_operation_classes_are_eligible
    %w[publish deploy access privilege-expansion merge].each do |operation|
      content = {"operation" => operation, "target" => {"resource" => "production"},
        "candidate_head" => "a" * 40, "input_digest" => "b" * 64, "context" => "Exact change",
        "options" => ["proceed", "decline"], "recommendation" => "proceed", "prerequisites" => ["tests", "review", "OTP when publisher requests"]}
      assert_equal operation, Policy.document(content)["operation"]
      value = Policy.acknowledge(record.merge(content), "2026-10-05T01:00:00Z")
      assert_equal "approved-by-silence", Policy.resolve(value, checkpoint: checkpoint(value), now: value["deadline"])["state"]
    end
  end
end
