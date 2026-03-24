# frozen_string_literal: true

require "socket"

module Ace
  module TestRunner
    module Models
      # Represents a complete test report
      class TestReport
        attr_accessor :result, :configuration, :timestamp, :report_path,
          :files_tested, :environment, :metadata

        def initialize(attributes = {})
          @result = attributes[:result] || TestResult.new
          @configuration = attributes[:configuration] || TestConfiguration.new
          @timestamp = attributes[:timestamp] || Time.now
          @report_path = attributes[:report_path]
          @files_tested = attributes[:files_tested] || []
          @environment = attributes[:environment] || capture_environment
          @metadata = attributes[:metadata] || {}
        end

        def success?
          result.success?
        end

        def summary
          {
            status: success? ? "success" : "failure",
            passed: result.passed,
            failed: result.failed,
            errors: result.errors,
            skipped: result.skipped,
            total: result.total_tests,
            pass_rate: result.pass_rate,
            duration: result.duration,
            timestamp: timestamp.iso8601
          }
        end

        def failure_summary
          return [] unless result.has_failures?

          result.failures_detail.map do |failure|
            {
              type: failure.type,
              test: failure.full_test_name,
              location: failure.location,
              message: failure.message
            }
          end
        end

        def to_h
          {
            summary: summary,
            result: result.to_h,
            configuration: configuration.to_h,
            timestamp: timestamp.iso8601,
            report_path: report_path,
            files_tested: files_tested,
            environment: environment,
            failures: failure_summary,
            deprecations: result.deprecations,
            metadata: metadata
          }
        end

        def to_json(*args)
          to_h.to_json(*args)
        end

        def to_markdown
          lines = []
          lines << "# Test Report"
          lines << ""
          lines << "**Generated:** #{timestamp.strftime("%Y-%m-%d %H:%M:%S")}"
          lines << "**Status:** #{success? ? "✅ Success" : "❌ Failed"}"
          lines << ""

          lines << "## Summary"
          lines << ""
          lines << "| Metric | Value |"
          lines << "|--------|-------|"
          lines << "| Total Tests | #{result.total_tests} |"
          lines << "| Passed | #{result.passed} |"
          lines << "| Failed | #{result.failed} |"
          lines << "| Errors | #{result.errors} |"
          lines << "| Skipped | #{result.skipped} |"
          lines << "| Pass Rate | #{result.pass_rate}% |"
          lines << "| Duration | #{result.duration}s |"
          lines << ""

          if result.has_failures?
            lines << "## Failures"
            lines << ""
            result.failures_detail.each_with_index do |failure, idx|
              lines << "### #{idx + 1}. #{failure.full_test_name}"
              lines << ""
              lines << "- **Type:** #{failure.type}"
              lines << "- **Location:** `#{failure.location}`"
              lines << "- **Message:** #{failure.message}"
              lines << "- **Fix:** #{failure.fix_suggestion}" if failure.fix_suggestion
              lines << ""
            end
          end

          if result.has_deprecations?
            lines << "## Deprecations"
            lines << ""
            result.deprecations.each do |deprecation|
              lines << "- #{deprecation}"
            end
            lines << ""
          end

          if files_tested.any?
            lines << "## Files Tested"
            lines << ""
            files_tested.each do |file|
              lines << "- #{file}"
            end
            lines << ""
          end

          lines.join("\n")
        end

        private

        def capture_environment
          {
            ruby_version: RUBY_VERSION,
            ruby_platform: RUBY_PLATFORM,
            minitest_version: defined?(Minitest::VERSION) ? Minitest::VERSION : "unknown",
            ace_test_runner_version: VERSION,
            working_directory: Dir.pwd,
            user: ENV["USER"],
            hostname: ENV["HOSTNAME"] || Socket.gethostname
          }
        end
      end
    end
  end
end
