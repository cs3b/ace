# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Atoms
        # Holds CLI-provider detection and CLI-args helpers.
        #
        # Standalone scenario execution for CLI providers now runs through the
        # deterministic runner/verifier pipeline.
        # Provider lists and CLI args are configurable via config.yml.
        class CliProviderAdapter
          # Legacy shorthand values that still appear in existing configs and should map
          # to explicit flags for deterministic command behavior.
          CLI_ARG_ALIAS = {
            "full-auto" => ["--sandbox danger-full-access", "--ask-for-approval never"],
            "dangerously-bypass-approvals-and-sandbox" => ["--sandbox danger-full-access", "--ask-for-approval never"]
          }.freeze

          # @param config [Hash] Configuration hash (string keys) with providers section
          def initialize(config = {})
            @cli_providers = config.dig("providers", "cli") || %w[claude gemini codex codexoss opencode pi]
            @cli_args_map = config.dig("providers", "cli_args") || {
              "claude" => ["dangerously-skip-permissions"],
              "codex" => ["--sandbox danger-full-access", "--ask-for-approval never"]
            }
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
          # @return [String, nil] Required CLI args as a legacy string
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
          # @return [String, nil] Required CLI args as a legacy string
          def required_cli_args(provider_string)
            name = self.class.provider_name(provider_string)
            args = required_cli_args_list_from(name)
            return nil if args.nil?

            args.join(" ")
          end

          # @return [Array<String>, nil] Required CLI args as an array
          def required_cli_args_list(provider_string)
            name = self.class.provider_name(provider_string)
            required_cli_args_list_from(name)
          end

          # @return [Array<String>, nil] Required CLI args as an array
          def self.required_cli_args_list(provider_string)
            default_instance.required_cli_args_list(provider_string)
          end

          private

          def required_cli_args_list_from(provider_name)
            value = @cli_args_map[provider_name]
            return nil if value.nil?

            args = Array(value).map(&:to_s).map(&:strip).reject(&:empty?)
            return nil if args.empty?

            return CLI_ARG_ALIAS[args.first] if args.length == 1 && CLI_ARG_ALIAS.key?(args.first)

            args
          end

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
              - Do not run `/ace-...` inside a shell command.
              - If slash commands are unavailable, stop and report that limitation in `Issues`.
              - Write reports under `.ace-local/test-e2e/*-reports/`.
              - Return only this structured summary:
              #{return_contract}
            PROMPT
          end

          public

          # Build a skill invocation prompt for scenario-level execution
          #
          # @param scenario [Models::TestScenario] The test scenario
          # @param run_id [String, nil] Pre-generated run ID for deterministic report paths
          # @param test_cases [Array<String>, nil] Optional test case IDs to filter
          # @param sandbox_path [String, nil] Path to pre-populated sandbox (skips setup steps)
          # @param env_vars [Hash, nil] Environment variables from setup execution
          # @param report_dir [String, nil] Explicit report directory path (overrides computed path)
          # @return [String] Skill invocation prompt
          def build_skill_prompt(scenario, run_id: nil, test_cases: nil, sandbox_path: nil, env_vars: nil, report_dir: nil)
            cmd = "/as-e2e-run #{scenario.package} #{scenario.test_id}"
            cmd += " #{test_cases.join(',')}" if test_cases&.any?
            cmd += " --run-id #{run_id}" if run_id
            cmd += " --sandbox #{sandbox_path}" if sandbox_path
            cmd += " --env #{env_vars.map { |k, v| "#{k}=#{v}" }.join(',')}" if env_vars&.any?
            cmd += " --report-dir #{report_dir}" if report_dir
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
            cmd = "/as-e2e-run #{scenario.package} #{scenario.test_id} #{test_case.tc_id} --tc-mode --sandbox #{sandbox_path}"
            cmd += " --run-id #{run_id}" if run_id
            cmd += " --env #{env_vars.map { |k, v| "#{k}=#{v}" }.join(',')}" if env_vars&.any?
            build_execution_prompt(command: cmd, tc_mode: true)
          end

          # Build an independent verifier prompt.
          #
          # This is intentionally a second invocation to avoid sharing runner context.
          def build_verifier_prompt(scenario, run_id: nil, sandbox_path: nil, test_cases: nil, report_dir: nil)
            report_dir ||= if run_id
              ".ace-local/test-e2e/#{scenario.dir_name(run_id)}-reports"
            end

            tc_filter = test_cases&.any? ? test_cases.join(", ") : "all discovered test cases"
            sandbox_info = sandbox_path || "(unknown)"
            report_info = report_dir || "(unknown)"

            <<~PROMPT.strip
              You are the independent verifier for an E2E scenario.

              Verify this scenario in a new, isolated agent context:
              - Package: #{scenario.package}
              - Test ID: #{scenario.test_id}
              - Sandbox path: #{sandbox_info}
              - Report directory: #{report_info}
              - Scope: #{tc_filter}

              Verification requirements:
              - Inspect sandbox artifacts and scenario files directly.
              - Evaluate each test case using `TC-*.verify.md` criteria when present.
              - Classify each failed test case with one category:
                `test-spec-error`, `tool-bug`, `runner-error`, or `infrastructure-error`.
              - Write/update report files under the report directory.
              - Use TC-first schema in report frontmatter and metadata.

              Return only this structured summary:
              - **Test ID**: ...
              - **Status**: pass | fail | partial | error
              - **TCs Passed**: ...
              - **TCs Failed**: ...
              - **TCs Total**: ...
              - **Score**: ...
              - **Verdict**: pass | partial | fail
              - **Failed TCs**: TC-001:tool-bug, TC-002:runner-error (or `None`)
              - **Issues**: ...
            PROMPT
          end

          # Lazily-loaded default instance backed by ConfigLoader
          # @return [CliProviderAdapter]
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

        end

        # Backward-compatible alias while callers migrate off the legacy name.
        SkillPromptBuilder = CliProviderAdapter
      end
    end
  end
end
