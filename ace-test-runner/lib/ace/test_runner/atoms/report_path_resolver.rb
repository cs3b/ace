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
        # @param report_root [String, nil] Centralized report root
        # @param package_name [String, nil] Package name used for centralized lookup
        # @return [String, nil] The absolute path to the best available report file, or nil if none exist
        def call(package_path, report_root: nil, package_name: nil)
          return nil unless package_path && Dir.exist?(package_path)

          reports_dir = report_directory(package_path, report_root: report_root, package_name: package_name)
          return nil unless reports_dir

          REPORT_PRIORITY.each do |filename|
            path = File.join(reports_dir, filename)
            return path if File.exist?(path)
          end

          nil
        end

        def report_directory(package_path, report_root: nil, package_name: nil)
          candidates(package_path, report_root, package_name).each do |dir|
            return dir if Dir.exist?(dir)
          end

          nil
        end

        def candidates(package_path, report_root, package_name)
          dirs = []

          if report_root
            short_name = package_name.to_s.sub(/\Aace-/, "")
            short_name = File.basename(package_path).sub(/\Aace-/, "") if short_name.empty?
            dirs << File.join(report_root, short_name, "latest")
          end

          dirs << File.join(package_path, "test-reports", "latest")
          dirs.uniq
        end
      end
    end
  end
end
