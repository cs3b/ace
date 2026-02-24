# frozen_string_literal: true

require "ace/llm"
require "ace/llm/query_interface"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Executes standalone goal-mode scenarios using the 6-phase pipeline.
        class GoalModeExecutor
          # @param provider [String]
          # @param timeout [Integer]
          # @param sandbox_builder [Molecules::GoalModeSandboxBuilder]
          # @param prompt_bundler [Molecules::GoalModePromptBundler]
          # @param report_generator [Molecules::GoalModeReportGenerator]
          def initialize(provider:, timeout:, sandbox_builder: nil, prompt_bundler: nil, report_generator: nil)
            @provider = provider
            @timeout = timeout
            @sandbox_builder = sandbox_builder || GoalModeSandboxBuilder.new
            @prompt_bundler = prompt_bundler || GoalModePromptBundler.new
            @report_generator = report_generator || GoalModeReportGenerator.new
          end

          # @param scenario [Models::TestScenario]
          # @param cli_args [String, nil]
          # @param sandbox_path [String]
          # @param report_dir [String]
          # @param env_vars [Hash, nil]
          # @param test_cases [Array<String>, nil]
          # @return [Models::TestResult]
          def execute(scenario:, cli_args:, sandbox_path:, report_dir:, env_vars: nil, test_cases: nil)
            started_at = Time.now

            build_env = @sandbox_builder.build(
              scenario: scenario,
              sandbox_path: sandbox_path,
              test_cases: test_cases
            )
            merged_env = (env_vars || {}).merge(build_env)

            runner = @prompt_bundler.prepare_runner(
              scenario: scenario,
              sandbox_path: sandbox_path,
              test_cases: test_cases
            )
            run_llm(
              prompt_path: runner[:prompt_path],
              system_path: runner[:system_path],
              output_path: runner[:output_path],
              cli_args: cli_args,
              env_vars: merged_env
            )

            verifier = @prompt_bundler.prepare_verifier(
              scenario: scenario,
              sandbox_path: sandbox_path,
              test_cases: test_cases
            )
            verifier_response = run_llm(
              prompt_path: verifier[:prompt_path],
              system_path: verifier[:system_path],
              output_path: verifier[:output_path],
              cli_args: cli_args,
              env_vars: merged_env
            )

            @report_generator.generate(
              scenario: scenario,
              verifier_output: verifier_response[:text],
              report_dir: report_dir,
              provider: @provider,
              started_at: started_at,
              completed_at: Time.now
            )
          rescue StandardError => e
            Models::TestResult.new(
              test_id: scenario.test_id,
              status: "error",
              summary: "Goal-mode execution pipeline failed",
              error: "#{e.class}: #{e.message}",
              started_at: started_at || Time.now,
              completed_at: Time.now
            )
          end

          private

          def run_llm(prompt_path:, system_path:, output_path:, cli_args:, env_vars:)
            prompt = File.read(prompt_path)
            system = File.read(system_path)

            Ace::LLM::QueryInterface.query(
              @provider,
              prompt,
              system: system,
              cli_args: cli_args,
              timeout: @timeout,
              fallback: false,
              output: output_path,
              subprocess_env: env_vars
            )
          end
        end
      end
    end
  end
end
