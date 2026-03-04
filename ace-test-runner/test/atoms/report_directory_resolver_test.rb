# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/test_runner/atoms/report_directory_resolver"

module Ace
  module TestRunner
    module Atoms
      class ReportDirectoryResolverTest < Minitest::Test
        def test_short_package_name_drops_ace_prefix
          assert_equal "task", ReportDirectoryResolver.short_package_name("ace-task")
          assert_equal "my-package", ReportDirectoryResolver.short_package_name("my-package")
        end

        def test_resolve_package_report_dir_uses_short_package_name
          path = ReportDirectoryResolver.resolve_package_report_dir(
            report_root: "/tmp/reports",
            package_name: "ace-test-runner"
          )

          assert_equal "/tmp/reports/test-runner", path
        end

        def test_infer_package_name_prefers_package_dir
          name = ReportDirectoryResolver.infer_package_name(
            package_dir: "/repo/ace-bundle",
            test_files: [],
            cwd: "/repo"
          )

          assert_equal "ace-bundle", name
        end

        def test_infer_package_name_uses_test_file_prefix_when_package_dir_missing
          name = ReportDirectoryResolver.infer_package_name(
            package_dir: nil,
            test_files: ["ace-review/test/atoms/foo_test.rb"],
            cwd: "/repo"
          )

          assert_equal "ace-review", name
        end
      end
    end
  end
end
