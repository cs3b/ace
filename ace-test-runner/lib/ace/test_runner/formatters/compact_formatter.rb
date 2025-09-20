# frozen_string_literal: true

module Ace
  module TestRunner
    module Formatters
      # Compact formatter for CI environments (dots/F/E/S output)
      class CompactFormatter < BaseFormatter
        MAX_FAILURES_TO_DISPLAY = 7

        def initialize(options = {})
          super
          @test_count = 0
          @line_width = options[:line_width] || 80
          @configuration = options
        end

        def format_stdout(result)
          lines = []

          # Progress dots are printed during execution, ensure newline
          lines << "" if @test_count > 0

          # Report directory with timestamp
          if @configuration && @configuration[:save_reports]
            timestamp = Time.now.strftime("%Y-%m-%d-%H%M%S")
            lines << "Details: #{@configuration[:report_dir] || 'test-reports'}/#{timestamp}/"
          end

          # Compact single-line summary with emoji status
          status = if result.success?
            "✅"
          elsif result.errors > 0
            "💥"
          else
            "❌"
          end

          summary = "#{status} #{result.total_tests} tests, #{result.assertions} assertions, " +
                   "#{result.failed} failures, #{result.errors} errors (#{format_duration(result.duration)})"
          lines << summary

          # Add failure details if there are any
          if result.has_failures?
            lines << ""
            total_failures = result.failed + result.errors
            lines << "FAILURES (#{total_failures}):"

            # Get report path if available
            report_path = if @configuration && @configuration[:save_reports]
              timestamp = Time.now.strftime("%Y-%m-%d-%H%M%S")
              "#{@configuration[:report_dir] || 'test-reports'}/#{timestamp}"
            else
              "test-reports/latest"
            end

            # Display up to MAX_FAILURES_TO_DISPLAY failures
            failures_to_show = result.failures_detail.take(MAX_FAILURES_TO_DISPLAY)

            failures_to_show.each_with_index do |failure, idx|
              # Extract file and line from location (e.g., "/path/file.rb:42:in `test_method'")
              location_match = failure.location.match(/^([^:]+):(\d+)/)
              if location_match
                file = location_match[1].gsub(/^.*\/test\//, "test/")  # Shorten path
                line = location_match[2]
                location = "#{file}:#{line}"
              else
                location = failure.location
              end

              # 2-line format: location - short message + report path
              message = truncate_message(failure.message, 60)
              lines << "  #{location} - #{message}"
              lines << "  → Details: #{report_path}/failures.json"
              lines << ""  # Add blank line between failures for readability
            end

            # If there are more failures than displayed
            if result.failures_detail.size > MAX_FAILURES_TO_DISPLAY
              remaining = result.failures_detail.size - MAX_FAILURES_TO_DISPLAY
              lines << "  ... and #{remaining} more #{remaining == 1 ? 'failure' : 'failures'}. See full report for details."
            end
          end

          lines.join("\n")
        end

        def format_report(report)
          # For CI, keep the report simple and parseable
          {
            status: report.success? ? "success" : "failure",
            stats: {
              total: report.result.total_tests,
              passed: report.result.passed,
              failed: report.result.failed,
              errors: report.result.errors,
              skipped: report.result.skipped,
              assertions: report.result.assertions,
              duration: report.result.duration
            },
            failures: report.result.failures_detail.map { |f| failure_summary(f) }
          }
        end

        def on_start(total_files)
          # No verbose output in compact mode
          @test_count = 0
        end

        def on_test_complete(file, success, duration)
          # Print single character for each test file
          char = if success
            colorize(".", :green)
          else
            colorize("F", :red)
          end

          print char
          @test_count += 1

          # New line every N characters to prevent line overflow
          puts if @test_count % @line_width == 0
        end

        def on_finish(result)
          # Ensure we're on a new line
          puts unless @test_count == 0 || @test_count % @line_width == 0
          puts format_stdout(result)
        end

        private

        def truncate_message(message, max_length = 100)
          return "" unless message

          msg = message.strip.gsub(/\n/, " ")
          if msg.length > max_length
            "#{msg[0...max_length - 3]}..."
          else
            msg
          end
        end

        def failure_summary(failure)
          {
            test: failure.full_test_name,
            location: failure.location,
            message: truncate_message(failure.message)
          }
        end
      end
    end
  end
end