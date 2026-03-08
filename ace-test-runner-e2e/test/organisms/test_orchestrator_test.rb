# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

class TestOrchestratorTest < Minitest::Test
  TestOrchestrator = Ace::Test::EndToEndRunner::Organisms::TestOrchestrator
  TestResult = Ace::Test::EndToEndRunner::Models::TestResult
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario

  # Stub executor that returns controllable results without LLM calls
  class StubExecutor
    def initialize(status: "pass", test_cases: [], summary: "Stub result")
      @status = status
      @test_cases = test_cases
      @summary = summary
    end

    def execute(scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil)
      TestResult.new(
        test_id: scenario.test_id,
        status: @status,
        test_cases: @test_cases,
        summary: @summary,
        started_at: Time.now,
        completed_at: Time.now + 1
      )
    end
  end

  def setup
    @output = StringIO.new
  end

  def test_run_returns_empty_for_nonexistent_package
    orchestrator = create_orchestrator

    results = orchestrator.run(
      package: "ace-nonexistent",
      output: @output
    )

    assert_empty results
    assert_match(/No E2E tests found/, @output.string)
  end

  def test_run_returns_empty_for_nonexistent_test_id
    orchestrator = create_orchestrator

    results = orchestrator.run(
      package: "ace-lint",
      test_id: "TS-LINT-999",
      output: @output
    )

    assert_empty results
    assert_match(/No E2E tests found/, @output.string)
    assert_match(/TS-LINT-999/, @output.string)
  end

  def test_run_single_test_returns_passing_result
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      orchestrator = create_orchestrator(base_dir: tmpdir)

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert_equal 1, results.size
      assert_equal "TS-TEST-001", results.first.test_id
      assert_equal "pass", results.first.status
      assert results.first.success?
      assert_match(/Running E2E test/, @output.string)
      assert_match(/Result: .* PASS/, @output.string)
    end
  end

  def test_run_single_test_shows_tc_counts
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001 TC-002])
      executor = StubExecutor.new(
        status: "pass",
        test_cases: [
          { id: "TC-001", description: "Check A", status: "pass" },
          { id: "TC-002", description: "Check B", status: "pass" }
        ]
      )
      orchestrator = create_orchestrator(base_dir: tmpdir, executor: executor)

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert_match(/Result: .* PASS\s+2\/2 cases/, @output.string)
    end
  end

  def test_run_single_test_omits_tc_counts_when_zero
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      executor = StubExecutor.new(status: "error", test_cases: [])
      orchestrator = create_orchestrator(base_dir: tmpdir, executor: executor)

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      # Should show "Result: ✗ ERROR" with no TC counts
      assert_match(/Result: .* ERROR\n/, @output.string)
      refute_match(/cases/, @output.string)
    end
  end

  def test_run_package_returns_all_results
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-002", %w[TC-001])
      orchestrator = create_orchestrator(base_dir: tmpdir)

      results = orchestrator.run(
        package: "my-pkg",
        output: @output
      )

      assert_equal 2, results.size
      assert(results.all?(&:success?), "All results should pass")
      assert_match(/Discovered 2 E2E tests/, @output.string)
      assert_match(/Tests:\s+2 passed, 0 failed/, @output.string)
    end
  end

  def test_run_package_shows_started_messages
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-002", %w[TC-001])
      orchestrator = create_orchestrator(base_dir: tmpdir)

      orchestrator.run(package: "my-pkg", output: @output)

      assert_match(/\[started\] TS-TEST-001/, @output.string)
      assert_match(/\[started\] TS-TEST-002/, @output.string)
    end
  end

  def test_run_package_shows_tc_counts_in_done_lines
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001 TC-002])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-002", %w[TC-001 TC-002])
      executor = StubExecutor.new(
        status: "pass",
        test_cases: [
          { id: "TC-001", description: "Check", status: "pass" },
          { id: "TC-002", description: "Check", status: "pass" }
        ]
      )
      orchestrator = create_orchestrator(base_dir: tmpdir, executor: executor)

      orchestrator.run(package: "my-pkg", output: @output)

      assert_match(/\[1\/2\] .* TS-TEST-001\s+PASS\s+2\/2 cases/, @output.string)
    end
  end

  def test_run_package_summary_includes_tc_stats
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001 TC-002])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-002", %w[TC-001 TC-002])
      executor = StubExecutor.new(
        status: "pass",
        test_cases: [
          { id: "TC-001", description: "Check", status: "pass" },
          { id: "TC-002", description: "Check", status: "pass" }
        ]
      )
      orchestrator = create_orchestrator(base_dir: tmpdir, executor: executor)

      orchestrator.run(package: "my-pkg", output: @output)

      # 2 tests × 2 TCs each = 4 total, all passing
      assert_match(/Tests:\s+2 passed, 0 failed/, @output.string)
      assert_match(/Test cases:\s+4 passed, 0 failed \(100%\)/, @output.string)
    end
  end

  def test_run_package_summary_omits_tc_stats_when_zero
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-002", %w[TC-001])
      orchestrator = create_orchestrator(base_dir: tmpdir)

      orchestrator.run(package: "my-pkg", output: @output)

      # No TCs → summary without TC stats line
      assert_match(/Tests:\s+2 passed, 0 failed/, @output.string)
      refute_match(/Test cases:/, @output.string)
    end
  end

  def test_run_package_writes_suite_report
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-002", %w[TC-001])
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        timestamp_generator: -> { "rpt123" }
      )

      orchestrator.run(package: "my-pkg", output: @output)

      report_path = File.join(tmpdir, ".ace-local", "test-e2e", "rpt123-final-report.md")
      assert File.exist?(report_path), "Suite report should be created"
      assert_match(/Report: .*rpt123-final-report\.md/, @output.string)
    end
  end

  def test_run_uses_injected_timestamp
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        timestamp_generator: -> { "abc123" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert results.first.report_dir.include?("abc123")
    end
  end

  def test_report_directory_created
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        timestamp_generator: -> { "ts1234" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      report_dir = results.first.report_dir
      assert Dir.exist?(report_dir), "Report directory should be created"
      assert report_dir.include?(".ace-local/test-e2e/")
    end
  end

  def test_failed_test_result_propagated
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      executor = StubExecutor.new(status: "fail", summary: "Test failed")
      orchestrator = create_orchestrator(base_dir: tmpdir, executor: executor)

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert_equal 1, results.size
      assert_equal "fail", results.first.status
      assert results.first.failed?
      assert_match(/Result: .* FAIL/, @output.string)
    end
  end

  def test_package_run_with_mixed_results
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-002", %w[TC-001])
      call_count = 0
      # Executor that alternates pass/fail
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil|
        call_count += 1
        TestResult.new(
          test_id: scenario.test_id,
          status: call_count.odd? ? "pass" : "fail",
          summary: "Result #{call_count}",
          started_at: Time.now,
          completed_at: Time.now + 1
        )
      end

      orchestrator = create_orchestrator(base_dir: tmpdir, executor: executor)

      results = orchestrator.run(
        package: "my-pkg",
        output: @output
      )

      assert_equal 2, results.size
      assert_equal 1, results.count(&:success?)
      assert_equal 1, results.count(&:failed?)
      assert_match(/Tests:\s+1 passed, 1 failed/, @output.string)
    end
  end

  def test_cli_provider_missing_expected_report_is_error
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        timestamp_generator: -> { "cli123" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert_equal 1, results.size
      expected_dir = File.join(tmpdir, ".ace-local", "test-e2e", "cli123-my-pkg-ts001-reports")
      assert_equal "error", results.first.status
      assert_equal expected_dir, results.first.report_dir
      assert_includes results.first.error, "Expected report directory was not created"
      assert_match(/pipeline mode: runner\+verifier/, @output.string)
    end
  end

  def test_cli_provider_does_not_use_stale_report_dirs
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])

      stale_dir = File.join(tmpdir, ".ace-local", "test-e2e", "old111-my-pkg-ts001-reports")
      FileUtils.mkdir_p(stale_dir)
      File.write(File.join(stale_dir, "metadata.yml"), <<~YAML)
        status: "pass"
        results:
          passed: 1
          failed: 0
          total: 1
      YAML

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        timestamp_generator: -> { "new222" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      expected_dir = File.join(tmpdir, ".ace-local", "test-e2e", "new222-my-pkg-ts001-reports")
      assert_equal "error", results.first.status
      assert_equal expected_dir, results.first.report_dir
      refute_equal stale_dir, results.first.report_dir
    end
  end

  def test_api_provider_writes_reports
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "google:gemini-2.5-flash",
        timestamp_generator: -> { "api123" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert_equal 1, results.size
      report_dir = results.first.report_dir
      assert Dir.exist?(report_dir), "API provider should create report dir via ReportWriter"
      refute_match(/pipeline mode: runner\+verifier/, @output.string)
    end
  end

  def test_cli_provider_finds_agent_written_reports
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])

      # Simulate agent-written report dir at the expected path (matching timestamp)
      agent_dir = File.join(tmpdir, ".ace-local", "test-e2e", "bbb222-my-pkg-ts001-reports")
      FileUtils.mkdir_p(agent_dir)
      File.write(File.join(agent_dir, "summary.r.md"), "# Report")

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        timestamp_generator: -> { "bbb222" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert_equal agent_dir, results.first.report_dir
    end
  end

  def test_cli_provider_reads_metadata_yml_for_status
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])

      # Simulate agent-written report dir with metadata.yml showing pass
      agent_dir = File.join(tmpdir, ".ace-local", "test-e2e", "meta01-my-pkg-ts001-reports")
      FileUtils.mkdir_p(agent_dir)
      File.write(File.join(agent_dir, "metadata.yml"), <<~YAML)
        status: "pass"
        results:
          passed: 5
          failed: 0
          total: 5
      YAML

      # Executor returns "error" status — metadata.yml should override
      executor = StubExecutor.new(status: "error", summary: "Parse error")
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        timestamp_generator: -> { "meta01" },
        executor: executor
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert_equal "pass", results.first.status
      assert_equal 5, results.first.passed_count
      assert_equal 0, results.first.failed_count
      assert_equal 5, results.first.total_count
      assert_match(/Result: .* PASS/, @output.string)
    end
  end

  def test_cli_provider_falls_back_without_metadata_yml
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])

      # Simulate agent-written report dir WITHOUT metadata.yml
      agent_dir = File.join(tmpdir, ".ace-local", "test-e2e", "nomta1-my-pkg-ts001-reports")
      FileUtils.mkdir_p(agent_dir)
      File.write(File.join(agent_dir, "summary.r.md"), "# Report")

      executor = StubExecutor.new(status: "error", summary: "Parse error")
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        timestamp_generator: -> { "nomta1" },
        executor: executor
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      # Should fall back to executor result status since no metadata.yml
      assert_equal "error", results.first.status
      assert_equal agent_dir, results.first.report_dir
    end
  end

  def test_cli_provider_passes_run_id_to_executor
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])

      received_run_id = nil
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil|
        received_run_id = run_id
        TestResult.new(
          test_id: scenario.test_id,
          status: "pass",
          summary: "OK",
          started_at: Time.now,
          completed_at: Time.now + 1
        )
      end

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        timestamp_generator: -> { "runid1" },
        executor: executor
      )

      orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert_equal "runid1", received_run_id
    end
  end

  def test_api_provider_does_not_pass_run_id_to_executor
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])

      received_run_id = :not_called
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil|
        received_run_id = run_id
        TestResult.new(
          test_id: scenario.test_id,
          status: "pass",
          summary: "OK",
          started_at: Time.now,
          completed_at: Time.now + 1
        )
      end

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "google:gemini-2.5-flash",
        timestamp_generator: -> { "api001" },
        executor: executor
      )

      orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert_nil received_run_id
    end
  end

  def test_batch_run_generates_unique_run_ids_for_cli_provider
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-002", %w[TC-001])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-003", %w[TC-001])

      received_run_ids = []
      mutex = Mutex.new
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil|
        mutex.synchronize { received_run_ids << run_id }
        TestResult.new(
          test_id: scenario.test_id,
          status: "pass",
          summary: "OK",
          started_at: Time.now,
          completed_at: Time.now + 1
        )
      end

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        executor: executor
      )

      orchestrator.run(
        package: "my-pkg",
        output: @output
      )

      # All run_ids should be non-nil and unique
      assert_equal 3, received_run_ids.size
      assert received_run_ids.none?(&:nil?), "All run_ids should be non-nil for CLI provider"
      assert_equal received_run_ids.uniq.size, received_run_ids.size, "All run_ids should be unique"
    end
  end

  def test_parallel_execution_runs_all_tests
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-002", %w[TC-001])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-003", %w[TC-001])
      orchestrator = create_orchestrator(base_dir: tmpdir, parallel: 2)

      results = orchestrator.run(
        package: "my-pkg",
        output: @output
      )

      assert_equal 3, results.size
      assert(results.all?(&:success?), "All results should pass")
      assert_match(/Tests:\s+3 passed, 0 failed/, @output.string)
      # All test IDs should appear in output
      assert_match(/TS-TEST-001/, @output.string)
      assert_match(/TS-TEST-002/, @output.string)
      assert_match(/TS-TEST-003/, @output.string)
    end
  end

  def test_parallel_default_from_config
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-002", %w[TC-001])
      # Don't pass parallel: — let it pick up from config (default 3)
      orchestrator = TestOrchestrator.new(
        provider: "test:stub",
        timeout: 10,
        base_dir: tmpdir,
        timestamp_generator: -> { "test00" },
        executor: StubExecutor.new
      )

      results = orchestrator.run(
        package: "my-pkg",
        output: @output
      )

      assert_equal 2, results.size
      assert(results.all?(&:success?))
    end
  end

  def test_parallel_one_behaves_sequentially
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-002", %w[TC-001])
      execution_order = []
      mutex = Mutex.new

      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil|
        mutex.synchronize { execution_order << scenario.test_id }
        TestResult.new(
          test_id: scenario.test_id,
          status: "pass",
          summary: "OK",
          started_at: Time.now,
          completed_at: Time.now + 1
        )
      end

      orchestrator = create_orchestrator(base_dir: tmpdir, executor: executor, parallel: 1)

      results = orchestrator.run(
        package: "my-pkg",
        output: @output
      )

      assert_equal 2, results.size
      assert_equal %w[TS-TEST-001 TS-TEST-002], execution_order
      assert_match(/Tests:\s+2 passed, 0 failed/, @output.string)
      # Should NOT show parallelism message
      refute_match(/parallelism/, @output.string)
    end
  end

  def test_run_uses_externally_provided_run_id
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        timestamp_generator: -> { "should_not_use" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        run_id: "ext123",
        output: @output
      )

      # The external run_id should be used in the report dir path
      assert results.first.report_dir.include?("ext123"),
        "Should use externally provided run_id, got: #{results.first.report_dir}"
      refute results.first.report_dir.include?("should_not_use"),
        "Should NOT use timestamp generator when run_id provided"
    end
  end

  def test_run_generates_timestamp_when_no_run_id
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        timestamp_generator: -> { "gen789" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      # Should fall back to timestamp generator when no run_id provided
      assert results.first.report_dir.include?("gen789"),
        "Should use timestamp generator when no run_id, got: #{results.first.report_dir}"
    end
  end

  def test_parallel_results_preserve_order
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-002", %w[TC-001])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-003", %w[TC-001])

      # Executor where test 1 is slow, test 2/3 are fast
      # With parallel > 1, test 2 may finish before test 1
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil|
        sleep(0.05) if scenario.test_id == "TS-TEST-001"
        TestResult.new(
          test_id: scenario.test_id,
          status: "pass",
          summary: "OK",
          started_at: Time.now,
          completed_at: Time.now + 1
        )
      end

      orchestrator = create_orchestrator(base_dir: tmpdir, executor: executor, parallel: 3)

      results = orchestrator.run(
        package: "my-pkg",
        output: @output
      )

      # Results array should be in original file order regardless of completion order
      assert_equal %w[TS-TEST-001 TS-TEST-002 TS-TEST-003], results.map(&:test_id)
    end
  end

  def test_cli_provider_runs_setup_before_execution
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package_with_setup(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])

      received = {}
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil|
        received[:sandbox_path] = sandbox_path
        received[:env_vars] = env_vars
        TestResult.new(
          test_id: scenario.test_id,
          status: "pass",
          summary: "OK",
          started_at: Time.now,
          completed_at: Time.now + 1
        )
      end

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        executor: executor
      )

      orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      refute_nil received[:sandbox_path], "sandbox_path should be set for CLI provider"
      assert received[:sandbox_path].include?(".ace-local/test-e2e/"),
        "sandbox_path should be under .ace-local/test-e2e/"
      assert_instance_of Hash, received[:env_vars]
      # PROJECT_ROOT_PATH should be expanded to absolute sandbox path
      assert received[:env_vars]["PROJECT_ROOT_PATH"].end_with?(".ace-local/test-e2e/test00-my-pkg-ts001"),
        "PROJECT_ROOT_PATH should be expanded to absolute sandbox path"
    end
  end

  def test_cli_provider_passes_run_id_to_setup_tmux_session
    skip "tmux not available" unless system("tmux", "-V", out: File::NULL, err: File::NULL)

    Dir.mktmpdir do |tmpdir|
      create_ts_test_package_with_run_id_tmux_setup(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])

      received = {}
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil|
        received[:env_vars] = env_vars
        TestResult.new(
          test_id: scenario.test_id,
          status: "pass",
          summary: "OK",
          started_at: Time.now,
          completed_at: Time.now + 1
        )
      end

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        executor: executor,
        timestamp_generator: -> { "8pny7t0" }
      )

      orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert_equal "8pny7t0", received.dig(:env_vars, "ACE_TMUX_SESSION")
    ensure
      system("tmux", "kill-session", "-t", "8pny7t0", out: File::NULL, err: File::NULL)
    end
  end

  def test_cli_provider_sandbox_includes_tc_files
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package_with_setup(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001 TC-002])

      received_sandbox = nil
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil|
        received_sandbox = sandbox_path
        TestResult.new(
          test_id: scenario.test_id,
          status: "pass",
          summary: "OK",
          started_at: Time.now,
          completed_at: Time.now + 1
        )
      end

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        executor: executor
      )

      orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      refute_nil received_sandbox, "sandbox_path should be set"
      assert File.exist?(File.join(received_sandbox, "sample.txt")),
        "fixture files must be copied to sandbox for setup execution"
    end
  end

  def test_api_provider_does_not_run_setup
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package_with_setup(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001])

      received = {}
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil|
        received[:sandbox_path] = sandbox_path
        received[:env_vars] = env_vars
        TestResult.new(
          test_id: scenario.test_id,
          status: "pass",
          summary: "OK",
          started_at: Time.now,
          completed_at: Time.now + 1
        )
      end

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "google:gemini-2.5-flash",
        executor: executor
      )

      orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert_nil received[:sandbox_path], "sandbox_path should be nil for API providers"
      assert_nil received[:env_vars], "env_vars should be nil for API providers"
    end
  end

  def test_cli_provider_reconciles_all_passed_metadata_to_pass
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001 TC-002 TC-003])

      # Simulate agent-written report with status "fail" but all 3/3 passed
      agent_dir = File.join(tmpdir, ".ace-local", "test-e2e", "rec001-my-pkg-ts001-reports")
      FileUtils.mkdir_p(agent_dir)
      File.write(File.join(agent_dir, "metadata.yml"), <<~YAML)
        status: "fail"
        results:
          passed: 3
          failed: 0
          total: 3
      YAML

      executor = StubExecutor.new(status: "fail", summary: "Agent said fail")
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        timestamp_generator: -> { "rec001" },
        executor: executor
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert_equal "pass", results.first.status
      assert_equal 3, results.first.passed_count
      assert_equal 0, results.first.failed_count
    end
  end

  def test_cli_provider_keeps_fail_when_cases_not_all_passed
    Dir.mktmpdir do |tmpdir|
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001 TC-002 TC-003])

      agent_dir = File.join(tmpdir, ".ace-local", "test-e2e", "rec002-my-pkg-ts001-reports")
      FileUtils.mkdir_p(agent_dir)
      File.write(File.join(agent_dir, "metadata.yml"), <<~YAML)
        status: "fail"
        results:
          passed: 2
          failed: 1
          total: 3
      YAML

      executor = StubExecutor.new(status: "fail", summary: "Agent said fail")
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        timestamp_generator: -> { "rec002" },
        executor: executor
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "TS-TEST-001",
        output: @output
      )

      assert_equal "fail", results.first.status
      assert_equal 2, results.first.passed_count
      assert_equal 1, results.first.failed_count
    end
  end

  def test_package_run_with_test_cases_skips_non_matching_scenarios
    Dir.mktmpdir do |tmpdir|
      # Create two scenarios with different test cases
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001", %w[TC-001 TC-002])
      create_ts_test_package(tmpdir, "my-pkg", "TS-TEST-002", %w[TC-003 TC-004])

      executed_scenarios = []
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil|
        executed_scenarios << { test_id: scenario.test_id, test_cases: test_cases }
        TestResult.new(
          test_id: scenario.test_id,
          status: "pass",
          summary: "Passed",
          started_at: Time.now,
          completed_at: Time.now + 1
        )
      end

      orchestrator = create_orchestrator(base_dir: tmpdir, executor: executor)

      # Filter to TC-001 which only exists in TS-TEST-001
      results = orchestrator.run(
        package: "my-pkg",
        test_cases: %w[TC-001],
        output: @output
      )

      assert_equal 2, results.size

      # Only TS-TEST-001 should have been executed via the executor
      assert_equal 1, executed_scenarios.size
      assert_equal "TS-TEST-001", executed_scenarios.first[:test_id]
      assert_equal %w[TC-001], executed_scenarios.first[:test_cases]

      # TS-TEST-002 should be skipped (no matching test cases)
      skipped_result = results.find { |r| r.test_id == "TS-TEST-002" }
      assert_equal "skip", skipped_result&.status
    end
  end

  def test_standalone_scenario_does_not_force_verify_when_flag_disabled
    Dir.mktmpdir do |tmpdir|
      create_goal_ts_test_package(tmpdir, "my-pkg", "TS-TEST-001")
      expected_dir = File.join(tmpdir, ".ace-local", "test-e2e", "test00-my-pkg-ts001-reports")
      FileUtils.mkdir_p(expected_dir)

      captured_verify = nil
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil, verify: false|
        captured_verify = verify
        TestResult.new(
          test_id: scenario.test_id,
          status: "pass",
          summary: "OK",
          started_at: Time.now,
          completed_at: Time.now + 1
        )
      end

      orchestrator = create_orchestrator(base_dir: tmpdir, executor: executor, provider: "claude:sonnet")
      orchestrator.run(package: "my-pkg", test_id: "TS-TEST-001", verify: false, output: @output)

      assert_equal false, captured_verify
    end
  end

  private

  def create_orchestrator(base_dir: nil, timestamp_generator: nil, executor: nil, provider: nil, parallel: nil)
    base = base_dir || File.expand_path("../../..", __dir__)
    TestOrchestrator.new(
      provider: provider || "test:stub",
      timeout: 10,
      parallel: parallel || 1,
      base_dir: base,
      timestamp_generator: timestamp_generator || -> { "test00" },
      executor: executor || StubExecutor.new
    )
  end

  def create_ts_test_package(tmpdir, package, scenario_id, tc_ids)
    ts_dir = File.join(tmpdir, package, "test", "e2e", "#{scenario_id}-test")
    FileUtils.mkdir_p(ts_dir)

    File.write(File.join(ts_dir, "scenario.yml"), <<~YAML)
      test-id: #{scenario_id}
      title: Test #{scenario_id}
      area: test
      package: #{package}
      priority: medium
    YAML

    runner_files = tc_ids.map { |tc_id| "          - ./#{tc_id}-check.runner.md" }.join("\n")
    verify_files = tc_ids.map { |tc_id| "          - ./#{tc_id}-check.verify.md" }.join("\n")

    File.write(File.join(ts_dir, "runner.yml.md"), <<~MD)
      ---
      bundle:
        files:
