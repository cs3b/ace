# frozen_string_literal: true

module Ace
  module E2eRunner
    module Atoms
      class PromptBuilder
        SYSTEM_PROMPT = <<~PROMPT
          You are an E2E test executor. Execute the test scenario and return results as JSON:
          {
            "test_id": "MT-XXX-NNN",
            "status": "pass|fail|partial|error",
            "test_cases": [{"id": "TC-001", "status": "pass|fail", "actual": "...", "notes": "..."}],
            "summary": "Brief execution summary"
          }
        PROMPT

        def build(test_scenario)
          <<~PROMPT
            Execute the following end-to-end test scenario. Follow the steps carefully and return only JSON.

            Test ID: #{test_scenario.id}
            Package: #{test_scenario.package || "unknown"}

            Scenario:
            #{test_scenario.content}
          PROMPT
        end
      end
    end
  end
end
