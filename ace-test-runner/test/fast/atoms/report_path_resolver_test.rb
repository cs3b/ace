# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/ace/test_runner/atoms/report_path_resolver"
require "tmpdir"

module Ace
  module TestRunner
    module Atoms
      class ReportPathResolverTest < Minitest::Test
        def setup
          @temp_dir = Dir.mktmpdir
          @report_root = File.join(@temp_dir, ".ace-local", "test", "reports")
          @reports_dir = File.join(@report_root, "my-package", "latest")
          FileUtils.mkdir_p(@reports_dir)
        end

        def teardown
          FileUtils.remove_entry(@temp_dir)
        end

        def test_returns_failures_json_if_exists
          create_file("failures.json")
          create_file("summary.json")

          path = ReportPathResolver.call(@temp_dir, report_root: @report_root, package_name: "ace-my-package")
          assert_equal File.join(@reports_dir, "failures.json"), path
        end

        def test_returns_summary_json_if_failures_missing
          create_file("summary.json")

          path = ReportPathResolver.call(@temp_dir, report_root: @report_root, package_name: "ace-my-package")
          assert_equal File.join(@reports_dir, "summary.json"), path
        end

        def test_returns_report_md_if_json_missing
          create_file("report.md")

          path = ReportPathResolver.call(@temp_dir, report_root: @report_root, package_name: "ace-my-package")
          assert_equal File.join(@reports_dir, "report.md"), path
        end

        def test_returns_nil_if_no_reports_exist
          path = ReportPathResolver.call(@temp_dir, report_root: @report_root, package_name: "ace-my-package")
          assert_nil path
        end

        def test_returns_nil_if_reports_dir_does_not_exist
          FileUtils.rm_rf(@reports_dir)
          path = ReportPathResolver.call(@temp_dir, report_root: @report_root, package_name: "ace-my-package")
          assert_nil path
        end

        def test_falls_back_to_legacy_test_reports_layout
          legacy_dir = File.join(@temp_dir, "test-reports", "latest")
          FileUtils.mkdir_p(legacy_dir)
          File.write(File.join(legacy_dir, "summary.json"), "content")
          FileUtils.rm_rf(@reports_dir)

          path = ReportPathResolver.call(@temp_dir, report_root: @report_root, package_name: "ace-my-package")
          assert_equal File.join(legacy_dir, "summary.json"), path
        end

        private

        def create_file(name)
          File.write(File.join(@reports_dir, name), "content")
        end
      end
    end
  end
end
