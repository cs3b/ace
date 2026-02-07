# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Atoms
        # Pure formatting functions for E2E test display output.
        # No I/O, no side effects — all methods return strings.
        module DisplayHelpers
          ANSI_COLORS = {
            green: "\033[32m",
            red: "\033[31m",
            yellow: "\033[33m",
            cyan: "\033[36m",
            gray: "\033[90m",
            reset: "\033[0m"
          }.freeze

          SEPARATOR = "=" * 65

          module_function

          # @param success [Boolean]
          # @return [String] "✓" or "✗"
          def status_icon(success)
            success ? "\u2713" : "\u2717"
          end

          # Right-aligned elapsed seconds for columnar output
          # @param seconds [Numeric]
          # @return [String] e.g. " 10.7s"
          def format_elapsed(seconds)
            sprintf("%5.1fs", seconds)
          end

          # Human-readable duration for summary lines
          # @param seconds [Numeric]
          # @return [String] e.g. "1m 50s" or "10.70s"
          def format_duration(seconds)
            if seconds >= 60
              "#{(seconds / 60).floor}m #{(seconds % 60).round(0)}s"
            else
              sprintf("%.2fs", seconds)
            end
          end

          # Test case count display suffix
          # @param result [Models::TestResult]
          # @return [String] e.g. "  0/8 cases" or ""
          def tc_count_display(result)
            return "" if result.total_count == 0

            "  #{result.passed_count}/#{result.total_count} cases"
          end

          # @return [String] 65-char separator line
          def separator
            SEPARATOR
          end

          # Wrap text in ANSI color codes (or return plain text)
          # @param text [String]
          # @param color_name [Symbol] one of :green, :red, :yellow, :cyan, :gray
          # @param use_color [Boolean]
          # @return [String]
          def color(text, color_name, use_color: true)
            return text unless use_color

            "#{ANSI_COLORS[color_name]}#{text}#{ANSI_COLORS[:reset]}"
          end

          # Format summary lines for display after a test run
          # @param results [Array<Models::TestResult>]
          # @param duration [Numeric] total duration in seconds
          # @param report_path [String]
          # @param use_color [Boolean]
          # @return [Array<String>] lines to print
          def format_summary_lines(results, duration, report_path, use_color: false)
            passed = results.count(&:success?)
            failed = results.size - passed
            total_tc = results.sum(&:total_count)
            total_passed_tc = results.sum(&:passed_count)
            total_failed_tc = total_tc - total_passed_tc

            lines = [separator]
            lines << "Duration:     #{format_duration(duration)}"
            lines << "Tests:        #{passed} passed, #{failed} failed"

            if total_tc > 0
              pct = (total_passed_tc * 100.0 / total_tc).round(0)
              lines << "Test cases:   #{total_passed_tc} passed, #{total_failed_tc} failed (#{pct}%)"
            end

            lines << "Report:       #{report_path}"
            lines << ""

            if failed == 0
              lines << color("\u2713 ALL TESTS PASSED", :green, use_color: use_color)
            else
              lines << color("\u2717 SOME TESTS FAILED", :red, use_color: use_color)
            end

            lines << separator
            lines
          end

          # Format a single-test result line
          # @param result [Models::TestResult]
          # @param use_color [Boolean]
          # @return [String]
          def format_single_result(result, use_color: false)
            icon = color(status_icon(result.success?), result.success? ? :green : :red, use_color: use_color)
            tc = tc_count_display(result)

            "Result: #{icon} #{result.status.upcase}#{tc}"
          end
        end
      end
    end
  end
end
