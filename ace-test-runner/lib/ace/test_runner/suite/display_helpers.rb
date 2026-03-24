# frozen_string_literal: true

module Ace
  module TestRunner
    module Suite
      # DisplayHelpers provides shared formatting methods for display managers.
      # This module centralizes common output formatting logic used by both
      # SimpleDisplayManager (line-by-line) and DisplayManager (animated).
      #
      # == Interface Requirements
      #
      # Including classes must implement:
      #   color(text, color_name) - Apply color to text (or return text unchanged)
      #     @param text [String] the text to colorize
      #     @param color_name [Symbol] one of :green, :red, :yellow
      #     @return [String] colorized text or plain text
      #
      # This module provides a `colorize` wrapper that delegates to `color()`.
      # Internal methods use `colorize()` for consistency; including classes
      # only need to implement `color()`.
      #
      module DisplayHelpers
        # Render the overall summary section
        # @param summary [Hash] summary data from orchestrator
        # @param start_time [Time] when the test run started
        # @param separator [String] visual separator line
        def render_summary(summary, start_time, separator)
          puts
          puts separator

          total_duration = Time.now - start_time
          total_skipped = summary[:total_skipped] || 0

          # Show packages with skipped tests first (least important, scrolls away)
          render_skipped_packages(summary, total_skipped)

          # Show failed packages (important but less than status)
          render_failed_packages(summary)

          # Duration
          puts "Duration:    #{sprintf("%.2f", total_duration)}s"

          # Stats (packages, tests, assertions)
          puts "Packages:    #{summary[:packages_passed]} passed, #{summary[:packages_failed]} failed"
          render_tests_line(summary, total_skipped)
          render_assertions_line(summary)

          # Overall status message LAST (most visible)
          puts
          render_status_message(summary[:packages_failed], total_skipped)

          puts separator
        end

        private

        def render_status_message(packages_failed, total_skipped)
          if packages_failed == 0 && total_skipped == 0
            puts colorize("✓ ALL TESTS PASSED", :green)
          elsif packages_failed == 0 && total_skipped > 0
            puts colorize("✓ ALL TESTS PASSED", :green)
          else
            puts colorize("✗ SOME TESTS FAILED", :red)
          end
        end

        def render_tests_line(summary, total_skipped)
          return unless summary[:total_tests] > 0

          if total_skipped > 0
            puts "Tests:       #{summary[:total_passed]} passed, #{summary[:total_failed]} failed, #{total_skipped} skipped"
          else
            puts "Tests:       #{summary[:total_passed]} passed, #{summary[:total_failed]} failed"
          end
        end

        def render_assertions_line(summary)
          return unless summary[:total_assertions] && summary[:total_assertions] > 0

          assertions_failed = summary[:assertions_failed] || 0
          assertions_passed = summary[:total_assertions] - assertions_failed
          puts "Assertions:  #{assertions_passed} passed, #{assertions_failed} failed"
        end

        def render_failed_packages(summary)
          return unless summary[:failed_packages] && !summary[:failed_packages].empty?

          puts
          puts "Failed packages:"
          summary[:failed_packages].each do |pkg|
            puts "  - #{pkg[:name]}: #{pkg[:failures]} failures, #{pkg[:errors]} errors"
            puts Ace::TestRunner::Molecules::FailedPackageReporter.format_for_display(pkg)
          end
        end

        def render_skipped_packages(summary, total_skipped)
          return unless total_skipped > 0

          packages_with_skips = summary[:results].select { |r| (r[:skipped] || 0) > 0 }
          return if packages_with_skips.empty?

          skip_parts = packages_with_skips.map { |pkg| "#{pkg[:package]} (#{pkg[:skipped]})" }
          puts "Skipped: #{skip_parts.join(", ")}"
          puts
        end

        # Colorize text - must be implemented by including class
        # @param text [String] text to colorize
        # @param color_name [Symbol] color name (:green, :red, :yellow)
        # @return [String] colorized text or plain text if color disabled
        def colorize(text, color_name)
          color(text, color_name)
        end
      end
    end
  end
end
