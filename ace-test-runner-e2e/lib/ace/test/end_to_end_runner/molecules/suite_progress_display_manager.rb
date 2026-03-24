# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Animated ANSI table display manager for suite-level E2E test output (--progress mode).
        # Updates test rows in place using cursor movement escape codes.
        # Modeled on ProgressDisplayManager for visual consistency.
        class SuiteProgressDisplayManager
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
            @start_time = Time.now
            @last_refresh = Time.at(0)

            # Build row map: "package:test_file" => line number
            @rows = {}
            @states = {}      # key => :waiting | :running | :completed
            @results = {}     # key => result hash
            @started_at = {}  # key => Time

            @test_queue.each_with_index do |item, index|
              key = row_key(item[:package], item[:test_file])
              @rows[key] = index + 5  # account for header lines (sep + title + sep + blank)
              @states[key] = :waiting
            end
          end

          # Clear screen, print header, pre-render all rows as "waiting", print footer
          # @param total_tests [Integer]
          # @param pkg_count [Integer]
          def show_header(total_tests, pkg_count)
            dh = Atoms::DisplayHelpers

            # Clear screen (preserves scrollback)
            @output.print "\033[H\033[J"

            @output.puts dh.double_separator
            @output.puts "  ACE E2E Test Suite - Running #{total_tests} tests across #{pkg_count} packages"
            @output.puts dh.double_separator
            @output.puts

            # Pre-render all rows in waiting state
            @test_queue.each do |item|
              print_row(item[:package], item[:test_file])
            end

            @output.puts
            @output.puts
            # Guard against empty queue: default to current line if no rows
            @footer_line = @rows.values.max + 3 if @rows.values.any?
            update_footer
          end

          # Update row to "running" state
          # @param package [String]
          # @param test_file [String]
          def test_started(package, test_file)
            key = row_key(package, test_file)
            @states[key] = :running
            @started_at[key] = Time.now
            print_row(package, test_file)
            update_footer
          end

          # Update row to completed state with result
          # @param result [Hash] with :status, :passed_cases, :total_cases
          # @param package [String]
          # @param test_file [String]
          # @param elapsed [Numeric] seconds
          def test_completed(result, package, test_file, elapsed)
            key = row_key(package, test_file)
            @states[key] = :completed
            @results[key] = result.merge(elapsed: elapsed)
            print_row(package, test_file)
            update_footer
          end

          # Refresh running rows to update elapsed timers + footer
          # Throttled to ~4Hz — the poll loop runs at 10Hz but redraws are expensive
          def refresh
            now = Time.now
            return if now - @last_refresh < REFRESH_INTERVAL

            @last_refresh = now

            @states.each do |key, state|
              next unless state == :running

              item = find_item(key)
              print_row(item[:package], item[:test_file]) if item
            end
            update_footer
          end

          # Move past the table area and print summary
          # @param results [Hash] with :total, :passed, :failed, :errors, :packages
          # @param duration [Numeric] total elapsed seconds
          def show_summary(results, duration)
            move_to_line((@footer_line || 6) + 1)
            @output.puts

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

          def row_key(package, test_file)
            "#{package}:#{test_file}"
          end

          def find_item(key)
            @test_queue.find { |item| row_key(item[:package], item[:test_file]) == key }
          end

          def extract_test_name(test_file)
            File.basename(File.dirname(test_file))
          end

          def print_row(package, test_file)
            dh = Atoms::DisplayHelpers
            key = row_key(package, test_file)
            line = @rows[key]
            state = @states[key]
            test_name = extract_test_name(test_file)

            move_to_line(line)
            @output.print "\033[K" # clear line

            pkg_col = package.ljust(@pkg_width)
            name_col = test_name.ljust(@name_width)

            case state
            when :waiting
              icon = dh.color(dh.waiting_icon, :gray, use_color: @use_color)
              elapsed = "      -"
              @output.print "#{icon}  #{elapsed}  #{pkg_col}  #{name_col}  waiting"

            when :running
              icon = dh.color(dh.running_icon, :cyan, use_color: @use_color)
              secs = Time.now - (@started_at[key] || Time.now)
              elapsed = dh.format_suite_elapsed(secs)
              @output.print "#{icon}  #{elapsed}  #{pkg_col}  #{name_col}  running"

            when :completed
              result = @results[key]
              success = result[:status] == "pass"
              icon = dh.color(dh.status_icon(success), success ? :green : :red, use_color: @use_color)
              elapsed = dh.format_suite_elapsed(result[:elapsed])

              cases_str = ""
              if result[:total_cases] && result[:total_cases] > 0
                cases_str = "#{result[:passed_cases]}/#{result[:total_cases]} cases"
              end

              @output.print "#{icon}  #{elapsed}  #{pkg_col}  #{name_col}  #{cases_str}"
            end
          end

          def update_footer
            return unless @footer_line

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
