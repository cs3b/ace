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
          # System prompt for TC-level (single test case) execution
          TC_SYSTEM_PROMPT = <<~PROMPT
            You are an E2E test executor for the ACE (Agentic Coding Environment) toolkit.

            Your task is to execute a single test case in a pre-populated sandbox and return structured results.

            ## Instructions

            1. The test sandbox is pre-populated at the path provided — do NOT create or modify the sandbox setup
            2. Read the test case steps carefully
            3. Execute the test case steps in the sandbox
            4. Record pass/fail status
            5. Return results as JSON

            ## Output Format

            You MUST return a JSON block wrapped in ```json fences with these fields:

            ```json
            {
              "test_id": "TS-XXX-NNN",
              "tc_id": "TC-NNN",
              "status": "pass|fail",
              "actual": "What actually happened",
              "notes": "Any additional observations",
              "summary": "Brief result"
            }
            ```

            ## Rules

            - Execute ONLY the single test case provided
            - Execute in the pre-populated sandbox (do not modify setup files)
            - Record actual output/behavior, not just expected
            - If the test case cannot be executed (missing tool, permission error), mark as "fail" with explanation
          PROMPT

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
              "test_id": "TS-XXX-NNN",
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

          # Build a TC-level user prompt for a single test case
          #
          # @param test_case [Models::TestCase] The single test case to execute
          # @param scenario [Models::TestScenario] The parent scenario for metadata
          # @param sandbox_path [String] Path to the pre-populated sandbox
          # @return [String] The TC-level user prompt
          def build_tc(test_case:, scenario:, sandbox_path:)
            if test_case.pending?
              return <<~PROMPT
                # SKIP Test Case: #{scenario.test_id} / #{test_case.tc_id}

                **Package:** #{scenario.package}
                **Scenario:** #{scenario.title}
                **Test Case:** #{test_case.title}
                **Status:** PENDING — #{test_case.pending}

                This test case is marked as pending and should NOT be executed.
                Return the following JSON result:

                ```json
                {
                  "test_id": "#{scenario.test_id}",
                  "tc_id": "#{test_case.tc_id}",
                  "status": "skip",
                  "actual": "Skipped — pending",
                  "notes": "#{test_case.pending}",
                  "summary": "Pending: #{test_case.pending}"
                }
                ```
              PROMPT
            end

            <<~PROMPT
              # Execute Test Case: #{scenario.test_id} / #{test_case.tc_id}

              **Package:** #{scenario.package}
              **Scenario:** #{scenario.title}
              **Test Case:** #{test_case.title}
              **Sandbox Path:** #{sandbox_path}

              ## Test Case Content

              #{test_case.content}

              ---

              Execute the test case steps in the sandbox at `#{sandbox_path}` and return JSON results as specified in your instructions.
            PROMPT
          end

          # Build the user prompt for a test scenario
          #
          # @param scenario [Models::TestScenario] The test scenario to execute
          # @param test_cases [Array<String>, nil] Optional test case IDs to filter
          # @return [String] The user prompt containing the test scenario
          def build(scenario, test_cases: nil)
            filter_instruction = if test_cases&.any?
              "\n**IMPORTANT:** Execute ONLY the following test cases: #{test_cases.join(", ")}. Skip all other test cases.\n"
            else
              ""
            end

            pending_instruction = build_pending_tc_skip_instruction(scenario)

            execute_instruction = if test_cases&.any?
              "Execute only the specified test cases (#{test_cases.join(", ")}) and return the JSON results as specified in your instructions."
            else
              "Execute all test cases in this scenario and return the JSON results as specified in your instructions."
            end

            <<~PROMPT
              # Execute E2E Test: #{scenario.test_id}

              **Package:** #{scenario.package}
              **Title:** #{scenario.title}
              **Priority:** #{scenario.priority}
              #{filter_instruction}#{pending_instruction}
              ## Test Scenario

              #{scenario.content}

              ---

              #{execute_instruction}
            PROMPT
          end

          private

          # Build instruction for pending test cases if any exist
          #
          # @param scenario [Models::TestScenario] The test scenario
          # @return [String] Pending instruction text or empty string
          def build_pending_tc_skip_instruction(scenario)
            pending_tcs = scenario.test_cases.select(&:pending?)
            return "" unless pending_tcs.any?

            lines = pending_tcs.map { |tc| "- #{tc.tc_id}: #{tc.pending}" }
            "\n**SKIP these test cases (pending):**\n#{lines.join("\n")}\nFor skipped test cases, report status as \"skip\" in your results.\n"
          end
        end
      end
    end
  end
end
