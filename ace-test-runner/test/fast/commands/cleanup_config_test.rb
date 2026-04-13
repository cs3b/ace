# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/test_runner/cli"
require "json"

class CleanupConfigTest < Minitest::Test
  include TestHelper

  def test_cleanup_uses_config_cascade_for_report_dir
    with_temp_dir do |dir|
      # Create a custom report directory via config
      custom_report_dir = "custom-reports"
      FileUtils.mkdir_p(custom_report_dir)

      # Create .ace/test-runner/config.yml with custom report_dir
      FileUtils.mkdir_p(".ace/test-runner")
      File.write(".ace/test-runner/config.yml", <<~YAML)
        version: 1
        defaults:
          report_dir: #{custom_report_dir}
      YAML

      # Create fake report directories with proper summary.json files
      old_timestamp = (Time.now - (40 * 24 * 60 * 60)).iso8601
      3.times do |i|
        report_path = File.join(custom_report_dir, "report#{i}")
        FileUtils.mkdir_p(report_path)
        # Create summary.json with old timestamp (required by cleanup logic)
        File.write(File.join(report_path, "summary.json"), JSON.generate({
          timestamp: old_timestamp,
          success: true,
          passed: 1,
          failed: 0,
          total: 1
        }))
      end

      # Verify reports exist in custom dir before cleanup
      assert_equal 3, Dir.glob("#{custom_report_dir}/*").size

      # Run cleanup WITHOUT --report-dir CLI option
      # It should read from config cascade
      command = Ace::TestRunner::CLI::Commands::Test.new

      output = capture_io do
        command.call(
          args: [],
          cleanup_reports: true,
          cleanup_keep: 0,
          cleanup_age: 30
        )
      end

      # Verify cleanup happened in the config-specified directory
      assert_match(/Cleaning up test reports/, output.first)
      assert_match(/Deleted 3 old reports/, output.first)
      assert_equal 0, Dir.glob("#{custom_report_dir}/*").size
    end
  end

  def test_cleanup_cli_option_overrides_config
    with_temp_dir do |dir|
      # Create config with one report dir
      config_report_dir = "config-reports"
      FileUtils.mkdir_p(config_report_dir)

      FileUtils.mkdir_p(".ace/test-runner")
      File.write(".ace/test-runner/config.yml", <<~YAML)
        version: 1
        defaults:
          report_dir: #{config_report_dir}
      YAML

      # Create CLI-specified report dir
      cli_report_dir = "cli-reports"
      FileUtils.mkdir_p(cli_report_dir)

      # Create report with summary.json in both directories
      old_timestamp = (Time.now - (40 * 24 * 60 * 60)).iso8601
      summary_content = JSON.generate({
        timestamp: old_timestamp,
        success: true,
        passed: 1,
        failed: 0,
        total: 1
      })

      FileUtils.mkdir_p(File.join(config_report_dir, "old_report"))
      File.write(File.join(config_report_dir, "old_report", "summary.json"), summary_content)

      FileUtils.mkdir_p(File.join(cli_report_dir, "old_report"))
      File.write(File.join(cli_report_dir, "old_report", "summary.json"), summary_content)

      # Run cleanup WITH --report-dir CLI option
      command = Ace::TestRunner::CLI::Commands::Test.new

      capture_io do
        command.call(
          args: [],
          cleanup_reports: true,
          cleanup_keep: 0,
          cleanup_age: 30,
          report_dir: cli_report_dir
        )
      end

      # CLI dir should be cleaned
      assert_equal 0, Dir.glob("#{cli_report_dir}/*").size
      # Config dir should be untouched
      assert_equal 1, Dir.glob("#{config_report_dir}/*").size
    end
  end
end
