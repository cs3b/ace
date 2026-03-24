# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Atoms
        # Builds LLM prompts for suite-level final report synthesis
        #
        # Pure atom (no I/O). Constructs system and user prompts from
        # pre-read test result data for LLM-based report generation.
        class SuiteReportPromptBuilder
          SYSTEM_PROMPT = <<~PROMPT
            You are a senior QA engineer writing an E2E test suite report.

            Generate a structured markdown report with YAML frontmatter. The report should provide actionable insights, not just raw data.

            ## Required Sections

            1. **YAML Frontmatter** — suite-id, package, status, tests-run, executed timestamp
            2. **Summary Table** — Test ID, Title, Status, Passed, Failed, Total columns
            3. **Overall Line** — "X/Y test cases passed (Z%)"
            4. **Failed Tests** (if any) — For each failed test: root cause analysis, failed test case details
            5. **Friction Analysis** — Developer experience issues, tooling pain points, environment problems observed across tests
            6. **Improvement Suggestions** — Concrete, actionable recommendations based on the failures and friction observed
            7. **Positive Observations** — What worked well, reliable patterns, strengths
            8. **Reports Table** — Test ID mapped to report directory names

            ## Formatting Rules

            - Use GitHub-flavored markdown
            - Frontmatter must be valid YAML between --- fences
            - Keep root cause analysis concise but specific
            - Friction analysis should focus on patterns across tests, not individual failures
            - Suggestions should be actionable (not vague like "improve testing")
            - If all tests pass, skip Failed Tests section and focus on positive observations and any friction
          PROMPT

          # Build user prompt from pre-read test result data
          #
          # @param results_data [Array<Hash>] Pre-read result data, each with:
          #   :test_id, :title, :status, :passed, :failed, :total,
          #   :test_cases, :report_dir_name, :summary_content, :experience_content
          # @param package [String] Package name
          # @param timestamp [String] Suite timestamp ID
          # @param overall_status [String] "pass", "partial", or "fail"
          # @param executed_at [String] ISO 8601 execution timestamp
          # @return [String] User prompt for LLM
          def build(results_data, package:, timestamp:, overall_status:, executed_at:)
            parts = []
            parts << "# Suite Report Request"
            parts << ""
            parts << "**Package:** #{package}"
            parts << "**Suite ID:** #{timestamp}"
            parts << "**Status:** #{overall_status}"
            parts << "**Executed:** #{executed_at}"
            parts << "**Tests Run:** #{results_data.size}"
            parts << ""

            total_passed = results_data.sum { |r| r[:passed] }
            results_data.sum { |r| r[:failed] }
            total_tc = results_data.sum { |r| r[:total] }
            parts << "**Overall:** #{total_passed}/#{total_tc} test cases passed"
            parts << ""

            parts << "## Test Results"
            parts << ""

            results_data.each do |r|
              parts << "### #{r[:test_id]}: #{r[:title]}"
              parts << "- **Status:** #{r[:status]}"
              parts << "- **Passed:** #{r[:passed]}/#{r[:total]}"
              parts << "- **Report Dir:** #{r[:report_dir_name]}" if r[:report_dir_name]

              if r[:test_cases]&.any?
                parts << ""
                parts << "**Test Cases:**"
                r[:test_cases].each do |tc|
                  parts << "- #{tc[:id]}: #{tc[:description]} — #{tc[:status]}"
                end
              end

              if r[:summary_content]
                parts << ""
                parts << "**Summary Report:**"
                parts << r[:summary_content]
              end

              if r[:experience_content]
                parts << ""
                parts << "**Experience Report:**"
                parts << r[:experience_content]
              end

              parts << ""
            end

            parts.join("\n")
          end
        end
      end
    end
  end
end
