require_relative "../../test_helper"
require "ace/assign/molecules/evidence_calculator"

class EvidenceCalculatorTest < AceAssignTestCase
  def test_calculate_returns_required_evidence_fields
    evidence = Ace::Assign::Molecules::EvidenceCalculator.calculate(pr_number: 42, auto_merge: false)

    assert evidence[:head]
    assert evidence[:tree]
    assert evidence[:changed_scope_digest]
    assert_includes %w[current stale missing], evidence[:review_receipt]
    assert_includes %w[current stale missing], evidence[:release_receipt]
    assert_includes %w[terminal open unknown], evidence[:feedback_state]
    assert_equal "report-only", evidence[:merge_decision]
    assert evidence[:decision_digest]
  end

  def test_auto_merge_authorizes_when_all_receipts_current
    calc = Ace::Assign::Molecules::EvidenceCalculator.new
    calc.stub(:evaluate_review_receipt, "current") do
      calc.stub(:evaluate_release_receipt, "current") do
        evidence = calc.calculate(pr_number: 42, auto_merge: true)
        assert_equal "authorized", evidence[:merge_decision]
      end
    end
  end

  def test_auto_merge_downgrades_to_approval_required_when_stale
    calc = Ace::Assign::Molecules::EvidenceCalculator.new
    calc.stub(:evaluate_review_receipt, "stale") do
      evidence = calc.calculate(pr_number: 42, auto_merge: true)
      assert_equal "approval-required", evidence[:merge_decision]
    end
  end
end
