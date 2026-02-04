# frozen_string_literal: true

require "fileutils"
require "time"
require "yaml"

module Ace
  module E2eRunner
    module Molecules
      class ReportWriter
        def initialize(report_dir:, timestamp:)
          @report_dir = report_dir
          @timestamp = timestamp
        end

        def write_all(results)
          base_dir = File.join(@report_dir, @timestamp)
          FileUtils.mkdir_p(base_dir)

          results.each { |result| write_test_report(result, base_dir) }
          write_summary(results, base_dir)

          base_dir
        end

        private

        def write_test_report(result, base_dir)
          test_dir = File.join(base_dir, result.test_id.to_s)
          FileUtils.mkdir_p(test_dir)
          summary_path = File.join(test_dir, "summary.r.md")

          content = String.new("# E2E Test Report\n\n")
          content << "- Test ID: #{result.test_id}\n"
          content << "- Status: #{result.status}\n"
          content << "- Duration: #{format_duration(result.duration)}\n" if result.duration
          content << "- Package: #{result.package}\n" if result.package
          content << "\n"

          if result.summary
            content << "## Summary\n\n#{result.summary}\n\n"
          end

          if result.error_message
            content << "## Error\n\n#{result.error_message}\n\n"
          end

          if result.test_cases && result.test_cases.is_a?(Array) && result.test_cases.any?
            content << "## Test Cases\n\n"
            result.test_cases.each do |test_case|
              content << "- #{test_case.inspect}\n"
            end
          end

          File.write(summary_path, content)
        end

        def write_summary(results, base_dir)
          summary_path = File.join(base_dir, "summary.r.md")
          frontmatter = {
            "timestamp" => Time.now.utc.iso8601,
            "total_tests" => results.length,
            "passed" => results.count(&:success?),
            "failed" => results.count(&:failure?)
          }

          content = String.new("---\n")
          content << frontmatter.to_yaml
          content << "---\n\n"
          content << "# E2E Test Summary\n\n"
          content << "## Results\n\n"
          content << "| Test ID | Package | Status | Duration |\n"
          content << "|---------|---------|--------|----------|\n"

          results.each do |result|
            duration = format_duration(result.duration)
            content << "| #{result.test_id} | #{result.package || "-"} | #{result.status} | #{duration} |\n"
          end

          failed_results = results.select(&:failure?)
          if failed_results.any?
            content << "\n## Failed Tests\n\n"
            failed_results.each do |result|
              content << "### #{result.test_id}\n\n"
              content << "- Status: #{result.status}\n"
              content << "- Summary: #{result.summary || "(none)"}\n"
              content << "- Error: #{result.error_message || "(none)"}\n\n"
            end
          end

          File.write(summary_path, content)
        end

        def format_duration(duration)
          return "-" unless duration
          "#{duration.round(2)}s"
        end
      end
    end
  end
end
