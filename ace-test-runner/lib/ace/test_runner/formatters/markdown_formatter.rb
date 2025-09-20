# frozen_string_literal: true

module Ace
  module TestRunner
    module Formatters
      # Markdown formatter for human-readable reports
      class MarkdownFormatter < BaseFormatter
        def format_stdout(result)
          # For markdown, provide a brief summary on stdout
          lines = []
          lines << "# Test Results"
          lines << ""
          lines << "**Status:** #{result.success? ? '✅ Passed' : '❌ Failed'}"
          lines << "**Summary:** #{result.summary_line}"
          lines << "**Duration:** #{format_duration(result.duration)}"

          if result.has_failures?
            lines << ""
            lines << "## Failures"
            result.failures_detail.take(5).each_with_index do |failure, idx|
              lines << "#{idx + 1}. `#{failure.full_test_name}` at #{failure.short_location}"
            end

            if result.failures_detail.size > 5
              lines << "... and #{result.failures_detail.size - 5} more"
            end
          end

          lines.join("\n")
        end

        def format_report(report)
          # Return the markdown string for saving
          generate_markdown_report(report)
        end

        def on_start(total_files)
          puts "Starting test execution for #{pluralize(total_files, 'file')}..."
        end

        def on_test_complete(file, success, duration)
          status = success ? "✓" : "✗"
          puts "  #{status} #{File.basename(file)} (#{format_duration(duration)})"
        end

        def on_finish(result)
          puts ""
          puts format_stdout(result)
        end

        private

        def generate_markdown_report(report)
          lines = []

          # Header
          lines << "# Test Execution Report"
          lines << ""
          lines << "**Generated:** #{report.timestamp.strftime('%Y-%m-%d %H:%M:%S')}"
          lines << "**Status:** #{report.success? ? '✅ Success' : '❌ Failed'}"
          lines << ""

          # Executive Summary
          lines << "## Executive Summary"
          lines << ""
          lines << report.result.summary_line
          lines << ""
          lines << "- **Pass Rate:** #{format_percentage(report.result.pass_rate)}"
          lines << "- **Duration:** #{format_duration(report.result.duration)}"
          lines << "- **Total Assertions:** #{report.result.assertions}"
          lines << ""

          # Statistics Table
          lines << "## Test Statistics"
          lines << ""
          lines << "| Metric | Count | Percentage |"
          lines << "|--------|-------|------------|"
          lines << "| Total Tests | #{report.result.total_tests} | 100% |"
          lines << "| Passed | #{report.result.passed} | #{calculate_percentage(report.result.passed, report.result.total_tests)}% |"
          lines << "| Failed | #{report.result.failed} | #{calculate_percentage(report.result.failed, report.result.total_tests)}% |"
          lines << "| Errors | #{report.result.errors} | #{calculate_percentage(report.result.errors, report.result.total_tests)}% |"
          lines << "| Skipped | #{report.result.skipped} | #{calculate_percentage(report.result.skipped, report.result.total_tests)}% |"
          lines << ""

          # Failures Section
          if report.result.has_failures?
            lines << "## Test Failures"
            lines << ""

            report.result.failures_detail.each_with_index do |failure, idx|
              lines << "### #{idx + 1}. #{failure.full_test_name}"
              lines << ""
              lines << "- **Type:** #{failure.type.to_s.capitalize}"
              lines << "- **Location:** `#{failure.location}`"
              lines << ""
              lines << "**Error Message:**"
              lines << "```"
              lines << failure.message
              lines << "```"
              lines << ""

              if failure.fix_suggestion
                lines << "**Suggested Fix:**"
                lines << "> #{failure.fix_suggestion}"
                lines << ""
              end
            end
          end

          # Deprecations Section
          if report.result.has_deprecations?
            lines << "## Deprecation Warnings"
            lines << ""
            lines << "The following deprecations were detected:"
            lines << ""
            report.result.deprecations.each do |deprecation|
              lines << "- #{deprecation}"
            end
            lines << ""
          end

          # Files Tested Section
          if report.files_tested.any?
            lines << "## Files Tested"
            lines << ""
            lines << "The following test files were executed:"
            lines << ""
            report.files_tested.each do |file|
              lines << "- `#{file}`"
            end
            lines << ""
          end

          # Environment Section
          lines << "## Test Environment"
          lines << ""
          lines << "| Property | Value |"
          lines << "|----------|-------|"
          lines << "| Ruby Version | #{report.environment[:ruby_version]} |"
          lines << "| Platform | #{report.environment[:ruby_platform]} |"
          lines << "| Minitest Version | #{report.environment[:minitest_version]} |"
          lines << "| Test Runner Version | #{report.environment[:ace_test_runner_version]} |"
          lines << "| Working Directory | `#{report.environment[:working_directory]}` |"
          lines << ""

          # Configuration Section
          lines << "## Configuration"
          lines << ""
          lines << "| Setting | Value |"
          lines << "|---------|-------|"
          lines << "| Format | #{report.configuration.format} |"
          lines << "| Report Directory | `#{report.configuration.report_dir}` |"
          lines << "| Save Reports | #{report.configuration.save_reports} |"
          lines << "| Fail Fast | #{report.configuration.fail_fast} |"
          lines << "| Verbose | #{report.configuration.verbose} |"
          lines << ""

          # Footer
          lines << "---"
          lines << ""
          lines << "*Generated by ace-test-runner v#{VERSION}*"

          lines.join("\n")
        end

        def calculate_percentage(value, total)
          return 0 if total == 0
          ((value.to_f / total) * 100).round(1)
        end
      end
    end
  end
end