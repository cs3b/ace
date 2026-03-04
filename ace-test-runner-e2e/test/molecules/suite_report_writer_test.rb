# frozen_string_literal: true

require_relative "../test_helper"

class SuiteReportWriterTest < Minitest::Test
  SuiteReportWriter = Ace::Test::EndToEndRunner::Molecules::SuiteReportWriter
  TestResult = Ace::Test::EndToEndRunner::Models::TestResult
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario

  def setup
    @writer = SuiteReportWriter.new(config: {})
  end

  def test_writes_report_to_correct_path
    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_results_and_scenarios(tmpdir)
      stub_llm_query("# LLM Report")

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "abc123", base_dir: tmpdir)

      assert_equal File.join(tmpdir, ".ace-local", "test-e2e", "abc123-final-report.md"), path
      assert File.exist?(path), "Report file should exist"
    end
  end

  def test_llm_response_is_written_to_file
    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_results_and_scenarios(tmpdir)
      stub_llm_query("# Synthesized Report\n\n**Overall:** 3/4 test cases passed (75%)\n\nRich analysis.")

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      content = File.read(path)
      assert_match(/Synthesized Report/, content)
      assert_match(/Rich analysis/, content)
      # Overall line is validated/replaced with deterministic values
      assert_match(/\*\*Overall:\*\* 3\/4 test cases passed \(75%\)/, content)
    end
  end

  def test_llm_failure_falls_back_to_static_template
    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_results_and_scenarios(tmpdir)
      stub_llm_query_failure(RuntimeError.new("LLM unavailable"))

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      content = File.read(path)
      # Static template assertions
      assert_match(/^suite-id: ts1234$/, content)
      assert_match(/^package: ace-lint$/, content)
      assert_match(/^status: (pass|partial|fail)$/, content)
      assert_match(/## Summary/, content)
      assert_match(/TS-TEST-001/, content)
      assert_match(/TS-TEST-002/, content)
      assert_match(/\*\*Overall:\*\*/, content)
    end
  end

  def test_static_fallback_frontmatter_contains_required_keys
    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_results_and_scenarios(tmpdir)
      stub_llm_query_failure(RuntimeError.new("timeout"))

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      content = File.read(path)
      assert_match(/^suite-id: ts1234$/, content)
      assert_match(/^package: ace-lint$/, content)
      assert_match(/^status: (pass|partial|fail)$/, content)
      assert_match(/^tests-run: 2$/, content)
      assert_match(/^executed: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/, content)
    end
  end

  def test_static_fallback_summary_table_lists_all_tests
    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_results_and_scenarios(tmpdir)
      stub_llm_query_failure(RuntimeError.new("network error"))

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      content = File.read(path)
      assert_match(/## Summary/, content)
      assert_match(/TS-TEST-001/, content)
      assert_match(/TS-TEST-002/, content)
      assert_match(/\| Test ID \| Title \| Status \| Passed \| Failed \| Total \|/, content)
    end
  end

  def test_static_fallback_overall_line_shows_tc_stats
    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_results_and_scenarios(tmpdir)
      stub_llm_query_failure(RuntimeError.new("error"))

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      content = File.read(path)
      assert_match(/\*\*Overall:\*\* 3\/4 test cases passed \(75%\)/, content)
    end
  end

  def test_static_fallback_failed_section_appears_when_failures_exist
    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_results_and_scenarios(tmpdir)
      stub_llm_query_failure(RuntimeError.new("error"))

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      content = File.read(path)
      assert_match(/## Failed Tests/, content)
      assert_match(/TS-TEST-002/, content)
      assert_match(/TC-002/, content)
      assert_match(/Second check/, content)
    end
  end

  def test_static_fallback_no_failed_section_when_all_pass
    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_all_passing(tmpdir)
      stub_llm_query_failure(RuntimeError.new("error"))

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      content = File.read(path)
      refute_match(/## Failed Tests/, content)
    end
  end

  def test_static_fallback_status_is_pass_when_all_pass
    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_all_passing(tmpdir)
      stub_llm_query_failure(RuntimeError.new("error"))

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      content = File.read(path)
      assert_match(/^status: pass$/, content)
    end
  end

  def test_static_fallback_status_is_fail_when_all_fail
    Dir.mktmpdir do |tmpdir|
      results = [
        TestResult.new(test_id: "TS-TEST-001", status: "fail",
                       test_cases: [{ id: "TC-001", description: "Check", status: "fail" }],
                       summary: "Failed")
      ]
      scenarios = [make_scenario("TS-TEST-001", "Test One")]
      stub_llm_query_failure(RuntimeError.new("error"))

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      content = File.read(path)
      assert_match(/^status: fail$/, content)
    end
  end

  def test_reads_summary_and_experience_from_report_dirs
    Dir.mktmpdir do |tmpdir|
      # Create report dirs with summary and experience files
      report_dir = File.join(tmpdir, ".ace-local", "test-e2e", "ts1234-lint-ts001-reports")
      FileUtils.mkdir_p(report_dir)
      File.write(File.join(report_dir, "summary.r.md"), "## Summary\nTest passed cleanly.")
      File.write(File.join(report_dir, "experience.r.md"), "## Experience\nSmooth run.")

      results = [
        TestResult.new(
          test_id: "TS-TEST-001", status: "pass",
          test_cases: [{ id: "TC-001", description: "Check", status: "pass" }],
          summary: "Passed",
          report_dir: report_dir
        )
      ]
      scenarios = [make_scenario("TS-TEST-001", "Test One")]

      # Capture the prompt passed to LLM to verify report content was included
      captured_prompt = nil
      Ace::LLM::QueryInterface.define_singleton_method(:query) do |_model, prompt, **_opts|
        captured_prompt = prompt
        { text: "# LLM Report" }
      end

      @writer.write(results, scenarios,
                    package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      assert_match(/Test passed cleanly/, captured_prompt)
      assert_match(/Smooth run/, captured_prompt)
    ensure
      restore_llm_query
    end
  end

  def test_handles_missing_report_files_gracefully
    Dir.mktmpdir do |tmpdir|
      # Report dir exists but no files inside
      report_dir = File.join(tmpdir, ".ace-local", "test-e2e", "ts1234-lint-ts001-reports")
      FileUtils.mkdir_p(report_dir)

      results = [
        TestResult.new(
          test_id: "TS-TEST-001", status: "pass",
          test_cases: [{ id: "TC-001", description: "Check", status: "pass" }],
          summary: "Passed",
          report_dir: report_dir
        )
      ]
      scenarios = [make_scenario("TS-TEST-001", "Test One")]

      captured_prompt = nil
      Ace::LLM::QueryInterface.define_singleton_method(:query) do |_model, prompt, **_opts|
        captured_prompt = prompt
        { text: "# LLM Report" }
      end

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      assert File.exist?(path)
      # Should not include summary/experience sections since files don't exist
      refute_match(/Summary Report/, captured_prompt)
      refute_match(/Experience Report/, captured_prompt)
    ensure
      restore_llm_query
    end
  end

  def test_configurable_model_passed_through
    config = { "reporting" => { "model" => "gflash", "timeout" => 120 } }
    writer = SuiteReportWriter.new(config: config)

    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_all_passing(tmpdir)

      captured_model = nil
      captured_timeout = nil
      Ace::LLM::QueryInterface.define_singleton_method(:query) do |model, _prompt, **opts|
        captured_model = model
        captured_timeout = opts[:timeout]
        { text: "# Report" }
      end

      writer.write(results, scenarios,
                   package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      assert_equal "gflash", captured_model
      assert_equal 120, captured_timeout
    ensure
      restore_llm_query
    end
  end

  def test_llm_hallucinated_overall_line_is_corrected
    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_results_and_scenarios(tmpdir)
      # LLM returns wrong aggregate: "6/27 (22%)" instead of correct "3/4 (75%)"
      stub_llm_query("# Report\n\n**Overall:** 6/27 test cases passed (22%)\n\nAnalysis.")

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      content = File.read(path)
      # Wrong numbers must be replaced with correct deterministic values
      refute_match(/6\/27/, content)
      refute_match(/22%/, content)
      assert_match(/\*\*Overall:\*\* 3\/4 test cases passed \(75%\)/, content)
    end
  end

  def test_llm_missing_overall_line_gets_appended
    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_results_and_scenarios(tmpdir)
      # LLM omits the Overall line entirely
      stub_llm_query("# Report\n\nSome analysis without overall line.")

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      content = File.read(path)
      assert_match(/\*\*Overall:\*\* 3\/4 test cases passed \(75%\)/, content)
    end
  end

  def test_llm_correct_overall_line_is_preserved
    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_results_and_scenarios(tmpdir)
      stub_llm_query("# Report\n\n**Overall:** 3/4 test cases passed (75%)\n\nCorrect analysis.")

      path = @writer.write(results, scenarios,
                           package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      content = File.read(path)
      assert_match(/\*\*Overall:\*\* 3\/4 test cases passed \(75%\)/, content)
      assert_match(/Correct analysis/, content)
    end
  end

  def test_creates_cache_directory
    Dir.mktmpdir do |tmpdir|
      results, scenarios = build_all_passing(tmpdir)
      stub_llm_query("# Report")
      cache_dir = File.join(tmpdir, ".ace-local", "test-e2e")
      refute Dir.exist?(cache_dir), "Cache dir should not exist before write"

      @writer.write(results, scenarios,
                    package: "ace-lint", timestamp: "ts1234", base_dir: tmpdir)

      assert Dir.exist?(cache_dir), "Cache dir should be created"
    end
  end

  private

  # Stub LLM to return a successful response
  def stub_llm_query(text)
    Ace::LLM::QueryInterface.define_singleton_method(:query) do |_model, _prompt, **_opts|
      { text: text }
    end
  end

  # Stub LLM to raise an error (triggers static fallback)
  def stub_llm_query_failure(error)
    Ace::LLM::QueryInterface.define_singleton_method(:query) do |_model, _prompt, **_opts|
      raise error
    end
  end

  # Restore original LLM query method
  def restore_llm_query
    if Ace::LLM::QueryInterface.singleton_class.method_defined?(:query)
      Ace::LLM::QueryInterface.singleton_class.remove_method(:query)
    end
  end

  def make_scenario(test_id, title)
    TestScenario.new(
      test_id: test_id,
      title: title,
      area: "test",
      package: "ace-lint",
      file_path: "/tmp/#{test_id}scenario.yml",
      content: "# #{test_id}"
    )
  end

  def build_results_and_scenarios(tmpdir)
    scenarios = [
      make_scenario("TS-TEST-001", "Test One"),
      make_scenario("TS-TEST-002", "Test Two")
    ]

    results = [
      TestResult.new(
        test_id: "TS-TEST-001",
        status: "pass",
        test_cases: [
          { id: "TC-001", description: "First check", status: "pass" },
          { id: "TC-002", description: "Second check", status: "pass" }
        ],
        summary: "All passed",
        report_dir: File.join(tmpdir, ".ace-local", "test-e2e", "ts1234-lint-ts001-reports")
      ),
      TestResult.new(
        test_id: "TS-TEST-002",
        status: "fail",
        test_cases: [
          { id: "TC-001", description: "First check", status: "pass" },
          { id: "TC-002", description: "Second check", status: "fail" }
        ],
        summary: "One failed",
        report_dir: File.join(tmpdir, ".ace-local", "test-e2e", "ts1234-lint-mt002-reports")
      )
    ]

    [results, scenarios]
  end

  def build_all_passing(tmpdir)
    scenarios = [
      make_scenario("TS-TEST-001", "Test One"),
      make_scenario("TS-TEST-002", "Test Two")
    ]

    results = [
      TestResult.new(
        test_id: "TS-TEST-001",
        status: "pass",
        test_cases: [
          { id: "TC-001", description: "First check", status: "pass" }
        ],
        summary: "Passed",
        report_dir: File.join(tmpdir, ".ace-local", "test-e2e", "ts1234-lint-ts001-reports")
      ),
      TestResult.new(
        test_id: "TS-TEST-002",
        status: "pass",
        test_cases: [
          { id: "TC-001", description: "First check", status: "pass" }
        ],
        summary: "Passed",
        report_dir: File.join(tmpdir, ".ace-local", "test-e2e", "ts1234-lint-mt002-reports")
      )
    ]

    [results, scenarios]
  end
end
