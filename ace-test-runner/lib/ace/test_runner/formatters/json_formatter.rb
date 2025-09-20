# frozen_string_literal: true

module Ace
  module TestRunner
    module Formatters
      # JSON formatter for machine-readable output
      class JsonFormatter < BaseFormatter
        def format_stdout(result)
          # For JSON format, stdout gets the complete JSON
          JSON.pretty_generate(format_result_hash(result))
        end

        def format_report(report)
          # Complete report in JSON format
          {
            version: "1.0",
            generator: "ace-test-runner",
            timestamp: report.timestamp.iso8601,
            environment: report.environment,
            configuration: report.configuration.to_h,
            summary: report.summary,
            result: format_result_hash(report.result),
            failures: format_failures_array(report.result.failures_detail),
            deprecations: report.result.deprecations,
            files_tested: report.files_tested,
            metadata: report.metadata
          }
        end

        def on_start(total_files)
          # JSON formatter doesn't output progress
        end

        def on_test_complete(file, success, duration)
          # JSON formatter doesn't output progress
        end

        def on_finish(result)
          # Output complete JSON at the end
          puts format_stdout(result)
        end

        private

        def format_result_hash(result)
          {
            summary: {
              passed: result.passed,
              failed: result.failed,
              errors: result.errors,
              skipped: result.skipped,
              total: result.total_tests,
              assertions: result.assertions,
              duration: result.duration,
              pass_rate: result.pass_rate,
              success: result.success?
            },
            timing: {
              start_time: result.start_time&.iso8601,
              end_time: result.end_time&.iso8601,
              duration_seconds: result.duration,
              duration_formatted: format_duration(result.duration)
            },
            failures: format_failures_array(result.failures_detail),
            deprecations: result.deprecations
          }
        end

        def format_failures_array(failures)
          failures.map do |failure|
            {
              type: failure.type.to_s,
              test_name: failure.test_name,
              test_class: failure.test_class,
              full_name: failure.full_test_name,
              message: failure.message,
              location: {
                file: failure.file_path,
                line: failure.line_number,
                full: failure.location
              },
              fix_suggestion: failure.fix_suggestion,
              backtrace: failure.backtrace
            }
          end
        end
      end
    end
  end
end