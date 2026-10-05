# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/test_runner/formatters/progress_formatter"
require "ace/test_runner/formatters/progress_file_formatter"

class ProgressReportLinksTest < Minitest::Test
  def test_failure_headers_and_truncation_use_only_actual_saved_reports
    result = Ace::TestRunner::Models::TestResult.new(failed: 2,
      failures_detail: 2.times.map do |index|
        Ace::TestRunner::Models::TestFailure.new(test_name: "test_failure_#{index}", message: "controlled failure")
      end)
    [Ace::TestRunner::Formatters::ProgressFormatter, Ace::TestRunner::Formatters::ProgressFileFormatter].each do |klass|
      [nil, "/reports/exact-execution"].each do |path|
        formatter = klass.new(save_reports: !path.nil?, report_dir: "/unrelated/reports", max_failures_to_display: 1)
        formatter.report_path = path
        output = formatter.format_stdout(result)
        assert_includes output, "1/2"
        assert_includes output, "and 1 more failure"
        refute_includes output, "latest"
        refute_includes output, "/unrelated"
        if path
          assert_includes output, "#{path}/failures.json"
          assert_includes output, "#{path}/failures/001-test_failure_0.md"
        else
          assert_includes output, "No saved report"
          refute_includes output, "failures.json"
          refute_includes output, "→ Details:"
        end
      end
    end
  end
end
