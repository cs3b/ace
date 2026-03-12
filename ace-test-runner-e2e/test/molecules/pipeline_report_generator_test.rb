# frozen_string_literal: true

require_relative "../test_helper"

class PipelineReportGeneratorTest < Minitest::Test
  ReportGenerator = Ace::Test::EndToEndRunner::Molecules::PipelineReportGenerator
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
          - **Verdict**: **PASS**
          - **Evidence**: results/tc/01/help.txt has encode/decode commands

          ### Goal 2 - Roundtrip
          - **Verdict**: **FAIL**
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

  def test_generate_accepts_h2_goal_headings_and_category_with_suffix_text
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      generator = ReportGenerator.new

      result = generator.generate(
        scenario: build_scenario(tmpdir),
        verifier_output: <<~OUT,
          ## Goal 1 - Help Survey
          - **Verdict**: PASS
          - **Evidence**: results/tc/01/help.txt has all commands

          ## Goal 2 — Roundtrip
          - **Verdict**: FAIL
          - **Category**: tool-bug - output mismatch on decode
          - **Evidence**: decoded date does not match original
        OUT
        report_dir: report_dir,
        provider: "claude:haiku",
        started_at: Time.utc(2026, 2, 24, 10, 0, 0),
        completed_at: Time.utc(2026, 2, 24, 10, 1, 0)
      )

      assert_equal "partial", result.status

      metadata = YAML.safe_load_file(File.join(report_dir, "metadata.yml"))
      assert_equal "tool-bug", metadata["failed"].first["category"]
    end
  end

  def test_generate_extracts_multiline_evidence_blocks
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      generator = ReportGenerator.new

      result = generator.generate(
        scenario: build_scenario(tmpdir),
        verifier_output: <<~OUT,
          ### Goal 1 - Help Survey
          - **Verdict**: PASS
          - **Evidence**: results/tc/01/help.txt has all commands

          ### Goal 2 - Roundtrip
          - **Verdict**: FAIL
          - **Evidence of failure**:
            - `results/tc/02/dry-run.stdout`: no safe candidates
            - `results/tc/02/prune.stdout`: removed both task.001 and task.002
          - **Category**: test-spec-error
        OUT
        report_dir: report_dir,
        provider: "claude:haiku",
        started_at: Time.utc(2026, 2, 24, 10, 0, 0),
        completed_at: Time.utc(2026, 2, 24, 10, 1, 0)
      )

      assert_equal "partial", result.status

      metadata = YAML.safe_load_file(File.join(report_dir, "metadata.yml"))
      failed = metadata.fetch("failed").first
      assert_equal "TC-002", failed["tc"]
      assert_equal "test-spec-error", failed["category"]
      refute_empty failed["evidence"]
      assert_includes failed["evidence"], "no safe candidates"
      assert_includes failed["evidence"], "removed both task.001 and task.002"
    end
  end

  def test_write_failure_report_creates_deterministic_error_reports
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      generator = ReportGenerator.new
      scenario = build_scenario(tmpdir)

      result = generator.write_failure_report(
        scenario: scenario,
        report_dir: report_dir,
        provider: "claude:haiku",
        started_at: Time.utc(2026, 2, 24, 10, 0, 0),
        completed_at: Time.utc(2026, 2, 24, 10, 1, 0),
        error_message: "RuntimeError: verifier parse failed"
      )

      assert_equal "error", result.status
      assert_equal report_dir, result.report_dir

      metadata = YAML.safe_load_file(File.join(report_dir, "metadata.yml"))
      assert_equal "error", metadata["status"]
      assert_equal "fail", metadata["verdict"]

      summary = File.read(File.join(report_dir, "summary.r.md"))
      assert_includes summary, "RuntimeError: verifier parse failed"
    end
  end

  def test_generate_converts_unstructured_verifier_output_into_error_report
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      generator = ReportGenerator.new

      result = generator.generate(
        scenario: build_scenario(tmpdir),
        verifier_output: <<~OUT,
          I understand the verification format, but no sandbox artifacts were provided.
          Expected paths include results/tc/{NN}/ with stdout, stderr, and exit files.
        OUT
        report_dir: report_dir,
        provider: "claude:haiku",
        started_at: Time.utc(2026, 2, 24, 10, 0, 0),
        completed_at: Time.utc(2026, 2, 24, 10, 1, 0)
      )

      assert_equal "error", result.status
      assert_equal "Verifier returned unstructured output", result.summary

      metadata = YAML.safe_load_file(File.join(report_dir, "metadata.yml"))
      assert_equal "error", metadata["status"]
      assert_equal "fail", metadata["verdict"]

      summary = File.read(File.join(report_dir, "summary.r.md"))
      assert_includes summary, "no sandbox artifacts were provided"
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
      test_cases: [
        TestCase.new(tc_id: "TC-001", title: "Help Survey", content: "", file_path: File.join(tmpdir, "TC-001.runner.md"),
                     goal_format: "standalone"),
        TestCase.new(tc_id: "TC-002", title: "Roundtrip", content: "", file_path: File.join(tmpdir, "TC-002.runner.md"),
                     goal_format: "standalone")
      ]
    )
  end
end
