# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Atoms
        # Parses and normalizes test case IDs from markdown content
        #
        # Provides pure utility methods for:
        # - Extracting TC-NNN headers from markdown test scenarios
        # - Normalizing various test case ID formats to TC-NNN
        # - Filtering test cases by ID list
        #
        # Normalization rules (consistent with workflow bash logic):
        # - "TC-001"  -> "TC-001" (already normalized)
        # - "tc-001"  -> "TC-001" (uppercased)
        # - "001"     -> "TC-001" (prefix added)
        # - "1"       -> "TC-001" (zero-padded and prefixed)
        # - "TC-1"    -> "TC-001" (zero-padded)
        class TestCaseParser
          # Pattern matching TC-NNN headers in markdown
          # Matches: ### TC-001: Description
          TC_HEADER_PATTERN = /^###\s+(TC-\d+[a-z]?)[\s:]/i

          # Normalize a single test case identifier to TC-NNN format
          #
          # @param id [String] Raw test case ID in any accepted format
          # @return [String] Normalized TC-NNN format
          # @raise [ArgumentError] If the ID cannot be normalized
          def self.normalize_identifier(id)
            raw = id.to_s.strip
            raise ArgumentError, "Empty test case ID" if raw.empty?

            # Strip TC- prefix if present (case-insensitive)
            number_part = raw.sub(/\Atc-/i, "")

            # Extract numeric portion and optional alpha suffix
            match = number_part.match(/\A(\d+)([a-z]?)\z/i)
            raise ArgumentError, "Invalid test case ID: '#{id}'" unless match

            numeric = match[1]
            suffix = match[2].downcase

            # Zero-pad to 3 digits minimum
            padded = format("%03d", numeric.to_i)

            "TC-#{padded}#{suffix}"
          end

          # Normalize multiple test case identifiers
          #
          # @param ids [Array<String>] Raw test case IDs
          # @return [Array<String>] Normalized TC-NNN format IDs
          def self.normalize_identifiers(ids)
            ids.map { |id| normalize_identifier(id) }
          end

          # Parse a comma-separated string of test case IDs
          #
          # @param input [String] Comma-separated test case IDs (e.g., "tc-001,002,TC-3")
          # @return [Array<String>] Normalized TC-NNN format IDs
          # @raise [ArgumentError] If input is empty or contains invalid IDs
          def self.parse(input)
            raw = input.to_s.strip
            raise ArgumentError, "Empty test cases input" if raw.empty?

            ids = raw.split(",").map(&:strip).reject(&:empty?)
            raise ArgumentError, "No valid test case IDs found in: '#{input}'" if ids.empty?

            normalize_identifiers(ids)
          end

          # Extract available test case IDs from markdown content
          #
          # Scans for ### TC-NNN: headers in the test scenario markdown.
          #
          # @param content [String] Markdown content of a test scenario
          # @return [Array<String>] List of test case IDs found (e.g., ["TC-001", "TC-002"])
          def self.extract_from_content(content)
            content.scan(TC_HEADER_PATTERN).map { |match| match[0].upcase }
          end

          # Filter test case content by ID list
          #
          # Given a list of desired test case IDs and the available IDs in content,
          # validates that all requested IDs exist and returns the validated set.
          #
          # @param requested_ids [Array<String>] Normalized test case IDs to filter
          # @param available_ids [Array<String>] Test case IDs available in the scenario
          # @return [Array<String>] Validated test case IDs
          # @raise [ArgumentError] If any requested IDs are not found in the scenario
          def self.validate_against_available(requested_ids, available_ids)
            normalized_available = available_ids.map(&:upcase)
            missing = requested_ids.reject { |id| normalized_available.include?(id.upcase) }

            unless missing.empty?
              raise ArgumentError,
                "Test case(s) not found: #{missing.join(", ")}. " \
                "Available: #{available_ids.join(", ")}"
            end

            requested_ids
          end
        end
      end
    end
  end
end
