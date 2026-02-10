# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Atoms
        # Builds prompts for CLI-provider skill/workflow-based E2E test execution
        #
        # CLI providers (claude, gemini, codex, etc.) can actually execute commands,
        # unlike API providers which can only predict results. This builder creates
        # appropriate prompts for each CLI provider type:
        # - Skill-aware providers (claude): Use /ace:run-e2e-test skill invocation
        # - Other CLI providers: Embed workflow content + test scenario directly
        #
        # Provider lists and CLI args are configurable via .ace-defaults/e2e-runner/config.yml
        # and can be overridden in .ace/e2e-runner/config.yml.
        class SkillPromptBuilder
          # @param config [Hash] Configuration hash (string keys) with providers section
          def initialize(config = {})
            @cli_providers = config.dig("providers", "cli") || %w[claude gemini codex codexoss opencode pi]
            @skill_aware = config.dig("providers", "skill_aware") || %w[claude]
            @cli_args_map = config.dig("providers", "cli_args") || {"claude" => "dangerously-skip-permissions", "codex" => "full-auto"}
          end

          # Check if a provider string refers to a CLI provider
          #
          # @param provider_string [String] Provider:model string (e.g., "claude:sonnet")
          # @return [Boolean]
          def self.cli_provider?(provider_string)
            default_instance.cli_provider?(provider_string)
          end

          # Check if a provider supports skill invocation
          #
          # @param provider_string [String] Provider:model string
          # @return [Boolean]
          def self.skill_aware?(provider_string)
            default_instance.skill_aware?(provider_string)
          end

          # Extract provider name from provider:model string
          #
          # @param provider_string [String] e.g., "claude:sonnet"
          # @return [String] e.g., "claude"
          def self.provider_name(provider_string)
            provider_string.to_s.split(":").first.to_s
          end

          # Get required CLI args for a provider
          #
          # @param provider_string [String] Provider:model string
          # @return [String, nil] Required CLI args or nil
          def self.required_cli_args(provider_string)
            default_instance.required_cli_args(provider_string)
          end

          # Instance method: check if a provider string refers to a CLI provider
          #
          # @param provider_string [String] Provider:model string
          # @return [Boolean]
          def cli_provider?(provider_string)
            name = self.class.provider_name(provider_string)
            @cli_providers.include?(name)
          end

          # Instance method: check if a provider supports skill invocation
          #
          # @param provider_string [String] Provider:model string
          # @return [Boolean]
          def skill_aware?(provider_string)
            name = self.class.provider_name(provider_string)
            @skill_aware.include?(name)
          end

          # Instance method: get required CLI args for a provider
          #
          # @param provider_string [String] Provider:model string
          # @return [String, nil] Required CLI args or nil
          def required_cli_args(provider_string)
            name = self.class.provider_name(provider_string)
            @cli_args_map[name]
          end

          # Build a skill invocation prompt for skill-aware providers (claude)
          #
          # @param scenario [Models::TestScenario] The test scenario
          # @param run_id [String, nil] Pre-generated run ID for deterministic report paths
          # @param test_cases [Array<String>, nil] Optional test case IDs to filter
          # @return [String] Skill invocation prompt
          def build_skill_prompt(scenario, run_id: nil, test_cases: nil)
            cmd = "/ace:run-e2e-test #{scenario.package} #{scenario.test_id}"
            cmd += " #{test_cases.join(',')}" if test_cases&.any?
            cmd += " --run-id #{run_id}" if run_id
            cmd
          end

          # Build a workflow-embedded prompt for non-skill-aware CLI providers
          #
          # @param scenario [Models::TestScenario] The test scenario
          # @param workflow_content [String] Content of run-e2e-test.wf.md
          # @param run_id [String, nil] Pre-generated run ID for deterministic report paths
          # @param test_cases [Array<String>, nil] Optional test case IDs to filter
          # @return [String] Prompt with embedded workflow and scenario
          def build_workflow_prompt(scenario, workflow_content:, run_id: nil, test_cases: nil)
            <<~PROMPT
              # Execute E2E Test: #{scenario.test_id}

              **Package:** #{scenario.package}
              **Title:** #{scenario.title}
              #{"**Run ID:** #{run_id}" if run_id}
              #{"**Test Cases:** #{test_cases.join(', ')}" if test_cases&.any?}

              ## Workflow Instructions

              Follow these instructions to execute the test:

              #{workflow_content}

              ## Test Scenario

              #{scenario.content}

              ---

              #{test_cases_instruction(test_cases)}
              Execute this test following the workflow instructions above. After completion,
              return a structured summary in this exact format:

              - **Test ID**: #{scenario.test_id}
              - **Status**: pass | fail | partial
              - **Passed**: {count}
              - **Failed**: {count}
              - **Total**: {count}
              - **Report Paths**: {timestamp}-{short-pkg}-{short-id}-reports/*
              - **Issues**: Brief description or "None"
            PROMPT
          end

          # Build a TC-level skill invocation prompt for skill-aware providers
          #
          # @param test_case [Models::TestCase] The single test case
          # @param scenario [Models::TestScenario] The parent scenario
          # @param sandbox_path [String] Path to the pre-populated sandbox
          # @param run_id [String, nil] Pre-generated run ID
          # @return [String] Skill invocation prompt
          def build_tc_skill_prompt(test_case:, scenario:, sandbox_path:, run_id: nil)
            cmd = "/ace:run-e2e-test #{scenario.package} #{scenario.test_id} #{test_case.tc_id} --tc-mode --sandbox #{sandbox_path}"
            cmd += " --run-id #{run_id}" if run_id
            cmd
          end

          # Build a TC-level workflow-embedded prompt for non-skill-aware CLI providers
          #
          # @param test_case [Models::TestCase] The single test case
          # @param scenario [Models::TestScenario] The parent scenario
          # @param sandbox_path [String] Path to the pre-populated sandbox
          # @param workflow_content [String] Content of run-e2e-test workflow
          # @param run_id [String, nil] Pre-generated run ID
          # @return [String] Prompt with embedded workflow and TC content
          def build_tc_workflow_prompt(test_case:, scenario:, sandbox_path:, workflow_content:, run_id: nil)
            <<~PROMPT
              # Execute Test Case: #{scenario.test_id} / #{test_case.tc_id}

              **Package:** #{scenario.package}
              **Scenario:** #{scenario.title}
              **Test Case:** #{test_case.title}
              **Sandbox Path:** #{sandbox_path}
              #{"**Run ID:** #{run_id}" if run_id}

              ## Workflow Instructions

              Follow these instructions to execute the test case:

              #{workflow_content}

              ## Test Case Content

              #{test_case.content}

              ---

              Execute this test case in the pre-populated sandbox at `#{sandbox_path}`.
              Do NOT create or modify the sandbox setup — it is already prepared.
              After completion, return a structured summary in this exact format:

              - **Test ID**: #{scenario.test_id}
              - **TC ID**: #{test_case.tc_id}
              - **Status**: pass | fail
              - **Report Paths**: {timestamp}-{short-pkg}-{short-id}-{tc-short-id}-reports/*
              - **Issues**: Brief description or "None"
            PROMPT
          end

          private

          # Build test cases filtering instruction for prompts
          #
          # @param test_cases [Array<String>, nil] Test case IDs to filter
          # @return [String] Instruction text or empty string
          def test_cases_instruction(test_cases)
            return "" unless test_cases&.any?

            "**IMPORTANT:** Execute ONLY the following test cases: #{test_cases.join(', ')}. Skip all other test cases.\n\n"
          end

          public

          # Get system prompt for E2E execution (overrides provider defaults)
          #
          # @param provider_string [String] Provider:model string
          # @return [String, nil] System prompt or nil (skill-aware providers don't need one)
          def system_prompt_for(provider_string)
            return nil if skill_aware?(provider_string)

            <<~PROMPT
              You are an E2E test executor for the ACE (Agentic Coding Environment) toolkit.

              Your task is to execute the provided test scenario by running actual commands.
              You MUST use your tools to execute shell commands, read files, and write reports.

              ## Rules

              - Execute ALL commands shown in the workflow and test scenario
              - Create sandbox directories as specified
              - Run each test case and record actual results
              - Write report files to disk as instructed
              - Return the structured summary at the end
            PROMPT
          end

          # Lazily-loaded default instance backed by ConfigLoader
          # @return [SkillPromptBuilder]
          def self.default_instance
            @default_instance ||= begin
              config = if defined?(Molecules::ConfigLoader)
                Molecules::ConfigLoader.load
              else
                {}
              end
              new(config)
            end
          end

          # Reset the default instance (for testing)
          def self.reset_default_instance!
            @default_instance = nil
          end
        end
      end
    end
  end
end
