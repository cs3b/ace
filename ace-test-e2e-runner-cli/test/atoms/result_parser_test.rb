# frozen_string_literal: true

require "test_helper"

module Ace
  module E2eRunner
    class ResultParserTest < AceE2eRunnerTestCase
      def test_parse_json_response
        response = <<~TEXT
          ```json
          {"test_id":"MT-ABC-001","status":"pass","summary":"ok"}
          ```
        TEXT

        parser = Atoms::ResultParser.new
        result = parser.parse(response)

        assert_equal "MT-ABC-001", result.test_id
        assert_equal "pass", result.status
        assert_equal "ok", result.summary
      end

      def test_parse_invalid_response_returns_error
        parser = Atoms::ResultParser.new
        result = parser.parse("no json here", test_id: "MT-FAIL-001")

        assert_equal "error", result.status
        assert_equal "MT-FAIL-001", result.test_id
        assert_equal "parse_error", result.error_type
      end
    end
  end
end
