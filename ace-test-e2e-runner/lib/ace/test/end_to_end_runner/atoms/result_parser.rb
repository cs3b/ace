# frozen_string_literal: true

require "json"

module Ace
  module Test
    module EndToEndRunner
      module Atoms
        # Parses structured JSON results from LLM responses
        #
        # Extracts JSON from LLM text output, handling various formatting
        # patterns including fenced code blocks and raw JSON.
        class ResultParser
          # Parse LLM response text into a structured result hash
          #
          # @param text [String] Raw LLM response text
          # @return [Hash] Parsed result with :test_id, :status, :test_cases, :summary
          # @raise [ParseError] If no valid JSON found in response
          def self.parse(text)
            json_str = extract_json(text)
            raise ParseError, "No JSON found in LLM response" if json_str.nil?

            parsed = JSON.parse(json_str, symbolize_names: true)
            validate_result(parsed)
            normalize_result(parsed)
          rescue JSON::ParserError => e
            raise ParseError, "Invalid JSON in LLM response: #{e.message}"
          end

          # Extract JSON from text, handling code fences and raw JSON
          #
          # @param text [String] Text potentially containing JSON
          # @return [String, nil] Extracted JSON string or nil
          def self.extract_json(text)
            return nil if text.nil? || text.strip.empty?

            # Try to find JSON in code fences first
            match = text.match(/```(?:json)?\s*\n(.*?)\n\s*```/m)
            return match[1].strip if match

            # Try to find raw JSON object (greedy to capture nested braces in test_cases)
            # Note: This may over-match if response has multiple JSON objects; the
            # code-fence path above is the primary extraction method.
            match = text.match(/(\{.*\})/m)
            return match[1].strip if match

            nil
          end

          # Validate that parsed result has required fields
          #
          # @param result [Hash] Parsed JSON result
          # @raise [ParseError] If required fields are missing
          def self.validate_result(result)
            required = %i[test_id status]
            missing = required.reject { |field| result.key?(field) }
            unless missing.empty?
              raise ParseError, "Missing required fields in result: #{missing.join(', ')}"
            end
          end

          # Normalize result to ensure consistent structure
          #
          # @param result [Hash] Parsed result
          # @return [Hash] Normalized result
          def self.normalize_result(result)
            {
              test_id: result[:test_id],
              status: result[:status],
              test_cases: normalize_test_cases(result[:test_cases] || []),
              summary: result[:summary] || "",
              observations: result[:observations] || ""
            }
          end

          # Normalize test case entries
          #
          # @param test_cases [Array<Hash>] Raw test case data
          # @return [Array<Hash>] Normalized test cases
          def self.normalize_test_cases(test_cases)
            test_cases.map do |tc|
              {
                id: tc[:id] || "unknown",
                description: tc[:description] || "",
                status: tc[:status] || "fail",
                actual: tc[:actual] || "",
                notes: tc[:notes] || ""
              }
            end
          end

          private_class_method :validate_result, :normalize_result, :normalize_test_cases

          # Error raised when parsing LLM response fails
          class ParseError < StandardError; end
        end
      end
    end
  end
end
