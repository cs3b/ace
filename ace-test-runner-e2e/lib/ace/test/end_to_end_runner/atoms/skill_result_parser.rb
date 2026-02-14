# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Atoms
        # Parses structured markdown results from CLI-provider skill/workflow execution
        #
        # CLI providers return results in the subagent return contract format:
        #   - **Test ID**: TS-LINT-001
        #   - **Status**: pass
        #   - **Passed**: 8
        #   - **Failed**: 0
        #   - **Total**: 8
        #   - **Report Paths**: 8p5jo2-lint-ts001-reports/*
        #   - **Issues**: None
        #
        # Falls back to ResultParser.parse() for JSON responses.
        class SkillResultParser
          # Parse response text from a CLI provider
          #
          # @param text [String] Raw response text
          # @return [Hash] Parsed result with :test_id, :status, :test_cases, :summary, :observations
          # @raise [ResultParser::ParseError] If neither markdown nor JSON can be parsed
          def self.parse(text)
            raise ResultParser::ParseError, "Empty response from CLI provider" if text.nil? || text.strip.empty?

            parsed = parse_markdown(text)
            return to_normalized(parsed) if parsed

            # Fall back to JSON parsing via ResultParser
            ResultParser.parse(text)
          end

          # Parse the markdown return contract format
          #
          # @param text [String] Response text
          # @return [Hash, nil] Parsed fields or nil if format not matched
          def self.parse_markdown(text)
            fields = {}

            fields[:test_id] = extract_field(text, "Test ID")
            fields[:status] = extract_field(text, "Status")
            fields[:passed] = extract_field(text, "Passed")
            fields[:failed] = extract_field(text, "Failed")
            fields[:total] = extract_field(text, "Total")
            fields[:report_paths] = extract_field(text, "Report Paths")
            fields[:issues] = extract_field(text, "Issues")

            # Need at least test_id and status for a valid parse
            return nil unless fields[:test_id] && fields[:status]

            fields
          end

          # Convert parsed markdown fields to normalized result format
          #
          # @param parsed [Hash] Parsed markdown fields
          # @return [Hash] Normalized result matching ResultParser output format
          def self.to_normalized(parsed)
            parsed[:status] = normalize_status(parsed[:status])

            passed = parsed[:passed].to_i
            failed = parsed[:failed].to_i
            total = parsed[:total].to_i

            # Build synthetic test cases from counts
            test_cases = []
            passed.times { |i| test_cases << { id: "TC-#{format('%03d', i + 1)}", description: "", status: "pass", actual: "", notes: "" } }
            failed.times { |i| test_cases << { id: "TC-#{format('%03d', passed + i + 1)}", description: "", status: "fail", actual: "", notes: "" } }

            issues = parsed[:issues]
            observations = (issues && issues.downcase != "none") ? issues : ""

            {
              test_id: parsed[:test_id],
              status: parsed[:status],
              test_cases: test_cases,
              summary: "#{passed}/#{total} passed",
              observations: observations
            }
          end

          # Extract a field value from markdown bold-key format
          #
          # @param text [String] Text to search
          # @param field_name [String] Field name (e.g., "Test ID")
          # @return [String, nil] Extracted value or nil
          def self.extract_field(text, field_name)
            # Match "- **Field Name**: value" or "**Field Name**: value"
            match = text.match(/\*\*#{Regexp.escape(field_name)}\*\*:\s*(.+?)$/i)
            return nil unless match

            value = match[1].strip
            value.empty? ? nil : value
          end

          # Parse TC-level response text from a CLI provider
          #
          # Handles TC-level markdown with **TC ID** field. Falls back to
          # parse() if the response has the multi-TC format.
          #
          # @param text [String] Raw response text
          # @return [Hash] Parsed result with single-entry :test_cases array
          # @raise [ResultParser::ParseError] If neither format can be parsed
          def self.parse_tc(text)
            raise ResultParser::ParseError, "Empty response from CLI provider" if text.nil? || text.strip.empty?

            parsed = parse_tc_markdown(text)
            return to_tc_normalized(parsed) if parsed

            # Fall back to standard parse (handles both markdown and JSON)
            parse(text)
          end

          # Parse TC-level markdown return contract
          def self.parse_tc_markdown(text)
            fields = {}

            fields[:test_id] = extract_field(text, "Test ID")
            fields[:tc_id] = extract_field(text, "TC ID")
            fields[:status] = extract_field(text, "Status")
            fields[:report_paths] = extract_field(text, "Report Paths")
            fields[:issues] = extract_field(text, "Issues")

            # Need test_id, tc_id, and status for a valid TC parse
            return nil unless fields[:test_id] && fields[:tc_id] && fields[:status]

            fields
          end

          # Convert parsed TC markdown to normalized result format
          def self.to_tc_normalized(parsed)
            parsed[:status] = normalize_status(parsed[:status])

            issues = parsed[:issues]
            observations = (issues && issues.downcase != "none") ? issues : ""

            {
              test_id: parsed[:test_id],
              status: parsed[:status],
              test_cases: [{
                id: parsed[:tc_id],
                description: "",
                status: parsed[:status],
                actual: "",
                notes: observations
              }],
              summary: "#{parsed[:tc_id]} #{parsed[:status]}",
              observations: observations
            }
          end

          # Normalize a status value: take first word, default to "unknown"
          def self.normalize_status(value)
            value.to_s.strip.split(/\s+/).first || "unknown"
          end

          private_class_method :parse_markdown, :to_normalized, :extract_field,
                              :parse_tc_markdown, :to_tc_normalized, :normalize_status
        end
      end
    end
  end
end
