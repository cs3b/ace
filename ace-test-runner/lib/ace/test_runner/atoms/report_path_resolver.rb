# frozen_string_literal: true

module Ace
  module TestRunner
    module Atoms
      module ReportPathResolver
        module_function

        REPORT_PRIORITY = [
          "failures.json",
          "summary.json",
          "report.md",
          "report.json",
          "raw_output.txt"
        ].freeze

        # Resolves the best available report file path for a package
        #
        # The resolver checks for report files in the following priority order:
        #   1. failures.json - Detailed failure information
        #   2. summary.json - Summary of test results
        #   3. report.md - Markdown formatted report
        #   4. report.json - JSON formatted report
        #   5. raw_output.txt - Raw test output
        #
        # @param package_path [String] The root path of the package
        # @return [String, nil] The absolute path to the best available report file, or nil if none exist
        def call(package_path)
          return nil unless package_path && Dir.exist?(package_path)

          reports_dir = File.join(package_path, "test-reports", "latest")
          return nil unless Dir.exist?(reports_dir)

          REPORT_PRIORITY.each do |filename|
            path = File.join(reports_dir, filename)
            return path if File.exist?(path)
          end

          nil
        end
      end
    end
  end
end
