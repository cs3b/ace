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
            passed.times { |i| test_cases << {id: "TC-#{format("%03d", i + 1)}", description: "", status: "pass", actual: "", notes: ""} }
            failed.times { |i| test_cases << {id: "TC-#{format("%03d", passed + i + 1)}", description: "", status: "fail", actual: "", notes: ""} }

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

          # Parse verifier-mode markdown return contract.
          #
          # @param text [String]
          # @return [Hash] Normalized test result payload
          def self.parse_verifier(text)
            raise ResultParser::ParseError, "Empty response from CLI provider" if text.nil? || text.strip.empty?

            fields = {}
            fields[:test_id] = extract_field(text, "Test ID")
            fields[:status] = extract_field(text, "Status")
            fields[:tcs_passed] = extract_field(text, "TCs Passed")
            fields[:tcs_failed] = extract_field(text, "TCs Failed")
            fields[:tcs_total] = extract_field(text, "TCs Total")
            fields[:score] = extract_field(text, "Score")
            fields[:verdict] = extract_field(text, "Verdict")
            fields[:failed_tcs] = extract_field(text, "Failed TCs")
            fields[:issues] = extract_field(text, "Issues")

            return parse_minimal_verifier(text) unless fields[:test_id] && fields[:status]
            return parse(text) unless fields[:tcs_passed] && fields[:tcs_failed] && fields[:tcs_total]

            passed = fields[:tcs_passed].to_i
            failed = fields[:tcs_failed].to_i
            total = fields[:tcs_total].to_i
            status = normalize_status(fields[:status])

            failed_entries = parse_failed_tcs(fields[:failed_tcs])
            failed_ids = failed_entries.map { |e| e[:tc] }.to_set
            test_cases = []
            pass_index = 0
            passed.times do
              pass_index += 1
              pass_index += 1 while failed_ids.include?("TC-#{format("%03d", pass_index)}")
              test_cases << {id: "TC-#{format("%03d", pass_index)}", description: "", status: "pass", actual: "", notes: ""}
            end
            if failed_entries.empty?
              failed.times do |i|
                test_cases << {id: "TC-#{format("%03d", passed + i + 1)}", description: "", status: "fail", actual: "", notes: ""}
              end
            else
              failed_entries.each do |entry|
                test_cases << {
                  id: entry[:tc],
                  description: "",
                  status: "fail",
                  actual: "",
                  notes: entry[:category],
                  category: entry[:category]
                }
              end
            end

            summary = if total.positive?
              "#{passed}/#{total} passed (#{fields[:verdict] || status})"
            else
              fields[:verdict] || status
            end

            {
              test_id: fields[:test_id],
              status: status,
              test_cases: test_cases,
              summary: summary,
              observations: (fields[:issues].to_s.strip.casecmp("none").zero? ? "" : fields[:issues].to_s)
            }
          end

          def self.parse_minimal_verifier(text)
            compact = text.to_s.strip
            status_match = compact.match(/\b(PASS|FAIL|PARTIAL|ERROR)\b/i)
            return parse(text) unless status_match

            status = normalize_status(status_match[1])
            evidence = compact.sub(/^.*?\b#{Regexp.escape(status_match[1])}\b[:\-\s]*/i, "").strip
            tc_status = (status == "pass") ? "pass" : "fail"

            {
              test_id: "",
              status: status,
              test_cases: [{
                id: "TC-001",
                description: "",
                status: tc_status,
                actual: "",
                notes: evidence,
                category: ((tc_status == "fail") ? "unknown" : nil)
              }],
              summary: evidence.empty? ? status : evidence,
              observations: evidence
            }
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
            (value.to_s.strip.split(/\s+/).first || "unknown").downcase
          end

          def self.parse_failed_tcs(value)
            return [] if value.nil? || value.strip.empty? || value.strip.casecmp("none").zero?

            value.split(",").map(&:strip).filter_map do |entry|
              tc, category = entry.split(":", 2).map { |part| part.to_s.strip }
              next if tc.empty?

              {tc: tc.upcase, category: (category.to_s.empty? ? "unknown" : category)}
            end
          end

          private_class_method :parse_markdown, :to_normalized, :extract_field,
            :parse_tc_markdown, :to_tc_normalized, :normalize_status,
            :parse_failed_tcs, :parse_minimal_verifier
        end
      end
    end
  end
end
