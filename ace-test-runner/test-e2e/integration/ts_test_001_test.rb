# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "fileutils"

class TSTEST001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @source_root = ENV.fetch("ACE_E2E_SOURCE_ROOT", @root)
    @exe = File.join(@root, "exe", "ace-test")
  end

  def run_cmd(*args, chdir: @source_root)
    Open3.capture3(command_env, @exe, *args, chdir: chdir)
  end

  def test_tc_001_run_package_tests
    report_dir = File.join(@root, "results", "tc", "01", "reports")
    stdout, stderr, status = run_cmd(
      File.join(@source_root, "ace-test-runner-e2e"),
      "atoms",
      "--report-dir",
      report_dir
    )

    assert status.success?, stderr
    assert_match(/Running tests in ace-test-runner-e2e|assertions/i, stdout)
    assert Dir.glob(File.join(report_dir, "**", "*")).any? { |path| File.file?(path) }
  end

  def test_tc_002_run_specific_file
    report_dir = File.join(@root, "results", "tc", "02", "reports")
    stdout, stderr, status = run_cmd(
      File.join(@source_root, "ace-test-runner-e2e"),
      "test/molecules/integration_runner_case_reporting_test.rb",
      "--report-dir",
      report_dir
    )

    assert status.success?, stderr
    assert_match(/integration_runner_case_reporting_test|assertions/i, stdout)
    assert Dir.glob(File.join(report_dir, "**", "*")).any? { |path| File.file?(path) }
  end

  def test_tc_003_run_test_group
    report_dir = File.join(@root, "results", "tc", "03", "reports")
    stdout, stderr, status = run_cmd(
      File.join(@source_root, "ace-test-runner-e2e"),
      "atoms",
      "--report-dir",
      report_dir
    )

    assert status.success?, stderr
    assert_match(/Running tests in ace-test-runner-e2e|Running 8\/36 test files/i, stdout)
    assert Dir.glob(File.join(report_dir, "**", "*")).any? { |path| File.file?(path) }
  end

  def test_tc_004_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-test/, stdout + stderr)
    assert_match(/Run tests in package/i, stdout + stderr)
  end

  private

  def command_env
    {
      "RUBYOPT" => "-W0",
      "PROJECT_ROOT_PATH" => @source_root,
      "ACE_E2E_SOURCE_ROOT" => @source_root
    }
  end
end
