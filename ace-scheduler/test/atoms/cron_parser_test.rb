# frozen_string_literal: true

require "test_helper"

module Ace
  module Scheduler
    class CronParserTest < AceSchedulerTestCase
      def test_valid_expression
        parser = Atoms::CronParser.new
        assert parser.valid?("0 9 * * *")
      end

      def test_invalid_expression
        parser = Atoms::CronParser.new
        refute parser.valid?("invalid cron")
      end
    end
  end
end
