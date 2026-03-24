# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

class ProgressDisplayManagerTest < Minitest::Test
  ProgressDisplayManager = Ace::Test::EndToEndRunner::Molecules::ProgressDisplayManager
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario
  TestResult = Ace::Test::EndToEndRunner::Models::TestResult

  def setup
    @output = StringIO.new
    @scenarios = [
      create_scenario(test_id: "TS-LINT-001", title: "Basic lint check", package: "ace-lint"),
      create_scenario(test_id: "TS-LINT-002", title: "Advanced lint check", package: "ace-lint")
    ]
    @display = ProgressDisplayManager.new(@scenarios, output: @output, parallel: 2)
  end

  def test_initialize_display_clears_screen_and_renders_waiting_rows
    @display.initialize_display
    out = @output.string

    # ANSI clear screen
    assert_match(/\033\[H\033\[J/, out, "should clear screen")
    # Separator
    assert_match(/E2E Tests: ace-lint/, out, "should show package name")
    assert_match(/2 tests/, out, "should show test count")
    # Waiting rows
    assert_match(/waiting/, out, "should show waiting state for rows")
    # Footer
    assert_match(/Active: 0/, out)
    assert_match(/Completed: 0/, out)
    assert_match(/Waiting: 2/, out)
  end

  def test_test_started_changes_row_to_running
    @display.initialize_display
    @output.truncate(0)
    @output.rewind

    @display.test_started(@scenarios[0])
    out = @output.string

    assert_match(/running/, out, "should show running state")
    assert_match(/Active: 1/, out)
    assert_match(/Waiting: 1/, out)
  end

  def test_test_completed_changes_row_to_completed
    @display.initialize_display
    @display.test_started(@scenarios[0])
    @output.truncate(0)
    @output.rewind

    result = create_result(test_id: "TS-LINT-001", status: "pass", cases: 5)
    @display.test_completed(@scenarios[0], result, 1, 2)
    out = @output.string

    assert_match(/PASS/, out, "should show PASS status")
    assert_match(/Completed: 1/, out)
  end

  def test_test_completed_shows_fail_status
    @display.initialize_display
    @display.test_started(@scenarios[0])
    @output.truncate(0)
    @output.rewind

    result = create_result(test_id: "TS-LINT-001", status: "fail", cases: 3, failed: 1)
    @display.test_completed(@scenarios[0], result, 1, 2)
    out = @output.string

    assert_match(/FAIL/, out, "should show FAIL status")
  end

  def test_refresh_throttles_to_4hz
    @display.initialize_display
    @display.test_started(@scenarios[0])
    @output.truncate(0)
    @output.rewind

    # First refresh after start should produce output (enough time has passed)
    @display.refresh
    refute_empty @output.string, "first refresh should have produced output"

    @output.truncate(0)
    @output.rewind

    # Immediate second refresh should be throttled (no output)
    @display.refresh
    assert_empty @output.string, "second refresh within 250ms should be throttled"
  end

  private

  def create_scenario(test_id:, title: "Test", package: "ace-lint")
    TestScenario.new(
      test_id: test_id,
      title: title,
      area: "lint",
      package: package,
      file_path: "/tmp/#{test_id}scenario.yml",
      content: "# Test content"
    )
  end

  def create_result(test_id:, status:, cases: 0, failed: 0)
    passed = cases - failed
    test_cases = []
    passed.times { |i| test_cases << {id: "TC-#{format("%03d", i + 1)}", status: "pass"} }
    failed.times { |i| test_cases << {id: "TC-#{format("%03d", passed + i + 1)}", status: "fail"} }

    TestResult.new(
      test_id: test_id,
      status: status,
      test_cases: test_cases,
      summary: "#{passed}/#{cases} passed",
      started_at: Time.now - 10,
      completed_at: Time.now
    )
  end
end
