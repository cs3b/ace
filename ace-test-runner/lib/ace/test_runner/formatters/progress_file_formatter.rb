# frozen_string_literal: true

require_relative "base_formatter"

module Ace
  module TestRunner
    module Formatters
      # Progress formatter that shows one dot per test file (faster execution)
      class ProgressFileFormatter < BaseFormatter
        def initialize(options = {})
          super
          @test_count = 0
          @line_width = options[:line_width] || 80
          @configuration = options
          @max_failures_to_display = options[:max_failures_to_display] || 7
        end

        def format_stdout(result)
          lines = []

          # Progress dots are printed during execution, ensure newline
          lines << "" if @test_count > 0

          # Report directory - use actual report path if available
          if @report_path
            lines << "Details: #{@report_path}/"
          elsif @configuration && @configuration[:save_reports]
            lines << "Details: #{@configuration[:report_dir] || ".ace-local/test/reports"}/latest/"
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

            # Display up to max_failures_to_display failures
            failures_to_show = result.failures_detail.take(@max_failures_to_display)

            # Show failure count header with reference to full report if needed
            if total_failures > @max_failures_to_display
              report_path = @report_path || "#{@configuration[:report_dir] || ".ace-local/test/reports"}/latest"
              lines << "FAILURES (#{failures_to_show.size}/#{total_failures}) → #{report_path}/failures.json:"
            else
              lines << "FAILURES (#{total_failures}):"
            end

            failures_to_show.each_with_index do |failure, idx|
              # Extract file and line from location (e.g., "/path/file.rb:42:in `test_method'")
              if failure.location
                location_match = failure.location.match(/^([^:]+):(\d+)/)
                if location_match
                  file = location_match[1].gsub(/^.*\/test\//, "test/")  # Shorten path
                  line = location_match[2]
                  location = "#{file}:#{line}"
                else
                  location = failure.location
                end
              else
                location = failure.test_name || "unknown"
              end

              # Format: location - short message with individual failure report path
              message = truncate_message(failure.message, 60)
              lines << "  #{location} - #{message}"

              # Show individual failure report path if we have the report path
              if @report_path
                failure_filename = format("%03d-%s.md", idx + 1,
                  failure.full_test_name.gsub(/\W+/, "_").downcase[0...50])
                lines << "  → Details: #{@report_path}/failures/#{failure_filename}"
              end
            end

            # If there are more failures than displayed
            if result.failures_detail.size > @max_failures_to_display
              remaining = result.failures_detail.size - @max_failures_to_display
              report_path = @report_path || "#{@configuration[:report_dir] || ".ace-local/test/reports"}/latest"
              lines << "  ... and #{remaining} more #{(remaining == 1) ? "failure" : "failures"}. See full report: #{report_path}/failures.json"
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
          # No verbose output in progress mode
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

          msg = message.strip.tr("\n", " ")
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
