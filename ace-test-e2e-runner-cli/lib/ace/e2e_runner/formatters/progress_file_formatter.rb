# frozen_string_literal: true

require_relative "base_formatter"

module Ace
  module E2eRunner
    module Formatters
      class ProgressFileFormatter < BaseFormatter
        def on_start(total_tests)
          @total_tests = total_tests
          @completed = 0
          print "Running #{total_tests} E2E tests " unless quiet?
        end

        def on_test_complete(_test_id, status, _duration, _report_path)
          return if quiet?
          @completed += 1
          print(status == "pass" ? "." : "F")
          if (@completed % 50).zero?
            print " #{@completed}/#{@total_tests}"
          end
        end

        def on_finish(summary)
          return if quiet?
          puts ""
          puts "Summary: #{summary[:passed]}/#{summary[:total]} passed"
          puts "Failed: #{summary[:failed]}" if summary[:failed].to_i.positive?
        end

        private

        def quiet?
          @options[:quiet]
        end
      end
    end
  end
end
