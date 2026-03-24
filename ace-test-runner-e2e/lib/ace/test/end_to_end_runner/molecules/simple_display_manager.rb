# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Line-by-line display manager for E2E test output (default mode).
        # Optimized for piping, log capture, and agent consumption.
        # No ANSI cursor control — each event appends a new line.
        class SimpleDisplayManager
          # @param scenarios [Array<Models::TestScenario>] tests to run
          # @param output [IO] output stream
          # @param parallel [Integer] parallelism level
          def initialize(scenarios, output:, parallel:)
            @scenarios = scenarios
            @output = output
            @parallel = parallel
            @use_color = output.respond_to?(:tty?) && output.tty?
            @start_time = Time.now
          end

          # Print header showing test count and parallelism
          def initialize_display
            package = @scenarios.first&.package || "unknown"
            @output.puts "Discovered #{@scenarios.size} E2E tests in #{package}"
            @output.puts "Running with parallelism: #{@parallel}" if @parallel > 1
          end

          # Print line when a test begins
          # @param scenario [Models::TestScenario]
          def test_started(scenario)
            @output.puts "[started] #{scenario.test_id}: #{scenario.title}"
          end

          # Print line when a test completes
          # @param scenario [Models::TestScenario]
          # @param result [Models::TestResult]
          # @param completed [Integer] number completed so far
          # @param total [Integer] total number of tests
          def test_completed(scenario, result, completed, total)
            h = Atoms::DisplayHelpers
            icon = h.color(h.status_icon(result.success?), result.success? ? :green : :red, use_color: @use_color)
            elapsed = h.format_elapsed(result.duration)
            tc = h.tc_count_display(result)

            @output.puts "[#{completed}/#{total}] #{icon}  #{elapsed}  #{scenario.test_id}  #{result.status.upcase}#{tc}"
          end

          # Print a single-test result line (for run-single-test mode)
          # @param result [Models::TestResult]
          def show_single_result(result)
            @output.puts Atoms::DisplayHelpers.format_single_result(result, use_color: @use_color)
          end

          # No-op — simple mode doesn't need refresh
          def refresh
          end

          # Print structured summary block
          # @param results [Array<Models::TestResult>]
          # @param report_path [String]
          def show_summary(results, report_path)
            lines = Atoms::DisplayHelpers.format_summary_lines(
              results, Time.now - @start_time, report_path, use_color: @use_color
            )
            lines.each { |line| @output.puts line }
          end
        end
      end
    end
  end
end
