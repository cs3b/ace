# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/test_runner/suite"

module Ace
  module TestRunner
    module Suite
      class DurationEstimatorTest < Minitest::Test
        def test_estimate_reads_duration_from_centralized_reports
          Dir.mktmpdir do |tmpdir|
            package_path = File.join(tmpdir, "ace-sample")
            report_root = File.join(tmpdir, ".ace-local", "test", "reports")
            latest_dir = File.join(report_root, "sample", "latest")

            FileUtils.mkdir_p(package_path)
            FileUtils.mkdir_p(latest_dir)
            File.write(File.join(latest_dir, "summary.json"), JSON.generate({ duration: 12.34 }))

            estimator = DurationEstimator.new(report_root: report_root)
            assert_equal 12.34, estimator.estimate({ "name" => "ace-sample", "path" => package_path })
          end
        end

        def test_estimate_falls_back_to_legacy_test_reports
          Dir.mktmpdir do |tmpdir|
            package_path = File.join(tmpdir, "ace-legacy")
            legacy_latest = File.join(package_path, "test-reports", "latest")

            FileUtils.mkdir_p(legacy_latest)
            File.write(File.join(legacy_latest, "summary.json"), JSON.generate({ duration: 5.67 }))

            estimator = DurationEstimator.new(report_root: File.join(tmpdir, ".ace-local", "test", "reports"))
            assert_equal 5.67, estimator.estimate({ "name" => "ace-legacy", "path" => package_path })
          end
        end
      end
    end
  end
end
