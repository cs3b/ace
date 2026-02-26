# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/task_completion_gate"

class TaskCompletionGateTest < Minitest::Test
  def test_blocks_when_success_criteria_has_unchecked_items
    result = Ace::Taskflow::Molecules::TaskCompletionGate.evaluate(
      content: markdown_with_sections(success_unchecked: 2, validation_unchecked: 0),
      require_success_criteria: true,
      require_validation_questions: false
    )

    assert result[:blocked]
    assert_equal 1, result[:violations].size
    assert_equal "Success Criteria", result[:violations].first[:section]
    assert_equal 2, result[:violations].first[:unresolved_count]
  end

  def test_does_not_block_when_all_success_criteria_items_are_checked
    result = Ace::Taskflow::Molecules::TaskCompletionGate.evaluate(
      content: markdown_with_sections(success_unchecked: 0, validation_unchecked: 0),
      require_success_criteria: true,
      require_validation_questions: false
    )

    refute result[:blocked]
    assert_empty result[:violations]
    assert_empty result[:warnings]
  end

  def test_validation_questions_is_warning_by_default
    result = Ace::Taskflow::Molecules::TaskCompletionGate.evaluate(
      content: markdown_with_sections(success_unchecked: 0, validation_unchecked: 1),
      require_success_criteria: true,
      require_validation_questions: false
    )

    refute result[:blocked]
    assert_empty result[:violations]
    assert_equal 1, result[:warnings].size
    assert_equal "Validation Questions", result[:warnings].first[:section]
  end

  def test_validation_questions_can_be_required
    result = Ace::Taskflow::Molecules::TaskCompletionGate.evaluate(
      content: markdown_with_sections(success_unchecked: 0, validation_unchecked: 1),
      require_success_criteria: true,
      require_validation_questions: true
    )

    assert result[:blocked]
    assert_equal "Validation Questions", result[:violations].first[:section]
  end

  private

  def markdown_with_sections(success_unchecked:, validation_unchecked:)
    success_checked = [2 - success_unchecked, 0].max
    validation_checked = [1 - validation_unchecked, 0].max

    <<~MARKDOWN
      # Sample Task

      ## Success Criteria
      #{(["- [ ] unresolved success"] * success_unchecked).join("\n")}
      #{(["- [x] done success"] * success_checked).join("\n")}

      ## Validation Questions
      #{(["- [ ] unresolved question"] * validation_unchecked).join("\n")}
      #{(["- [x] answered question"] * validation_checked).join("\n")}
    MARKDOWN
  end
end
