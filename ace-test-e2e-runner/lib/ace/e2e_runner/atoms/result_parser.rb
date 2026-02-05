# frozen_string_literal: true

require "json"

module Ace
  module E2eRunner
    module Atoms
      class ResultParser
        def parse(response_text, test_id: nil)
          json_text = extract_json(response_text)
          data = JSON.parse(json_text)

          Models::TestResult.new(
            test_id: data["test_id"] || test_id,
            status: data["status"] || "error",
            test_cases: data["test_cases"],
            summary: data["summary"],
            raw_response: response_text
          )
        rescue StandardError => e
          Models::TestResult.new(
            test_id: test_id,
            status: "error",
            error_type: "parse_error",
            error_message: e.message,
            raw_response: response_text
          )
        end

        private

        def extract_json(text)
          code_block = text.match(/```(?:json)?\s*(\{.*?\})\s*```/m)
          return code_block[1] if code_block

          start_idx = text.index("{")
          end_idx = text.rindex("}")
          raise "No JSON object found in response" unless start_idx && end_idx && end_idx > start_idx

          text[start_idx..end_idx]
        end
      end
    end
  end
end
