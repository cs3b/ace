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

      assert content.include?("MT-LINT-001"), "Should contain test ID"
      assert content.include?("ace-lint"), "Should contain package name"
      assert content.include?("pass"), "Should contain status"
    end
  end

  def test_summary_report_contains_test_cases
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result(test_cases: [
        { id: "TC-001", description: "Valid file", status: "pass" },
        { id: "TC-002", description: "Style issues", status: "fail" }
      ])

      paths = @writer.write(result, scenario, report_dir: report_dir)
      content = File.read(paths[:summary])

      assert content.include?("TC-001"), "Should contain TC-001"
      assert content.include?("TC-002"), "Should contain TC-002"
      assert content.include?("Valid file"), "Should contain TC-001 description"
    end
  end

  def test_metadata_is_valid_yaml
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      scenario = create_scenario
      result = create_result

      paths = @writer.write(result, scenario, report_dir: report_dir)
      metadata = YAML.safe_load_file(paths[:metadata])

      assert_equal "MT-LINT-001", metadata["test-id"]
      assert_equal "ace-lint", metadata["package"]
      assert_equal "pass", metadata["status"]
      assert_equal 2, metadata["results"]["passed"]
      assert_equal 0, metadata["results"]["failed"]
      assert_equal 2, metadata["results"]["total"]
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

  private

  def create_scenario(overrides = {})
    defaults = {
      test_id: "MT-LINT-001",
      title: "Test Title",
      area: "lint",
      package: "ace-lint",
      file_path: "/tmp/test.mt.md",
      content: "# Test"
    }
    TestScenario.new(**defaults.merge(overrides))
  end

  def create_result(overrides = {})
    defaults = {
      test_id: "MT-LINT-001",
      status: "pass",
      test_cases: [
        { id: "TC-001", description: "First", status: "pass" },
        { id: "TC-002", description: "Second", status: "pass" }
      ],
      summary: "All passed",
      started_at: Time.utc(2026, 2, 6, 12, 0, 0),
      completed_at: Time.utc(2026, 2, 6, 12, 1, 30)
    }
    TestResult.new(**defaults.merge(overrides))
  end
end
