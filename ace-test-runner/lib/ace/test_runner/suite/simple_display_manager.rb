# frozen_string_literal: true

require_relative "display_helpers"

module Ace
  module TestRunner
    module Suite
      # SimpleDisplayManager provides line-by-line output without ANSI cursor control.
      # This is the default display mode, optimized for piping and agent consumption.
      #
      # Unlike DisplayManager which uses ANSI escape codes to update lines in place,
      # SimpleDisplayManager simply prints one line per package as it completes.
      class SimpleDisplayManager
        include DisplayHelpers

        attr_reader :packages, :config, :start_time

        def initialize(packages, config)
          @packages = packages
          @config = config
          @package_status = {}
          @start_time = Time.now
          @use_color = config.dig("test_suite", "display", "color") != false
          @package_width = calculate_package_width
        end

        # Print initial message showing how many packages will run
        def initialize_display
          puts "Running tests for #{@packages.size} packages..."
        end

        # Called when a package status changes. Prints a line when package completes.
        def update_package(package, status, _output = nil)
          @package_status[package["name"]] = status

          # Only print when package completes
          return unless status[:completed]

          print_completion_line(package, status)
        end

        # No-op for simple mode - we don't need live updates
        def refresh
          # Intentionally empty - simple mode doesn't refresh
        end

        # No-op for simple mode - results already printed as packages complete
        def show_final_results
          # Intentionally empty - completion lines already printed in update_package
        end

        # Display the summary section using shared helpers
        def show_summary(summary)
          render_summary(summary, @start_time, separator)
        end

        private

        # Print completion line with columnar format for easy scanning:
        # STATUS  TIME  PACKAGE                    TESTS    ASSERTS    FAIL
        # OK     1.57s  ace-handbook                   1          3       0
        def print_completion_line(package, status)
          results = status[:results] || {}
          duration = results[:duration] || status[:elapsed] || 0
          elapsed = sprintf("%5.2fs", duration)

          tests = results[:tests] || 0
          assertions = results[:assertions] || 0
          failures = results[:failures] || 0
          errors = results[:errors] || 0
          skipped = results[:skipped] || 0

          if status[:success]
            icon = package_status_icon(true, skipped)
            failure_count = failures
          else
            icon = package_status_icon(false, 0)
            failure_count = failures + errors
          end

          # Format: ICON  TIME  PACKAGE  TESTS  ASSERTS  FAIL [SKIP]
          name = package["name"].ljust(@package_width)
          tests_col = "#{tests.to_s.rjust(4)} tests"
          asserts_col = "#{assertions.to_s.rjust(5)} asserts"
          fail_col = "#{failure_count.to_s.rjust(3)} fail"

          line = "#{icon}  #{elapsed}  #{name}  #{tests_col}  #{asserts_col}  #{fail_col}"
          line += "  #{skipped} skip" if skipped > 0
          line += "  timeout" if status[:timed_out]

          puts line
        end

        def package_status_icon(success, skipped_count)
          return color("✗", :red) unless success
          (skipped_count > 0) ? color("?", :yellow) : color("✓", :green)
        end

        def separator
          "=" * 65
        end

        def color(text, color_name)
          return text unless @use_color

          colors = {
            green: "\033[32m",
            red: "\033[31m",
            yellow: "\033[33m",
            reset: "\033[0m"
          }

          "#{colors[color_name]}#{text}#{colors[:reset]}"
        end

        def calculate_package_width
          max_length = @packages.map { |p| p["name"].length }.max || 0
          [max_length, 15].max  # Minimum width of 15 for readability
        end
      end
    end
  end
end
