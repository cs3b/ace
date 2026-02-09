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

    def execute(scenario, cli_args: nil, run_id: nil, test_cases: nil)
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
      test_id: "MT-LINT-999",
      output: @output
    )

    assert_empty results
    assert_match(/No E2E tests found/, @output.string)
    assert_match(/MT-LINT-999/, @output.string)
  end

  def test_run_single_test_returns_passing_result
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])
      orchestrator = create_orchestrator(base_dir: tmpdir)

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "MT-TEST-001",
        output: @output
      )

      assert_equal 1, results.size
      assert_equal "MT-TEST-001", results.first.test_id
      assert_equal "pass", results.first.status
      assert results.first.success?
      assert_match(/Running E2E test/, @output.string)
      assert_match(/Result: .* PASS/, @output.string)
    end
  end

  def test_run_single_test_shows_tc_counts
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])
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
        test_id: "MT-TEST-001",
        output: @output
      )

      assert_match(/Result: .* PASS\s+2\/2 cases/, @output.string)
    end
  end

  def test_run_single_test_omits_tc_counts_when_zero
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])
      executor = StubExecutor.new(status: "error", test_cases: [])
      orchestrator = create_orchestrator(base_dir: tmpdir, executor: executor)

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "MT-TEST-001",
        output: @output
      )

      # Should show "Result: ✗ ERROR" with no TC counts
      assert_match(/Result: .* ERROR\n/, @output.string)
      refute_match(/cases/, @output.string)
    end
  end

  def test_run_package_returns_all_results
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", %w[MT-TEST-001 MT-TEST-002])
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
      create_test_package(tmpdir, "my-pkg", %w[MT-TEST-001 MT-TEST-002])
      orchestrator = create_orchestrator(base_dir: tmpdir)

      orchestrator.run(package: "my-pkg", output: @output)

      assert_match(/\[started\] MT-TEST-001: Test MT-TEST-001/, @output.string)
      assert_match(/\[started\] MT-TEST-002: Test MT-TEST-002/, @output.string)
    end
  end

  def test_run_package_shows_tc_counts_in_done_lines
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", %w[MT-TEST-001 MT-TEST-002])
      executor = StubExecutor.new(
        status: "pass",
        test_cases: [
          { id: "TC-001", description: "Check", status: "pass" },
          { id: "TC-002", description: "Check", status: "pass" }
        ]
      )
      orchestrator = create_orchestrator(base_dir: tmpdir, executor: executor)

      orchestrator.run(package: "my-pkg", output: @output)

      assert_match(/\[1\/2\] .* MT-TEST-001\s+PASS\s+2\/2 cases/, @output.string)
    end
  end

  def test_run_package_summary_includes_tc_stats
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", %w[MT-TEST-001 MT-TEST-002])
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
      create_test_package(tmpdir, "my-pkg", %w[MT-TEST-001 MT-TEST-002])
      orchestrator = create_orchestrator(base_dir: tmpdir)

      orchestrator.run(package: "my-pkg", output: @output)

      # No TCs → summary without TC stats line
      assert_match(/Tests:\s+2 passed, 0 failed/, @output.string)
      refute_match(/Test cases:/, @output.string)
    end
  end

  def test_run_package_writes_suite_report
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", %w[MT-TEST-001 MT-TEST-002])
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        timestamp_generator: -> { "rpt123" }
      )

      orchestrator.run(package: "my-pkg", output: @output)

      report_path = File.join(tmpdir, ".cache", "ace-test-e2e", "rpt123-final-report.md")
      assert File.exist?(report_path), "Suite report should be created"
      assert_match(/Report: .*rpt123-final-report\.md/, @output.string)
    end
  end

  def test_run_uses_injected_timestamp
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        timestamp_generator: -> { "abc123" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "MT-TEST-001",
        output: @output
      )

      assert results.first.report_dir.include?("abc123")
    end
  end

  def test_report_directory_created
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        timestamp_generator: -> { "ts1234" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "MT-TEST-001",
        output: @output
      )

      report_dir = results.first.report_dir
      assert Dir.exist?(report_dir), "Report directory should be created"
      assert report_dir.include?(".cache/ace-test-e2e/")
    end
  end

  def test_failed_test_result_propagated
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])
      executor = StubExecutor.new(status: "fail", summary: "Test failed")
      orchestrator = create_orchestrator(base_dir: tmpdir, executor: executor)

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "MT-TEST-001",
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
      create_test_package(tmpdir, "my-pkg", %w[MT-TEST-001 MT-TEST-002])
      call_count = 0
      # Executor that alternates pass/fail
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil|
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

  def test_cli_provider_skips_report_writing
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        timestamp_generator: -> { "cli123" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "MT-TEST-001",
        output: @output
      )

      assert_equal 1, results.size
      # CLI providers should NOT have orchestrator-written reports
      report_dir = File.join(tmpdir, ".cache", "ace-test-e2e", "cli123-pkg-mt001-reports")
      refute Dir.exist?(report_dir), "CLI provider should not create report dir via ReportWriter"
      assert_match(/skill mode/, @output.string)
    end
  end

  def test_api_provider_writes_reports
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])
      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "google:gemini-2.5-flash",
        timestamp_generator: -> { "api123" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "MT-TEST-001",
        output: @output
      )

      assert_equal 1, results.size
      report_dir = results.first.report_dir
      assert Dir.exist?(report_dir), "API provider should create report dir via ReportWriter"
      refute_match(/skill mode/, @output.string)
    end
  end

  def test_cli_provider_finds_agent_written_reports
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])

      # Simulate agent-written report dir at the expected path (matching timestamp)
      # short_package for "my-pkg" is "my-pkg" (no ace- prefix to strip)
      # short_id for "MT-TEST-001" is "mt001"
      agent_dir = File.join(tmpdir, ".cache", "ace-test-e2e", "bbb222-my-pkg-mt001-reports")
      FileUtils.mkdir_p(agent_dir)
      File.write(File.join(agent_dir, "summary.r.md"), "# Report")

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        provider: "claude:sonnet",
        timestamp_generator: -> { "bbb222" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "MT-TEST-001",
        output: @output
      )

      assert_equal agent_dir, results.first.report_dir
    end
  end

  def test_cli_provider_reads_metadata_yml_for_status
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])

      # Simulate agent-written report dir with metadata.yml showing pass
      agent_dir = File.join(tmpdir, ".cache", "ace-test-e2e", "meta01-my-pkg-mt001-reports")
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
        test_id: "MT-TEST-001",
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
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])

      # Simulate agent-written report dir WITHOUT metadata.yml
      agent_dir = File.join(tmpdir, ".cache", "ace-test-e2e", "nomta1-my-pkg-mt001-reports")
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
        test_id: "MT-TEST-001",
        output: @output
      )

      # Should fall back to executor result status since no metadata.yml
      assert_equal "error", results.first.status
      assert_equal agent_dir, results.first.report_dir
    end
  end

  def test_cli_provider_passes_run_id_to_executor
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])

      received_run_id = nil
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil|
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
        test_id: "MT-TEST-001",
        output: @output
      )

      assert_equal "runid1", received_run_id
    end
  end

  def test_api_provider_does_not_pass_run_id_to_executor
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])

      received_run_id = :not_called
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil|
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
        test_id: "MT-TEST-001",
        output: @output
      )

      assert_nil received_run_id
    end
  end

  def test_batch_run_generates_unique_run_ids_for_cli_provider
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", %w[MT-TEST-001 MT-TEST-002 MT-TEST-003])

      received_run_ids = []
      mutex = Mutex.new
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil|
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
      create_test_package(tmpdir, "my-pkg", %w[MT-TEST-001 MT-TEST-002 MT-TEST-003])
      orchestrator = create_orchestrator(base_dir: tmpdir, parallel: 2)

      results = orchestrator.run(
        package: "my-pkg",
        output: @output
      )

      assert_equal 3, results.size
      assert(results.all?(&:success?), "All results should pass")
      assert_match(/Tests:\s+3 passed, 0 failed/, @output.string)
      # All test IDs should appear in output
      assert_match(/MT-TEST-001/, @output.string)
      assert_match(/MT-TEST-002/, @output.string)
      assert_match(/MT-TEST-003/, @output.string)
    end
  end

  def test_parallel_default_from_config
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", %w[MT-TEST-001 MT-TEST-002])
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
      create_test_package(tmpdir, "my-pkg", %w[MT-TEST-001 MT-TEST-002])
      execution_order = []
      mutex = Mutex.new

      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil|
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
      assert_equal %w[MT-TEST-001 MT-TEST-002], execution_order
      assert_match(/Tests:\s+2 passed, 0 failed/, @output.string)
      # Should NOT show parallelism message
      refute_match(/parallelism/, @output.string)
    end
  end

  def test_run_uses_externally_provided_run_id
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        timestamp_generator: -> { "should_not_use" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "MT-TEST-001",
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
      create_test_package(tmpdir, "my-pkg", ["MT-TEST-001"])

      orchestrator = create_orchestrator(
        base_dir: tmpdir,
        timestamp_generator: -> { "gen789" }
      )

      results = orchestrator.run(
        package: "my-pkg",
        test_id: "MT-TEST-001",
        output: @output
      )

      # Should fall back to timestamp generator when no run_id provided
      assert results.first.report_dir.include?("gen789"),
        "Should use timestamp generator when no run_id, got: #{results.first.report_dir}"
    end
  end

  def test_parallel_results_preserve_order
    Dir.mktmpdir do |tmpdir|
      create_test_package(tmpdir, "my-pkg", %w[MT-TEST-001 MT-TEST-002 MT-TEST-003])

      # Executor where test 1 is slow, test 2/3 are fast
      # With parallel > 1, test 2 may finish before test 1
      executor = Object.new
      executor.define_singleton_method(:execute) do |scenario, cli_args: nil, run_id: nil, test_cases: nil|
        sleep(0.05) if scenario.test_id == "MT-TEST-001"
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
      assert_equal %w[MT-TEST-001 MT-TEST-002 MT-TEST-003], results.map(&:test_id)
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

  def create_test_package(tmpdir, package, test_ids)
    test_dir = File.join(tmpdir, package, "test", "e2e")
    FileUtils.mkdir_p(test_dir)

    test_ids.each do |test_id|
      File.write(File.join(test_dir, "#{test_id}-test.mt.md"), <<~CONTENT)
        ---
        test-id: #{test_id}
        title: Test #{test_id}
        area: test
        package: #{package}
        ---

        # Test #{test_id}

        ## Test Cases

        ### TC-001: Basic check
        Verify basic functionality.
      CONTENT
    end
  end
end
