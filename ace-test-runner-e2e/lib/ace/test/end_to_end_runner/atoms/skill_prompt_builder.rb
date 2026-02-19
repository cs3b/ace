# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Atoms
        # Builds skill invocation prompts for CLI-provider E2E test execution
        #
        # All CLI providers use skill invocation (/ace:run-e2e-test). The skill
        # routes to the appropriate workflow based on arguments (--sandbox present
        # or not). Provider lists and CLI args are configurable via config.yml.
        class SkillPromptBuilder
          # @param config [Hash] Configuration hash (string keys) with providers section
          def initialize(config = {})
            @cli_providers = config.dig("providers", "cli") || %w[claude gemini codex codexoss opencode pi]
            @cli_args_map = config.dig("providers", "cli_args") || {"claude" => "dangerously-skip-permissions", "codex" => "full-auto"}
          end

          # Check if a provider string refers to a CLI provider
          #
          # @param provider_string [String] Provider:model string (e.g., "claude:sonnet")
          # @return [Boolean]
          def self.cli_provider?(provider_string)
            default_instance.cli_provider?(provider_string)
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

          # Instance method: get required CLI args for a provider
          #
          # @param provider_string [String] Provider:model string
          # @return [String, nil] Required CLI args or nil
          def required_cli_args(provider_string)
            name = self.class.provider_name(provider_string)
            @cli_args_map[name]
          end

          # Build a skill invocation prompt for scenario-level execution
          #
          # @param scenario [Models::TestScenario] The test scenario
          # @param run_id [String, nil] Pre-generated run ID for deterministic report paths
          # @param test_cases [Array<String>, nil] Optional test case IDs to filter
          # @param sandbox_path [String, nil] Path to pre-populated sandbox (skips setup steps)
          # @param env_vars [Hash, nil] Environment variables from setup execution
          # @return [String] Skill invocation prompt
          def build_skill_prompt(scenario, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil)
            cmd = "/ace:run-e2e-test #{scenario.package} #{scenario.test_id}"
            cmd += " #{test_cases.join(',')}" if test_cases&.any?
            cmd += " --run-id #{run_id}" if run_id
            cmd += " --sandbox #{sandbox_path}" if sandbox_path
            cmd += " --env #{env_vars.map { |k, v| "#{k}=#{v}" }.join(',')}" if env_vars&.any?
            build_execution_prompt(command: cmd, tc_mode: false)
          end

          # Build a TC-level skill invocation prompt
          #
          # @param test_case [Models::TestCase] The single test case
          # @param scenario [Models::TestScenario] The parent scenario
          # @param sandbox_path [String] Path to the pre-populated sandbox
          # @param run_id [String, nil] Pre-generated run ID
          # @param env_vars [Hash, nil] Environment variables from setup execution
          # @return [String] Skill invocation prompt
          def build_tc_skill_prompt(test_case:, scenario:, sandbox_path:, run_id: nil, env_vars: nil)
            cmd = "/ace:run-e2e-test #{scenario.package} #{scenario.test_id} #{test_case.tc_id} --tc-mode --sandbox #{sandbox_path}"
            cmd += " --run-id #{run_id}" if run_id
            cmd += " --env #{env_vars.map { |k, v| "#{k}=#{v}" }.join(',')}" if env_vars&.any?
            build_execution_prompt(command: cmd, tc_mode: true)
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

          private

          def build_execution_prompt(command:, tc_mode:)
            return_contract = if tc_mode
              "- **Test ID**: ...\n- **TC ID**: ...\n- **Status**: pass | fail\n- **Report Paths**: ...\n- **Issues**: ..."
            else
              "- **Test ID**: ...\n- **Status**: pass | fail | partial\n- **Passed**: ...\n- **Failed**: ...\n- **Total**: ...\n- **Report Paths**: ...\n- **Issues**: ..."
            end

            <<~PROMPT.strip
              Run this as a slash command in the agent chat interface (not in bash):
              #{command}

              Execution requirements:
              - Do not run `/ace:...` inside a shell command.
              - If slash commands are unavailable, stop and report that limitation in `Issues`.
              - Write reports under `.cache/ace-test-e2e/*-reports/`.
              - Return only this structured summary:
              #{return_contract}
            PROMPT
          end
        end
      end
    end
  end
end
