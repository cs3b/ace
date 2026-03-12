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
            return nil if text.nil? || text.to_s.strip.empty?

            stripped = text.to_s.strip

            # Try to find JSON in code fences first
            match = stripped.match(/```(?:json)?\s*\n(.*?)\n\s*```/m)
            return match[1].strip if match

            # Treat unfenced content as JSON only when the whole payload is a JSON object.
            return stripped if stripped.start_with?("{") && stripped.end_with?("}")

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
              status: result[:status].to_s.downcase,
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
                notes: tc[:notes] || "",
                criteria: normalize_criteria(tc[:criteria] || [])
              }
            end
          end

          # Normalize optional criteria evaluations
          #
          # @param criteria [Array<Hash>] Raw criteria results
          # @return [Array<Hash>] Normalized criteria entries
          def self.normalize_criteria(criteria)
            criteria.map do |criterion|
              {
                id: criterion[:id] || "",
                description: criterion[:description] || criterion[:criterion] || "",
                status: (criterion[:status] || "fail").to_s.downcase,
                evidence: criterion[:evidence] || ""
              }
            end
          end

          # Parse TC-level LLM response into a structured result hash
          #
          # Handles single-TC JSON format with tc_id field. Falls back to
          # parse() if the response contains multi-TC format.
          #
          # @param text [String] Raw LLM response text
          # @return [Hash] Parsed result with single-entry :test_cases array
          # @raise [ParseError] If no valid JSON found in response
          def self.parse_tc(text)
            json_str = extract_json(text)
            raise ParseError, "No JSON found in LLM response" if json_str.nil?

            parsed = JSON.parse(json_str, symbolize_names: true)

            # If response has test_cases array, delegate to standard parse
            return parse(text) if parsed.key?(:test_cases)

            validate_tc_result(parsed)
            normalize_tc_result(parsed)
          rescue JSON::ParserError => e
            raise ParseError, "Invalid JSON in LLM response: #{e.message}"
          end

          # Validate TC-level result fields
          def self.validate_tc_result(result)
            required = %i[test_id tc_id status]
            missing = required.reject { |field| result.key?(field) }
            unless missing.empty?
              raise ParseError, "Missing required fields in TC result: #{missing.join(', ')}"
            end
          end

          # Normalize TC-level result to standard format with single-entry test_cases
          def self.normalize_tc_result(result)
            {
              test_id: result[:test_id],
              status: result[:status],
              test_cases: [{
                id: result[:tc_id],
                description: result[:summary] || "",
                status: result[:status],
                actual: result[:actual] || "",
                notes: result[:notes] || "",
                criteria: normalize_criteria(result[:criteria] || [])
              }],
              summary: result[:summary] || "",
              observations: result[:notes] || ""
            }
          end

          private_class_method :validate_result, :normalize_result, :normalize_test_cases,
                              :normalize_criteria, :validate_tc_result, :normalize_tc_result

          # Error raised when parsing LLM response fails
          class ParseError < StandardError; end
        end
      end
    end
  end
end
