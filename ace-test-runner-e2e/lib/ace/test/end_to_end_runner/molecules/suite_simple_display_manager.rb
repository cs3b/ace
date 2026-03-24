# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Line-by-line display manager for suite-level E2E test output (default mode).
        # Extracted from SuiteOrchestrator to match the display manager pattern
        # used by TestOrchestrator (SimpleDisplayManager / ProgressDisplayManager).
        class SuiteSimpleDisplayManager
          # @param test_queue [Array<Hash>] flat list of {package:, test_file:} items
          # @param output [IO] output stream
          # @param use_color [Boolean] enable ANSI color
          # @param pkg_width [Integer] column width for package names
          # @param name_width [Integer] column width for test names
          def initialize(test_queue, output:, use_color:, pkg_width:, name_width:)
            @test_queue = test_queue
            @output = output
            @use_color = use_color
            @pkg_width = pkg_width
            @name_width = name_width
          end

          # Print suite header with separator, title, separator
          # @param total_tests [Integer]
          # @param pkg_count [Integer]
          def show_header(total_tests, pkg_count)
            dh = Atoms::DisplayHelpers
            @output.puts dh.double_separator
            @output.puts "  ACE E2E Test Suite - Running #{total_tests} tests across #{pkg_count} packages"
            @output.puts dh.double_separator
            @output.puts
          end

          # No-op — simple mode doesn't show start events
          def test_started(_package, _test_file)
          end

          # Print a columnar result line
          # @param result [Hash] with :status, :passed_cases, :total_cases
          # @param package [String]
          # @param test_file [String]
          # @param elapsed [Numeric] seconds
          def test_completed(result, package, test_file, elapsed)
            dh = Atoms::DisplayHelpers
            success = result[:status] == "pass"
            icon = dh.color(dh.status_icon(success), success ? :green : :red, use_color: @use_color)
            test_name = extract_test_name(test_file)

            cases_str = ""
            if result[:total_cases] && result[:total_cases] > 0
              cases_str = "#{result[:passed_cases]}/#{result[:total_cases]} cases"
            end

            line = dh.format_suite_test_line(
              icon, elapsed, package, test_name, cases_str,
              pkg_width: @pkg_width, name_width: @name_width
            )
            @output.puts line
          end

          # No-op — simple mode doesn't need refresh
          def refresh
          end

          # Print structured summary block
          # @param results [Hash] with :total, :passed, :failed, :errors, :packages
          # @param duration [Numeric] total elapsed seconds
          def show_summary(results, duration)
            failed_details = collect_failed_details(results)

            lines = Atoms::DisplayHelpers.format_suite_summary(
              {
                total: results[:total],
                passed: results[:passed],
                failed: results[:failed],
                errors: results[:errors],
                total_cases: results[:total_cases] || 0,
                passed_cases: results[:passed_cases] || 0,
                duration: duration,
                failed_details: failed_details
              },
              use_color: @use_color
            )

            lines.each { |line| @output.puts line }
          end

          private

          def extract_test_name(test_file)
            File.basename(File.dirname(test_file))
          end

          def collect_failed_details(results)
            failed_details = []
            results[:packages].each do |package, test_results|
              test_results.each do |result|
                next if result[:status] == "pass"

                test_name = result[:test_name] || "unknown"
                cases = if result[:total_cases] && result[:total_cases] > 0
                  "#{result[:passed_cases]}/#{result[:total_cases]} cases"
                else
                  result[:error] || result[:summary] || "failed"
                end
                failed_details << {package: package, test_name: test_name, cases: cases}
              end
            end
            failed_details
          end
        end
      end
    end
  end
end
