# frozen_string_literal: true

require "test_helper"
require "ace/e2e_runner/formatters/progress_formatter"

module Ace
  module E2eRunner
    class ProgressFormatterTest < AceE2eRunnerTestCase
      def test_progress_output
        formatter = Formatters::ProgressFormatter.new({})

        output = capture_io do
          formatter.on_start(1)
          formatter.on_test_start("MT-TEST-001", "ace-test")
          formatter.on_test_complete("MT-TEST-001", "pass", 1.23, nil)
          formatter.on_finish(total: 1, passed: 1, failed: 0)
        end

        assert_includes output[0], "Running 1 E2E test"
        assert_includes output[0], "MT-TEST-001"
        assert_includes output[0], "PASS"
        assert_includes output[0], "Summary: 1/1 passed"
      end
    end
  end
end
