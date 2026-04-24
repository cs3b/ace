# frozen_string_literal: true

require_relative "../../test_helper"
require "fileutils"
require "stringio"
require "tmpdir"
require "yaml"

class RunSuiteTest < Minitest::Test
  RunSuite = Ace::Test::EndToEndRunner::CLI::Commands::RunSuite
  SuiteOrchestrator = Ace::Test::EndToEndRunner::Organisms::SuiteOrchestrator

  class StubSuiteOrchestrator
    attr_reader :calls

    def initialize(*responses)
      @responses = responses
      @calls = []
    end

    def run(options = {})
      @calls << options.dup
      response = @responses.shift
      raise "Unexpected orchestrator call" unless response

      Marshal.load(Marshal.dump(response))
    end
  end

  class StubRunSuite < RunSuite
    def initialize(orchestrator)
      super()
      @orchestrator = orchestrator
    end

    private

    def build_orchestrator(max_parallel:, output:, progress:)
      @orchestrator
    end
  end

  def setup
    @output = StringIO.new
  end

  def test_run_suite_default_options
    command = RunSuite.new

    # Just verify the command can be created
    assert_instance_of RunSuite, command
  end

  def test_run_suite_is_dry_cli_command
    command = RunSuite.new

    assert_kind_of Ace::Support::Cli::Command, command
  end

  def test_run_suite_has_call_method
    command = RunSuite.new

    assert_respond_to command, :call
  end

  def test_coerce_types_converts_string_to_integer
    command = RunSuite.new

    # Use the protected coerce_types method via the Base module
    result = command.send(:coerce_types, {parallel: "4", timeout: "120"}, parallel: :integer, timeout: :integer)

    assert_equal 4, result[:parallel]
    assert_equal 120, result[:timeout]
  end

  def test_coerce_types_leaves_non_converted_options_alone
    command = RunSuite.new

    result = command.send(:coerce_types, {parallel: "4", other: "string"}, parallel: :integer)

    assert_equal 4, result[:parallel]
    assert_equal "string", result[:other]
  end

  def test_quiet_method_recognizes_quiet_flag
    command = RunSuite.new

    assert command.send(:quiet?, quiet: true)
    refute command.send(:quiet?, quiet: false)
    refute command.send(:quiet?, {})
  end

  def test_call_accepts_packages_argument
    command = RunSuite.new

    # Verify the call method accepts packages as a keyword argument
    method = command.method(:call)
    param_names = method.parameters.map(&:last)
    assert_includes param_names, :packages
  end

  def test_run_suite_is_available_as_command_class
    assert_equal RunSuite, Ace::Test::EndToEndRunner::CLI::Commands::RunSuite
  end

  def test_call_accepts_only_failures_option
    command = RunSuite.new

    # Verify the call method signature accepts only_failures via **options
    method = command.method(:call)
    # **options captures only_failures
    param_types = method.parameters.map(&:first)
    assert_includes param_types, :keyrest, "call should accept **options for only_failures"
  end

  def test_parse_csv_list_normalizes_tags
    command = RunSuite.new

    tags = command.send(:parse_csv_list, "Smoke, happy-path, use-case:Lint")

    assert_equal ["smoke", "happy-path", "use-case:lint"], tags
  end

  def test_full_suite_retries_once_and_writes_flaky_wrapper_report
    Dir.mktmpdir do |tmpdir|
      first_dir = create_scenario_report(
        tmpdir,
        report_dir_name: "8rniaaa-tmux-ts002-reports",
        test_id: "TS-TMUX-002",
        title: "ace-tmux Outside-Tmux Window Targeting",
        package: "ace-tmux",
        status: "fail",
        failed: [
          {
            "tc" => "TC-005",
            "category" => "test-spec-error",
            "evidence" => "target-session.txt was missing on attempt 1"
          }
        ]
      )
      retry_dir = create_scenario_report(
        tmpdir,
        report_dir_name: "8rnibbb-tmux-ts002-reports",
        test_id: "TS-TMUX-002",
        title: "ace-tmux Outside-Tmux Window Targeting",
        package: "ace-tmux",
        status: "pass",
        failed: []
      )
      first_report = create_suite_report(tmpdir, "8rni111-suite-report.md")
      retry_report = create_suite_report(tmpdir, "8rni222-suite-report.md")

      orchestrator = StubSuiteOrchestrator.new(
        suite_results_for("fail", "TS-TMUX-002-window-targeting", first_dir, first_report),
        suite_results_for("pass", "TS-TMUX-002-window-targeting", retry_dir, retry_report)
      )
      command = StubRunSuite.new(orchestrator)

      results = Dir.chdir(tmpdir) { command.call(parallel: "0", quiet: true) }

      assert_equal 2, orchestrator.calls.length
      assert_equal false, orchestrator.calls.first[:only_failures]
      assert_equal true, orchestrator.calls.last[:only_failures]
      assert_equal true, results[:retry_attempted]
      assert_equal 2, results[:attempts]
      assert_equal ["TS-TMUX-002"], results[:flaky_scenarios].map { |entry| entry["test_id"] }
      assert File.exist?(results[:report_path]), "Expected final wrapper report to be written"

      content = File.read(results[:report_path])
      assert_includes content, "## Flaky Recoveries"
      assert_includes content, "TS-TMUX-002"
      assert_includes content, "target-session.txt was missing on attempt 1"
      assert_includes content, "8rni111-suite-report.md"
      assert_includes content, "8rni222-suite-report.md"
    end
  end

  def test_full_suite_pass_does_not_retry
    Dir.mktmpdir do |tmpdir|
      pass_dir = create_scenario_report(
        tmpdir,
        report_dir_name: "8rniccc-lint-ts001-reports",
        test_id: "TS-LINT-001",
        title: "ace-lint Goal-Based E2E",
        package: "ace-lint",
        status: "pass",
        failed: []
      )
      pass_report = create_suite_report(tmpdir, "8rni333-suite-report.md")

      orchestrator = StubSuiteOrchestrator.new(
        suite_results_for("pass", "TS-LINT-001-lint-pipeline", pass_dir, pass_report)
      )
      command = StubRunSuite.new(orchestrator)

      results = Dir.chdir(tmpdir) { command.call(parallel: "0", quiet: true) }

      assert_equal 1, orchestrator.calls.length
      assert_equal false, results[:retry_attempted]
      assert_equal 1, results[:attempts]
    end
  end

  def test_packages_filter_defaults_retry_off
    Dir.mktmpdir do |tmpdir|
      fail_dir = create_scenario_report(
        tmpdir,
        report_dir_name: "8rniddd-lint-ts001-reports",
        test_id: "TS-LINT-001",
        title: "ace-lint Goal-Based E2E",
        package: "ace-lint",
        status: "fail",
        failed: [{"tc" => "TC-001", "category" => "runner-error", "evidence" => "lint failed"}]
      )
      fail_report = create_suite_report(tmpdir, "8rni444-suite-report.md")

      orchestrator = StubSuiteOrchestrator.new(
        suite_results_for("fail", "TS-LINT-001-lint-pipeline", fail_dir, fail_report)
      )
      command = StubRunSuite.new(orchestrator)

      error = assert_raises(Ace::Support::Cli::Error) do
        Dir.chdir(tmpdir) { command.call(packages: "ace-lint", parallel: "0", quiet: true) }
      end

      assert_equal 1, orchestrator.calls.length
      assert_match(/failed or errored/, error.message)
    end
  end

  def test_only_failures_defaults_retry_off
    Dir.mktmpdir do |tmpdir|
      fail_dir = create_scenario_report(
        tmpdir,
        report_dir_name: "8rnieee-lint-ts001-reports",
        test_id: "TS-LINT-001",
        title: "ace-lint Goal-Based E2E",
        package: "ace-lint",
        status: "fail",
        failed: [{"tc" => "TC-001", "category" => "runner-error", "evidence" => "lint failed"}]
      )
      fail_report = create_suite_report(tmpdir, "8rni555-suite-report.md")

      orchestrator = StubSuiteOrchestrator.new(
        suite_results_for("fail", "TS-LINT-001-lint-pipeline", fail_dir, fail_report)
      )
      command = StubRunSuite.new(orchestrator)

      assert_raises(Ace::Support::Cli::Error) do
        Dir.chdir(tmpdir) { command.call(only_failures: true, parallel: "0", quiet: true) }
      end

      assert_equal 1, orchestrator.calls.length
      assert_equal true, orchestrator.calls.first[:only_failures]
    end
  end

  def test_explicit_retry_is_rejected_for_scoped_runs
    orchestrator = StubSuiteOrchestrator.new
    command = StubRunSuite.new(orchestrator)

    error = assert_raises(Ace::Support::Cli::Error) do
      command.call(packages: "ace-lint", parallel: "0", retry_failures_once: true, quiet: true)
    end

    assert_equal 0, orchestrator.calls.length
    assert_match(/only supported for full unfiltered suite runs/, error.message)
  end

  def test_retry_empty_surface_after_failure_raises
    Dir.mktmpdir do |tmpdir|
      fail_dir = create_scenario_report(
        tmpdir,
        report_dir_name: "8rnifff-tmux-ts002-reports",
        test_id: "TS-TMUX-002",
        title: "ace-tmux Outside-Tmux Window Targeting",
        package: "ace-tmux",
        status: "fail",
        failed: [{"tc" => "TC-005", "category" => "test-spec-error", "evidence" => "missing target marker"}]
      )
      fail_report = create_suite_report(tmpdir, "8rni666-suite-report.md")

      orchestrator = StubSuiteOrchestrator.new(
        suite_results_for("fail", "TS-TMUX-002-window-targeting", fail_dir, fail_report),
        {total: 0, passed: 0, failed: 0, errors: 0, packages: {}, report_path: create_suite_report(tmpdir, "8rni777-suite-report.md")}
      )
      command = StubRunSuite.new(orchestrator)

      error = assert_raises(Ace::Support::Cli::Error) do
        Dir.chdir(tmpdir) { command.call(parallel: "0", quiet: true) }
      end

      assert_equal 2, orchestrator.calls.length
      assert_match(/Retry pass found no failed test scenarios/, error.message)
    end
  end

  private

  def create_suite_report(root_dir, filename)
    path = File.join(root_dir, ".ace-local", "test-e2e", filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "# suite report\n")
    path
  end

  def create_scenario_report(root_dir, report_dir_name:, test_id:, title:, package:, status:, failed:)
    report_dir = File.join(root_dir, ".ace-local", "test-e2e", report_dir_name)
    FileUtils.mkdir_p(report_dir)
    metadata = {
      "test-id" => test_id,
      "package" => package,
      "status" => status,
      "failed" => failed,
      "failed_test_cases" => failed.map { |entry| entry["tc"] }.compact,
      "tcs-passed" => (status == "pass" ? 1 : 0),
      "tcs-total" => 1
    }
    File.write(File.join(report_dir, "metadata.yml"), YAML.dump(metadata))
    frontmatter = {
      "test-id" => test_id,
      "title" => title,
      "package" => package,
      "status" => status,
      "failed" => failed
    }
    yaml = YAML.dump(frontmatter).sub(/\A---\s*\n/, "").sub(/\.\.\.\s*\n\z/, "")
    File.write(File.join(report_dir, "report.md"), "---\n#{yaml}---\n\n# report\n")
    report_dir
  end

  def suite_results_for(status, test_name, report_dir, report_path)
    passed = (status == "pass") ? 1 : 0
    failed = (status == "pass") ? 0 : 1
    {
      total: 1,
      passed: passed,
      failed: failed,
      errors: 0,
      packages: {
        "ace-test" => [
          {
            status: status,
            summary: "#{passed}/1 passed",
            test_name: test_name,
            report_dir: report_dir,
            passed_cases: passed,
            total_cases: 1
          }
        ]
      },
      report_path: report_path
    }
  end
end
