# frozen_string_literal: true

require_relative "display_helpers"

module Ace
  module TestRunner
    module Suite
      class DisplayManager
        include DisplayHelpers

        attr_reader :packages, :config, :lines, :start_time

        def initialize(packages, config)
          @packages = packages
          @config = config
          @lines = {}
          @package_status = {}
          @start_time = Time.now
          @use_color = config.dig("test_suite", "display", "color") != false
          @last_refresh = Time.now
          @refresh_interval = config.dig("test_suite", "display", "update_interval") || 0.1
        end

        def initialize_display
          # Clear screen like Ctrl+L (preserves scrollback)
          print "\033[H\033[J"

          # Print header
          puts separator
          puts "  ACE Test Suite Runner - Running #{@packages.size} packages"
          puts separator
          puts

          # Reserve lines for each package
          @packages.each_with_index do |package, index|
            @lines[package["name"]] = index + 5  # Account for header lines
            @package_status[package["name"]] = {status: :waiting}
            print_package_line(package["name"])
          end

          # Print footer space
          puts
          puts
          @footer_line = @lines.values.max + 3
        end

        def update_package(package, status, output = nil)
          @package_status[package["name"]] = status
          print_package_line(package["name"])
          update_footer
        end

        def refresh
          # Only refresh if enough time has passed
          return if Time.now - @last_refresh < @refresh_interval

          @package_status.each do |name, _status|
            print_package_line(name)
          end
          update_footer
          @last_refresh = Time.now
        end

        # Finalize display by moving cursor past the display area.
        # In progress mode, package results are already shown inline during updates,
        # so we skip redrawing the results table. The overall summary is handled by show_summary.
        def finalize_display
          move_to_line(@footer_line + 1)
          puts
        end

        # Alias for backward compatibility
        alias_method :show_final_results, :finalize_display

        # Display the summary section using shared helpers
        def show_summary(summary)
          render_summary(summary, @start_time, separator)
        end

        private

        def print_package_line(name)
          status = @package_status[name]
          line = @lines[name]

          move_to_line(line)
          print "\033[K"  # Clear line

          # Format package name (fixed width, no brackets)
          pkg_name = name.ljust(25)

          case status[:status]
          when :waiting
            icon = color("·", :gray)
            elapsed = "  0.00s"
            progress = "[············]  waiting"
            print "#{icon}  #{elapsed}  #{pkg_name}  #{progress}"

          when :running
            icon = color("⋯", :cyan)
            duration = status.dig(:results, :duration) || status[:elapsed] || 0
            elapsed = sprintf("%5.2fs", duration)
            progress_bar = build_progress_bar(status)
            count = if status[:total] && status[:total] > 0
              "#{status[:progress]}/#{status[:total]}"
            else
              "running"
            end
            print "#{icon}  #{elapsed}  #{pkg_name}  #{progress_bar}  #{count}"

          when :completed
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
            tests_col = "#{tests.to_s.rjust(4)} tests"
            asserts_col = "#{assertions.to_s.rjust(5)} asserts"
            fail_col = "#{failure_count.to_s.rjust(3)} fail"

            line_text = "#{icon}  #{elapsed}  #{pkg_name}  #{tests_col}  #{asserts_col}  #{fail_col}"
            line_text += "  #{skipped} skip" if skipped > 0

            print line_text
          end
        end

        # Determines the appropriate status icon for a package
        # Returns ? (yellow) for successful packages with skipped tests (informational)
        # Returns ✓ (green) for successful packages without skipped tests
        # Returns ✗ (red) for failed packages
        def package_status_icon(success, skipped_count)
          return color("✗", :red) unless success
          (skipped_count > 0) ? color("?", :yellow) : color("✓", :green)
        end

        def build_progress_bar(status)
          bar_width = 13
          if status[:total] && status[:total] > 0
            progress = status[:progress] || 0
            filled = (progress.to_f / status[:total] * bar_width).round
          else
            # Animate based on elapsed time if no total
            duration = status.dig(:results, :duration) || status[:elapsed] || 0
            filled = ((duration % 3) * bar_width / 3).round
          end

          filled = [filled, bar_width].min
          empty = bar_width - filled

          "[" + color("▓" * filled, :green) + "░" * empty + "]"
        end

        def update_footer
          move_to_line(@footer_line)
          print "\033[K"

          active = @package_status.count { |_, s| s[:status] == :running }
          completed = @package_status.count { |_, s| s[:status] == :completed }
          waiting = @package_status.count { |_, s| s[:status] == :waiting }

          print "Active: #{active} | Completed: #{completed} | Waiting: #{waiting}"
        end

        def move_to_line(line)
          print "\033[#{line};1H"
        end

        def separator
          "═" * 65
        end

        def color(text, color_name)
          return text unless @use_color

          colors = {
            green: "\033[32m",
            red: "\033[31m",
            yellow: "\033[33m",
            cyan: "\033[36m",
            gray: "\033[90m",
            reset: "\033[0m"
          }

          "#{colors[color_name]}#{text}#{colors[:reset]}"
        end
      end
    end
  end
end
