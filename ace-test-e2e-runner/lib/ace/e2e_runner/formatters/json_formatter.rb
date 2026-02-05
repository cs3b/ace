# frozen_string_literal: true

require "json"
require_relative "base_formatter"

module Ace
  module E2eRunner
    module Formatters
      class JsonFormatter < BaseFormatter
        def initialize(options = {})
          super
          @events = []
        end

        def on_start(total_tests)
          @events << { event: "start", total_tests: total_tests }
        end

        def on_test_complete(test_id, status, duration, report_path)
          @events << {
            event: "test_complete",
            test_id: test_id,
            status: status,
            duration: duration,
            report_path: report_path
          }
        end

        def on_finish(summary)
          payload = {
            events: @events,
            summary: summary
          }
          puts JSON.pretty_generate(payload)
        end
      end
    end
  end
end
