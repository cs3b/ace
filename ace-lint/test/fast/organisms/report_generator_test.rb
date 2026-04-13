# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "fileutils"
require "json"

class Ace::Lint::Organisms::ReportGeneratorTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir("report_generator_test")
  end

  def teardown
    FileUtils.remove_entry(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  def test_generate_creates_report_directory
    results = [create_passed_result]

    result = Ace::Lint::Organisms::ReportGenerator.generate(
      results,
      project_root: @temp_dir
    )

    assert result[:success]
    assert Dir.exist?(result[:dir])
    assert result[:dir].include?(".ace-local/lint/")
  end

  def test_generate_creates_json_file
    results = [create_passed_result]

    result = Ace::Lint::Organisms::ReportGenerator.generate(
      results,
      project_root: @temp_dir
    )

    assert result[:success]
    report_path = File.join(result[:dir], "report.json")
    assert File.exist?(report_path)

    content = JSON.parse(File.read(report_path))
    assert_kind_of Hash, content
  end

  def test_report_includes_metadata
    results = [create_passed_result]

    result = Ace::Lint::Organisms::ReportGenerator.generate(
      results,
      project_root: @temp_dir,
      options: {fix: true, validators: [:standardrb]}
    )

    report_path = File.join(result[:dir], "report.json")
    content = JSON.parse(File.read(report_path))
    metadata = content["report_metadata"]

    assert_includes metadata.keys, "generated_at"
    assert_includes metadata.keys, "compact_id"
    assert_includes metadata.keys, "ace_lint_version"
    assert_includes metadata.keys, "scan_options"

    # Verify compact_id format (6 characters, alphanumeric)
    assert_match(/\A[0-9a-z]{6}\z/, metadata["compact_id"])

    # Verify version
    assert_equal Ace::Lint::VERSION, metadata["ace_lint_version"]
  end

  def test_report_includes_summary
    results = [
      create_passed_result,
      create_failed_result,
      create_formatted_result,
      create_skipped_result
    ]

    result = Ace::Lint::Organisms::ReportGenerator.generate(
      results,
      project_root: @temp_dir
    )

    report_path = File.join(result[:dir], "report.json")
    content = JSON.parse(File.read(report_path))
    summary = content["summary"]

    assert_equal 4, summary["total_files"]
    assert_equal 3, summary["scanned"]  # 4 total - 1 skipped
    assert_equal 1, summary["skipped"]
    assert_equal 1, summary["fixed"]
    assert_equal 1, summary["failed"]
    assert_equal 1, summary["passed"]
    assert_equal 2, summary["total_errors"]  # failed result has 2 errors
    assert_equal 0, summary["total_warnings"]
  end

  def test_report_categorizes_results
    results = [
      create_passed_result,
      create_failed_result,
      create_formatted_result,
      create_skipped_result,
      create_warnings_only_result
    ]

    result = Ace::Lint::Organisms::ReportGenerator.generate(
      results,
      project_root: @temp_dir
    )

    report_path = File.join(result[:dir], "report.json")
    content = JSON.parse(File.read(report_path))
    categorized = content["results"]

    assert_equal 1, categorized["fixed"].length
    assert_equal 1, categorized["failed"].length
    assert_equal 1, categorized["warnings_only"].length
    assert_equal 1, categorized["passed"].length
    assert_equal 1, categorized["skipped"].length
  end

  def test_compact_id_format
    results = [create_passed_result]

    result = Ace::Lint::Organisms::ReportGenerator.generate(
      results,
      project_root: @temp_dir
    )

    # Extract compact_id from dir path
    # Path format: .ace-local/lint/{compact_id}
    compact_id = File.basename(result[:dir])

    # Should be 6 character alphanumeric
    assert_match(/\A[0-9a-z]{6}\z/, compact_id)
  end

  def test_build_summary_counts_correctly
    results = [
      create_passed_result,
      create_formatted_result,
      create_failed_result
    ]

    summary = Ace::Lint::Organisms::ReportGenerator.build_summary(results)

    assert_equal 3, summary[:total_files]
    assert_equal 3, summary[:scanned]
    assert_equal 0, summary[:skipped]
    assert_equal 1, summary[:fixed]
    assert_equal 1, summary[:failed]
    assert_equal 1, summary[:passed]
  end

  def test_categorize_results_correctly
    results = [
      create_passed_result,
      create_formatted_result,
      create_failed_result,
      create_skipped_result
    ]

    categorized = Ace::Lint::Organisms::ReportGenerator.categorize_results(results)

    assert_equal 1, categorized[:passed].length
    assert_equal 1, categorized[:fixed].length
    assert_equal 1, categorized[:failed].length
    assert_equal 1, categorized[:skipped].length
  end

  def test_sanitize_options_filters_correctly
    options = {
      fix: true,
      format: false,
      type: :ruby,
      validators: [:standardrb, :rubocop],
      some_internal_option: "should_not_appear"
    }

    sanitized = Ace::Lint::Organisms::ReportGenerator.sanitize_options(options)

    assert_equal true, sanitized[:fix]
    assert_equal false, sanitized[:format]  # false values preserved (user choice)
    assert_equal "ruby", sanitized[:type]
    assert_equal %w[standardrb rubocop], sanitized[:validators]
    refute_includes sanitized.keys, :some_internal_option
  end

  def test_generate_handles_errors_gracefully
    # Use an invalid path that cannot be created
    result = Ace::Lint::Organisms::ReportGenerator.generate(
      [create_passed_result],
      project_root: "/nonexistent/path/that/should/fail"
    )

    refute result[:success]
    assert_includes result.keys, :error
  end

  # Tests for new markdown report generation

  def test_generates_ok_md_for_passed_files
    results = [create_passed_result]

    result = Ace::Lint::Organisms::ReportGenerator.generate(
      results,
      project_root: @temp_dir
    )

    assert result[:success]
    assert result[:files].key?(:ok)
    assert_equal 1, result[:files][:ok][:count]

    ok_path = File.join(result[:dir], "ok.md")
    assert File.exist?(ok_path)

    content = File.read(ok_path)
    assert_includes content, "# Lint: Passed Files"
    assert_includes content, "lib/passed.rb"
  end

  def test_generates_fixed_md_for_formatted_files
    results = [create_formatted_result]

    result = Ace::Lint::Organisms::ReportGenerator.generate(
      results,
      project_root: @temp_dir
    )

    assert result[:success]
    assert result[:files].key?(:fixed)
    assert_equal 1, result[:files][:fixed][:count]

    fixed_path = File.join(result[:dir], "fixed.md")
    assert File.exist?(fixed_path)

    content = File.read(fixed_path)
    assert_includes content, "# Lint: Auto-Fixed Files"
    assert_includes content, "lib/formatted.rb"
  end

  def test_generates_pending_md_for_files_with_issues
    results = [create_failed_result, create_warnings_only_result]

    result = Ace::Lint::Organisms::ReportGenerator.generate(
      results,
      project_root: @temp_dir
    )

    assert result[:success]
    assert result[:files].key?(:pending)
    # 2 errors + 1 warning = 3 issues
    assert_equal 3, result[:files][:pending][:count]

    pending_path = File.join(result[:dir], "pending.md")
    assert File.exist?(pending_path)

    content = File.read(pending_path)
    assert_includes content, "# Lint: Pending Issues"
    assert_includes content, "## lib/failed.rb"
    assert_includes content, "## lib/warnings.rb"
    assert_includes content, "- [ ]"  # Checkboxes present
  end

  def test_does_not_generate_ok_md_when_no_passed_files
    results = [create_failed_result]

    result = Ace::Lint::Organisms::ReportGenerator.generate(
      results,
      project_root: @temp_dir
    )

    assert result[:success]
    refute result[:files].key?(:ok)
    refute File.exist?(File.join(result[:dir], "ok.md"))
  end

  def test_does_not_generate_fixed_md_when_no_formatted_files
    results = [create_passed_result]

    result = Ace::Lint::Organisms::ReportGenerator.generate(
      results,
      project_root: @temp_dir
    )

    assert result[:success]
    refute result[:files].key?(:fixed)
    refute File.exist?(File.join(result[:dir], "fixed.md"))
  end

  def test_does_not_generate_pending_md_when_no_issues
    results = [create_passed_result]

    result = Ace::Lint::Organisms::ReportGenerator.generate(
      results,
      project_root: @temp_dir
    )

    assert result[:success]
    refute result[:files].key?(:pending)
    refute File.exist?(File.join(result[:dir], "pending.md"))
  end

  def test_pending_md_groups_issues_by_file
    results = [create_failed_result]

    result = Ace::Lint::Organisms::ReportGenerator.generate(
      results,
      project_root: @temp_dir
    )

    pending_path = File.join(result[:dir], "pending.md")
    content = File.read(pending_path)

    # Should have file header with issue count
    assert_includes content, "## lib/failed.rb (2 issues)"
    # Should have checkboxes for each error
    assert_includes content, "- [ ] Line 10: Line too long"
    assert_includes content, "- [ ] Line 20: Missing semicolon"
  end

  private

  def create_passed_result
    Ace::Lint::Models::LintResult.new(
      file_path: "lib/passed.rb",
      success: true,
      errors: [],
      warnings: [],
      formatted: false,
      skipped: false,
      runner: :standardrb
    )
  end

  def create_failed_result
    Ace::Lint::Models::LintResult.new(
      file_path: "lib/failed.rb",
      success: false,
      errors: [
        Ace::Lint::Models::ValidationError.new(message: "Line too long", line: 10),
        Ace::Lint::Models::ValidationError.new(message: "Missing semicolon", line: 20)
      ],
      warnings: [],
      formatted: false,
      skipped: false,
      runner: :standardrb
    )
  end

  def create_formatted_result
    Ace::Lint::Models::LintResult.new(
      file_path: "lib/formatted.rb",
      success: true,
      errors: [],
      warnings: [],
      formatted: true,
      skipped: false,
      runner: :standardrb
    )
  end

  def create_skipped_result
    Ace::Lint::Models::LintResult.skipped(
      file_path: "lib/skipped.txt",
      reason: "Unsupported file type"
    )
  end

  def create_warnings_only_result
    Ace::Lint::Models::LintResult.new(
      file_path: "lib/warnings.rb",
      success: true,
      errors: [],
      warnings: [
        Ace::Lint::Models::ValidationError.new(message: "Consider using ...", line: 5, severity: :warning)
      ],
      formatted: false,
      skipped: false,
      runner: :standardrb
    )
  end
end
