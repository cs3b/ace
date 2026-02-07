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
          # @return [String] Skill invocation prompt
          def build_skill_prompt(scenario, run_id: nil)
            cmd = "/ace:run-e2e-test #{scenario.package} #{scenario.test_id}"
            cmd += " --run-id #{run_id}" if run_id
            cmd
          end

          # Build a workflow-embedded prompt for non-skill-aware CLI providers
          #
          # @param scenario [Models::TestScenario] The test scenario
          # @param workflow_content [String] Content of run-e2e-test.wf.md
          # @param run_id [String, nil] Pre-generated run ID for deterministic report paths
          # @return [String] Prompt with embedded workflow and scenario
          def build_workflow_prompt(scenario, workflow_content:, run_id: nil)
            <<~PROMPT
              # Execute E2E Test: #{scenario.test_id}

              **Package:** #{scenario.package}
              **Title:** #{scenario.title}
              #{"**Run ID:** #{run_id}" if run_id}

              ## Workflow Instructions

              Follow these instructions to execute the test:

              #{workflow_content}

              ## Test Scenario

              #{scenario.content}

              ---

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
