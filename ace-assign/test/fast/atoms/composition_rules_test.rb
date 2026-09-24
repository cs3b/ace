# frozen_string_literal: true

require_relative "../../test_helper"

class CompositionRulesTest < AceAssignTestCase
  def setup
    @catalog_dir = gem_catalog_dir
    @rules = Ace::Assign::Atoms::CompositionRules.load(@catalog_dir)
  end

  # load tests

  def test_load_returns_hash
    assert_kind_of Hash, @rules
  end

  def test_load_has_ordering_rules
    assert @rules["ordering"]
    assert @rules["ordering"].length >= 1
  end

  def test_load_has_pairs
    assert @rules["pairs"]
    assert @rules["pairs"].length >= 1
  end

  def test_load_does_not_define_a_fixed_review_cycle_limit
    refute @rules.key?("review_cycles")
  end

  def test_load_missing_directory_returns_defaults
    rules = Ace::Assign::Atoms::CompositionRules.load("/nonexistent/path")

    assert_kind_of Hash, rules
    assert_equal [], rules["ordering"]
    assert_equal [], rules["pairs"]
  end

  # validate_ordering tests

  def test_validate_ordering_correct_sequence
    step_names = ["onboard", "work-on-task", "create-pr", "apply-feedback", "review-pr", "update-pr-desc"]
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(step_names, @rules)

    assert_empty violations
  end

  def test_validate_ordering_onboard_not_first
    step_names = ["work-on-task", "onboard", "create-pr"]
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(step_names, @rules)

    onboard_violation = violations.find { |v| v[:rule] == "onboard-first" }
    refute_nil onboard_violation
    assert_match(/onboard.*must be first/, onboard_violation[:message])
  end

  def test_validate_ordering_review_before_pr
    step_names = ["onboard", "review-pr", "create-pr"]
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(step_names, @rules)

    pr_violation = violations.find { |v| v[:rule] == "pr-before-review" }
    refute_nil pr_violation
    assert_match(/create-pr.*must come before.*review-pr/, pr_violation[:message])
  end

  def test_validate_ordering_feedback_after_final_review
    step_names = ["onboard", "create-pr", "review-pr", "apply-feedback"]
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(step_names, @rules)

    review_violation = violations.find { |v| v[:rule] == "apply-before-final-review" }
    refute_nil review_violation
  end

  def test_validate_ordering_feedback_after_review_workflow
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(
      ["create-pr", "review-pr", "apply-feedback-1"], @rules
    )
    assert violations.any? { |violation| violation[:rule] == "apply-before-final-review" }
  end

  def test_validate_ordering_rejects_ready_before_final_review
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(
      ["create-pr", "mark-pr-ready", "review-pr"], @rules
    )
    assert violations.any? { |violation| violation[:rule] == "review-before-ready" }
  end

  def test_validate_ordering_rejects_description_update_after_ready
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(
      ["create-pr", "review-pr", "mark-pr-ready", "update-pr-desc"], @rules
    )
    assert violations.any? { |violation| violation[:rule] == "pr-desc-before-ready" }
  end

  def test_validate_ordering_rejects_merge_before_ready
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(
      ["create-pr", "review-pr", "auto-merge", "mark-pr-ready"], @rules
    )
    assert violations.any? { |violation| violation[:rule] == "ready-before-merge" }
  end

  def test_validate_ordering_rejects_feedback_after_first_matching_review
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(
      ["create-pr", "apply-feedback-1", "review-pr", "apply-feedback-2"], @rules
    )
    assert violations.any? { |violation| violation[:rule] == "apply-before-final-review" }
  end

  def test_validate_ordering_accepts_final_review_after_all_feedback
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(
      ["create-pr", "apply-feedback-1", "review-pr-1", "apply-feedback-2", "review-pr"], @rules
    )
    refute violations.any? { |violation| violation[:rule] == "apply-before-final-review" }
  end

  def test_reflect_verify_cycle_allows_a_second_verification_after_reflection
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(
      ["verify-test-suite", "reflect-and-refactor", "verify-test-suite-2"], @rules
    )
    refute violations.any? { |violation| violation[:rule] == "reflect-after-verify" }
  end

  def test_validate_ordering_pr_description_before_final_review
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(
      ["create-pr", "update-pr-desc", "review-pr"], @rules
    )
    assert violations.any? { |violation| violation[:rule] == "review-before-update-pr" }
  end

  def test_validate_ordering_accepts_refreshed_description_after_final_review
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(
      ["create-pr", "update-pr-desc-early", "review-pr", "update-pr-desc-final"], @rules
    )
    refute violations.any? { |violation| violation[:rule] == "review-before-update-pr" }
  end

  def test_validate_ordering_missing_steps_no_violation
    # Rules only fire when both steps are present
    step_names = ["onboard", "work-on-task"]
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(step_names, @rules)

    assert_empty violations
  end

  def test_validate_ordering_empty_list
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering([], @rules)

    assert_empty violations
  end

  def test_validate_ordering_onboard_first_when_only_step
    step_names = ["onboard"]
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(step_names, @rules)

    assert_empty violations
  end

  def test_validate_ordering_without_onboard_no_violation
    # onboard-first only fires when onboard IS present but not first
    step_names = ["work-on-task", "create-pr"]
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(step_names, @rules)

    assert_empty violations
  end

  def test_validate_ordering_plan_before_onboard
    # plan-task before onboard violates onboard-before-plan
    step_names = ["plan-task", "onboard", "work-on-task"]
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(step_names, @rules)

    onboard_plan_violation = violations.find { |v| v[:rule] == "onboard-before-plan" }
    refute_nil onboard_plan_violation
    assert_match(/onboard.*must come before.*plan-task/, onboard_plan_violation[:message])
  end

  def test_validate_ordering_work_before_plan
    # work-on-task before plan-task violates plan-before-implementation
    step_names = ["onboard", "work-on-task", "plan-task"]
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(step_names, @rules)

    plan_impl_violation = violations.find { |v| v[:rule] == "plan-before-implementation" }
    refute_nil plan_impl_violation
    assert_match(/plan-task.*must come before.*work-on-task/, plan_impl_violation[:message])
  end

  def test_validate_ordering_plan_task_correct_sequence
    # Correct ordering: onboard, plan-task, work-on-task
    step_names = ["onboard", "plan-task", "work-on-task", "create-pr"]
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(step_names, @rules)

    plan_violations = violations.select { |v| v[:rule].include?("plan") }
    assert_empty plan_violations
  end

  # suggest_additions tests

  def test_suggest_additions_does_not_add_feedback_after_final_review
    step_names = ["onboard", "work-on-task", "create-pr", "review-pr"]
    suggestions = Ace::Assign::Atoms::CompositionRules.suggest_additions(step_names, @rules)

    apply_suggestion = suggestions.find { |s| s[:step] == "apply-feedback" }
    assert_nil apply_suggestion
  end

  def test_suggest_additions_pair_complete
    step_names = ["review-pr", "apply-feedback"]
    suggestions = Ace::Assign::Atoms::CompositionRules.suggest_additions(step_names, @rules)

    # review-apply pair is complete, no suggestion needed
    pair_suggestions = suggestions.select { |s| ["review-pr", "apply-feedback"].include?(s[:step]) }
    assert_empty pair_suggestions
  end

  def test_suggest_additions_no_pair_steps
    # No pair members present — only conditional suggestions expected
    step_names = ["onboard"]
    suggestions = Ace::Assign::Atoms::CompositionRules.suggest_additions(step_names, @rules)

    pair_suggestions = suggestions.select { |s| ["review-pr", "apply-feedback"].include?(s[:step]) }
    assert_empty pair_suggestions
  end

  def test_suggest_additions_conditional_pair_skipped
    # verify-test-suite/fix-tests pair is conditional, should not suggest
    step_names = ["verify-test-suite"]
    suggestions = Ace::Assign::Atoms::CompositionRules.suggest_additions(step_names, @rules)

    fix_suggestion = suggestions.find { |s| s[:step] == "fix-tests" }
    assert_nil fix_suggestion
  end

  def test_suggest_additions_empty_list
    suggestions = Ace::Assign::Atoms::CompositionRules.suggest_additions([], @rules)

    assert_empty suggestions
  end

  # conditional suggestion tests

  def test_suggest_additions_conditional_work_on_task_suggests_test_suite
    step_names = ["onboard", "work-on-task", "create-pr"]
    suggestions = Ace::Assign::Atoms::CompositionRules.suggest_additions(step_names, @rules)

    test_suggestion = suggestions.find { |s| s[:step] == "verify-test-suite" }
    refute_nil test_suggestion
    assert_equal "required", test_suggestion[:strength]
  end

  def test_suggest_additions_conditional_fix_bug_suggests_test_suite
    step_names = ["onboard", "fix-bug"]
    suggestions = Ace::Assign::Atoms::CompositionRules.suggest_additions(step_names, @rules)

    test_suggestion = suggestions.find { |s| s[:step] == "verify-test-suite" }
    refute_nil test_suggestion
  end

  def test_suggest_additions_conditional_no_trigger_no_suggestion
    step_names = ["onboard", "research"]
    suggestions = Ace::Assign::Atoms::CompositionRules.suggest_additions(step_names, @rules)

    test_suggestion = suggestions.find { |s| s[:step] == "verify-test-suite" }
    assert_nil test_suggestion
  end

  def test_suggest_additions_conditional_already_included_not_suggested
    step_names = ["onboard", "work-on-task", "verify-test-suite"]
    suggestions = Ace::Assign::Atoms::CompositionRules.suggest_additions(step_names, @rules)

    test_suggestion = suggestions.find { |s| s[:step] == "verify-test-suite" }
    assert_nil test_suggestion
  end

  def test_suggest_additions_conditional_plan_task_with_work
    # "assignment includes work-on-task" should suggest plan-task and mark-task-done
    step_names = ["onboard", "work-on-task", "create-pr"]
    suggestions = Ace::Assign::Atoms::CompositionRules.suggest_additions(step_names, @rules)

    plan_suggestion = suggestions.find { |s| s[:step] == "plan-task" }
    refute_nil plan_suggestion
    assert_equal "recommended", plan_suggestion[:strength]

    done_suggestion = suggestions.find { |s| s[:step] == "mark-task-done" }
    refute_nil done_suggestion
    assert_equal "recommended", done_suggestion[:strength]
  end

  def test_suggest_additions_conditional_plan_task_already_included
    # plan-task already present — should not be suggested
    step_names = ["onboard", "plan-task", "work-on-task"]
    suggestions = Ace::Assign::Atoms::CompositionRules.suggest_additions(step_names, @rules)

    plan_suggestion = suggestions.find { |s| s[:step] == "plan-task" }
    assert_nil plan_suggestion
  end

  # prefix matching tests

  def test_validate_ordering_prefix_match_release_minor
    # "release" rule should match "release-minor" step name
    step_names = ["onboard", "release-minor", "work-on-task"]
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(step_names, @rules)

    release_violation = violations.find { |v| v[:rule] == "release-after-implementation" }
    refute_nil release_violation
    assert_match(/work-on-task.*must come before.*release/, release_violation[:message])
  end

  def test_validate_ordering_prefix_match_correct_order
    step_names = ["onboard", "work-on-task", "release-minor", "create-pr"]
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(step_names, @rules)

    release_violation = violations.find { |v| v[:rule] == "release-after-implementation" }
    assert_nil release_violation
  end

  def test_validate_ordering_prefix_match_release_patch
    # "release" should also match "release-patch-1"
    step_names = ["onboard", "release-patch-1", "work-on-task"]
    violations = Ace::Assign::Atoms::CompositionRules.validate_ordering(step_names, @rules)

    release_violation = violations.find { |v| v[:rule] == "release-after-implementation" }
    refute_nil release_violation
  end

  private

  def gem_catalog_dir
    gem_root = File.expand_path("../../..", __dir__)
    File.join(gem_root, ".ace-defaults", "assign", "catalog")
  end
end
