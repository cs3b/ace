# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/test_runner/molecules/failed_package_reporter"
require "tmpdir"

module Ace
  module TestRunner
    module Molecules
      class FailedPackageReporterTest < Minitest::Test
        def setup
          @temp_dir = Dir.mktmpdir
          @package_path = File.join(@temp_dir, "my-package")
          FileUtils.mkdir_p(@package_path)
          @report_root = File.join(@temp_dir, ".ace-local", "test", "reports")
          @reports_dir = File.join(@report_root, "my-package", "latest")
          FileUtils.mkdir_p(@reports_dir)
          @package = { path: @package_path, name: "ace-my-package", report_root: @report_root }
        end

        def teardown
          FileUtils.remove_entry(@temp_dir)
        end

        def test_format_for_display_with_existing_report
          File.write(File.join(@reports_dir, "failures.json"), "{}")
          
          output = FailedPackageReporter.format_for_display(@package)
          
          # Should contain the path to failures.json
          assert_match(/→ See .*failures\.json/, output)
        end

        def test_format_for_display_fallback
          # No report files created
          
          output = FailedPackageReporter.format_for_display(@package)
          
          assert_match(/→ Check .*\.ace-local\/test\/reports\/my-package\/ for details/, output)
        end

        def test_format_for_markdown_with_existing_report
          File.write(File.join(@reports_dir, "summary.json"), "{}")
          
          output = FailedPackageReporter.format_for_markdown(@package)
          
          assert_match(/- Report: `.*summary\.json`/, output)
        end

        def test_format_for_markdown_fallback
          output = FailedPackageReporter.format_for_markdown(@package)
          
          assert_match(/- Report: Check `.*\.ace-local\/test\/reports\/my-package\/` for details/, output)
        end

        def test_format_for_display_handles_relative_path_error
          File.write(File.join(@reports_dir, "failures.json"), "{}")
          Pathname.stub :new, ->(_) { raise StandardError, "path calculation failed" } do
            output = FailedPackageReporter.format_for_display(@package)
            assert_match(/→ See /, output)
          end
        end
      end
    end
  end
end
