# frozen_string_literal: true

module Ace
  module TestRunner
    module Models
      # Represents the result of a test run
      class TestResult
        attr_accessor :passed, :failed, :skipped, :errors, :assertions,
          :duration, :start_time, :end_time, :failures_detail,
          :deprecations, :raw_output, :stderr, :execution_success

        def initialize(attributes = {})
          @passed = attributes[:passed] || 0
          @failed = attributes[:failed] || 0
          @skipped = attributes[:skipped] || 0
          @errors = attributes[:errors] || 0
          @assertions = attributes[:assertions] || 0
          @duration = attributes[:duration] || 0.0
          @start_time = attributes[:start_time]
          @end_time = attributes[:end_time]
          @failures_detail = attributes[:failures_detail] || []
          @deprecations = attributes[:deprecations] || []
          @raw_output = attributes[:raw_output] || ""
          @stderr = attributes[:stderr] || ""
          @execution_success = attributes.fetch(:execution_success, true) == true
        end

        def total_tests
          passed + failed + skipped + errors
        end

        def success?
          execution_success && failed == 0 && errors == 0
        end

        def has_failures?
          !success?
        end

        def execution_error
          return nil if execution_success
          stderr.to_s.strip.empty? ? "Test execution did not complete successfully" : stderr.to_s.strip
        end

        def has_skips?
          skipped > 0
        end

        def has_deprecations?
          deprecations.any?
        end

        def pass_rate
          return 0.0 if total_tests == 0
          (passed.to_f / total_tests * 100).round(2)
        end

        def summary_line
          parts = []
          parts << "✅ #{passed} passed" if passed > 0
          parts << "❌ #{failed} failed" if failed > 0
          parts << "💥 #{errors} errors" if errors > 0
          parts << "⚠️ #{skipped} skipped" if skipped > 0
          parts << "❌ execution failed" unless execution_success

          parts.empty? ? "No tests executed" : parts.join(", ")
        end

        def to_h
          {
            passed: passed,
            failed: failed,
            skipped: skipped,
            errors: errors,
            assertions: assertions,
            total_tests: total_tests,
            duration: duration,
            pass_rate: pass_rate,
            success: success?,
            execution_success: execution_success,
            execution_error: execution_error,
            start_time: start_time&.iso8601,
            end_time: end_time&.iso8601,
            failures: failures_detail.map(&:to_h),
            deprecations: deprecations
          }
        end

        def to_json(*args)
          to_h.to_json(*args)
        end
      end
    end
  end
end
