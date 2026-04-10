# frozen_string_literal: true

require "ace/llm"
require "ace/llm/query_interface"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Executes standalone scenarios using the deterministic pipeline.
        class PipelineExecutor
          # @param provider [String]
          # @param runner_provider [String]
          # @param verifier_provider [String]
          # @param timeout [Integer]
          # @param sandbox_builder [Molecules::PipelineSandboxBuilder]
          # @param prompt_bundler [Molecules::PipelinePromptBundler]
          # @param report_generator [Molecules::PipelineReportGenerator]
          def initialize(provider: nil, runner_provider: nil, verifier_provider: nil, timeout:,
            sandbox_builder: nil, prompt_bundler: nil, report_generator: nil)
            @runner_provider = runner_provider || provider
            @verifier_provider = verifier_provider || provider || @runner_provider
            @timeout = timeout
            @sandbox_builder = sandbox_builder || PipelineSandboxBuilder.new
            @prompt_bundler = prompt_bundler || PipelinePromptBundler.new
            @report_generator = report_generator || PipelineReportGenerator.new
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
              provider: @runner_provider,
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
              provider: @verifier_provider,
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
              runner_provider: @runner_provider,
              verifier_provider: @verifier_provider,
              started_at: started_at,
              completed_at: Time.now
            )
          rescue => e
            begin
              @report_generator.write_failure_report(
                scenario: scenario,
                report_dir: report_dir,
                runner_provider: @runner_provider,
                verifier_provider: @verifier_provider,
                started_at: started_at || Time.now,
                completed_at: Time.now,
                error_message: "#{e.class}: #{e.message}"
              )
            rescue => write_error
              Models::TestResult.new(
                test_id: scenario.test_id,
                status: "error",
                summary: "Execution pipeline failed",
                error: "#{e.class}: #{e.message}; failed to write error report: #{write_error.class}: #{write_error.message}",
                started_at: started_at || Time.now,
                completed_at: Time.now
              )
            end
          end

          private

          def run_llm(provider:, prompt_path:, system_path:, output_path:, cli_args:, env_vars:)
            prompt = File.read(prompt_path)
            system = File.read(system_path)
            sandbox_dir = env_vars["PROJECT_ROOT_PATH"] || env_vars[:PROJECT_ROOT_PATH]

            Ace::LLM::QueryInterface.query(
              provider,
              prompt,
              system: system,
              cli_args: cli_args,
              timeout: @timeout,
              fallback: false,
              output: output_path,
              subprocess_env: env_vars,
              working_dir: sandbox_dir
            )
          end
        end
      end
    end
  end
end
