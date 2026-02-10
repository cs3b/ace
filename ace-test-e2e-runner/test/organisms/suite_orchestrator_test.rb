# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

class SuiteOrchestratorTest < Minitest::Test
  SuiteOrchestrator = Ace::Test::EndToEndRunner::Organisms::SuiteOrchestrator

  # Stub discoverer that returns controlled test lists
  class StubDiscoverer
    def initialize(packages: [], tests: {})
      @packages = packages
      @tests = tests
    end

    def list_packages(base_dir:)
      @packages
    end

    def find_tests(package:, test_id: nil, base_dir:)
      @tests.fetch(package, [])
    end
  end

  # Stub affected detector
  class StubAffectedDetector
    def initialize(affected: [])
      @affected = affected
    end

    def detect(base_dir:, ref: nil)
      @affected
    end
  end

  # Stub failure finder that returns controlled failures
  class StubFailureFinder
    def initialize(failures_by_package: {})
      @failures_by_package = failures_by_package
    end

    def find_failures_by_package(packages:, base_dir:)
      @failures_by_package.select { |k, _| packages.include?(k) }
    end
  end

  def setup
    @output = StringIO.new
  end

  def test_run_returns_empty_when_no_packages_found
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    results = orchestrator.run

    assert_equal 0, results[:total]
    assert_equal 0, results[:passed]
    assert_equal 0, results[:failed]
    assert_equal 0, results[:errors]
    assert_match(/No packages with E2E tests found/, @output.string)
  end

  def test_run_returns_empty_when_no_tests_in_packages
    discoverer = StubDiscoverer.new(packages: ["ace-lint"], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    results = orchestrator.run

    assert_equal 0, results[:total]
  end

  def test_run_displays_test_count
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: { "ace-lint" => ["/path/to/MT-LINT-001.mt.md"] }
    )
    affected_detector = StubAffectedDetector.new(affected: ["ace-lint"])

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      affected_detector: affected_detector,
      output: @output
    )

    # Mock the subprocess spawn for testing
    def orchestrator.build_test_command(package, test_file, options, run_id: nil)
      "echo 'PASS' && exit 0"
    end

    results = orchestrator.run(parallel: false)

    assert_match(/ACE E2E Test Suite - Running 1 tests across 1 packages/, @output.string)
  end

  def test_run_with_affected_filter
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint", "ace-review"],
      tests: {
        "ace-lint" => ["/path/to/MT-LINT-001.mt.md"],
        "ace-review" => ["/path/to/MT-REVIEW-001.mt.md"]
      }
    )
    affected_detector = StubAffectedDetector.new(affected: ["ace-lint"])

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      affected_detector: affected_detector,
      output: @output
    )

    # Mock the subprocess spawn for testing
    def orchestrator.build_test_command(package, test_file, options, run_id: nil)
      "echo 'PASS' && exit 0"
    end

    results = orchestrator.run(affected: true, parallel: false)

    assert_match(/Affected packages: ace-lint/, @output.string)
    assert_match(/ACE E2E Test Suite - Running 1 tests across 1 packages/, @output.string)
  end

  def test_run_with_affected_filter_does_not_filter_when_no_affected_detected
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint", "ace-review"],
      tests: {
        "ace-lint" => ["/path/to/MT-LINT-001.mt.md"],
        "ace-review" => ["/path/to/MT-REVIEW-001.mt.md"]
      }
    )
    # When no affected packages are detected with --affected flag, we skip all tests
    affected_detector = StubAffectedDetector.new(affected: [])

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      affected_detector: affected_detector,
      output: @output
    )

    results = orchestrator.run(affected: true, parallel: false)

    # When no affected packages detected with --affected, runs zero tests
    assert_equal 0, results[:total]
  end

  def test_build_test_command_includes_options
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/MT-LINT-001.mt.md",
      { provider: "claude:sonnet", timeout: 120, cli_args: "test-arg" }
    )

    assert_kind_of Array, cmd
    assert_includes cmd, "ace-test-e2e"
    assert_includes cmd, "ace-lint"
    assert_includes cmd, "MT-LINT-001"

    # Find --provider and its value
    provider_idx = cmd.index("--provider")
    refute_nil provider_idx
    assert_equal "claude:sonnet", cmd[provider_idx + 1]

    # Find --timeout and its value
    timeout_idx = cmd.index("--timeout")
    refute_nil timeout_idx
    assert_equal "120", cmd[timeout_idx + 1]

    # Find --cli-args and its value
    cli_args_idx = cmd.index("--cli-args")
    refute_nil cli_args_idx
    assert_equal "test-arg", cmd[cli_args_idx + 1]
  end

  def test_build_test_command_sets_parallel_to_one
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/MT-LINT-001.mt.md",
      {}
    )

    assert_kind_of Array, cmd
    # Find --parallel and its value
    parallel_idx = cmd.index("--parallel")
    refute_nil parallel_idx
    assert_equal "1", cmd[parallel_idx + 1]
  end

  def test_extract_test_id_from_filename
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    test_id = orchestrator.send(:extract_test_id,
      "/path/to/ace-lint/test/e2e/MT-LINT-001.mt.md"
    )
    assert_equal "MT-LINT-001", test_id

    test_id = orchestrator.send(:extract_test_id,
      "/path/to/ace-lint/test/e2e/cli-api-parity.mt.md"
    )
    assert_equal "cli-api-parity", test_id
  end

  def test_max_parallel_accessor
    orchestrator = SuiteOrchestrator.new(max_parallel: 8)
    assert_equal 8, orchestrator.max_parallel
  end

  def test_base_dir_accessor
    orchestrator = SuiteOrchestrator.new(base_dir: "/custom/path")
    assert_equal "/custom/path", orchestrator.base_dir
  end

  def test_progress_flag_selects_progress_display_manager
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: { "ace-lint" => ["/path/to/MT-LINT-001.mt.md"] }
    )
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output,
      progress: true
    )

    # Run uses progress display manager — verify by checking for ANSI clear screen in output
    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      { status: "pass", summary: "Test passed", passed_cases: 3, total_cases: 3, test_name: "MT-LINT-001" }
    end

    results = orchestrator.run(parallel: false)
    out = @output.string

    # Progress display manager clears screen
    assert_match(/\033\[H\033\[J/, out, "progress mode should clear screen")
    assert_match(/Active:/, out, "progress mode should show footer")
  end

  def test_default_uses_simple_display_manager
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: { "ace-lint" => ["/path/to/MT-LINT-001.mt.md"] }
    )
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      { status: "pass", summary: "Test passed", passed_cases: 3, total_cases: 3, test_name: "MT-LINT-001" }
    end

    results = orchestrator.run(parallel: false)
    out = @output.string

    # Simple display manager does NOT clear screen
    refute_match(/\033\[H\033\[J/, out, "simple mode should not clear screen")
    # But does show the header
    assert_match(/ACE E2E Test Suite/, out)
  end

  def test_extract_test_name
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

    name = orchestrator.send(:extract_test_name, "/path/to/MT-BUNDLE-001-section-workflow.mt.md")
    assert_equal "MT-BUNDLE-001-section-workflow", name

    name = orchestrator.send(:extract_test_name, "/path/to/cli-api-parity.mt.md")
    assert_equal "cli-api-parity", name
  end

  def test_parse_subprocess_result_extracts_case_counts
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

    # Simulate a process hash with output containing case counts
    thread = Minitest::Mock.new
    exit_status = Minitest::Mock.new
    exit_status.expect(:exitstatus, 0)
    thread.expect(:value, exit_status)

    process = {
      output: "Result: \u2713 PASS  5/8 cases\nReport: /tmp/report",
      thread: thread,
      test_file: "/path/to/MT-TEST-001.mt.md"
    }

    result = orchestrator.send(:parse_subprocess_result, process)

    assert_equal "pass", result[:status]
    assert_equal 5, result[:passed_cases]
    assert_equal 8, result[:total_cases]
    assert_equal "MT-TEST-001", result[:test_name]
  end

  def test_parse_subprocess_result_handles_no_case_counts
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

    thread = Minitest::Mock.new
    exit_status = Minitest::Mock.new
    exit_status.expect(:exitstatus, 0)
    thread.expect(:value, exit_status)

    process = {
      output: "Some output without case counts",
      thread: thread,
      test_file: "/path/to/MT-TEST-002.mt.md"
    }

    result = orchestrator.send(:parse_subprocess_result, process)

    assert_equal "pass", result[:status]
    assert_nil result[:passed_cases]
    assert_nil result[:total_cases]
  end

  # --- Suite report generation tests ---

  # Stub report writer that records calls
  class StubSuiteReportWriter
    attr_reader :calls

    def initialize(report_path: "/tmp/test-report.md")
      @report_path = report_path
      @calls = []
    end

    def write(results, scenarios, package:, timestamp:, base_dir:)
      @calls << { results: results, scenarios: scenarios, package: package,
                  timestamp: timestamp, base_dir: base_dir }
      @report_path
    end
  end

  # Stub scenario parser that returns a fixed scenario
  class StubScenarioParser
    def parse(file_path)
      test_id = File.basename(file_path, ".mt.md")
      Ace::Test::EndToEndRunner::Models::TestScenario.new(
        test_id: test_id,
        title: "Test #{test_id}",
        area: "test",
        package: "ace-test",
        file_path: file_path,
        content: ""
      )
    end
  end

  def test_report_generated_after_sequential_run
    report_writer = StubSuiteReportWriter.new(report_path: "/tmp/test-final-report.md")
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: { "ace-lint" => ["/path/to/MT-LINT-001.mt.md"] }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output,
      suite_report_writer: report_writer,
      scenario_parser: StubScenarioParser.new,
      timestamp_generator: -> { "abc1234" }
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      { status: "pass", summary: "Test passed", passed_cases: 3, total_cases: 3,
        test_name: "MT-LINT-001", report_dir: "/tmp/reports/lint" }
    end

    results = orchestrator.run(parallel: false)

    # Report writer was called
    assert_equal 1, report_writer.calls.size
    call = report_writer.calls.first
    assert_equal "suite", call[:package]
    assert_equal "abc1234", call[:timestamp]

    # Results contain report path
    assert_equal "/tmp/test-final-report.md", results[:report_path]

    # Output contains report path
    assert_match(/Report: \/tmp\/test-final-report\.md/, @output.string)
  end

  def test_report_converts_result_hashes_to_test_result_models
    report_writer = StubSuiteReportWriter.new
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: { "ace-lint" => ["/path/to/MT-LINT-001.mt.md"] }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output,
      suite_report_writer: report_writer,
      scenario_parser: StubScenarioParser.new,
      timestamp_generator: -> { "abc1234" }
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      { status: "fail", summary: "Test failed", passed_cases: 2, total_cases: 5,
        test_name: "MT-LINT-001", report_dir: "/tmp/reports/lint" }
    end

    orchestrator.run(parallel: false)

    call = report_writer.calls.first
    test_result = call[:results].first
    assert_kind_of Ace::Test::EndToEndRunner::Models::TestResult, test_result
    assert_equal "MT-LINT-001", test_result.test_id
    assert_equal "fail", test_result.status
    assert_equal 2, test_result.passed_count
    assert_equal 3, test_result.failed_count
    assert_equal 5, test_result.total_count
  end

  def test_report_generation_failure_warns_but_does_not_raise
    # Writer that raises an error
    failing_writer = Object.new
    def failing_writer.write(*, **)
      raise "LLM connection failed"
    end

    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: { "ace-lint" => ["/path/to/MT-LINT-001.mt.md"] }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output,
      suite_report_writer: failing_writer,
      scenario_parser: StubScenarioParser.new,
      timestamp_generator: -> { "abc1234" }
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      { status: "pass", summary: "Test passed", passed_cases: 3, total_cases: 3,
        test_name: "MT-LINT-001" }
    end

    # Capture stderr to verify warning
    results = nil
    warning = nil
    original_stderr = $stderr
    $stderr = StringIO.new
    begin
      results = orchestrator.run(parallel: false)
      warning = $stderr.string
    ensure
      $stderr = original_stderr
    end

    # Results should still be valid, just without report_path
    assert_equal 1, results[:total]
    assert_equal 1, results[:passed]
    assert_nil results[:report_path]
    refute_match(/Report:/, @output.string)

    # Warning should be emitted to stderr
    assert_match(/Suite report generation failed/, warning)
    assert_match(/RuntimeError/, warning)
    assert_match(/LLM connection failed/, warning)
  end

  def test_generate_suite_report_converts_data_correctly
    report_writer = StubSuiteReportWriter.new
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer, output: @output,
      suite_report_writer: report_writer,
      scenario_parser: StubScenarioParser.new,
      timestamp_generator: -> { "abc1234" }
    )

    results = {
      packages: {
        "ace-lint" => [
          { status: "pass", test_name: "MT-LINT-001", passed_cases: 5, total_cases: 5, report_dir: "/tmp/r" },
          { status: "fail", test_name: "MT-LINT-002", passed_cases: 3, total_cases: 5, report_dir: "/tmp/r2" }
        ]
      }
    }
    package_tests = {
      "ace-lint" => ["/path/to/MT-LINT-001.mt.md", "/path/to/MT-LINT-002.mt.md"]
    }

    path = orchestrator.send(:generate_suite_report, results, package_tests)

    assert_equal "/tmp/test-report.md", path
    assert_equal 1, report_writer.calls.size

    call = report_writer.calls.first
    assert_equal 2, call[:results].size
    assert_equal "pass", call[:results][0].status
    assert_equal 5, call[:results][0].passed_count
    assert_equal "fail", call[:results][1].status
    assert_equal 3, call[:results][1].passed_count
    assert_equal 2, call[:results][1].failed_count
  end

  def test_no_report_when_no_results
    report_writer = StubSuiteReportWriter.new
    discoverer = StubDiscoverer.new(packages: ["ace-lint"], tests: {})

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output,
      suite_report_writer: report_writer,
      scenario_parser: StubScenarioParser.new,
      timestamp_generator: -> { "abc1234" }
    )

    results = orchestrator.run(parallel: false)

    # No tests discovered = early return, no report generation attempted
    assert_equal 0, results[:total]
    assert_equal 0, report_writer.calls.size
    assert_nil results[:report_path]
  end

  # --- Package filtering tests ---

  def test_run_filters_to_requested_packages
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint", "ace-review", "ace-bundle"],
      tests: {
        "ace-lint" => ["/path/to/MT-LINT-001.mt.md"],
        "ace-review" => ["/path/to/MT-REVIEW-001.mt.md"],
        "ace-bundle" => ["/path/to/MT-BUNDLE-001.mt.md"]
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      { status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
        test_name: File.basename(test_file, ".mt.md") }
    end

    results = orchestrator.run(packages: "ace-lint", parallel: false)

    # Only ace-lint should run
    assert_equal 1, results[:total]
    assert_includes results[:packages].keys, "ace-lint"
    refute_includes results[:packages].keys, "ace-review"
    refute_includes results[:packages].keys, "ace-bundle"
  end

  def test_run_filters_multiple_packages
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint", "ace-review", "ace-bundle"],
      tests: {
        "ace-lint" => ["/path/to/MT-LINT-001.mt.md"],
        "ace-review" => ["/path/to/MT-REVIEW-001.mt.md"],
        "ace-bundle" => ["/path/to/MT-BUNDLE-001.mt.md"]
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      { status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
        test_name: File.basename(test_file, ".mt.md") }
    end

    results = orchestrator.run(packages: "ace-lint,ace-review", parallel: false)

    assert_equal 2, results[:total]
    assert_includes results[:packages].keys, "ace-lint"
    assert_includes results[:packages].keys, "ace-review"
    refute_includes results[:packages].keys, "ace-bundle"
  end

  def test_run_filters_packages_with_no_match
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint", "ace-review"],
      tests: {
        "ace-lint" => ["/path/to/MT-LINT-001.mt.md"],
        "ace-review" => ["/path/to/MT-REVIEW-001.mt.md"]
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    results = orchestrator.run(packages: "ace-nonexistent", parallel: false)

    assert_equal 0, results[:total]
    assert_match(/No matching packages with E2E tests found/, @output.string)
  end

  # --- Run ID generation and threading tests ---

  def test_build_test_command_includes_run_id_when_provided
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/MT-LINT-001.mt.md",
      {},
      run_id: "batch01"
    )

    assert_kind_of Array, cmd
    run_id_idx = cmd.index("--run-id")
    refute_nil run_id_idx, "Command should include --run-id flag"
    assert_equal "batch01", cmd[run_id_idx + 1]
  end

  def test_build_test_command_omits_run_id_when_nil
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/MT-LINT-001.mt.md",
      {}
    )

    refute_includes cmd, "--run-id", "Command should not include --run-id when nil"
  end

  def test_generate_run_ids_returns_unique_ids
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    ids = orchestrator.send(:generate_run_ids, 5)

    assert_equal 5, ids.size
    assert_equal ids.uniq.size, ids.size, "All run IDs should be unique"
    assert ids.all? { |id| id.is_a?(String) && !id.empty? }, "All run IDs should be non-empty strings"
  end

  def test_run_sequential_passes_run_ids_to_single_test
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: { "ace-lint" => ["/path/to/MT-LINT-001.mt.md", "/path/to/MT-LINT-002.mt.md"] }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    received_run_ids = []
    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      (@received_run_ids ||= []) << run_id
      { status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
        test_name: File.basename(test_file, ".mt.md") }
    end

    # Access the instance variable via a reader
    def orchestrator.received_run_ids
      @received_run_ids || []
    end

    orchestrator.run(parallel: false)

    ids = orchestrator.received_run_ids
    assert_equal 2, ids.size
    assert ids.none?(&:nil?), "All run_ids should be non-nil"
    assert_equal ids.uniq.size, ids.size, "All run_ids should be unique"
  end

  def test_run_combines_packages_and_affected_filters
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint", "ace-review", "ace-bundle"],
      tests: {
        "ace-lint" => ["/path/to/MT-LINT-001.mt.md"],
        "ace-review" => ["/path/to/MT-REVIEW-001.mt.md"],
        "ace-bundle" => ["/path/to/MT-BUNDLE-001.mt.md"]
      }
    )
    # Only ace-lint and ace-bundle are affected
    affected_detector = StubAffectedDetector.new(affected: ["ace-lint", "ace-bundle"])

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      affected_detector: affected_detector,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      { status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
        test_name: File.basename(test_file, ".mt.md") }
    end

    # Request ace-lint and ace-review, but only ace-lint is affected
    results = orchestrator.run(packages: "ace-lint,ace-review", affected: true, parallel: false)

    # Intersection: only ace-lint matches both filters
    assert_equal 1, results[:total]
    assert_includes results[:packages].keys, "ace-lint"
    refute_includes results[:packages].keys, "ace-review"
    refute_includes results[:packages].keys, "ace-bundle"
  end

  # --- Only-failures filtering tests ---

  def test_run_with_only_failures_filters_to_packages_with_failures
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint", "ace-review"],
      tests: {
        "ace-lint" => ["/path/to/MT-LINT-001.mt.md"],
        "ace-review" => ["/path/to/MT-REVIEW-001.mt.md"]
      }
    )
    failure_finder = StubFailureFinder.new(
      failures_by_package: { "ace-lint" => ["TC-001", "TC-003"] }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      failure_finder: failure_finder,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      { status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
        test_name: File.basename(test_file, ".mt.md") }
    end

    results = orchestrator.run(only_failures: true, parallel: false)

    # Only ace-lint should run (it has failures)
    assert_equal 1, results[:total]
    assert_includes results[:packages].keys, "ace-lint"
    refute_includes results[:packages].keys, "ace-review"

    # Progress messages
    assert_match(/Packages with failures: ace-lint/, @output.string)
    assert_match(/ace-lint: TC-001, TC-003/, @output.string)
  end

  def test_run_with_only_failures_returns_empty_when_no_failures
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: { "ace-lint" => ["/path/to/MT-LINT-001.mt.md"] }
    )
    failure_finder = StubFailureFinder.new(failures_by_package: {})

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      failure_finder: failure_finder,
      output: @output
    )

    results = orchestrator.run(only_failures: true, parallel: false)

    assert_equal 0, results[:total]
    assert_match(/No failed test cases found in cache/, @output.string)
  end

  def test_run_with_only_failures_passes_test_cases_to_command
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: { "ace-lint" => ["/path/to/MT-LINT-001.mt.md"] }
    )
    failure_finder = StubFailureFinder.new(
      failures_by_package: { "ace-lint" => ["TC-001", "TC-003"] }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      failure_finder: failure_finder,
      output: @output
    )

    # First trigger run to set up @package_failures
    # We need to call run() which sets @package_failures, then verify build_test_command
    # Instead, directly test after running with only_failures
    orchestrator.instance_variable_set(:@package_failures, { "ace-lint" => ["TC-001", "TC-003"] })

    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/MT-LINT-001.mt.md",
      {}
    )

    test_cases_idx = cmd.index("--test-cases")
    refute_nil test_cases_idx, "Command should include --test-cases flag"
    assert_equal "TC-001,TC-003", cmd[test_cases_idx + 1]
  end

  def test_run_with_only_failures_no_test_cases_without_failures
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    # Without @package_failures set (nil), no --test-cases should appear
    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/MT-LINT-001.mt.md",
      {}
    )

    refute_includes cmd, "--test-cases",
      "Command should not include --test-cases when not in only-failures mode"
  end

  def test_run_with_only_failures_combined_with_affected
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint", "ace-review", "ace-bundle"],
      tests: {
        "ace-lint" => ["/path/to/MT-LINT-001.mt.md"],
        "ace-review" => ["/path/to/MT-REVIEW-001.mt.md"],
        "ace-bundle" => ["/path/to/MT-BUNDLE-001.mt.md"]
      }
    )
    # ace-lint and ace-review are affected
    affected_detector = StubAffectedDetector.new(affected: ["ace-lint", "ace-review"])
    # ace-lint and ace-bundle have failures (but ace-bundle is not affected)
    failure_finder = StubFailureFinder.new(
      failures_by_package: {
        "ace-lint" => ["TC-001"],
        "ace-bundle" => ["TC-002"]
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      affected_detector: affected_detector,
      failure_finder: failure_finder,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      { status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
        test_name: File.basename(test_file, ".mt.md") }
    end

    results = orchestrator.run(affected: true, only_failures: true, parallel: false)

    # Only ace-lint: affected AND has failures
    # ace-review: affected but no failures
    # ace-bundle: has failures but not affected
    assert_equal 1, results[:total]
    assert_includes results[:packages].keys, "ace-lint"
    refute_includes results[:packages].keys, "ace-review"
    refute_includes results[:packages].keys, "ace-bundle"
  end

  def test_run_with_only_failures_combined_with_packages_filter
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint", "ace-review", "ace-bundle"],
      tests: {
        "ace-lint" => ["/path/to/MT-LINT-001.mt.md"],
        "ace-review" => ["/path/to/MT-REVIEW-001.mt.md"],
        "ace-bundle" => ["/path/to/MT-BUNDLE-001.mt.md"]
      }
    )
    # ace-lint and ace-bundle have failures
    failure_finder = StubFailureFinder.new(
      failures_by_package: {
        "ace-lint" => ["TC-001"],
        "ace-bundle" => ["TC-002"]
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      failure_finder: failure_finder,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      { status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
        test_name: File.basename(test_file, ".mt.md") }
    end

    # Request only ace-lint,ace-review with only-failures
    results = orchestrator.run(packages: "ace-lint,ace-review", only_failures: true, parallel: false)

    # Only ace-lint: requested AND has failures
    # ace-review: requested but no failures
    # ace-bundle: has failures but not requested
    assert_equal 1, results[:total]
    assert_includes results[:packages].keys, "ace-lint"
    refute_includes results[:packages].keys, "ace-review"
    refute_includes results[:packages].keys, "ace-bundle"
  end

  def test_run_with_only_failures_multiple_packages_with_failures
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint", "ace-review"],
      tests: {
        "ace-lint" => ["/path/to/MT-LINT-001.mt.md"],
        "ace-review" => ["/path/to/MT-REVIEW-001.mt.md"]
      }
    )
    failure_finder = StubFailureFinder.new(
      failures_by_package: {
        "ace-lint" => ["TC-001"],
        "ace-review" => ["TC-002", "TC-003"]
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      failure_finder: failure_finder,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      { status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
        test_name: File.basename(test_file, ".mt.md") }
    end

    results = orchestrator.run(only_failures: true, parallel: false)

    assert_equal 2, results[:total]
    assert_includes results[:packages].keys, "ace-lint"
    assert_includes results[:packages].keys, "ace-review"

    assert_match(/Packages with failures: ace-lint, ace-review/, @output.string)
    assert_match(/ace-review: TC-002, TC-003/, @output.string)
  end
end
