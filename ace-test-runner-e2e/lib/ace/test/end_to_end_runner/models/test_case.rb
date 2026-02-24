# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Models
        # Data model representing a single TC-*.tc.md test case file
        #
        # Contains parsed frontmatter metadata and the full markdown body
        # from an independent test case file within a scenario directory.
        class TestCase
          VALID_MODES = %w[procedural goal].freeze

          attr_reader :tc_id, :title, :content, :file_path, :pending, :mode, :goal_format

          # @param tc_id [String] Test case identifier (e.g., "TC-001")
          # @param title [String] Test case title from frontmatter
          # @param content [String] Full markdown body (below frontmatter)
          # @param file_path [String] Absolute path to the .tc.md file
          # @param pending [String, nil] Pending reason (presence = pending, value = reason)
          # @param mode [String] Test case mode ("procedural" or "goal")
          # @param goal_format [String, nil] Goal mode variant ("inline" or "standalone")
          def initialize(tc_id:, title:, content:, file_path:, pending: nil, mode: "procedural", goal_format: nil)
            validate_mode!(mode)

            @tc_id = tc_id
            @title = title
            @content = content
            @file_path = file_path
            @pending = pending
            @mode = mode
            @goal_format = goal_format
          end

          # Whether this test case is pending (should be skipped)
          # @return [Boolean]
          def pending?
            !pending.nil?
          end

          # Generate short test case ID for directory naming
          # @return [String] Short ID (e.g., "tc001" from "TC-001", "tc001a" from "TC-001a")
          def short_id
            match = tc_id.match(/TC-(\d+[a-z]*)/i)
            return "tc#{match[1]}" if match

            tc_id.downcase.gsub(/[^a-z0-9]/, "")
          end

          # Whether this test case uses goal mode semantics
          # @return [Boolean]
          def goal_mode?
            mode == "goal"
          end

          private

          def validate_mode!(mode)
            return if VALID_MODES.include?(mode)

            raise ArgumentError, "Invalid test case mode '#{mode}'. Expected: #{VALID_MODES.join(', ')}"
          end
        end
      end
    end
  end
end
