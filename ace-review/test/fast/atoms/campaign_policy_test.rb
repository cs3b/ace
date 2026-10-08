# frozen_string_literal: true
require "test_helper"
require "ace/review/atoms/campaign_policy"

class CampaignPolicyTest < AceReviewTest
  Policy = Ace::Review::Atoms::CampaignPolicy

  def decision(profile: "delivery", rounds: 3, streak: 2, phase_rounds: rounds, accepted: false, **options)
    Policy.decision(profile: profile, bounds: Policy.bounds!(profile: profile, policy: {}),
      phase_rounds: phase_rounds, completed_rounds: rounds, clean_streak: streak, accepted: accepted, **options)
  end

  def test_discovery_exports_known_defects_at_two_and_never_accepts
    assert_equal "in_progress", decision(profile: "discovery", rounds: 1, streak: 0)["outcome"]
    result = decision(profile: "discovery", rounds: 2, streak: 0, accepted: true)
    assert_equal "discovery_complete", result["outcome"]
    refute result["accepted"]
    refute result["search_converged"]
    assert_equal "execution_failed", decision(profile: "discovery", rounds: 1, streak: 0, execution_failure: "authentication")["outcome"]
  end

  def test_search_threshold_and_current_acceptance_are_independent
    assert_equal "in_progress", decision(rounds: 2)["outcome"]
    assert_equal "search_converged", decision["outcome"]
    assert_equal "accepted", decision(accepted: true)["outcome"]
    refute decision(rounds: 3, streak: 1, accepted: true)["accepted"]
    assert_equal "execution_failed", decision(accepted: true, execution_failure: "authorization")["outcome"]
    assert_equal "needs_diagnosis", decision(accepted: true, recurrence: true)["outcome"]
    assert_equal "needs_escalation", decision(rounds: 5)["outcome"]
    assert_equal "accepted", decision(rounds: 5, accepted: true)["outcome"]
  end

  def test_recurrence_stops_equivalent_review_and_resume_retains_lifetime_counts
    assert_equal "needs_diagnosis", decision(recurrence: true)["outcome"]
    result = decision(rounds: 6, phase_rounds: 1)
    assert_equal 4, result["remaining_rounds"]
    assert_equal "search_converged", result["outcome"]
  end

  def test_invalid_or_weakened_profile_budget_refuses_before_execution
    assert_raises(ArgumentError) { Policy.bounds!(profile: "unknown", policy: {}) }
    [{"minimum_rounds" => 2}, {"clean_rounds" => 1}, {"maximum_rounds" => 6},
      {"minimum_rounds" => 6}, {"maximum_rounds" => 0}].each do |policy|
      assert_raises(ArgumentError) { Policy.bounds!(profile: "delivery", policy: policy) }
    end
    assert_equal 4, Policy.bounds!(profile: "delivery", policy: {"minimum_rounds" => 4})["minimum_rounds"]
  end

  def finding(id:, source:, priority: "high", disposition: "open", **extra)
    {"id" => id, "source_id" => source, "priority" => priority,
      "disposition" => disposition, "observed_in_round" => true}.merge(extra.transform_keys(&:to_s))
  end

  def test_severity_correction_recomputes_sequence_but_repair_does_not_rewrite_high
    high = finding(id: "defect", source: "source-one")
    attempts = [{"attempt_id" => "one", "assessments" => [high]},
      {"attempt_id" => "two", "assessments" => []}, {"attempt_id" => "three", "assessments" => []}]
    record = {"rounds" => attempts, "attempts" => attempts, "assessments" => [high]}
    assert_equal 2, Policy.clean_streak(record)
    record["assessments"] << high.merge("disposition" => "resolved", "observed_in_round" => false)
    assert_equal 2, Policy.clean_streak(record)
    record["assessments"] << high.merge("kind" => "severity_correction", "priority" => "medium")
    assert_equal 3, Policy.clean_streak(record)
    assert_equal 3, record["rounds"].size
  end

  def test_canonical_issue_retains_independent_sources_and_empty_report_cannot_close_it
    first = finding(id: "defect", source: "independent-one")
    duplicate = finding(id: "defect", source: "independent-two")
    record = {"inherited_findings" => [], "assessments" => [first, duplicate]}
    result = Policy.canonical_findings(record)
    assert_equal 1, result.size
    assert_equal %w[independent-one independent-two], result.first.fetch("sources").map { |item| item["source_id"] }
    assert_equal "open", result.first["disposition"]
    inherited = {"inherited_findings" => result, "assessments" => []}
    assert_equal 2, Policy.canonical_findings(inherited).first.fetch("sources").size
    assert_equal [], Policy.recurring_blockers(record)
    record["assessments"] << first.merge("kind" => "repair_attempt", "observed_in_round" => false)
    record["assessments"] << duplicate
    assert_equal [], Policy.recurring_blockers(record)
    record["assessments"] << finding(id: "defect", source: "independent-three")
    assert_equal "defect", Policy.recurring_blockers(record).first["finding_id"]
    record["assessments"] << duplicate.merge("disposition" => "resolved", "observed_in_round" => false)
    assert_equal [], Policy.recurring_blockers(record)
  end

  def test_explicit_phase_replay_retains_exhausted_phase_and_never_restarts_budget
    exhausted = {"id" => "initial", "profile" => "delivery", "round_start" => 0, "maximum_rounds" => 5}
    record = {"profile" => "delivery", "rounds" => Array.new(5) { {} }, "phases" => [exhausted]}
    args = {record: record, phase_id: "follow-up", reason: "verified repair needs current evidence", route: "review", additional_rounds: 2}
    phase = Policy.next_phase(**args)
    assert_equal 5, phase["round_start"]
    assert_equal 2, phase["maximum_rounds"]
    assert_equal [exhausted], record["phases"]
    record["phases"] << phase
    record["rounds"] << {}
    assert_same phase, Policy.next_phase(**args)
    assert_raises(ArgumentError) { Policy.next_phase(**args.merge(additional_rounds: 3)) }
    assert_raises(ArgumentError) { Policy.next_phase(**args.merge(reason: "")) }
    assert_raises(ArgumentError) { Policy.next_phase(**args.merge(additional_rounds: 0)) }
  end

  def retry_decision(attempts)
    Policy.retry_decision(attempts: attempts, round_id: "r1", scope: "full", provider: "selected")
  end

  def attempt(status, failure = nil, provider: "selected")
    {"round_id" => "r1", "scope" => "full", "provider" => provider, "status" => status, "failure" => failure}
  end

  def test_initial_plus_two_retries_are_bounded_per_provider_and_scope
    failures = Array.new(3) { attempt("failed", "timeout") }
    assert_equal "execute", retry_decision(failures.take(2))["next_action"]
    assert_equal "retries_exhausted", retry_decision(failures)["next_action"]
    assert_equal 0, retry_decision(failures)["remaining_attempts"]
    assert_equal "execute", retry_decision([attempt("failed", "timeout", provider: "other")])["next_action"]
  end

  def test_terminal_unknown_and_completed_attempts_never_retry
    Policy::TERMINAL_FAILURES.each do |failure|
      assert_equal "terminal_failure", retry_decision([attempt("failed", failure)])["next_action"]
    end
    %w[running uncertain].each do |status|
      assert_equal "resolve_original_attempt", retry_decision([attempt(status)])["next_action"]
    end
    assert_equal "already_completed", retry_decision([attempt("succeeded")])["next_action"]
    assert_raises(ArgumentError) { retry_decision([attempt("failed", "guessed-from-text")]) }
  end
end