#{runner_files}
      ---

      # Runner
      Workspace root: (current directory)
    MD

    File.write(File.join(ts_dir, "verifier.yml.md"), <<~MD)
      ---
      bundle:
        files:
#{verify_files}
      ---

      # Verifier
    MD

    tc_ids.each do |tc_id|
      File.write(File.join(ts_dir, "#{tc_id}-check.runner.md"), <<~CONTENT)
        # Goal #{tc_id}
        Run #{tc_id}.
      CONTENT
      File.write(File.join(ts_dir, "#{tc_id}-check.verify.md"), <<~CONTENT)
        # Verify #{tc_id}
        Verify #{tc_id}.
      CONTENT
    end
  end

  def create_ts_test_package_with_setup(tmpdir, package, scenario_id, tc_ids)
    ts_dir = File.join(tmpdir, package, "test", "e2e", "#{scenario_id}-test")
    fixtures_dir = File.join(ts_dir, "fixtures")
    FileUtils.mkdir_p(fixtures_dir)
    File.write(File.join(fixtures_dir, "sample.txt"), "fixture content")

    File.write(File.join(ts_dir, "scenario.yml"), <<~YAML)
      test-id: #{scenario_id}
      title: Test #{scenario_id}
      area: test
      package: #{package}
      priority: medium
      setup:
        - copy-fixtures
        - agent-env:
            PROJECT_ROOT_PATH: "."
    YAML

    runner_files = tc_ids.map { |tc_id| "          - ./#{tc_id}-check.runner.md" }.join("\n")
    verify_files = tc_ids.map { |tc_id| "          - ./#{tc_id}-check.verify.md" }.join("\n")

    File.write(File.join(ts_dir, "runner.yml.md"), <<~MD)
      ---
      bundle:
        files:
