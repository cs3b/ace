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

    def find_tests(package:, base_dir:, test_id: nil, **_filters)
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
    def initialize(failures_by_package: {}, failures_by_scenario: {})
      @failures_by_package = failures_by_package
      @failures_by_scenario = failures_by_scenario
    end

    def find_failures_by_package(packages:, base_dir:)
      @failures_by_package.select { |k, _| packages.include?(k) }
    end

    def find_failures_by_scenario(packages:, base_dir:)
      @failures_by_scenario.select { |k, _| packages.include?(k) }
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
      tests: {"ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"]}
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

    orchestrator.run(parallel: false)

    assert_match(/ACE E2E Test Suite - Running 1 tests across 1 packages/, @output.string)
  end

  def test_run_with_affected_filter
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint", "ace-review"],
      tests: {
        "ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"],
        "ace-review" => ["/path/to/TS-REVIEW-001-test/scenario.yml"]
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

    orchestrator.run(affected: true, parallel: false)

    assert_match(/Affected packages: ace-lint/, @output.string)
    assert_match(/ACE E2E Test Suite - Running 1 tests across 1 packages/, @output.string)
  end

  def test_run_passes_tag_filters_to_discoverer
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: {"ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"]}
    )
    captured = []

    discoverer.define_singleton_method(:find_tests) do |package:, base_dir:, test_id: nil, **filters|
      captured << filters
      @tests.fetch(package, [])
    end

    orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)
    def orchestrator.build_test_command(package, test_file, options, run_id: nil)
      "echo 'PASS' && exit 0"
    end

    orchestrator.run(
      parallel: false,
      tags: ["smoke", "happy-path"],
      exclude_tags: ["deep"]
    )

    assert_equal 1, captured.length
    assert_equal ["smoke", "happy-path"], captured.first[:tags]
    assert_equal ["deep"], captured.first[:exclude_tags]
  end

  def test_run_with_affected_filter_does_not_filter_when_no_affected_detected
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint", "ace-review"],
      tests: {
        "ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"],
        "ace-review" => ["/path/to/TS-REVIEW-001-test/scenario.yml"]
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


  def test_build_test_queue_reads_execution_tier_from_scenario
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output,
      scenario_loader: StubScenarioLoader.new
    )

    queue = orchestrator.send(:build_test_queue, {
      "ace-test" => [
        "/tmp/TS-SERIAL-001-test/scenario.yml",
        "/tmp/TS-LOW-001-test/scenario.yml",
        "/tmp/TS-SAFE-001-test/scenario.yml"
      ]
    })

    assert_equal ["serial", "low-parallel", "safe-parallel"], queue.map { |item| item[:execution_tier] }
  end

  def test_build_test_command_includes_options
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/TS-LINT-001-test/scenario.yml",
      {provider: "claude:sonnet", timeout: 120, cli_args: "test-arg"})

    assert_kind_of Array, cmd
    assert_equal "ace-test-e2e", File.basename(cmd.first)
    assert_includes cmd, "ace-lint"
    assert_includes cmd, "TS-LINT-001"

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

  def test_build_test_command_prefers_scenario_timeout
    Dir.mktmpdir do |tmpdir|
      scenario_dir = File.join(tmpdir, "ace-lint", "test", "e2e", "TS-LINT-001-timeout")
      FileUtils.mkdir_p(scenario_dir)
      File.write(File.join(scenario_dir, "scenario.yml"), <<~YAML)
        test-id: TS-LINT-001
        title: Timeout Scenario
        area: test
        package: ace-lint
        timeout: 900
      YAML

      discoverer = StubDiscoverer.new(packages: [], tests: {})
      orchestrator = SuiteOrchestrator.new(
        discoverer: discoverer,
        output: @output,
        base_dir: tmpdir
      )

      cmd = orchestrator.send(:build_test_command,
        "ace-lint",
        File.join(scenario_dir, "scenario.yml"),
        {provider: "claude:sonnet", timeout: 120},
        run_id: "abc123")

      timeout_idx = cmd.index("--timeout")
      refute_nil timeout_idx
      assert_equal "900", cmd[timeout_idx + 1]
    end
  end

  def test_build_test_command_sets_parallel_to_one
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/TS-LINT-001-test/scenario.yml",
      {})

    assert_kind_of Array, cmd
    # Find --parallel and its value
    parallel_idx = cmd.index("--parallel")
    refute_nil parallel_idx
    assert_equal "1", cmd[parallel_idx + 1]
  end

  def test_build_test_command_prefers_local_bin_wrapper_when_available
    Dir.mktmpdir do |tmpdir|
      bin_dir = File.join(tmpdir, "bin")
      FileUtils.mkdir_p(bin_dir)
      local_exe = File.join(bin_dir, "ace-test-e2e")
      File.write(local_exe, "#!/bin/sh\nexit 0\n")
      FileUtils.chmod(0o755, local_exe)

      discoverer = StubDiscoverer.new(packages: [], tests: {})
      orchestrator = SuiteOrchestrator.new(
        base_dir: tmpdir,
        discoverer: discoverer,
        output: @output
      )

      cmd = orchestrator.send(:build_test_command,
        "ace-lint",
        "/path/to/ace-lint/test/e2e/TS-LINT-001-test/scenario.yml",
        {})

      assert_equal local_exe, cmd.first
    end
  end

  def test_build_test_command_includes_verify_flag_when_enabled
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/TS-LINT-001-test/scenario.yml",
      {verify: true})

    assert_includes cmd, "--verify"
  end

  def test_extract_test_id_from_filename
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    test_id = orchestrator.send(:extract_test_id,
      "/path/to/ace-lint/test/e2e/TS-LINT-001-test/scenario.yml")
    assert_equal "TS-LINT-001", test_id

    test_id = orchestrator.send(:extract_test_id,
      "/path/to/ace-lint/test/e2e/cli-api-parity/scenario.yml")
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
      tests: {"ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"]}
    )
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output,
      progress: true
    )

    # Run uses progress display manager — verify by checking for ANSI clear screen in output
    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      {status: "pass", summary: "Test passed", passed_cases: 3, total_cases: 3, test_name: "TS-LINT-001"}
    end

    orchestrator.run(parallel: false)
    out = @output.string

    # Progress display manager clears screen
    assert_match(/\033\[H\033\[J/, out, "progress mode should clear screen")
    assert_match(/Active:/, out, "progress mode should show footer")
  end

  def test_default_uses_simple_display_manager
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: {"ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"]}
    )
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      {status: "pass", summary: "Test passed", passed_cases: 3, total_cases: 3, test_name: "TS-LINT-001"}
    end

    orchestrator.run(parallel: false)
    out = @output.string

    # Simple display manager does NOT clear screen
    refute_match(/\033\[H\033\[J/, out, "simple mode should not clear screen")
    # But does show the header
    assert_match(/ACE E2E Test Suite/, out)
  end

  def test_extract_test_name
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

    name = orchestrator.send(:extract_test_name, "/path/to/TS-BUNDLE-001-section-workflow/scenario.yml")
    assert_equal "TS-BUNDLE-001-section-workflow", name

    name = orchestrator.send(:extract_test_name, "/path/to/cli-api-parity/scenario.yml")
    assert_equal "cli-api-parity", name
  end

  def test_parse_subprocess_result_extracts_case_counts
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

    # Simulate a process hash with output where all cases pass
    thread = Minitest::Mock.new
    exit_status = Minitest::Mock.new
    exit_status.expect(:exitstatus, 0)
    thread.expect(:value, exit_status)

    process = {
      output: "Result: \u2713 PASS  8/8 cases\nReport: /tmp/report",
      thread: thread,
      test_file: "/path/to/TS-TEST-001-test/scenario.yml"
    }

    result = orchestrator.send(:parse_subprocess_result, process)

    assert_equal "pass", result[:status]
    assert_equal 8, result[:passed_cases]
    assert_equal 8, result[:total_cases]
    assert_equal "TS-TEST-001-test", result[:test_name]
  end

  def test_parse_subprocess_result_includes_raw_output
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

    thread = Minitest::Mock.new
    exit_status = Minitest::Mock.new
    exit_status.expect(:exitstatus, 0)
    thread.expect(:value, exit_status)

    raw = "Result: \u2713 PASS  3/3 cases\nReport: /tmp/report"
    process = {
      output: raw,
      thread: thread,
      test_file: "/path/to/TS-TEST-001-test/scenario.yml"
    }

    result = orchestrator.send(:parse_subprocess_result, process)

    assert_equal raw, result[:raw_output]
  end

  def test_parse_subprocess_result_detects_partial_as_fail_on_exit_zero
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

    thread = Minitest::Mock.new
    exit_status = Minitest::Mock.new
    exit_status.expect(:exitstatus, 0)
    thread.expect(:value, exit_status)

    process = {
      output: "Result: ✓ PARTIAL  3/5 cases\nReport: /tmp/report",
      thread: thread,
      test_file: "/path/to/TS-TEST-001-test/scenario.yml"
    }

    result = orchestrator.send(:parse_subprocess_result, process)

    assert_equal "fail", result[:status]
    assert_equal 3, result[:passed_cases]
    assert_equal 5, result[:total_cases]
    assert_equal "3/5 passed", result[:summary]
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
      test_file: "/path/to/TS-TEST-002-test/scenario.yml"
    }

    result = orchestrator.send(:parse_subprocess_result, process)

    assert_equal "pass", result[:status]
    assert_nil result[:passed_cases]
    assert_nil result[:total_cases]
  end

  def test_partial_status_counted_as_failed_in_sequential
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: {"ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"]}
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output,
      suite_report_writer: StubSuiteReportWriter.new,
      scenario_loader: StubScenarioLoader.new,
      timestamp_generator: -> { "abc1234" }
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      {status: "partial", summary: "3/5 passed", passed_cases: 3, total_cases: 5,
       test_name: "TS-LINT-001-test"}
    end

    results = orchestrator.run(parallel: false)

    assert_equal 1, results[:total]
    assert_equal 0, results[:passed]
    assert_equal 1, results[:failed]
    assert_equal 5, results[:total_cases]
    assert_equal 3, results[:passed_cases]
  end

  def test_case_counts_accumulated_across_tests
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: {"ace-lint" => [
        "/path/to/TS-LINT-001-test/scenario.yml",
        "/path/to/TS-LINT-002-test/scenario.yml"
      ]}
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output,
      suite_report_writer: StubSuiteReportWriter.new,
      scenario_loader: StubScenarioLoader.new,
      timestamp_generator: -> { "abc1234" }
    )

    call_count = 0
    orchestrator.define_singleton_method(:run_single_test) do |package, test_file, options, run_id: nil|
      call_count += 1
      if call_count == 1
        {status: "pass", summary: "Test passed", passed_cases: 5, total_cases: 5,
         test_name: "TS-LINT-001-test"}
      else
        {status: "fail", summary: "3/8 passed", passed_cases: 3, total_cases: 8,
         test_name: "TS-LINT-002-test"}
      end
    end

    results = orchestrator.run(parallel: false)

    assert_equal 2, results[:total]
    assert_equal 13, results[:total_cases]
    assert_equal 8, results[:passed_cases]
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
      @calls << {results: results, scenarios: scenarios, package: package,
                  timestamp: timestamp, base_dir: base_dir}
      @report_path
    end
  end

  # Stub scenario loader that returns a fixed scenario
  class StubScenarioLoader
    def load(dir_path)
      dir_name = File.basename(dir_path)
      test_id = dir_name.match(/(TS-[A-Z]+-\d+)/)&.[](1) || dir_name
      Ace::Test::EndToEndRunner::Models::TestScenario.new(
        test_id: test_id,
        title: "Test #{test_id}",
        area: "test",
        package: "ace-test",
        file_path: dir_path,
        content: "",
        dir_path: dir_path,
        test_cases: [],
        execution_tier: (dir_name.include?("SERIAL") ? "serial" : (dir_name.include?("LOW") ? "low-parallel" : "safe-parallel"))
      )
    end
  end

  def test_report_generated_after_sequential_run
    report_writer = StubSuiteReportWriter.new(report_path: "/tmp/test-final-report.md")
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: {"ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"]}
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output,
      suite_report_writer: report_writer,
      scenario_loader: StubScenarioLoader.new,
      timestamp_generator: -> { "abc1234" }
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      {status: "pass", summary: "Test passed", passed_cases: 3, total_cases: 3,
       test_name: "TS-LINT-001-test", report_dir: "/tmp/reports/lint"}
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
      tests: {"ace-lint" => ["/path/to/TS-LINT-001/scenario.yml"]}
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output,
      suite_report_writer: report_writer,
      scenario_loader: StubScenarioLoader.new,
      timestamp_generator: -> { "abc1234" }
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      {status: "fail", summary: "Test failed", passed_cases: 2, total_cases: 5,
       test_name: "TS-LINT-001", report_dir: "/tmp/reports/lint"}
    end

    orchestrator.run(parallel: false)

    call = report_writer.calls.first
    test_result = call[:results].first
    assert_kind_of Ace::Test::EndToEndRunner::Models::TestResult, test_result
    assert_equal "TS-LINT-001", test_result.test_id
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
      tests: {"ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"]}
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output,
      suite_report_writer: failing_writer,
      scenario_loader: StubScenarioLoader.new,
      timestamp_generator: -> { "abc1234" }
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      {status: "pass", summary: "Test passed", passed_cases: 3, total_cases: 3,
       test_name: "TS-LINT-001-test"}
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
      scenario_loader: StubScenarioLoader.new,
      timestamp_generator: -> { "abc1234" }
    )

    results = {
      packages: {
        "ace-lint" => [
          {status: "pass", test_name: "TS-LINT-001-test", passed_cases: 5, total_cases: 5, report_dir: "/tmp/r"},
          {status: "fail", test_name: "TS-LINT-002-test", passed_cases: 3, total_cases: 5, report_dir: "/tmp/r2"}
        ]
      }
    }
    package_tests = {
      "ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml", "/path/to/TS-LINT-002-test/scenario.yml"]
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
      scenario_loader: StubScenarioLoader.new,
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
        "ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"],
        "ace-review" => ["/path/to/TS-REVIEW-001-test/scenario.yml"],
        "ace-bundle" => ["/path/to/TS-BUNDLE-001-test/scenario.yml"]
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      {status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
       test_name: File.basename(File.dirname(test_file))}
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
        "ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"],
        "ace-review" => ["/path/to/TS-REVIEW-001-test/scenario.yml"],
        "ace-bundle" => ["/path/to/TS-BUNDLE-001-test/scenario.yml"]
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      {status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
       test_name: File.basename(File.dirname(test_file))}
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
        "ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"],
        "ace-review" => ["/path/to/TS-REVIEW-001-test/scenario.yml"]
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
      "/path/to/ace-lint/test/e2e/TS-LINT-001-test/scenario.yml",
      {},
      run_id: "batch01")

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
      "/path/to/ace-lint/test/e2e/TS-LINT-001-test/scenario.yml",
      {})

    refute_includes cmd, "--run-id", "Command should not include --run-id when nil"
  end

  def test_build_test_command_includes_report_dir_when_run_id_provided
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/TS-LINT-001-test/scenario.yml",
      {},
      run_id: "batch01")

    assert_kind_of Array, cmd
    report_dir_idx = cmd.index("--report-dir")
    refute_nil report_dir_idx, "Command should include --report-dir flag when run_id is provided"
    report_dir_value = cmd[report_dir_idx + 1]
    assert_includes report_dir_value, "batch01-lint-ts001-reports",
      "Report dir should use scenario dir_name with -reports suffix"
  end

  def test_build_test_command_omits_report_dir_when_no_run_id
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/TS-LINT-001-test/scenario.yml",
      {})

    refute_includes cmd, "--report-dir", "Command should not include --report-dir when no run_id"
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
      tests: {"ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml", "/path/to/TS-LINT-002-test/scenario.yml"]}
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )
    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      (@received_run_ids ||= []) << run_id
      {status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
       test_name: File.basename(File.dirname(test_file))}
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
        "ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"],
        "ace-review" => ["/path/to/TS-REVIEW-001-test/scenario.yml"],
        "ace-bundle" => ["/path/to/TS-BUNDLE-001-test/scenario.yml"]
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
      {status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
       test_name: File.basename(File.dirname(test_file))}
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
        "ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"],
        "ace-review" => ["/path/to/TS-REVIEW-001-test/scenario.yml"]
      }
    )
    failure_finder = StubFailureFinder.new(
      failures_by_scenario: {"ace-lint" => {"TS-LINT-001" => ["TC-001", "TC-003"]}}
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      failure_finder: failure_finder,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      {status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
       test_name: File.basename(File.dirname(test_file))}
    end

    results = orchestrator.run(only_failures: true, parallel: false)

    # Only ace-lint should run (it has failures)
    assert_equal 1, results[:total]
    assert_includes results[:packages].keys, "ace-lint"
    refute_includes results[:packages].keys, "ace-review"

    # Progress messages
    assert_match(/Packages with failed scenarios: ace-lint/, @output.string)
    assert_match(%r{ace-lint/TS-LINT-001}, @output.string)
  end

  def test_run_with_only_failures_returns_empty_when_no_failures
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: {"ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"]}
    )
    failure_finder = StubFailureFinder.new(failures_by_scenario: {})

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      failure_finder: failure_finder,
      output: @output
    )

    results = orchestrator.run(only_failures: true, parallel: false)

    assert_equal 0, results[:total]
    assert_match(/No failed test scenarios found in cache/, @output.string)
  end

  def test_run_with_only_failures_does_not_add_test_case_filters_to_command
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint"],
      tests: {"ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"]}
    )
    failure_finder = StubFailureFinder.new(
      failures_by_scenario: {"ace-lint" => {"TS-LINT-001" => ["TC-001", "TC-003"]}}
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      failure_finder: failure_finder,
      output: @output
    )

    # Set up @scenario_failures directly to test build_test_command
    orchestrator.instance_variable_set(:@scenario_failures,
      {"ace-lint" => {"TS-LINT-001" => ["TC-001", "TC-003"]}})

    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/TS-LINT-001-test/scenario.yml",
      {})

    refute_includes cmd, "--test-cases"
  end

  def test_run_with_only_failures_no_test_cases_without_failures
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    # Without scenario failures, no --test-cases should appear
    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/TS-LINT-001-test/scenario.yml",
      {})

    refute_includes cmd, "--test-cases",
      "Command should not include --test-cases when not in only-failures mode"
  end

  def test_run_with_only_failures_combined_with_affected
    discoverer = StubDiscoverer.new(
      packages: ["ace-lint", "ace-review", "ace-bundle"],
      tests: {
        "ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"],
        "ace-review" => ["/path/to/TS-REVIEW-001-test/scenario.yml"],
        "ace-bundle" => ["/path/to/TS-BUNDLE-001-test/scenario.yml"]
      }
    )
    # ace-lint and ace-review are affected
    affected_detector = StubAffectedDetector.new(affected: ["ace-lint", "ace-review"])
    # ace-lint and ace-bundle have failures (but ace-bundle is not affected)
    failure_finder = StubFailureFinder.new(
      failures_by_scenario: {
        "ace-lint" => {"TS-LINT-001" => ["TC-001"]},
        "ace-bundle" => {"TS-BUNDLE-001" => ["TC-002"]}
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      affected_detector: affected_detector,
      failure_finder: failure_finder,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      {status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
       test_name: File.basename(File.dirname(test_file))}
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
        "ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"],
        "ace-review" => ["/path/to/TS-REVIEW-001-test/scenario.yml"],
        "ace-bundle" => ["/path/to/TS-BUNDLE-001-test/scenario.yml"]
      }
    )
    # ace-lint and ace-bundle have failures
    failure_finder = StubFailureFinder.new(
      failures_by_scenario: {
        "ace-lint" => {"TS-LINT-001" => ["TC-001"]},
        "ace-bundle" => {"TS-BUNDLE-001" => ["TC-002"]}
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      failure_finder: failure_finder,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      {status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
       test_name: File.basename(File.dirname(test_file))}
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
        "ace-lint" => ["/path/to/TS-LINT-001-test/scenario.yml"],
        "ace-review" => ["/path/to/TS-REVIEW-001-test/scenario.yml"]
      }
    )
    failure_finder = StubFailureFinder.new(
      failures_by_scenario: {
        "ace-lint" => {"TS-LINT-001" => ["TC-001"]},
        "ace-review" => {"TS-REVIEW-001" => ["TC-002", "TC-003"]}
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      failure_finder: failure_finder,
      output: @output
    )

    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      {status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
       test_name: File.basename(File.dirname(test_file))}
    end

    results = orchestrator.run(only_failures: true, parallel: false)

    assert_equal 2, results[:total]
    assert_includes results[:packages].keys, "ace-lint"
    assert_includes results[:packages].keys, "ace-review"

    assert_match(/Packages with failed scenarios: ace-lint, ace-review/, @output.string)
    assert_match(%r{ace-review/TS-REVIEW-001}, @output.string)
  end

  def test_build_test_command_omits_test_cases_for_scenario_failures
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      output: @output
    )

    # Scenario-level failures always re-run full scenario, no --test-cases filter
    orchestrator.instance_variable_set(:@scenario_failures,
      {"ace-lint" => {"TS-LINT-001" => ["*"]}})

    cmd = orchestrator.send(:build_test_command,
      "ace-lint",
      "/path/to/ace-lint/test/e2e/TS-LINT-001-test/scenario.yml",
      {})

    refute_includes cmd, "--test-cases",
      "Command should not include --test-cases when failures contain wildcard"
  end

  def test_run_with_only_failures_launches_only_failing_scenarios
    # Package has 3 scenarios, but only 1 is failing
    discoverer = StubDiscoverer.new(
      packages: ["ace-git-secrets"],
      tests: {
        "ace-git-secrets" => [
          "/path/to/TS-SECRETS-001-test/scenario.yml",
          "/path/to/TS-SECRETS-002-test/scenario.yml",
          "/path/to/TS-SECRETS-003-test/scenario.yml"
        ]
      }
    )
    failure_finder = StubFailureFinder.new(
      failures_by_scenario: {
        "ace-git-secrets" => {"TS-SECRETS-001" => ["TC-001"]}
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      failure_finder: failure_finder,
      output: @output
    )
    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      (@executed_tests ||= []) << File.basename(File.dirname(test_file))
      {status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
       test_name: File.basename(File.dirname(test_file))}
    end

    def orchestrator.executed_tests
      @executed_tests || []
    end

    results = orchestrator.run(only_failures: true, parallel: false)

    # Only 1 scenario should be executed, not all 3
    assert_equal 1, results[:total]
    assert_equal ["TS-SECRETS-001-test"], orchestrator.executed_tests
  end

  def test_run_with_only_failures_keeps_scenario_scope_without_test_case_flags
    # Two scenarios in same package with different failing TCs
    discoverer = StubDiscoverer.new(
      packages: ["ace-git-secrets"],
      tests: {
        "ace-git-secrets" => [
          "/path/to/TS-SECRETS-001-test/scenario.yml",
          "/path/to/TS-SECRETS-002-test/scenario.yml"
        ]
      }
    )
    failure_finder = StubFailureFinder.new(
      failures_by_scenario: {
        "ace-git-secrets" => {
          "TS-SECRETS-001" => ["TC-001"],
          "TS-SECRETS-002" => ["TC-002", "TC-003"]
        }
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      failure_finder: failure_finder,
      output: @output
    )

    # Set up @scenario_failures to ensure per-scenario filtering in discovery only
    orchestrator.instance_variable_set(:@scenario_failures, {
      "ace-git-secrets" => {
        "TS-SECRETS-001" => ["TC-001"],
        "TS-SECRETS-002" => ["TC-002", "TC-003"]
      }
    })

    cmd1 = orchestrator.send(:build_test_command,
      "ace-git-secrets",
      "/path/to/TS-SECRETS-001-test/scenario.yml",
      {})
    cmd2 = orchestrator.send(:build_test_command,
      "ace-git-secrets",
      "/path/to/TS-SECRETS-002-test/scenario.yml",
      {})

    refute_includes cmd1, "--test-cases"
    refute_includes cmd2, "--test-cases"
  end

  def test_file_matches_test_id_with_descriptive_suffix
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

    # Exact match
    assert orchestrator.send(:file_matches_test_id?,
      "/path/to/TS-SECRETS-001-test/scenario.yml", "TS-SECRETS-001")

    # Descriptive suffix match
    assert orchestrator.send(:file_matches_test_id?,
      "/path/to/TS-COMMIT-002-specific-file-commit/scenario.yml", "TS-COMMIT-002")

    # Non-match: different test-id
    refute orchestrator.send(:file_matches_test_id?,
      "/path/to/TS-SECRETS-002-test/scenario.yml", "TS-SECRETS-001")

    # Non-match: test-id is prefix but no "-" separator (e.g. 001 vs 001a)
    refute orchestrator.send(:file_matches_test_id?,
      "/path/to/TS-BUNDLE-001a-error-sections/scenario.yml", "TS-BUNDLE-001")
  end

  def test_only_failures_matches_files_with_descriptive_suffixes
    discoverer = StubDiscoverer.new(
      packages: ["ace-git-secrets"],
      tests: {
        "ace-git-secrets" => [
          "/path/to/TS-SECRETS-001-secret-detection/scenario.yml",
          "/path/to/TS-SECRETS-002-allowlist/scenario.yml",
          "/path/to/TS-SECRETS-003-custom-patterns/scenario.yml"
        ]
      }
    )
    failure_finder = StubFailureFinder.new(
      failures_by_scenario: {
        "ace-git-secrets" => {"TS-SECRETS-001" => ["TC-001"]}
      }
    )

    orchestrator = SuiteOrchestrator.new(
      discoverer: discoverer,
      failure_finder: failure_finder,
      output: @output
    )
    def orchestrator.run_single_test(package, test_file, options, run_id: nil)
      (@executed_tests ||= []) << File.basename(File.dirname(test_file))
      {status: "pass", summary: "Test passed", passed_cases: 1, total_cases: 1,
       test_name: File.basename(File.dirname(test_file))}
    end

    def orchestrator.executed_tests
      @executed_tests || []
    end

    results = orchestrator.run(only_failures: true, parallel: false)

    assert_equal 1, results[:total]
    assert_equal ["TS-SECRETS-001-secret-detection"], orchestrator.executed_tests
  end

  def test_build_test_command_matches_suffix_filenames_to_scenario_failures
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

    orchestrator.instance_variable_set(:@scenario_failures, {
      "ace-git-commit" => {"TS-COMMIT-002" => ["TC-001", "TC-003"]}
    })

    cmd = orchestrator.send(:build_test_command,
      "ace-git-commit",
      "/path/to/TS-COMMIT-002-specific-file-commit/scenario.yml",
      {})

    assert_equal "ace-test-e2e", File.basename(cmd.first)
    refute_includes cmd, "--test-cases"
  end

  # --- Subprocess output saving tests ---

  def test_save_subprocess_output_writes_log_to_report_dir
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      FileUtils.mkdir_p(report_dir)

      discoverer = StubDiscoverer.new(packages: [], tests: {})
      orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

      result = {report_dir: report_dir, raw_output: "test output here"}
      orchestrator.send(:save_subprocess_output, result)

      log_path = File.join(report_dir, "subprocess_output.log")
      assert File.exist?(log_path), "subprocess_output.log should be created"
      assert_equal "test output here", File.read(log_path)
    end
  end

  def test_save_subprocess_output_uses_parent_dir_for_file_path
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      FileUtils.mkdir_p(report_dir)
      file_path = File.join(report_dir, "final-report.md")

      discoverer = StubDiscoverer.new(packages: [], tests: {})
      orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

      result = {report_dir: file_path, raw_output: "output data"}
      orchestrator.send(:save_subprocess_output, result)

      log_path = File.join(report_dir, "subprocess_output.log")
      assert File.exist?(log_path), "subprocess_output.log should be written to parent dir"
      assert_equal "output data", File.read(log_path)
    end
  end

  def test_save_subprocess_output_skips_when_no_report_dir
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

    # Should not raise
    orchestrator.send(:save_subprocess_output, {report_dir: nil, raw_output: "data"})
  end

  def test_save_subprocess_output_skips_when_empty_output
    Dir.mktmpdir do |tmpdir|
      discoverer = StubDiscoverer.new(packages: [], tests: {})
      orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

      orchestrator.send(:save_subprocess_output, {report_dir: tmpdir, raw_output: ""})

      refute File.exist?(File.join(tmpdir, "subprocess_output.log")),
        "Should not write empty subprocess output"
    end
  end

  # --- Metadata override with case count reconciliation ---

  def test_override_from_metadata_reconciles_all_passed_to_pass
    Dir.mktmpdir do |tmpdir|
      # Create metadata where status is "fail" but all cases passed
      report_dir = File.join(tmpdir, "reports")
      FileUtils.mkdir_p(report_dir)
      File.write(File.join(report_dir, "metadata.yml"), YAML.dump({
        "status" => "fail",
        "results" => {"passed" => 3, "total" => 3}
      }))

      discoverer = StubDiscoverer.new(packages: [], tests: {})
      orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

      result = {status: "fail", report_dir: report_dir, passed_cases: 0, total_cases: 0}
      overridden = orchestrator.send(:override_from_metadata, result)

      assert_equal "pass", overridden[:status]
      assert_equal 3, overridden[:passed_cases]
      assert_equal 3, overridden[:total_cases]
    end
  end

  def test_override_from_metadata_keeps_fail_when_cases_differ
    Dir.mktmpdir do |tmpdir|
      report_dir = File.join(tmpdir, "reports")
      FileUtils.mkdir_p(report_dir)
      File.write(File.join(report_dir, "metadata.yml"), YAML.dump({
        "status" => "fail",
        "results" => {"passed" => 2, "total" => 3}
      }))

      discoverer = StubDiscoverer.new(packages: [], tests: {})
      orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)

      result = {status: "fail", report_dir: report_dir, passed_cases: 0, total_cases: 0}
      overridden = orchestrator.send(:override_from_metadata, result)

      assert_equal "fail", overridden[:status]
    end
  end

  # --- Failure stub writing tests ---

  def test_write_failure_stubs_creates_metadata_for_errored_tests
    Dir.mktmpdir do |tmpdir|
      discoverer = StubDiscoverer.new(
        packages: ["ace-lint"],
        tests: {"ace-lint" => ["#{tmpdir}/ace-lint/test/e2e/TS-LINT-001/scenario.yml"]}
      )

      ts_counter = 0
      timestamp_gen = -> {
        ts_counter += 1
        "stub#{format("%03d", ts_counter)}"
      }

      orchestrator = SuiteOrchestrator.new(
        discoverer: discoverer,
        output: @output,
        base_dir: tmpdir,
        timestamp_generator: timestamp_gen,
        suite_report_writer: StubSuiteReportWriter.new,
        scenario_loader: StubScenarioLoader.new
      )

      # Simulate an errored test result with no report_dir (subprocess crashed)
      results = {
        packages: {
          "ace-lint" => [
            {status: "error", error: "Provider 503", test_name: "TS-LINT-001",
             report_dir: nil, passed_cases: nil, total_cases: nil}
          ]
        }
      }
      package_tests = {
        "ace-lint" => ["#{tmpdir}/ace-lint/test/e2e/TS-LINT-001/scenario.yml"]
      }

      orchestrator.send(:write_failure_stubs, results, package_tests)

      # Verify a stub metadata.yml was written
      cache_dir = File.join(tmpdir, ".ace-local", "test-e2e")
      metadata_files = Dir.glob(File.join(cache_dir, "*-reports", "metadata.yml"))
      assert_equal 1, metadata_files.size, "Should write one stub metadata file"

      data = YAML.safe_load_file(metadata_files.first)
      assert_equal "ace-lint", data["package"]
      assert_equal "error", data["status"]
      assert_equal "TS-LINT-001", data["test-id"]
    end
  end

  def test_write_failure_stubs_writes_subprocess_output_log
    Dir.mktmpdir do |tmpdir|
      discoverer = StubDiscoverer.new(
        packages: ["ace-lint"],
        tests: {"ace-lint" => ["#{tmpdir}/ace-lint/test/e2e/TS-LINT-001/scenario.yml"]}
      )

      ts_counter = 0
      timestamp_gen = -> {
        ts_counter += 1
        "stub#{format("%03d", ts_counter)}"
      }

      orchestrator = SuiteOrchestrator.new(
        discoverer: discoverer,
        output: @output,
        base_dir: tmpdir,
        timestamp_generator: timestamp_gen,
        suite_report_writer: StubSuiteReportWriter.new,
        scenario_loader: StubScenarioLoader.new
      )

      raw_output = "Running TS-LINT-001...\nError: Provider 503\nSome diagnostic info here"
      results = {
        packages: {
          "ace-lint" => [
            {status: "error", error: "Provider 503", test_name: "TS-LINT-001",
             report_dir: nil, passed_cases: nil, total_cases: nil,
             raw_output: raw_output}
          ]
        }
      }
      package_tests = {
        "ace-lint" => ["#{tmpdir}/ace-lint/test/e2e/TS-LINT-001/scenario.yml"]
      }

      orchestrator.send(:write_failure_stubs, results, package_tests)

      cache_dir = File.join(tmpdir, ".ace-local", "test-e2e")
      log_files = Dir.glob(File.join(cache_dir, "*-reports", "subprocess_output.log"))
      assert_equal 1, log_files.size, "Should write subprocess_output.log alongside metadata stub"
      assert_equal raw_output, File.read(log_files.first)
    end
  end

  def test_write_failure_stubs_skips_passing_tests
    Dir.mktmpdir do |tmpdir|
      discoverer = StubDiscoverer.new(
        packages: ["ace-lint"],
        tests: {"ace-lint" => ["#{tmpdir}/ace-lint/test/e2e/TS-LINT-001/scenario.yml"]}
      )

      orchestrator = SuiteOrchestrator.new(
        discoverer: discoverer,
        output: @output,
        base_dir: tmpdir,
        timestamp_generator: -> { "stub001" },
        suite_report_writer: StubSuiteReportWriter.new,
        scenario_loader: StubScenarioLoader.new
      )

      results = {
        packages: {
          "ace-lint" => [
            {status: "pass", summary: "Test passed", test_name: "TS-LINT-001",
             report_dir: nil, passed_cases: 3, total_cases: 3}
          ]
        }
      }
      package_tests = {
        "ace-lint" => ["#{tmpdir}/ace-lint/test/e2e/TS-LINT-001/scenario.yml"]
      }

      orchestrator.send(:write_failure_stubs, results, package_tests)

      cache_dir = File.join(tmpdir, ".ace-local", "test-e2e")
      metadata_files = Dir.glob(File.join(cache_dir, "*-reports", "metadata.yml"))
      assert_empty metadata_files, "Should not write stubs for passing tests"
    end
  end

  def test_write_failure_stubs_skips_when_metadata_already_exists
    Dir.mktmpdir do |tmpdir|
      # Create existing metadata on disk
      existing_report_dir = File.join(tmpdir, ".ace-local", "test-e2e", "existing-reports")
      FileUtils.mkdir_p(existing_report_dir)
      File.write(File.join(existing_report_dir, "metadata.yml"), YAML.dump({
        "test-id" => "TS-LINT-001",
        "package" => "ace-lint",
        "status" => "fail",
        "failed_test_cases" => ["TC-001"]
      }))

      discoverer = StubDiscoverer.new(
        packages: ["ace-lint"],
        tests: {"ace-lint" => ["#{tmpdir}/ace-lint/test/e2e/TS-LINT-001/scenario.yml"]}
      )

      orchestrator = SuiteOrchestrator.new(
        discoverer: discoverer,
        output: @output,
        base_dir: tmpdir,
        timestamp_generator: -> { "stub001" },
        suite_report_writer: StubSuiteReportWriter.new,
        scenario_loader: StubScenarioLoader.new
      )

      # Result has report_dir pointing to existing metadata
      results = {
        packages: {
          "ace-lint" => [
            {status: "fail", summary: "Test failed", test_name: "TS-LINT-001",
             report_dir: existing_report_dir, passed_cases: 2, total_cases: 3}
          ]
        }
      }
      package_tests = {
        "ace-lint" => ["#{tmpdir}/ace-lint/test/e2e/TS-LINT-001/scenario.yml"]
      }

      orchestrator.send(:write_failure_stubs, results, package_tests)

      # Only the original metadata file should exist, no new stub
      cache_dir = File.join(tmpdir, ".ace-local", "test-e2e")
      metadata_files = Dir.glob(File.join(cache_dir, "*-reports", "metadata.yml"))
      assert_equal 1, metadata_files.size, "Should not write additional stub when metadata exists"
      assert_equal existing_report_dir, File.dirname(metadata_files.first)
    end
  end

  def test_warn_on_lingering_claude_processes_emits_warning_in_debug_mode
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)
    status = Struct.new(:success?).new(true)

    old_env = ENV["ACE_LLM_DEBUG_SUBPROCESS"]
    ENV["ACE_LLM_DEBUG_SUBPROCESS"] = "1"

    Open3.stub :capture2, ["1234 claude -p --output-format json\n", status] do
      orchestrator.send(:warn_on_lingering_claude_processes)
    end

    assert_match(/Warning: Detected lingering claude -p processes \(1\)/, @output.string)
    assert_match(/1234 claude -p --output-format json/, @output.string)
  ensure
    ENV["ACE_LLM_DEBUG_SUBPROCESS"] = old_env
  end

  def test_warn_on_lingering_claude_processes_is_noop_when_debug_disabled
    discoverer = StubDiscoverer.new(packages: [], tests: {})
    orchestrator = SuiteOrchestrator.new(discoverer: discoverer, output: @output)
    status = Struct.new(:success?).new(true)

    old_env = ENV["ACE_LLM_DEBUG_SUBPROCESS"]
    ENV.delete("ACE_LLM_DEBUG_SUBPROCESS")

    Open3.stub :capture2, ["1234 claude -p --output-format json\n", status] do
      orchestrator.send(:warn_on_lingering_claude_processes)
    end

    assert_equal "", @output.string
  ensure
    ENV["ACE_LLM_DEBUG_SUBPROCESS"] = old_env
  end
end
