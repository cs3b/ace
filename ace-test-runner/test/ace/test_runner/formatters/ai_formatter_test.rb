# frozen_string_literal: true

require "test_helper"

class AiFormatterTest < Minitest::Test
  def setup
    @formatter = Ace::TestRunner::Formatters::AiFormatter.new(color: false)
  end

  def test_formats_successful_result_for_stdout
    result = Ace::TestRunner::Models::TestResult.new(
      passed: 10,
      failed: 0,
      errors: 0,
      skipped: 0,
      duration: 0.5
    )

    output = @formatter.format_stdout(result)
    assert_includes output, "✅ 10 passed"
    assert_includes output, "All tests passed"
    assert_includes output, "500"  # Duration formatting may vary
  end

  def test_formats_failed_result_for_stdout
    failure = Ace::TestRunner::Models::TestFailure.new(
      test_name: "test_example",
      file_path: "test/example_test.rb",
      line_number: 42
    )

    result = Ace::TestRunner::Models::TestResult.new(
      passed: 8,
      failed: 2,
      errors: 0,
      skipped: 0,
      duration: 1.0,
      failures_detail: [failure]
    )

    output = @formatter.format_stdout(result)
    assert_includes output, "❌ 2 failed"
    assert_includes output, "Tests failed"
    assert_includes output, "example_test.rb:42"
  end

  def test_includes_deprecation_warnings
    result = Ace::TestRunner::Models::TestResult.new(
      passed: 10,
      failed: 0,
      deprecations: ["Warning 1", "Warning 2"]
    )

    output = @formatter.format_stdout(result)
    assert_includes output, "⚠️  2 deprecation warnings"
  end

  def test_formats_report_structure
    result = Ace::TestRunner::Models::TestResult.new(
      passed: 10,
      failed: 2,
      duration: 1.5
    )

    report = Ace::TestRunner::Models::TestReport.new(result: result)
    formatted = @formatter.format_report(report)

    assert formatted.is_a?(Hash)
    assert formatted.key?(:summary)
    assert formatted.key?(:results)
    assert formatted.key?(:environment)
    assert_equal "failure", formatted[:summary][:status]
  end

  def test_on_start_output
    original_stdout = $stdout
    $stdout = StringIO.new

    @formatter.on_start(5)
    output = $stdout.string

    assert_includes output, "Starting test execution"
    assert_includes output, "5 files"
  ensure
    $stdout = original_stdout
  end

  def test_on_test_complete_output
    original_stdout = $stdout
    $stdout = StringIO.new

    @formatter.on_test_complete("test/example_test.rb", true, 0.1)
    output = $stdout.string

    assert_includes output, "✓"
    assert_includes output, "example_test.rb"
    assert_includes output, "100"  # Duration formatting may vary
  ensure
    $stdout = original_stdout
  end
end