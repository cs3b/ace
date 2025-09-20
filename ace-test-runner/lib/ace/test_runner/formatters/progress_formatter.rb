# frozen_string_literal: true

require_relative "base_formatter"

module Ace
  module TestRunner
    module Formatters
      # Progress formatter that shows one dot per test (not per file)
      class ProgressFormatter < BaseFormatter
        MAX_FAILURES_TO_DISPLAY = 7

        def initialize(options = {})
          super
          @test_count = 0
          @line_width = options[:line_width] || 80
          @configuration = options
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

              # Generate the individual failure report filename
              test_name = failure.full_test_name.gsub(/\W+/, "_").downcase
              test_name = test_name[0...50] if test_name.length > 50
              failure_file = format("%03d-%s.md", idx + 1, test_name)
              lines << "  → Details: #{report_path}/failures/#{failure_file}"
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
          stdout.each_line do |line|
            # Match test result lines like:
            # test_something [32m PASS[0m (0.00s)
            # test_other [31m FAIL[0m (0.01s)
            # test_error ERROR (0.00s)
            # test_skip SKIP (0.00s)
            if line =~ /^\s*test_\w+.*\s+(PASS|FAIL|ERROR|SKIP).*\([0-9.]+s\)/
              result = case $1
              when 'PASS'
                '.'
              when 'FAIL'
                'F'
              when 'ERROR'
                'E'
              when 'SKIP'
                'S'
              else
                '.'
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
          # Detect group from file path
          group = detect_group(file)

          # Print group header if it's a new group and groups are enabled
          if @show_groups && group != @current_group
            puts unless @test_count == 0
            puts ""
            puts colorize("═══ #{group.to_s.capitalize} Tests ═══", :cyan)
            @current_group = group
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

          # Track group counts
          @group_counts[group] += 1 if @show_groups
        end

        def detect_group(file_path)
          case file_path
          when /test\/unit\/atoms\//
            :atoms
          when /test\/unit\/molecules\//
            :molecules
          when /test\/unit\/organisms\//
            :organisms
          when /test\/unit\/models\//
            :models
          when /test\/integration\//
            :integration
          when /test\/system\//
            :system
          else
            :other
          end
        end

        def on_finish(result)
          # Ensure we're on a new line
          puts unless @test_count == 0 || @test_count % @line_width == 0

          # Print group summary if we have groups and groups are enabled
          if @show_groups && @group_counts.any?
            puts ""
            puts colorize("═══ Group Summary ═══", :cyan)
            @group_counts.each do |group, count|
              puts "  #{group.to_s.capitalize}: #{count} #{count == 1 ? 'file' : 'files'}"
            end
          end

          puts format_stdout(result)
        end

        private

        def result_color(result)
          case result
          when '.'
            :green
          when 'F'
            :red
          when 'E'
            :yellow
          when 'S'
            :cyan
          else
            :default
          end
        end

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