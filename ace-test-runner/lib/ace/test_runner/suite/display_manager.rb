# frozen_string_literal: true

module Ace
  module TestRunner
    module Suite
      class DisplayManager
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
            @package_status[package["name"]] = { status: :waiting }
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

        def show_final_results
          # Move to after all package lines
          move_to_line(@footer_line + 1)

          puts
          puts separator
          puts "  FINAL RESULTS"
          puts separator

          # Show each package's final status
          @packages.each do |package|
            status = @package_status[package["name"]]
            next unless status[:completed]

            results = status[:results] || {}
            name = package["name"].ljust(18)

            if status[:success]
              skipped = results[:skipped] || 0
              icon = package_status_icon(true, skipped)
              tests = results[:tests] || 0
              assertions = results[:assertions] || 0
              failures = results[:failures] || 0
              duration = results[:duration] || status[:elapsed] || 0

              if assertions > 0
                summary_text = "#{tests.to_s.rjust(3)} tests, #{assertions.to_s.rjust(3)} assertions, #{failures} failures"
                summary_text = append_skipped_text(summary_text, skipped)
                puts "#{name} #{icon} #{summary_text}".ljust(50) + sprintf("%6.2fs", duration)
              else
                summary_text = "#{tests.to_s.rjust(3)} tests, #{failures} failures"
                summary_text = append_skipped_text(summary_text, skipped)
                puts "#{name} #{icon} #{summary_text}".ljust(50) + sprintf("%6.2fs", duration)
              end
            else
              icon = package_status_icon(false, 0)
              tests = results[:tests] || 0
              assertions = results[:assertions] || 0
              failures = results[:failures] || 0
              errors = results[:errors] || 0
              skipped = results[:skipped] || 0
              duration = results[:duration] || status[:elapsed] || 0

              failure_text = []
              failure_text << "#{failures} failures" if failures > 0
              failure_text << "#{errors} errors" if errors > 0
              failure_text << "#{skipped} skipped" if skipped > 0

              if assertions > 0
                puts "#{name} #{icon} #{tests.to_s.rjust(3)} tests, #{assertions.to_s.rjust(3)} assertions, #{failure_text.join(', ')}".ljust(50) +
                     sprintf("%6.2fs", duration)
              else
                puts "#{name} #{icon} #{tests.to_s.rjust(3)} tests, #{failure_text.join(', ')}".ljust(50) +
                     sprintf("%6.2fs", duration)
              end
            end
          end
        end

        def show_summary(summary)
          puts
          puts separator

          total_duration = Time.now - @start_time

          # Overall status
          total_skipped = summary[:total_skipped] || 0
          if summary[:packages_failed] == 0 && total_skipped == 0
            puts color("✅ ALL TESTS PASSED!", :green)
          elsif summary[:packages_failed] == 0 && total_skipped > 0
            puts color("⚠️ ALL TESTS PASSED (with #{total_skipped} skipped)", :yellow)
          else
            puts color("❌ SOME TESTS FAILED", :red)
          end

          puts
          total_packages = summary[:packages_passed] + summary[:packages_failed]
          puts "Packages:  #{summary[:packages_passed]}/#{total_packages} passed, #{summary[:packages_failed]} failed"

          # Tests line
          if summary[:total_tests] > 0
            if total_skipped > 0
              puts "Tests:     #{summary[:total_tests]} total, #{summary[:total_passed]} passed, #{summary[:total_failed]} failed, #{total_skipped} skipped"
            else
              puts "Tests:     #{summary[:total_passed]}/#{summary[:total_tests]} passed, #{summary[:total_failed]} failed"
            end
          end

          # Assertions line if available
          if summary[:total_assertions] && summary[:total_assertions] > 0
            assertions_failed = summary[:assertions_failed] || 0
            assertions_passed = summary[:total_assertions] - assertions_failed
            puts "Assertions: #{assertions_passed}/#{summary[:total_assertions]} passed, #{assertions_failed} failed"
          end

          puts "Duration:  #{sprintf('%.2f', total_duration)}s (wall time)"

          # Show failed packages
          if summary[:failed_packages] && !summary[:failed_packages].empty?
            puts
            puts "Failed packages:"
            summary[:failed_packages].each do |pkg|
              puts "  - #{pkg[:name]}: #{pkg[:failures]} failures, #{pkg[:errors]} errors"
              puts "    → See #{pkg[:path]}/test-reports/latest/failures.json"
            end
          end

          # Show packages with skipped tests
          if total_skipped > 0
            packages_with_skips = summary[:results].select { |r| (r[:skipped] || 0) > 0 }
            if !packages_with_skips.empty?
              puts
              puts "Packages with skips:"
              packages_with_skips.each do |pkg|
                puts "  - #{pkg[:package]}: #{pkg[:skipped]} skipped"
              end
            end
          end

          puts separator
        end

        private

        def print_package_line(name)
          status = @package_status[name]
          line = @lines[name]

          move_to_line(line)
          print "\033[K"  # Clear line

          # Format package name (fixed width)
          pkg_name = "[#{name}]".ljust(20)

          case status[:status]
          when :waiting
            print "#{pkg_name} #{color('[············]', :gray)} Waiting...".ljust(60)
          when :running
            # Show progress bar
            progress_bar = build_progress_bar(status)
            elapsed = sprintf("%.1f", status[:elapsed] || 0)
            if status[:total] && status[:total] > 0
              print "#{pkg_name} #{progress_bar} #{status[:progress]}/#{status[:total]} tests".ljust(50) +
                    "#{elapsed}s"
            else
              # Show dots if no total count
              dots = (status[:dots] || "").chars.last(10).join
              print "#{pkg_name} #{progress_bar} #{dots}".ljust(50) + "#{elapsed}s"
            end
          when :completed
            results = status[:results] || {}
            elapsed = sprintf("%.2f", status[:elapsed] || 0)

            if status[:success]
              tests = results[:tests] || 0
              assertions = results[:assertions] || 0
              skipped = results[:skipped] || 0
              icon = package_status_icon(true, skipped)

              if assertions > 0
                summary_text = "#{tests} tests, #{assertions} assertions, 0 failures"
                summary_text = append_skipped_text(summary_text, skipped)
                print "#{pkg_name} #{icon} #{summary_text}".ljust(60) + "#{elapsed}s"
              else
                summary_text = "#{tests} tests, 0 failures"
                summary_text = append_skipped_text(summary_text, skipped)
                print "#{pkg_name} #{icon} #{summary_text}".ljust(60) + "#{elapsed}s"
              end
            else
              tests = results[:tests] || 0
              assertions = results[:assertions] || 0
              failures = results[:failures] || 0
              errors = results[:errors] || 0
              skipped = results[:skipped] || 0
              failure_count = failures + errors
              icon = package_status_icon(false, 0)

              if assertions > 0
                summary_text = "#{tests} tests, #{assertions} assertions, #{failure_count} failures"
                summary_text = append_skipped_text(summary_text, skipped)
                print "#{pkg_name} #{icon} #{summary_text}".ljust(60) + "#{elapsed}s"
              else
                summary_text = "#{tests} tests, #{failure_count} failures"
                summary_text = append_skipped_text(summary_text, skipped)
                print "#{pkg_name} #{icon} #{summary_text}".ljust(60) + "#{elapsed}s"
              end
            end
          end
        end

        # Determines the appropriate status icon for a package
        # Returns ⚠️ (yellow) for successful packages with skipped tests (informational)
        # Returns ✅ (green) for successful packages without skipped tests
        # Returns ❌ (red) for failed packages
        def package_status_icon(success, skipped_count)
          return color("❌", :red) unless success
          skipped_count > 0 ? color("⚠️", :yellow) : color("✅", :green)
        end

        # Appends skipped count text to a summary string if skipped > 0
        # This provides consistent formatting across all display methods
        def append_skipped_text(summary_text, skipped_count)
          skipped_count > 0 ? "#{summary_text}, #{skipped_count} skipped" : summary_text
        end

        def build_progress_bar(status)
          bar_width = 13
          if status[:total] && status[:total] > 0
            progress = status[:progress] || 0
            filled = (progress.to_f / status[:total] * bar_width).round
          else
            # Animate based on elapsed time if no total
            elapsed = status[:elapsed] || 0
            filled = ((elapsed % 3) * bar_width / 3).round
          end

          filled = [filled, bar_width].min
          empty = bar_width - filled

          bar = "[" + color("▓" * filled, :green) + "░" * empty + "]"
          bar
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