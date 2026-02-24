# frozen_string_literal: true

require "ace/llm"
require "ace/llm/query_interface"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Executes a single E2E test scenario via LLM
        #
        # Routes execution through two paths based on provider type:
        # - CLI providers (claude, gemini, codex): Skill-based execution
        #   with actual command execution and sandbox creation
        # - API providers (google, anthropic): Prompt-based prediction (original behavior)
        class TestExecutor
          # @param provider [String] LLM provider:model string
          # @param timeout [Integer] Request timeout in seconds
          # @param config [Hash] Configuration hash (string keys) from ConfigLoader
          def initialize(provider: nil, timeout: nil, config: nil)
            config ||= Molecules::ConfigLoader.load
            @provider = provider || config.dig("execution", "provider") || "claude:sonnet"
            @timeout = timeout || config.dig("execution", "timeout") || 300
            @prompt_builder = Atoms::PromptBuilder.new
            @skill_prompt_builder = Atoms::SkillPromptBuilder.new(config)
          end

          # Execute a single test scenario via LLM
          #
          # @param scenario [Models::TestScenario] The test scenario to execute
          # @param cli_args [String, nil] Extra args for CLI providers
          # @param run_id [String, nil] Pre-generated run ID for deterministic report paths
          # @param test_cases [Array<String>, nil] Optional test case IDs to filter
          # @param sandbox_path [String, nil] Path to pre-populated sandbox (skips LLM setup)
          # @param env_vars [Hash, nil] Environment variables from setup execution
          # @param report_dir [String, nil] Explicit report directory path (overrides computed path)
          # @return [Models::TestResult] Test execution result
          def execute(scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil,
                      env_vars: nil, report_dir: nil, verify: false)
            if Atoms::SkillPromptBuilder.cli_provider?(@provider)
              execute_via_skill(scenario, cli_args: cli_args, run_id: run_id, test_cases: test_cases,
                                sandbox_path: sandbox_path, env_vars: env_vars, report_dir: report_dir,
                                verify: verify)
            else
              execute_via_prompt(scenario, cli_args: cli_args, test_cases: test_cases)
            end
          end

          # Execute a single test case via LLM in a pre-populated sandbox
          #
          # @param test_case [Models::TestCase] The single test case to execute
          # @param sandbox_path [String] Path to the pre-populated sandbox
          # @param scenario [Models::TestScenario] The parent scenario for metadata
          # @param cli_args [String, nil] Extra args for CLI providers
          # @param run_id [String, nil] Pre-generated run ID
          # @param env_vars [Hash, nil] Environment variables from setup execution
          # @return [Models::TestResult] Test execution result
          def execute_tc(test_case:, sandbox_path:, scenario:, cli_args: nil, run_id: nil, env_vars: nil)
            if Atoms::SkillPromptBuilder.cli_provider?(@provider)
              execute_tc_via_skill(test_case, sandbox_path, scenario, cli_args: cli_args, run_id: run_id, env_vars: env_vars)
            else
              execute_tc_via_prompt(test_case, sandbox_path, scenario, cli_args: cli_args)
            end
          end

          private

          # Execute via skill invocation for CLI providers
          #
          # @param scenario [Models::TestScenario] The test scenario
          # @param cli_args [String, nil] User-provided CLI args
          # @param run_id [String, nil] Pre-generated run ID for deterministic report paths
          # @param test_cases [Array<String>, nil] Optional test case IDs to filter
          # @param sandbox_path [String, nil] Path to pre-populated sandbox
          # @param env_vars [Hash, nil] Environment variables from setup execution
          # @param report_dir [String, nil] Explicit report directory path (overrides computed path)
          # @return [Models::TestResult]
          def execute_via_skill(scenario, cli_args: nil, run_id: nil, test_cases: nil, sandbox_path: nil,
                                env_vars: nil, report_dir: nil, verify: false)
            started_at = Time.now

            prompt = @skill_prompt_builder.build_skill_prompt(
              scenario, run_id: run_id, test_cases: test_cases,
              sandbox_path: sandbox_path, env_vars: env_vars, report_dir: report_dir
            )

            merged_args = merge_cli_args(
              Atoms::SkillPromptBuilder.required_cli_args(@provider),
              cli_args
            )

            response = Ace::LLM::QueryInterface.query(
              @provider,
              prompt,
              system: nil,
              cli_args: merged_args,
              timeout: @timeout,
              fallback: false,
              subprocess_env: env_vars
            )

            invocation_error = detect_skill_invocation_error(response[:text])
            if invocation_error
              return Models::TestResult.new(
                test_id: scenario.test_id,
                status: "error",
                test_cases: [],
                summary: "Skill invocation failed before test execution",
                error: invocation_error,
                started_at: started_at,
                completed_at: Time.now
              )
            end

            if verify
              return execute_verifier(
                scenario: scenario,
                cli_args: cli_args,
                run_id: run_id,
                test_cases: test_cases,
                sandbox_path: resolve_sandbox_path(sandbox_path, report_dir),
                env_vars: env_vars,
                report_dir: report_dir,
                started_at: started_at
              )
            end

            parsed = Atoms::SkillResultParser.parse(response[:text])
            completed_at = Time.now

            # Validate TC fidelity: ensure agent executed the expected test cases
            fidelity = Atoms::TcFidelityValidator.validate(
              parsed, scenario, filtered_tc_ids: test_cases
            )
            if fidelity
              return Models::TestResult.new(
                test_id: scenario.test_id,
                status: "error",
                test_cases: parsed[:test_cases],
                summary: fidelity[:error],
                error: fidelity[:error],
                started_at: started_at,
                completed_at: completed_at
              )
            end

            Models::TestResult.new(
              test_id: scenario.test_id,
              status: parsed[:status],
              test_cases: parsed[:test_cases],
              summary: parsed[:summary],
              started_at: started_at,
              completed_at: completed_at
            )
          rescue Atoms::ResultParser::ParseError => e
            Models::TestResult.new(
              test_id: scenario.test_id,
              status: "error",
              summary: "Failed to parse CLI provider response",
              error: e.message,
              started_at: started_at,
              completed_at: Time.now
            )
          rescue Ace::LLM::Error => e
            Models::TestResult.new(
              test_id: scenario.test_id,
              status: "error",
              summary: "CLI provider execution failed",
              error: e.message,
              started_at: started_at || Time.now,
              completed_at: Time.now
            )
          rescue StandardError => e
            Models::TestResult.new(
              test_id: scenario.test_id,
              status: "error",
              summary: "Unexpected execution error",
              error: "#{e.class}: #{e.message}",
              started_at: started_at || Time.now,
              completed_at: Time.now
            )
          end

          # Execute verifier as an independent second invocation.
          #
          # The verifier result is authoritative for status in verify mode.
          def execute_verifier(scenario:, cli_args:, run_id:, test_cases:, sandbox_path:, env_vars:, report_dir:, started_at:)
            verifier_prompt = @skill_prompt_builder.build_verifier_prompt(
              scenario,
              run_id: run_id,
              sandbox_path: sandbox_path,
              test_cases: test_cases,
              report_dir: report_dir
            )

            merged_args = merge_cli_args(
              Atoms::SkillPromptBuilder.required_cli_args(@provider),
              cli_args
            )

            verifier_response = Ace::LLM::QueryInterface.query(
              @provider,
              verifier_prompt,
              system: nil,
              cli_args: merged_args,
              timeout: @timeout,
              fallback: false,
              subprocess_env: env_vars
            )

            invocation_error = detect_skill_invocation_error(verifier_response[:text])
            if invocation_error
              return Models::TestResult.new(
                test_id: scenario.test_id,
                status: "error",
                test_cases: [],
                summary: "Verifier invocation failed before verification",
                error: invocation_error,
                started_at: started_at,
                completed_at: Time.now
              )
            end

            parsed = Atoms::SkillResultParser.parse_verifier(verifier_response[:text])
            completed_at = Time.now

            Models::TestResult.new(
              test_id: scenario.test_id,
              status: parsed[:status],
              test_cases: parsed[:test_cases],
              summary: parsed[:summary],
              started_at: started_at,
              completed_at: completed_at
            )
          end

          def resolve_sandbox_path(sandbox_path, report_dir)
            return sandbox_path if sandbox_path && !sandbox_path.empty?
            return nil unless report_dir

            report_dir.sub(/-reports\z/, "")
          end

          # Execute via prompt for API providers (original behavior)
          #
          # @param scenario [Models::TestScenario] The test scenario
          # @param cli_args [String, nil] Extra args
          # @param test_cases [Array<String>, nil] Optional test case IDs to filter
          # @return [Models::TestResult]
          def execute_via_prompt(scenario, cli_args: nil, test_cases: nil)
            started_at = Time.now

            prompt = @prompt_builder.build(scenario, test_cases: test_cases)

            response = Ace::LLM::QueryInterface.query(
              @provider,
              prompt,
              system: Atoms::PromptBuilder::SYSTEM_PROMPT,
              cli_args: cli_args,
              timeout: @timeout,
              fallback: false
            )

            parsed = Atoms::ResultParser.parse(response[:text])
            completed_at = Time.now

            # Validate TC fidelity: ensure agent executed the expected test cases
            fidelity = Atoms::TcFidelityValidator.validate(
              parsed, scenario, filtered_tc_ids: test_cases
            )
            if fidelity
              return Models::TestResult.new(
                test_id: scenario.test_id,
                status: "error",
                test_cases: parsed[:test_cases],
                summary: fidelity[:error],
                error: fidelity[:error],
                started_at: started_at,
                completed_at: completed_at
              )
            end

            Models::TestResult.new(
              test_id: scenario.test_id,
              status: parsed[:status],
              test_cases: parsed[:test_cases],
              summary: parsed[:summary],
              started_at: started_at,
              completed_at: completed_at
            )
          rescue Atoms::ResultParser::ParseError => e
            Models::TestResult.new(
              test_id: scenario.test_id,
              status: "error",
              summary: "Failed to parse LLM response",
              error: e.message,
              started_at: started_at,
              completed_at: Time.now
            )
          rescue Ace::LLM::Error => e
            Models::TestResult.new(
              test_id: scenario.test_id,
              status: "error",
              summary: "LLM execution failed",
              error: e.message,
              started_at: started_at || Time.now,
              completed_at: Time.now
            )
          rescue StandardError => e
            Models::TestResult.new(
              test_id: scenario.test_id,
              status: "error",
              summary: "Unexpected execution error",
              error: "#{e.class}: #{e.message}",
              started_at: started_at || Time.now,
              completed_at: Time.now
            )
          end

          # Execute TC via skill invocation for CLI providers
          def execute_tc_via_skill(test_case, sandbox_path, scenario, cli_args: nil, run_id: nil, env_vars: nil)
            with_tc_error_handling(scenario) do |started_at|
              prompt = @skill_prompt_builder.build_tc_skill_prompt(
                test_case: test_case, scenario: scenario,
                sandbox_path: sandbox_path, run_id: run_id, env_vars: env_vars
              )

              merged_args = merge_cli_args(
                Atoms::SkillPromptBuilder.required_cli_args(@provider),
                cli_args
              )

              response = Ace::LLM::QueryInterface.query(
                @provider, prompt,
                system: nil, cli_args: merged_args,
                timeout: @timeout, fallback: false,
                subprocess_env: env_vars
              )

              invocation_error = detect_skill_invocation_error(response[:text])
              if invocation_error
                return Models::TestResult.new(
                  test_id: scenario.test_id,
                  status: "error",
                  test_cases: [],
                  summary: "TC skill invocation failed before test execution",
                  error: invocation_error,
                  started_at: started_at,
                  completed_at: Time.now
                )
              end

              parsed = Atoms::SkillResultParser.parse_tc(response[:text])
              completed_at = Time.now

              Models::TestResult.new(
                test_id: scenario.test_id,
                status: parsed[:status],
                test_cases: parsed[:test_cases],
                summary: parsed[:summary],
                started_at: started_at,
                completed_at: completed_at
              )
            end
          end

          # Execute TC via prompt for API providers
          def execute_tc_via_prompt(test_case, sandbox_path, scenario, cli_args: nil)
            with_tc_error_handling(scenario) do |started_at|
              prompt = @prompt_builder.build_tc(
                test_case: test_case, scenario: scenario, sandbox_path: sandbox_path
              )

              response = Ace::LLM::QueryInterface.query(
                @provider, prompt,
                system: Atoms::PromptBuilder::TC_SYSTEM_PROMPT,
                cli_args: cli_args, timeout: @timeout, fallback: false
              )

              parsed = Atoms::ResultParser.parse_tc(response[:text])
              completed_at = Time.now

              Models::TestResult.new(
                test_id: scenario.test_id,
                status: parsed[:status],
                test_cases: parsed[:test_cases],
                summary: parsed[:summary],
                started_at: started_at,
                completed_at: completed_at
              )
            end
          end

          # Shared error handling for TC execution methods
          def with_tc_error_handling(scenario)
            started_at = Time.now
            yield started_at
          rescue Atoms::ResultParser::ParseError => e
            Models::TestResult.new(
              test_id: scenario.test_id, status: "error",
              summary: "Failed to parse TC response",
              error: e.message, started_at: started_at, completed_at: Time.now
            )
          rescue Ace::LLM::Error => e
            Models::TestResult.new(
              test_id: scenario.test_id, status: "error",
              summary: "TC execution failed",
              error: e.message, started_at: started_at, completed_at: Time.now
            )
          rescue StandardError => e
            Models::TestResult.new(
              test_id: scenario.test_id, status: "error",
              summary: "Unexpected TC execution error",
              error: "#{e.class}: #{e.message}",
              started_at: started_at, completed_at: Time.now
            )
          end

          # Merge required CLI args with user-provided args
          #
          # @param required [String, nil] Provider-required args
          # @param user_provided [String, nil] User-provided args
          # @return [String, nil] Merged args string
          def merge_cli_args(required, user_provided)
            parts = [required, user_provided].compact.reject(&:empty?)
            return nil if parts.empty?

            parts.join(" ")
          end

          # Detect common failure modes where the agent did not execute the
          # /ace-e2e-run skill correctly.
          #
          # @param text [String] Raw LLM response text
          # @return [String, nil] Error message when a known failure is detected
          def detect_skill_invocation_error(text)
            return nil if text.nil? || text.strip.empty?

            checks = [
              [/\/ace-e2e-run.*command not found/i, "The slash command was executed in a shell instead of chat."],
              [/exit code 127.*\/ace-e2e-run|\/ace-e2e-run.*exit code 127/im, "The slash command failed with shell exit code 127."],
              [/No tests found for package/i, "The test command ran in the wrong context or with invalid arguments."],
              [/\bace-test\s+e2e\b/i, "An invalid command (`ace-test e2e`) was attempted instead of `ace-test-e2e`."],
              [/slash commands are unavailable/i, "The agent reported slash commands are unavailable in this environment."]
            ]

            checks.each do |pattern, message|
              next unless text.match?(pattern)

              detail = extract_matching_line(text, pattern)
              return "#{message} Detected output: #{detail}"
            end

            nil
          end

          def extract_matching_line(text, pattern)
            line = text.to_s.lines.find { |candidate| candidate.match?(pattern) }
            return line.strip if line && !line.strip.empty?

            text.to_s.strip.split(/\s+/).first(30).join(" ")
          end
        end
      end
    end
  end
end
