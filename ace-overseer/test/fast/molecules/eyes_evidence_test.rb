# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/overseer/molecules/eyes_evidence"

class EyesEvidenceTest < Minitest::Test
  EVIDENCE = Ace::Overseer::Molecules::EyesEvidence

  def setup
    @identity = {"pid" => 123, "started_at" => "linux:01234567-89ab-cdef-0123-456789abcdef:12345"}
    @args = {root: "/lab/ace", process: @identity, prompt: "first turn", required_sources: %w[tasks hitl], now_ms: 20_000}
    @branch = [
      {"type" => "custom", "customType" => "ace-wake-eyes-binding", "data" => {"ownerCwd" => "/lab/ace",
        "process" => {"pid" => 123, "startedAt" => @identity["started_at"]}}},
      {"type" => "message", "timestamp" => "1970-01-01T00:00:10.000Z", "message" => {"role" => "user", "content" => [{"type" => "text", "text" => "first turn"}]}},
      {"type" => "message", "message" => {"role" => "assistant", "stopReason" => "toolUse"}},
      {"type" => "message", "message" => {"role" => "assistant", "stopReason" => "stop"}},
      {"type" => "custom", "customType" => "ace-wake-eyes", "data" => {
        "ownerCwd" => "/lab/ace", "enabled" => true, "retired" => false, "breaker" => nil, "errors" => 0,
        "config" => {"intervalSeconds" => 30, "timeoutMs" => 60_000},
        "observerEvidence" => {"process" => {"pid" => 123, "startedAt" => @identity["started_at"]},
                               "observedAt" => 19_000, "sources" => {"tasks" => "ok", "hitl" => "ok"}}
      }}
    ]
  end

  def ready?(branch = @branch, **overrides)
    EVIDENCE.ready?(branch: branch, **@args.merge(overrides))
  end

  def test_accepts_a_fresh_healthy_observation_after_the_first_turn
    assert ready?
  end

  def test_real_sdk_can_bind_after_the_first_prompt
    binding = @branch.shift
    @branch.insert(1, binding)
    assert ready?
  end

  def test_rejects_an_old_process_stale_observation_or_wrong_project
    refute ready?(process: @identity.merge("started_at" => "linux:01234567-89ab-cdef-0123-456789abcdef:99999"))
    refute ready?(now_ms: 110_000)
    refute ready?(root: "/lab/other")
    refute ready?(process: {})
  end

  def test_rejects_missing_or_degraded_required_sources_and_breakers
    evidence = @branch.last.fetch("data").fetch("observerEvidence")
    evidence["sources"].delete("hitl")
    refute ready?
    evidence["sources"]["hitl"] = "degraded"
    refute ready?
    evidence["sources"]["hitl"] = "ok"
    @branch.last.fetch("data")["breaker"] = {"reason" => "quota"}
    refute ready?
  end

  def test_requires_the_prompt_and_an_assistant_response_in_this_branch
    refute ready?(@branch.drop(1))
    @branch[2]["message"]["stopReason"] = "error"
    refute ready?
    @branch[2]["message"]["stopReason"] = "toolUse"
    @branch[3]["message"]["stopReason"] = "error"
    refute ready?
    @branch[3]["message"]["stopReason"] = "stop"
    @branch.insert(2, {"type" => "message", "message" => {"role" => "user", "content" => "other"}})
    refute ready?
  end

  def test_a_restarted_process_must_observe_again_but_need_not_repeat_the_prompt
    new_identity = @identity.merge("started_at" => "linux:01234567-89ab-cdef-0123-456789abcdef:99999")
    @branch << {"type" => "message", "message" => {"role" => "user", "content" => "later work"}}
    @branch << {"type" => "custom", "customType" => "ace-wake-eyes-binding", "data" => {
      "ownerCwd" => "/lab/ace", "process" => {"pid" => 123, "startedAt" => new_identity["started_at"]}}}
    refute ready?(process: new_identity)
    new_snapshot = Marshal.load(Marshal.dump(@branch[4]))
    new_snapshot.fetch("data").fetch("observerEvidence")["process"]["startedAt"] = new_identity["started_at"]
    @branch << new_snapshot
    assert ready?(process: new_identity)
  end

  def test_a_user_turn_before_initial_eyes_evidence_is_not_initialization_proof
    @branch.insert(-2, {"type" => "message", "message" => {"role" => "user", "content" => "other"}})
    refute ready?
  end

  def test_an_eyes_wake_after_initialization_does_not_invalidate_readiness
    @branch << {"type" => "message", "message" => {"role" => "user", "content" => "[ace-eyes] Pending revisions"}}
    @branch << Marshal.load(Marshal.dump(@branch[4]))
    assert ready?
  end
end
