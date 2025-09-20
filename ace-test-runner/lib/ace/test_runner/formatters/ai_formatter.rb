# frozen_string_literal: true

module Ace
  module TestRunner
    module Formatters
      # AI-optimized formatter with dual output (stdout summary + detailed reports)
      class AiFormatter < BaseFormatter
        def format_stdout(result)
          lines = []

          # Summary line with icons
          lines << result.summary_line
          lines << ""

          # Overall status
          if result.success?
            status = colorize("Summary: All tests passed", :green)
            lines << "#{status} in #{format_duration(result.duration)}"
          else
            status = colorize("Summary: Tests failed", :red)
            lines << "#{status} in #{format_duration(result.duration)}"
            lines << ""
            lines << "Failures:"

            # List failures concisely
            result.failures_detail.each_with_index do |failure, idx|
              lines << "  #{idx + 1}. #{failure.short_location} - #{failure.test_name}"
            end
          end

          # Add deprecation warning if present
          if result.has_deprecations?
            lines << ""
            lines << colorize("⚠️  #{result.deprecations.size} deprecation warnings", :yellow)
          end

          lines.join("\n")
        end

        def format_report(report)
          {
            summary: format_summary(report),
            environment: report.environment,
            configuration: report.configuration.to_h,
            results: format_results(report.result),
            failures: format_failures(report.result.failures_detail),
            deprecations: report.result.deprecations,
            files_tested: report.files_tested,
            metadata: report.metadata,
            timestamp: report.timestamp.iso8601,
            report_path: report.report_path
          }
        end

        def on_start(total_files)
          puts colorize("🚀 Starting test execution...", :cyan)
          puts "Testing #{pluralize(total_files, 'file')}"
          puts ""
        end

        def on_test_complete(file, success, duration)
          status = success ? colorize("✓", :green) : colorize("✗", :red)
          puts "  #{status} #{File.basename(file)} (#{format_duration(duration)})"
        end

        def on_finish(result)
          puts ""
          puts format_stdout(result)
        end

        private

        def format_summary(report)
          result = report.result
          {
            status: report.success? ? "success" : "failure",
            tests: {
              total: result.total_tests,
              passed: result.passed,
              failed: result.failed,
              errors: result.errors,
              skipped: result.skipped
            },
            metrics: {
              pass_rate: format_percentage(result.pass_rate),
              duration: format_duration(result.duration),
              assertions: result.assertions
            },
            verdict: generate_verdict(result)
          }
        end

        def format_results(result)
          {
            execution_time: {
              start: result.start_time&.iso8601,
              end: result.end_time&.iso8601,
              duration: result.duration
            },
            statistics: {
              total_tests: result.total_tests,
              passed: result.passed,
              failed: result.failed,
              errors: result.errors,
              skipped: result.skipped,
              assertions: result.assertions,
              pass_rate: result.pass_rate
            },
            status_breakdown: status_breakdown(result)
          }
        end

        def format_failures(failures)
          failures.map.with_index do |failure, idx|
            {
              index: idx + 1,
              type: failure.type,
              test: failure.full_test_name,
              location: failure.location,
              message: failure.message,
              fix_suggestion: failure.fix_suggestion,
              severity: determine_severity(failure)
            }
          end
        end

        def status_breakdown(result)
          breakdown = []
          breakdown << { status: "passed", count: result.passed, icon: success_icon } if result.passed > 0
          breakdown << { status: "failed", count: result.failed, icon: failure_icon } if result.failed > 0
          breakdown << { status: "errors", count: result.errors, icon: error_icon } if result.errors > 0
          breakdown << { status: "skipped", count: result.skipped, icon: skip_icon } if result.skipped > 0
          breakdown
        end

        def generate_verdict(result)
          if result.success?
            "All tests passed successfully. Code appears to be working as expected."
          elsif result.pass_rate >= 90
            "Most tests passed (#{format_percentage(result.pass_rate)}). Minor issues need attention."
          elsif result.pass_rate >= 70
            "Moderate test success (#{format_percentage(result.pass_rate)}). Several issues require fixing."
          else
            "Low test success rate (#{format_percentage(result.pass_rate)}). Significant issues detected."
          end
        end

        def determine_severity(failure)
          case failure.type
          when :error
            "high"
          when :failure
            if failure.message =~ /nil|undefined|missing/i
              "medium"
            else
              "low"
            end
          else
            "unknown"
          end
        end
      end
    end
  end
end