# frozen_string_literal: true

require_relative "base_formatter"

module Ace
  module TestRunner
    module Formatters
      # Progress formatter that shows one dot per test (not per file)
      class ProgressFormatter < BaseFormatter
        def initialize(options = {})
          super
          @test_count = 0
          @line_width = options[:line_width] || 80
          @configuration = options
          @max_failures_to_display = options[:max_failures_to_display] || 7
          @test_results = []
          @current_group = nil
          @group_counts = Hash.new(0)
          @files_by_group = Hash.new { |h, k| h[k] = [] }
          @show_groups = options[:show_groups] != false
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
          status = status_icon(result)

          summary = "#{status} #{result.total_tests} tests, #{result.assertions} assertions, " +
            "#{result.failed} failures, #{result.errors} errors"
          summary += ", #{result.skipped} skipped" if result.has_skips?
          summary += " (#{format_duration(result.duration)})"
          lines << summary

          # Add failure details if there are any
          if result.has_failures?
            lines << ""
            total_failures = result.failed + result.errors

            # Display up to max_failures_to_display failures
            failures_to_show = result.failures_detail.take(@max_failures_to_display)

            # Determine the label based on what types we have
            failure_count = result.failures_detail.count { |f| f.type == :failure }
            error_count = result.failures_detail.count { |f| f.type == :error }

            label = if failure_count > 0 && error_count > 0
              "FAILURES & ERRORS"
            elsif error_count > 0
              "ERRORS"
            else
              "FAILURES"
            end

            # Show failure count header with reference to full report if needed
            if total_failures > @max_failures_to_display
              report_path = @report_path || "#{@configuration[:report_dir] || ".ace-local/test/reports"}/latest"
              lines << "#{label} (#{failures_to_show.size}/#{total_failures}) → #{report_path}/failures.json:"
            else
              lines << "#{label} (#{total_failures}):"
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
          @test_results = []
          @current_group = nil
          @group_counts = Hash.new(0)
          @total_files = total_files
          @total_available = nil
        end

        def on_start_with_totals(files_to_run, total_available)
          on_start(files_to_run)
          @total_available = total_available

          # Show file count if different from total available
          if total_available && total_available > files_to_run
            puts "Running #{files_to_run}/#{total_available} test files"
            puts ""
          end
        end

        def on_test_stdout(stdout)
          # Parse individual test results from stdout
          return unless stdout

          # Look for test result lines in Minitest output
          # Handles both plain and ANSI-colored output from Minitest::Reporters
          stdout.each_line do |line|
            # Match test result lines like:
            # test_something [32m PASS[0m (0.00s)
            # test_other [31m FAIL[0m (0.01s)
            # test_error ERROR (0.00s)
            # test_skip SKIP (0.00s)
            # Improved regex to handle ANSI codes and underscores in test names
            # ANSI codes are: \e[32m (color start), \e[0m (reset)
            if line =~ /^\s*test_[\w_]+.*\s+(PASS|FAIL|ERROR|SKIP).*\([0-9.]+s\)/
              result = case $1
              when "PASS"
                "."
              when "FAIL"
                "F"
              when "ERROR"
                "E"
              when "SKIP"
                "S"
              else
                "."
              end

              print colorize(result, result_color(result))
              @test_count += 1
              @test_results << result

              # New line every N characters to prevent line overflow
              puts if @test_count % @line_width == 0
            end
          end
        end

        def on_test_complete(file, success, duration)
          # Detect target from file path
          target = detect_target(file)

          # Print target header if it's a new target and target headers are enabled
          if @show_groups && target != @current_group
            puts unless @test_count == 0
            puts ""
            puts colorize("═══ #{target.to_s.capitalize} Tests ═══", :cyan)
            @current_group = target
            @test_count = 0  # Reset count for new line
          end

          # For per-test progress, we handle output in on_test_stdout if available
          # Otherwise fall back to per-file dots
          if @test_results.empty?
            # No per-test output received, show file-level dot
            char = success ? colorize(".", :green) : colorize("F", :red)
            print char
            @test_count += 1
            puts if @test_count % @line_width == 0
          end

          # Track target counts
          @group_counts[target] += 1 if @show_groups
        end

        def detect_target(file_path)
          case file_path
          when /test\/(fast|unit)\/atoms\//
            :atoms
          when /test\/(fast|unit)\/molecules\//
            :molecules
          when /test\/(fast|unit)\/organisms\//
            :organisms
          when /test\/(fast|unit)\/models\//
            :models
          when /test\/feat\//
            :feat
          when /test\/edge\//
            :edge
          else
            :other
          end
        end

        def on_target_start(target_name, file_count)
          puts "" unless @test_count == 0
          puts ""
          puts "Running #{target_name} (#{file_count} #{(file_count == 1) ? "file" : "files"})..."
          @test_count = 0
        end

        def on_target_complete(target_name, success, duration, summary)
          puts unless @test_count == 0 || @test_count % @line_width == 0

          status_icon = success ? "✓" : "✗"
          test_count = summary[:runs] || 0
          failure_count = summary[:failures] || 0

          status_line = "#{status_icon} #{target_name} complete " +
            "(#{format_duration(duration)}, #{test_count} tests, #{failure_count} failures)"

          puts colorize(status_line, success ? :green : :red)
          puts ""
        end

        def on_finish(result)
          # Ensure we're on a new line
          puts unless @test_count == 0 || @test_count % @line_width == 0

          # Print target summary if we have target headers enabled
          if @show_groups && @group_counts.any?
            puts ""
            puts colorize("═══ Target Summary ═══", :cyan)
            @group_counts.each do |target, count|
              puts "  #{target.to_s.capitalize}: #{count} #{(count == 1) ? "file" : "files"}"
            end
          end

          puts format_stdout(result)
        end

        private

        # Determines the appropriate status icon based on test results
        # Returns ⚠️ for successful tests with skips (informational)
        # Returns ✅ for successful tests without skips
        # Returns 💥 for tests with errors
        # Returns ❌ for tests with failures
        def status_icon(result)
          if result.success? && !result.has_skips?
            "✅"
          elsif result.success? && result.has_skips?
            "⚠️"
          elsif result.errors > 0
            "💥"
          else
            "❌"
          end
        end

        def result_color(result)
          case result
          when "."
            :green
          when "F"
            :red
          when "E"
            :yellow
          when "S"
            :cyan
          else
            :default
          end
        end

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
