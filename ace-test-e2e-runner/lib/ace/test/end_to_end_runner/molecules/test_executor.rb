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
        # - CLI providers (claude, gemini, codex): Skill/workflow-based execution
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
          # @return [Models::TestResult] Test execution result
          def execute(scenario, cli_args: nil, run_id: nil, test_cases: nil)
            if Atoms::SkillPromptBuilder.cli_provider?(@provider)
              execute_via_skill(scenario, cli_args: cli_args, run_id: run_id, test_cases: test_cases)
            else
              execute_via_prompt(scenario, cli_args: cli_args, test_cases: test_cases)
            end
          end

          private

          # Execute via skill/workflow for CLI providers
          #
          # @param scenario [Models::TestScenario] The test scenario
          # @param cli_args [String, nil] User-provided CLI args
          # @param run_id [String, nil] Pre-generated run ID for deterministic report paths
          # @param test_cases [Array<String>, nil] Optional test case IDs to filter
          # @return [Models::TestResult]
          def execute_via_skill(scenario, cli_args: nil, run_id: nil, test_cases: nil)
            started_at = Time.now

            if Atoms::SkillPromptBuilder.skill_aware?(@provider)
              prompt = @skill_prompt_builder.build_skill_prompt(scenario, run_id: run_id, test_cases: test_cases)
              system = nil
            else
              workflow_content = load_workflow_content
              prompt = @skill_prompt_builder.build_workflow_prompt(scenario, workflow_content: workflow_content, run_id: run_id, test_cases: test_cases)
              system = @skill_prompt_builder.system_prompt_for(@provider)
            end

            merged_args = merge_cli_args(
              Atoms::SkillPromptBuilder.required_cli_args(@provider),
              cli_args
            )

            response = Ace::LLM::QueryInterface.query(
              @provider,
              prompt,
              system: system,
              cli_args: merged_args,
              timeout: @timeout,
              fallback: false
            )

            parsed = Atoms::SkillResultParser.parse(response[:text])
            completed_at = Time.now

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

          # Load the run-e2e-test workflow content
          #
          # @return [String] Workflow markdown content
          def load_workflow_content
            project_root = find_project_root
            workflow_path = File.join(
              project_root,
              "ace-test-e2e-runner", "handbook", "workflow-instructions", "run-e2e-test.wf.md"
            )

            return File.read(workflow_path) if File.exist?(workflow_path)

            # Fallback: try relative to the gem itself
            gem_root = File.expand_path("../../../../..", __dir__)
            alt_path = File.join(gem_root, "handbook", "workflow-instructions", "run-e2e-test.wf.md")
            return File.read(alt_path) if File.exist?(alt_path)

            "(Workflow file not found - execute the test scenario directly)"
          end

          # Find the project root directory
          #
          # @return [String] Project root path
          def find_project_root
            if defined?(Ace::Support::Fs::Molecules::ProjectRootFinder)
              Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
            else
              Dir.pwd
            end
          end
        end
      end
    end
  end
end
