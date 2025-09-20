# frozen_string_literal: true

module Ace
  module TestRunner
    module Formatters
      # Compact formatter for CI environments (dots/F/E/S output)
      class CompactFormatter < BaseFormatter
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

          # Compact summary with emoji indicators
          summary_parts = []
          summary_parts << "✅ #{result.passed} passed" if result.passed > 0
          summary_parts << "❌ #{result.failed} failed" if result.failed > 0
          summary_parts << "💥 #{result.errors} errors" if result.errors > 0
          summary_parts << "⚠️  #{result.skipped} skipped" if result.skipped > 0

          if summary_parts.empty?
            lines << "No tests executed"
          else
            lines << summary_parts.join(", ") + " (#{format_duration(result.duration)})"
          end

          # 2-line failure summaries as specified
          if result.has_failures?
            lines << ""
            lines << "FAILURES (#{result.failed + result.errors}):"
            result.failures_detail.each_with_index do |failure, idx|
              # Extract file and line from location (e.g., "/path/file.rb:42:in `test_method'")
              location_match = failure.location.match(/^([^:]+):(\d+)/)
              if location_match
                file = location_match[1].gsub(/^.*\/test\//, "test/")  # Shorten path
                line = location_match[2]
                location = "#{file}:#{line}"
              else
                location = failure.location
              end

              # 2-line format: location - short message
              message = truncate_message(failure.message, 60)
              lines << "  #{location} - #{message}"
            end
          end

          # Report directory hint
          if @configuration && @configuration[:save_reports]
            timestamp = Time.now.strftime("%Y-%m-%d-%H%M%S")
            lines << ""
            lines << "Details: #{@configuration[:report_dir] || 'test-reports'}/#{timestamp}/"
          end

          # Final summary
          lines << "#{result.total_tests} tests, #{result.assertions} assertions, " +
                  "#{result.failed} failures, #{result.errors} errors (#{format_duration(result.duration)})"

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