# frozen_string_literal: true

require_relative "../../test_helper"

class VerificationResultTest < AceDemoTestCase
  def test_exposes_success_status_and_details
    result = Ace::Demo::Models::VerificationResult.new(
      success: true,
      status: "pass",
      commands_found: ["echo hi"],
      commands_missing: [],
      details: {inputs_recorded: 1},
      classification: "pass",
      summary: "Verification passed",
      retryable: false
    )

    assert_equal true, result.success?
    assert_equal "pass", result.status
    assert_equal ["echo hi"], result.commands_found
    assert_equal [], result.commands_missing
    assert_equal "pass", result.classification
    assert_equal "Verification passed", result.summary
    assert_equal false, result.retryable?
    assert_equal 1, result.details[:inputs_recorded]
  end
end
