# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/test_runner/suite"
require "stringio"

module Ace
  module TestRunner
    module Suite
      class DisplayHelpersTest < Minitest::Test
        # Test class that includes DisplayHelpers for testing
        class TestDisplay
          include DisplayHelpers

          attr_accessor :use_color

          def initialize(use_color: false)
            @use_color = use_color
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
        end

        def setup
          @display = TestDisplay.new
        end

        # render_summary tests (capture output)
        def test_render_summary_all_passed
          summary = {
            packages_passed: 5,
            packages_failed: 0,
            total_tests: 100,
            total_passed: 100,
            total_failed: 0,
            total_skipped: 0,
            total_assertions: 200,
            assertions_failed: 0,
            results: [],
            failed_packages: []
          }
          start_time = Time.now - 10
          separator = "=" * 65

          output = capture_output { @display.render_summary(summary, start_time, separator) }

          assert_includes output, "✓ ALL TESTS PASSED"
          assert_includes output, "Packages:    5 passed, 0 failed"
          assert_includes output, "Tests:       100 passed, 0 failed"
          assert_includes output, "Assertions:  200 passed, 0 failed"
          assert_match(/Duration:    \d+\.\d+s/, output)
        end

        def test_render_summary_with_failures
          summary = {
            packages_passed: 4,
            packages_failed: 1,
            total_tests: 100,
            total_passed: 95,
            total_failed: 5,
            total_skipped: 0,
            total_assertions: 200,
            assertions_failed: 5,
            results: [],
            failed_packages: [
              {name: "ace-test", path: "/path/to/ace-test", failures: 3, errors: 2, output: "error details", failed_tests: []}
            ]
          }
          start_time = Time.now - 10
          separator = "=" * 65

          output = capture_output { @display.render_summary(summary, start_time, separator) }

          assert_includes output, "✗ SOME TESTS FAILED"
          assert_includes output, "Packages:    4 passed, 1 failed"
          assert_includes output, "Failed packages:"
          assert_includes output, "ace-test: 3 failures, 2 errors"
        end

        def test_render_summary_with_skipped
          summary = {
            packages_passed: 5,
            packages_failed: 0,
            total_tests: 100,
            total_passed: 95,
            total_failed: 0,
            total_skipped: 5,
            total_assertions: 200,
            assertions_failed: 0,
            results: [
              {package: "ace-test", skipped: 3},
              {package: "ace-lint", skipped: 2}
            ],
            failed_packages: []
          }
          start_time = Time.now - 10
          separator = "=" * 65

          output = capture_output { @display.render_summary(summary, start_time, separator) }

          assert_includes output, "✓ ALL TESTS PASSED"
          assert_includes output, "5 skipped"
          assert_includes output, "Skipped: ace-test (3), ace-lint (2)"
        end

        def test_render_summary_no_assertions
          summary = {
            packages_passed: 2,
            packages_failed: 0,
            total_tests: 50,
            total_passed: 50,
            total_failed: 0,
            total_skipped: 0,
            total_assertions: 0,
            results: [],
            failed_packages: []
          }
          start_time = Time.now - 5
          separator = "=" * 65

          output = capture_output { @display.render_summary(summary, start_time, separator) }

          assert_includes output, "✓ ALL TESTS PASSED"
          assert_includes output, "Tests:       50 passed, 0 failed"
          refute_includes output, "Assertions:"
        end

        def test_render_summary_no_tests
          summary = {
            packages_passed: 1,
            packages_failed: 0,
            total_tests: 0,
            total_passed: 0,
            total_failed: 0,
            total_skipped: 0,
            total_assertions: 0,
            results: [],
            failed_packages: []
          }
          start_time = Time.now - 1
          separator = "=" * 65

          output = capture_output { @display.render_summary(summary, start_time, separator) }

          assert_includes output, "✓ ALL TESTS PASSED"
          refute_includes output, "Tests:"  # No tests line when total_tests is 0
        end

        def test_render_summary_status_is_last
          summary = {
            packages_passed: 5,
            packages_failed: 0,
            total_tests: 100,
            total_passed: 100,
            total_failed: 0,
            total_skipped: 0,
            total_assertions: 200,
            assertions_failed: 0,
            results: [],
            failed_packages: []
          }
          start_time = Time.now - 10
          separator = "=" * 65

          output = capture_output { @display.render_summary(summary, start_time, separator) }

          # Status line should appear after stats and before closing separator
          lines = output.lines.map(&:strip).reject(&:empty?)
          status_index = lines.index { |l| l.include?("ALL TESTS PASSED") }
          separator_indices = lines.each_index.select { |i| lines[i] == separator }

          # Status should be just before the last separator
          assert_equal separator_indices.last - 1, status_index, "Status should be just before closing separator"
        end

        private

        def capture_output
          original_stdout = $stdout
          $stdout = StringIO.new
          yield
          $stdout.string
        ensure
          $stdout = original_stdout
        end
      end
    end
  end
end
