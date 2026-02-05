# frozen_string_literal: true

require_relative "base_formatter"

module Ace
  module E2eRunner
    module Formatters
      class ProgressFormatter < BaseFormatter
        def on_start(total_tests)
          return if quiet?
          puts "Running #{total_tests} E2E test#{total_tests == 1 ? "" : "s"}..."
        end

        def on_test_start(test_id, package)
          return if quiet?
          print "- #{test_id} (#{package}) ... "
        end

        def on_test_complete(test_id, status, duration, report_path)
          return if quiet?
          detail = "#{status.upcase} (#{format_duration(duration)})"
          detail += " -> #{report_path}" if verbose? && report_path
          puts detail
        end

        def on_finish(summary)
          return if quiet?
          puts "Summary: #{summary[:passed]}/#{summary[:total]} passed"
          if summary[:failed].to_i.positive?
            puts "Failed: #{summary[:failed]}"
          end
        end

        private

        def quiet?
          @options[:quiet]
        end

        def verbose?
          @options[:verbose]
        end

        def format_duration(duration)
          return "-" unless duration
          "#{duration.round(2)}s"
        end
      end
    end
  end
end
