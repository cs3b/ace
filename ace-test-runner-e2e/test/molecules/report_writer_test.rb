# frozen_string_literal: true

require_relative "../test_helper"

class ReportWriterTest < Minitest::Test
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario
  TestResult = Ace::Test::EndToEndRunner::Models::TestResult

  def setup
    @writer = Ace::Test::EndToEndRunner::Molecules::ReportWriter.new
  end

  def test_write_creates_all_report_files
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result

      paths = @writer.write(result, scenario, report_dir: report_dir)

      assert File.exist?(paths[:summary]), "Summary report should exist"
      assert File.exist?(paths[:experience]), "Experience report should exist"
      assert File.exist?(paths[:metadata]), "Metadata report should exist"
    end
  end

  def test_summary_report_contains_test_info
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result

      paths = @writer.write(result, scenario, report_dir: report_dir)
      content = File.read(paths[:summary])

      assert content.include?("TS-LINT-001"), "Should contain test ID"
      assert content.include?("ace-lint"), "Should contain package name"
      assert content.include?("pass"), "Should contain status"
    end
  end

  def test_experience_report_status_is_complete_when_pass
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result(status: "pass")

      paths = @writer.write(result, scenario, report_dir: report_dir)
      content = File.read(paths[:experience])

      assert_match(/^status: complete$/, content.lines.find { |line| line.start_with?("status:") }.to_s.rstrip)
    end
  end

  def test_experience_report_status_is_incomplete_when_not_pass
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result(status: "partial")

      paths = @writer.write(result, scenario, report_dir: report_dir)
      content = File.read(paths[:experience])

      assert_match(/^status: incomplete$/, content.lines.find { |line| line.start_with?("status:") }.to_s.rstrip)
    end
  end

  def test_experience_report_status_is_incomplete_when_error
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result(status: "error", error: "provider failure")

      paths = @writer.write(result, scenario, report_dir: report_dir)
      content = File.read(paths[:experience])

      assert_match(/^status: incomplete$/, content.lines.find { |line| line.start_with?("status:") }.to_s.rstrip)
    end
  end

  def test_summary_report_contains_test_cases
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result(test_cases: [
        {id: "TC-001", description: "Valid file", status: "pass"},
        {id: "TC-002", description: "Style issues", status: "fail"}
      ])

      paths = @writer.write(result, scenario, report_dir: report_dir)
      content = File.read(paths[:summary])

      assert content.include?("TC-001"), "Should contain TC-001"
      assert content.include?("TC-002"), "Should contain TC-002"
      assert content.include?("Valid file"), "Should contain TC-001 description"
    end
  end

  def test_summary_report_contains_goal_criteria_section_when_present
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result(test_cases: [
        {
          id: "TC-001",
          description: "Goal mode case",
          status: "pass",
          criteria: [
            {description: "Artifact exists", status: "pass", evidence: "results/tc/01/output.txt"}
          ]
        }
      ])

      paths = @writer.write(result, scenario, report_dir: report_dir)
      content = File.read(paths[:summary])

      assert content.include?("## Goal Evaluation"), "Should contain goal evaluation section"
      assert content.include?("Artifact exists"), "Should contain criterion description"
      assert content.include?("results/tc/01/output.txt"), "Should contain criterion evidence"
    end
  end

  def test_metadata_is_valid_yaml
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result

      paths = @writer.write(result, scenario, report_dir: report_dir)
      metadata = YAML.safe_load_file(paths[:metadata])

      assert_equal "TS-LINT-001", metadata["test-id"]
      assert_equal "ace-lint", metadata["package"]
      assert_equal "pass", metadata["status"]
      assert_equal 2, metadata["tcs-passed"]
      assert_equal 0, metadata["tcs-failed"]
      assert_equal 2, metadata["tcs-total"]
      assert_equal 2, metadata["results"]["passed"]
      assert_equal 0, metadata["results"]["failed"]
      assert_equal 2, metadata["results"]["total"]
    end
  end

  def test_metadata_includes_empty_failed_test_cases_when_all_pass
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result(status: "pass", test_cases: [
        {id: "TC-001", description: "First", status: "pass"},
        {id: "TC-002", description: "Second", status: "pass"}
      ])

      paths = @writer.write(result, scenario, report_dir: report_dir)
      metadata = YAML.safe_load_file(paths[:metadata])

      assert_equal [], metadata["failed_test_cases"]
    end
  end

  def test_metadata_includes_failed_test_case_ids
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result(status: "fail", test_cases: [
        {id: "TC-001", description: "Valid file", status: "pass"},
        {id: "TC-002", description: "Style issues", status: "fail"},
        {id: "TC-003", description: "Syntax errors", status: "fail"}
      ])

      paths = @writer.write(result, scenario, report_dir: report_dir)
      metadata = YAML.safe_load_file(paths[:metadata])

      assert_equal ["TC-002", "TC-003"], metadata["failed_test_cases"]
    end
  end

  def test_metadata_failed_test_cases_with_empty_test_cases
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result(test_cases: [])

      paths = @writer.write(result, scenario, report_dir: report_dir)
      metadata = YAML.safe_load_file(paths[:metadata])

      assert_equal [], metadata["failed_test_cases"]
    end
  end

  def test_creates_report_directory
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "nested", "reports")
      refute Dir.exist?(report_dir)

      @writer.write(create_result, create_scenario, report_dir: report_dir)
      assert Dir.exist?(report_dir), "Should create nested report directory"
    end
  end

  # --- Per-TC Reports ---

  def test_write_with_test_case_includes_tc_id_in_summary
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario(test_id: "TS-LINT-001")
      tc = create_test_case(tc_id: "TC-001", title: "StandardRB Check")
      result = create_result(test_id: "TS-LINT-001")

      paths = @writer.write(result, scenario, report_dir: report_dir, test_case: tc)
      content = File.read(paths[:summary])

      assert content.include?("tc-id: TC-001"), "Summary should contain tc-id in frontmatter"
    end
  end

  def test_write_with_test_case_includes_scenario_id_in_summary
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario(test_id: "TS-LINT-001")
      tc = create_test_case
      result = create_result(test_id: "TS-LINT-001")

      paths = @writer.write(result, scenario, report_dir: report_dir, test_case: tc)
      content = File.read(paths[:summary])

      assert content.include?("scenario-id: TS-LINT-001"), "Summary should contain scenario-id in frontmatter"
    end
  end

  def test_write_with_test_case_includes_tc_title_in_summary
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario(test_id: "TS-LINT-001")
      tc = create_test_case(tc_id: "TC-001", title: "StandardRB Present")
      result = create_result(test_id: "TS-LINT-001")

      paths = @writer.write(result, scenario, report_dir: report_dir, test_case: tc)
      content = File.read(paths[:summary])

      assert content.include?("StandardRB Present"), "Summary should contain TC title"
    end
  end

  def test_write_with_test_case_metadata_includes_tc_id
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario(test_id: "TS-LINT-001")
      tc = create_test_case(tc_id: "TC-002")
      result = create_result(test_id: "TS-LINT-001")

      paths = @writer.write(result, scenario, report_dir: report_dir, test_case: tc)
      metadata = YAML.safe_load_file(paths[:metadata])

      assert_equal "TC-002", metadata["tc-id"]
    end
  end

  def test_write_with_test_case_metadata_includes_scenario_id
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario(test_id: "TS-LINT-001")
      tc = create_test_case
      result = create_result(test_id: "TS-LINT-001")

      paths = @writer.write(result, scenario, report_dir: report_dir, test_case: tc)
      metadata = YAML.safe_load_file(paths[:metadata])

      assert_equal "TS-LINT-001", metadata["scenario-id"]
    end
  end

  def test_write_without_test_case_unchanged
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result

      paths = @writer.write(result, scenario, report_dir: report_dir)
      metadata = YAML.safe_load_file(paths[:metadata])

      assert_nil metadata["tc-id"]
      assert_nil metadata["scenario-id"]
    end
  end

  def test_write_creates_all_files_with_test_case
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario(test_id: "TS-LINT-001")
      tc = create_test_case
      result = create_result(test_id: "TS-LINT-001")

      paths = @writer.write(result, scenario, report_dir: report_dir, test_case: tc)

      assert File.exist?(paths[:summary])
      assert File.exist?(paths[:experience])
      assert File.exist?(paths[:metadata])
    end
  end

  private

  def create_scenario(overrides = {})
    defaults = {
      test_id: "TS-LINT-001",
      title: "Test Title",
      area: "lint",
      package: "ace-lint",
      file_path: "/tmp/test/scenario.yml",
      content: "# Test"
    }
    TestScenario.new(**defaults.merge(overrides))
  end

  def create_result(overrides = {})
    defaults = {
      test_id: "TS-LINT-001",
      status: "pass",
      test_cases: [
        {id: "TC-001", description: "First", status: "pass"},
        {id: "TC-002", description: "Second", status: "pass"}
      ],
      summary: "All passed",
      started_at: Time.utc(2026, 2, 6, 12, 0, 0),
      completed_at: Time.utc(2026, 2, 6, 12, 1, 30)
    }
    TestResult.new(**defaults.merge(overrides))
  end

  def create_test_case(overrides = {})
    defaults = {
      tc_id: "TC-001",
      title: "Test Case Title",
      content: "## Objective\n\nVerify something.",
      file_path: "/tmp/test/TC-001-test-case.tc.md"
    }
    Ace::Test::EndToEndRunner::Models::TestCase.new(**defaults.merge(overrides))
  end
end
