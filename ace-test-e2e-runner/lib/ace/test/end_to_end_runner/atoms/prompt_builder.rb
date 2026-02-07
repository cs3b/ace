# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Atoms
        # Builds LLM prompts for E2E test execution
        #
        # Creates a system prompt that instructs the LLM to execute a test scenario
        # and return structured JSON results, along with the user prompt containing
        # the test scenario content.
        class PromptBuilder
          SYSTEM_PROMPT = <<~PROMPT
            You are an E2E test executor for the ACE (Agentic Coding Environment) toolkit.

            Your task is to execute the provided test scenario step by step and return structured results.

            ## Instructions

            1. Read the test scenario carefully
            2. Execute the Environment Setup commands
            3. Create any Test Data as specified
            4. Execute each Test Case (TC-NNN) in order
            5. Record pass/fail status for each test case
            6. Return results as JSON

            ## Output Format

            You MUST return a JSON block wrapped in ```json fences with these fields:

            ```json
            {
              "test_id": "MT-XXX-NNN",
              "status": "pass|fail|partial",
              "test_cases": [
                {
                  "id": "TC-001",
                  "description": "Brief description",
                  "status": "pass|fail",
                  "actual": "What actually happened",
                  "notes": "Any additional observations"
                }
              ],
              "summary": "Brief execution summary",
              "observations": "Any friction points or issues discovered"
            }
            ```

            ## Rules

            - Execute ALL test cases, even if earlier ones fail
            - Record actual output/behavior, not just expected
            - Use "partial" status if some test cases pass and some fail
            - Include meaningful observations about tool behavior
            - If a test case cannot be executed (missing tool, permission error), mark as "fail" with explanation
          PROMPT

          # Build the user prompt for a test scenario
          #
          # @param scenario [Models::TestScenario] The test scenario to execute
          # @return [String] The user prompt containing the test scenario
          def build(scenario)
            <<~PROMPT
              # Execute E2E Test: #{scenario.test_id}

              **Package:** #{scenario.package}
              **Title:** #{scenario.title}
              **Priority:** #{scenario.priority}

              ## Test Scenario

              #{scenario.content}

              ---

              Execute all test cases in this scenario and return the JSON results as specified in your instructions.
            PROMPT
          end
        end
      end
    end
  end
end
