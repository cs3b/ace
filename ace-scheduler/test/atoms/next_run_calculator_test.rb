# frozen_string_literal: true

require "test_helper"
require "time"

module Ace
  module Scheduler
    class NextRunCalculatorTest < AceSchedulerTestCase
      def test_calculate_next_run
        calculator = Atoms::NextRunCalculator.new
        from_time = Time.utc(2026, 2, 1, 8, 0, 0)

        next_run = calculator.calculate("0 9 * * *", from: from_time)
        assert_equal Time.utc(2026, 2, 1, 9, 0, 0), next_run
      end

      def test_time_until
        calculator = Atoms::NextRunCalculator.new
        from_time = Time.utc(2026, 2, 1, 8, 0, 0)
        next_run = Time.utc(2026, 2, 1, 9, 30, 0)

        assert_equal "1h 30m", calculator.time_until(next_run, from: from_time)
      end
    end
  end
end
