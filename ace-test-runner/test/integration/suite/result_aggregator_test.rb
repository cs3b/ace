# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/test_runner/suite"

module Ace
  module TestRunner
    module Suite
      class ResultAggregatorTest < Minitest::Test
        def test_aggregate_reads_centralized_report_directory
          Dir.mktmpdir do |tmpdir|
            package_path = File.join(tmpdir, "ace-sample")
            report_root = File.join(tmpdir, ".ace-local", "test", "reports")
            latest_dir = File.join(report_root, "sample", "latest")

            FileUtils.mkdir_p(package_path)
            FileUtils.mkdir_p(latest_dir)
            File.write(File.join(latest_dir, "summary.json"), JSON.generate({
              total: 3, passed: 3, failed: 0, errors: 0, skipped: 0, duration: 0.4, success: true
            }))
            File.write(File.join(latest_dir, "report.json"), JSON.generate({
              result: {assertions: 9}
            }))

            summary = ResultAggregator.new(
              [{"name" => "ace-sample", "path" => package_path}],
              report_root: report_root
            ).aggregate

            assert_equal 3, summary[:total_tests]
            assert_equal 1, summary[:packages_passed]
            assert_equal 0, summary[:packages_failed]
            assert_equal 9, summary[:total_assertions]
          end
        end

        def test_aggregate_falls_back_to_legacy_test_reports
          Dir.mktmpdir do |tmpdir|
            package_path = File.join(tmpdir, "ace-legacy")
            legacy_latest = File.join(package_path, "test-reports", "latest")

            FileUtils.mkdir_p(legacy_latest)
            File.write(File.join(legacy_latest, "summary.json"), JSON.generate({
              total: 2, passed: 2, failed: 0, errors: 0, skipped: 0, duration: 0.2, success: true
            }))

            summary = ResultAggregator.new(
              [{"name" => "ace-legacy", "path" => package_path}],
              report_root: File.join(tmpdir, ".ace-local", "test", "reports")
            ).aggregate

            assert_equal 2, summary[:total_tests]
            assert_equal 1, summary[:packages_passed]
          end
        end

        def test_aggregate_uses_runtime_results_when_summary_is_missing
          Dir.mktmpdir do |tmpdir|
            package_path = File.join(tmpdir, "ace-timeout")
            FileUtils.mkdir_p(package_path)

            summary = ResultAggregator.new(
              [{"name" => "ace-timeout", "path" => package_path}],
              report_root: File.join(tmpdir, ".ace-local", "test", "reports"),
              runtime_results: {
                "ace-timeout" => {
                  completed: true,
                  success: false,
                  elapsed: 10.0,
                  results: {
                    tests: 0,
                    failures: 0,
                    errors: 1,
                    duration: 10.0,
                    success: false,
                    error: "Timed out after 10 seconds"
                  }
                }
              }
            ).aggregate

            assert_equal 1, summary[:packages_failed]
            assert_equal "Timed out after 10 seconds", summary[:failed_packages].first[:error_message]
          end
        end

        def test_aggregate_prefers_runtime_timeout_over_stale_summary
          Dir.mktmpdir do |tmpdir|
            package_path = File.join(tmpdir, "ace-timeout")
            report_root = File.join(tmpdir, ".ace-local", "test", "reports")
            latest_dir = File.join(report_root, "timeout", "latest")

            FileUtils.mkdir_p(package_path)
            FileUtils.mkdir_p(latest_dir)
            File.write(File.join(latest_dir, "summary.json"), JSON.generate({
              total: 5, passed: 5, failed: 0, errors: 0, skipped: 0, duration: 0.5, success: true
            }))

            summary = ResultAggregator.new(
              [{"name" => "ace-timeout", "path" => package_path}],
              report_root: report_root,
              runtime_results: {
                "ace-timeout" => {
                  completed: true,
                  success: false,
                  elapsed: 15.0,
                  timed_out: true,
                  results: {
                    tests: 0,
                    failures: 0,
                    errors: 1,
                    duration: 15.0,
                    success: false,
                    error: "Timed out after 15 seconds"
                  }
                }
              }
            ).aggregate

            assert_equal 0, summary[:packages_passed]
            assert_equal 1, summary[:packages_failed]
            assert_equal 0, summary[:total_tests]
            assert_equal "Timed out after 15 seconds", summary[:failed_packages].first[:error_message]
          end
        end
      end
    end
  end
end
