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
          DOUBLE_SEPARATOR = "\u2550" * 65

          # Unicode and ASCII fallback icons for progress display
          UNICODE_ICONS = {
            waiting: "\u00b7",    # · (middle dot)
            running: "\u22ef",    # ⋯ (midline horizontal ellipsis)
            check: "\u2713",      # ✓ (check mark)
            cross: "\u2717"       # ✗ (ballot x)
          }.freeze

          ASCII_ICONS = {
            waiting: ".",
            running: "...",
            check: "OK",
            cross: "XX"
          }.freeze

          module_function

          # Detect if the current terminal supports Unicode
          # Checks LANG/LC_ALL environment variables for UTF-8 encoding
          # @return [Boolean] true if terminal likely supports Unicode
          def unicode_terminal?
            lang = ENV["LANG"] || ENV["LC_ALL"] || ""
            lang.include?("UTF-8") || lang.include?("utf-8")
          end

          # @return [String] 65-char double-line separator (═ or =)
          def double_separator
            unicode_terminal? ? DOUBLE_SEPARATOR : SEPARATOR
          end

          # @param success [Boolean]
          # @return [String] "✓" or "✗" (or ASCII fallback)
          def status_icon(success)
            icons = unicode_terminal? ? UNICODE_ICONS : ASCII_ICONS
            success ? icons[:check] : icons[:cross]
          end

          # Get the waiting icon for progress display
          # @return [String] "·" or "."
          def waiting_icon
            unicode_terminal? ? UNICODE_ICONS[:waiting] : ASCII_ICONS[:waiting]
          end

          # Get the running icon for progress display
          # @return [String] "⋯" or "..."
          def running_icon
            unicode_terminal? ? UNICODE_ICONS[:running] : ASCII_ICONS[:running]
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

          # Duration formatted for suite-level display (minute-range values)
          # @param seconds [Numeric]
          # @return [String] e.g. "4m 25s" or "45.3s"
          def format_suite_duration(seconds)
            if seconds >= 60
              "#{(seconds / 60).floor}m %02ds" % (seconds % 60).round(0)
            else
              sprintf("%.1fs", seconds)
            end
          end

          # Right-aligned elapsed for suite columnar output (wider field)
          # @param seconds [Numeric]
          # @return [String] e.g. " 4m 25s" (7 chars wide)
          def format_suite_elapsed(seconds)
            sprintf("%7s", format_suite_duration(seconds))
          end

          # Build a columnar test result line for suite display
          # @param icon [String] status icon (may include ANSI)
          # @param elapsed [Numeric] seconds
          # @param package [String] package name
          # @param test_name [String] test name
          # @param cases_str [String] e.g. "5/5 cases" or ""
          # @param pkg_width [Integer] column width for package
          # @param name_width [Integer] column width for test name
          # @return [String]
          def format_suite_test_line(icon, elapsed, package, test_name, cases_str, pkg_width:, name_width:)
            time_col = format_suite_elapsed(elapsed)
            pkg_col = package.ljust(pkg_width)
            name_col = test_name.ljust(name_width)
            "#{icon}  #{time_col}  #{pkg_col}  #{name_col}  #{cases_str}"
          end

          # Build the full suite summary block
          # @param results_data [Hash] with keys :total, :passed, :failed, :errors, :packages, :duration, :failed_details
          # @param use_color [Boolean]
          # @return [Array<String>] lines to print
          def format_suite_summary(results_data, use_color: false)
            lines = ["", double_separator]

            failed_details = results_data[:failed_details] || []
            if failed_details.any?
              lines << "Failed tests:"
              failed_details.each do |detail|
                lines << "  - #{detail[:package]}/#{detail[:test_name]}: #{detail[:cases]}"
              end
              lines << ""
            end

            lines << "Duration:    #{format_suite_duration(results_data[:duration])}"
            lines << "Tests:       #{results_data[:passed]} passed, #{results_data[:failed] + results_data[:errors]} failed"

            total_tc = results_data[:total_cases] || 0
            passed_tc = results_data[:passed_cases] || 0
            if total_tc > 0
              failed_tc = total_tc - passed_tc
              pct = (passed_tc * 100.0 / total_tc).round(0)
              lines << "Test cases:  #{passed_tc} passed, #{failed_tc} failed (#{pct}%)"
            end

            lines << ""
            lines << if results_data[:failed] + results_data[:errors] == 0
              color("\u2713 ALL TESTS PASSED", :green, use_color: use_color)
            else
              color("\u2717 SOME TESTS FAILED", :red, use_color: use_color)
            end
            lines << double_separator
            lines
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

            lines << if failed == 0
              color("\u2713 ALL TESTS PASSED", :green, use_color: use_color)
            else
              color("\u2717 SOME TESTS FAILED", :red, use_color: use_color)
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
