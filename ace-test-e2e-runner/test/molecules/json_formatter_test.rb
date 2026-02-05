# frozen_string_literal: true

require "test_helper"
require "ace/e2e_runner/formatters/json_formatter"
require "json"

module Ace
  module E2eRunner
    class JsonFormatterTest < AceE2eRunnerTestCase
      def test_json_output
        formatter = Formatters::JsonFormatter.new({})

        output = capture_io do
          formatter.on_start(1)
          formatter.on_test_complete("MT-TEST-001", "pass", 1.0, "/tmp/report")
          formatter.on_finish(total: 1, passed: 1, failed: 0)
        end

        parsed = JSON.parse(output[0])
        assert_equal 1, parsed["summary"]["total"]
        assert_equal 1, parsed["summary"]["passed"]
        assert_equal "start", parsed["events"][0]["event"]
      end
    end
  end
end
