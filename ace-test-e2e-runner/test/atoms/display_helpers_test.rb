# frozen_string_literal: true

require_relative "../test_helper"

class DisplayHelpersTest < Minitest::Test
  DisplayHelpers = Ace::Test::EndToEndRunner::Atoms::DisplayHelpers
  TestResult = Ace::Test::EndToEndRunner::Models::TestResult

  def test_status_icon_pass
    assert_equal "\u2713", DisplayHelpers.status_icon(true)
  end

  def test_status_icon_fail
    assert_equal "\u2717", DisplayHelpers.status_icon(false)
  end

  def test_format_elapsed_short
    assert_equal "  1.5s", DisplayHelpers.format_elapsed(1.5)
  end

  def test_format_elapsed_long
    assert_equal " 35.4s", DisplayHelpers.format_elapsed(35.4)
  end

  def test_format_elapsed_zero
    assert_equal "  0.0s", DisplayHelpers.format_elapsed(0)
  end

  def test_format_duration_under_60
    assert_equal "10.70s", DisplayHelpers.format_duration(10.7)
  end

  def test_format_duration_over_60
    assert_equal "1m 50s", DisplayHelpers.format_duration(110)
  end

  def test_format_duration_exact_minute
    assert_equal "2m 0s", DisplayHelpers.format_duration(120)
  end

  def test_tc_count_display_with_cases
    result = TestResult.new(
      test_id: "MT-TEST-001",
      status: "fail",
      test_cases: [
        { id: "TC-001", status: "pass" },
        { id: "TC-002", status: "fail" }
      ]
    )

    assert_equal "  1/2 cases", DisplayHelpers.tc_count_display(result)
  end

  def test_tc_count_display_no_cases
    result = TestResult.new(test_id: "MT-TEST-001", status: "error")

    assert_equal "", DisplayHelpers.tc_count_display(result)
  end

  def test_separator
    assert_equal "=" * 65, DisplayHelpers.separator
  end

  def test_color_with_color_enabled
    result = DisplayHelpers.color("hello", :green, use_color: true)
    assert_equal "\033[32mhello\033[0m", result
  end

  def test_color_with_color_disabled
    result = DisplayHelpers.color("hello", :green, use_color: false)
    assert_equal "hello", result
  end

  def test_color_red
    result = DisplayHelpers.color("fail", :red, use_color: true)
    assert_equal "\033[31mfail\033[0m", result
  end
end