#{runner_files}
      ---

      # Runner
      Workspace root: (current directory)
    MD

    File.write(File.join(ts_dir, "verifier.yml.md"), <<~MD)
      ---
      bundle:
        files:
#{verify_files}
      ---

      # Verifier
    MD

    tc_ids.each do |tc_id|
      File.write(File.join(ts_dir, "#{tc_id}-check.runner.md"), <<~CONTENT)
        # Goal #{tc_id}
        Run #{tc_id}.
      CONTENT
      File.write(File.join(ts_dir, "#{tc_id}-check.verify.md"), <<~CONTENT)
        # Verify #{tc_id}
        Verify #{tc_id}.
      CONTENT
    end
  end

  def create_ts_test_package_with_run_id_tmux_setup(tmpdir, package, scenario_id, tc_ids)
    ts_dir = File.join(tmpdir, package, "test", "e2e", "#{scenario_id}-tmux-runid")
    FileUtils.mkdir_p(ts_dir)

    File.write(File.join(ts_dir, "scenario.yml"), <<~YAML)
      test-id: #{scenario_id}
      title: Test #{scenario_id}
      area: test
      package: #{package}
      priority: medium
      setup:
        - tmux-session:
            name-source: run-id
        - agent-env:
            PROJECT_ROOT_PATH: "."
    YAML

    runner_files = tc_ids.map { |tc_id| "          - ./#{tc_id}-check.runner.md" }.join("\n")
    verify_files = tc_ids.map { |tc_id| "          - ./#{tc_id}-check.verify.md" }.join("\n")

    File.write(File.join(ts_dir, "runner.yml.md"), <<~MD)
      ---
      bundle:
        files:
