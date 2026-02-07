# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Animated ANSI table display manager for E2E test output (--progress mode).
        # Updates test rows in place using cursor movement escape codes.
        # Modeled on ace-test-runner's DisplayManager for visual consistency.
        class ProgressDisplayManager
          # @param scenarios [Array<Models::TestScenario>] tests to run
          # @param output [IO] output stream
          # @param parallel [Integer] parallelism level
          def initialize(scenarios, output:, parallel:)
            @scenarios = scenarios
            @output = output
            @parallel = parallel
            @use_color = output.respond_to?(:tty?) && output.tty?
            @start_time = Time.now
            @lines = {}           # scenario.test_id => line number
            @states = {}          # scenario.test_id => :waiting | :running | :completed
            @results = {}         # scenario.test_id => Models::TestResult
            @started_at = {}      # scenario.test_id => Time
            @title_width = calculate_title_width
          end

          # Print header and initial table with all tests in waiting state
          def initialize_display
            h = Atoms::DisplayHelpers
            package = @scenarios.first&.package || "unknown"

            # Clear screen (preserves scrollback)
            @output.print "\033[H\033[J"

            @output.puts h.separator
            @output.puts "  E2E Tests: #{package} (#{@scenarios.size} tests)"
            @output.puts h.separator
            @output.puts

            @scenarios.each_with_index do |scenario, index|
              line = index + 5  # account for header lines
              @lines[scenario.test_id] = line
              @states[scenario.test_id] = :waiting
              print_row(scenario)
            end

            @output.puts
            @output.puts
            @footer_line = @lines.values.max + 3
            update_footer
          end

          # Update row when a test begins
          # @param scenario [Models::TestScenario]
          def test_started(scenario)
            @states[scenario.test_id] = :running
            @started_at[scenario.test_id] = Time.now
            print_row(scenario)
            update_footer
          end

          # Update row when a test completes
          # @param scenario [Models::TestScenario]
          # @param result [Models::TestResult]
          # @param completed [Integer]
          # @param total [Integer]
          def test_completed(scenario, result, completed, total)
            @states[scenario.test_id] = :completed
            @results[scenario.test_id] = result
            print_row(scenario)
            update_footer
          end

          # Refresh running test rows to update elapsed timers
          def refresh
            @states.each do |test_id, state|
              next unless state == :running

              scenario = @scenarios.find { |s| s.test_id == test_id }
              print_row(scenario) if scenario
            end
            update_footer
          end

          # Print a single-test result line (for run-single-test mode)
          # @param result [Models::TestResult]
          def show_single_result(result)
            @output.puts Atoms::DisplayHelpers.format_single_result(result, use_color: @use_color)
          end

          # Print structured summary block
          # @param results [Array<Models::TestResult>]
          # @param report_path [String]
          def show_summary(results, report_path)
            # Move cursor past the display area
            move_to_line(@footer_line + 1)
            @output.puts

            lines = Atoms::DisplayHelpers.format_summary_lines(
              results, Time.now - @start_time, report_path, use_color: @use_color
            )
            lines.each { |line| @output.puts line }
          end

          private

          def print_row(scenario)
            h = Atoms::DisplayHelpers
            line = @lines[scenario.test_id]
            state = @states[scenario.test_id]

            move_to_line(line)
            @output.print "\033[K" # clear line

            title = scenario.title.ljust(@title_width)

            case state
            when :waiting
              icon = h.color("\u00b7", :gray, use_color: @use_color)
              elapsed = "  0.0s"
              status = "waiting"
              @output.print "#{icon}  #{elapsed}  #{scenario.test_id}  #{title}  #{status}"

            when :running
              icon = h.color("\u22ef", :cyan, use_color: @use_color)
              secs = Time.now - (@started_at[scenario.test_id] || Time.now)
              elapsed = h.format_elapsed(secs)
              status = "running"
              @output.print "#{icon}  #{elapsed}  #{scenario.test_id}  #{title}  #{status}"

            when :completed
              result = @results[scenario.test_id]
              success = result.success?
              icon = h.color(h.status_icon(success), success ? :green : :red, use_color: @use_color)
              elapsed = h.format_elapsed(result.duration)
              tc = h.tc_count_display(result)
              status_text = result.status.upcase
              @output.print "#{icon}  #{elapsed}  #{scenario.test_id}  #{title}  #{status_text}#{tc}"
            end
          end

          def update_footer
            move_to_line(@footer_line)
            @output.print "\033[K"

            active = @states.count { |_, s| s == :running }
            completed = @states.count { |_, s| s == :completed }
            waiting = @states.count { |_, s| s == :waiting }

            @output.print "Active: #{active} | Completed: #{completed} | Waiting: #{waiting}"
          end

          def move_to_line(line)
            @output.print "\033[#{line};1H"
          end

          def calculate_title_width
            max = @scenarios.map { |s| s.title.length }.max || 0
            [max, 20].max
          end
        end
      end
    end
  end
end
