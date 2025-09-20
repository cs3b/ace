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
        end

        def format_stdout(result)
          # The dots are printed during execution
          # This is the final summary
          lines = []
          lines << ""  # New line after dots
          lines << ""

          if result.success?
            lines << colorize("OK", :green)
          else
            lines << colorize("FAILED", :red)
          end

          # Compact summary line
          summary_parts = []
          summary_parts << pluralize(result.total_tests, "test")
          summary_parts << pluralize(result.assertions, "assertion")
          summary_parts << pluralize(result.failed, "failure") if result.failed > 0
          summary_parts << pluralize(result.errors, "error") if result.errors > 0
          summary_parts << pluralize(result.skipped, "skip") if result.skipped > 0

          lines << summary_parts.join(", ")
          lines << "Finished in #{format_duration(result.duration)}"

          # Add failure details in compact form
          if result.has_failures?
            lines << ""
            result.failures_detail.each_with_index do |failure, idx|
              lines << "#{idx + 1}) #{failure.full_test_name}"
              lines << "   #{failure.location}"
              lines << "   #{truncate_message(failure.message)}"
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