#{runner_files}
      ---

      # Runner
      Workspace root: (current directory)
    MD

    File.write(File.join(ts_dir, "verifier.yml.md"), <<~MD)
      ---
      bundle:
        files:
#{verify_files}
      ---

      # Verifier
    MD

    tc_ids.each do |tc_id|
      File.write(File.join(ts_dir, "#{tc_id}-check.runner.md"), <<~CONTENT)
        # Goal #{tc_id}
        Run #{tc_id}.
      CONTENT
      File.write(File.join(ts_dir, "#{tc_id}-check.verify.md"), <<~CONTENT)
        # Verify #{tc_id}
        Verify #{tc_id}.
      CONTENT
    end
  end

  def create_goal_ts_test_package(tmpdir, package, scenario_id)
    ts_dir = File.join(tmpdir, package, "test", "e2e", "#{scenario_id}-goal")
    FileUtils.mkdir_p(ts_dir)

    File.write(File.join(ts_dir, "scenario.yml"), <<~YAML)
      test-id: #{scenario_id}
      title: Goal #{scenario_id}
      area: test
      package: #{package}
      tool-under-test: fake-tool
    YAML

    File.write(File.join(ts_dir, "runner.yml.md"), <<~MD)
      ---
      bundle:
        files:
          - ./TC-001-first.runner.md
      ---

      # Runner
    MD

    File.write(File.join(ts_dir, "verifier.yml.md"), <<~MD)
      ---
      bundle:
        files:
          - ./TC-001-first.verify.md
      ---

      # Verifier
    MD

    File.write(File.join(ts_dir, "TC-001-first.runner.md"), "# Goal 1")
    File.write(File.join(ts_dir, "TC-001-first.verify.md"), "# Verify 1")
  end
end
