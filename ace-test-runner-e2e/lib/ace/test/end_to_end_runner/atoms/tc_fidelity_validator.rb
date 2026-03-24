# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Atoms
        # Validates that agent-reported test cases match the scenario's expected TCs
        #
        # Detects when an agent invents its own test cases instead of executing
        # the defined standalone TC files. Returns an error result when fidelity check fails.
        class TcFidelityValidator
          # Validate parsed result against expected test case count
          #
          # @param parsed [Hash] Parsed result from SkillResultParser (:test_cases, :status, etc.)
          # @param scenario [Models::TestScenario] The scenario with expected TCs
          # @param filtered_tc_ids [Array<String>, nil] TC IDs filter (when subset was requested)
          # @return [Hash, nil] Error info hash if validation fails, nil if valid
          def self.validate(parsed, scenario, filtered_tc_ids: nil)
            expected_ids = filtered_tc_ids || scenario.test_case_ids
            return nil if expected_ids.empty?

            reported_count = parsed[:test_cases]&.size || 0
            expected_count = expected_ids.size

            return nil if reported_count == expected_count

            {
              error: "TC fidelity mismatch: agent reported #{reported_count} test cases " \
                     "but scenario has #{expected_count} (#{expected_ids.join(", ")})",
              expected_count: expected_count,
              reported_count: reported_count,
              expected_ids: expected_ids
            }
          end
        end
      end
    end
  end
end
