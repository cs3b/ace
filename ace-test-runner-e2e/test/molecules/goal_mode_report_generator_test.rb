# frozen_string_literal: true

require_relative "../test_helper"

class GoalModeReportGeneratorTest < Minitest::Test
  ReportGenerator = Ace::Test::EndToEndRunner::Molecules::GoalModeReportGenerator
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario
  TestCase = Ace::Test::EndToEndRunner::Models::TestCase

  def test_generate_parses_goal_sections_and_writes_tc_first_reports
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      generator = ReportGenerator.new

      result = generator.generate(
        scenario: build_scenario(tmpdir),
        verifier_output: <<~OUT,
          ### Goal 1 - Help Survey
          - **Verdict**: PASS
          - **Evidence**: results/tc/01/help.txt has encode/decode commands

          ### Goal 2 - Roundtrip
          - **Verdict**: FAIL
          - **Category**: tool-bug
          - **Evidence**: decoded date does not match original

          **Results: 1/2 passed**
        OUT
        report_dir: report_dir,
        provider: "claude:haiku",
        started_at: Time.utc(2026, 2, 24, 10, 0, 0),
        completed_at: Time.utc(2026, 2, 24, 10, 1, 0)
      )

      assert_equal "partial", result.status
      assert_equal 2, result.total_count
      assert_equal 1, result.failed_count

      metadata = YAML.safe_load_file(File.join(report_dir, "metadata.yml"))
      assert_equal 1, metadata["tcs-passed"]
      assert_equal 1, metadata["tcs-failed"]
      assert_equal 2, metadata["tcs-total"]
      assert_equal "TC-002", metadata["failed"].first["tc"]
      assert_equal "tool-bug", metadata["failed"].first["category"]

      goal_report = File.read(File.join(report_dir, "report.md"))
      assert_includes goal_report, "runner-provider: claude:haiku"
      assert_includes goal_report, "| TC-002 | FAIL |"
    end
  end

  private

  def build_scenario(tmpdir)
    TestScenario.new(
      test_id: "TS-B36TS-001",
      title: "ace-b36ts Goal-Based E2E Pilot",
      area: "timestamp",
      package: "ace-b36ts",
      file_path: File.join(tmpdir, "scenario.yml"),
      content: "",
      mode: "goal",
      test_cases: [
        TestCase.new(tc_id: "TC-001", title: "Help Survey", content: "", file_path: File.join(tmpdir, "TC-001.runner.md"),
                     mode: "goal", goal_format: "standalone"),
        TestCase.new(tc_id: "TC-002", title: "Roundtrip", content: "", file_path: File.join(tmpdir, "TC-002.runner.md"),
                     mode: "goal", goal_format: "standalone")
      ]
    )
  end
end
