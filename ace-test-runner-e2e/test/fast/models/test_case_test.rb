# frozen_string_literal: true

require_relative "../../test_helper"

class TestCaseTest < Minitest::Test
  TestCase = Ace::Test::EndToEndRunner::Models::TestCase

  def test_basic_attributes
    tc = create_test_case
    assert_equal "TC-001", tc.tc_id
    assert_equal "StandardRB Used When Present", tc.title
    assert_equal "# Test content", tc.content
    assert_equal "/tmp/TC-001-standardrb-present.tc.md", tc.file_path
  end

  def test_short_id
    assert_equal "tc001", create_test_case(tc_id: "TC-001").short_id
    assert_equal "tc015", create_test_case(tc_id: "TC-015").short_id
    assert_equal "tc003", create_test_case(tc_id: "TC-003").short_id
  end

  def test_short_id_with_alpha_suffix
    assert_equal "tc001a", create_test_case(tc_id: "TC-001a").short_id
    assert_equal "tc001b", create_test_case(tc_id: "TC-001b").short_id
    assert_equal "tc003c", create_test_case(tc_id: "TC-003c").short_id
  end

  def test_short_id_fallback
    tc = create_test_case(tc_id: "CUSTOM-ID")
    assert_equal "customid", tc.short_id
  end

  def test_not_pending_by_default
    tc = create_test_case
    assert_nil tc.pending
    refute tc.pending?
  end

  def test_goal_format_defaults_to_nil
    tc = create_test_case
    assert_nil tc.goal_format
  end

  def test_standalone_goal_format
    tc = create_test_case(goal_format: "standalone")
    assert_equal "standalone", tc.goal_format
  end

  def test_pending_with_reason
    tc = create_test_case(pending: "Requires sandbox")
    assert_equal "Requires sandbox", tc.pending
    assert tc.pending?
  end

  private

  def create_test_case(overrides = {})
    defaults = {
      tc_id: "TC-001",
      title: "StandardRB Used When Present",
      content: "# Test content",
      file_path: "/tmp/TC-001-standardrb-present.tc.md"
    }
    TestCase.new(**defaults.merge(overrides))
  end
end
