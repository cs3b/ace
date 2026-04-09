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
          # @param timeout [Integer]
          # @param sandbox_builder [Molecules::PipelineSandboxBuilder]
          # @param prompt_bundler [Molecules::PipelinePromptBundler]
          # @param report_generator [Molecules::PipelineReportGenerator]
          def initialize(runner_provider:, verifier_provider:, timeout:, sandbox_builder: nil, prompt_bundler: nil, report_generator: nil)
            @runner_provider = runner_provider
            @verifier_provider = verifier_provider
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

            artifact_failures = detect_missing_artifacts(
              scenario: scenario,
              sandbox_path: sandbox_path,
              test_cases: test_cases
            )
            unless artifact_failures.empty?
              return @report_generator.write_failure_report(
                scenario: scenario,
                report_dir: report_dir,
                provider: {runner: @runner_provider, verifier: @verifier_provider},
                started_at: started_at,
                completed_at: Time.now,
                summary: "Scenario execution produced incomplete evidence",
                error_message: missing_artifact_error_message(artifact_failures),
                test_cases: build_missing_artifact_test_cases(scenario, artifact_failures)
              )
            end

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
              provider: {runner: @runner_provider, verifier: @verifier_provider},
              started_at: started_at,
              completed_at: Time.now
            )
          rescue => e
            begin
              @report_generator.write_failure_report(
                scenario: scenario,
                report_dir: report_dir,
                provider: {runner: @runner_provider, verifier: @verifier_provider},
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

          def detect_missing_artifacts(scenario:, sandbox_path:, test_cases: nil)
            selected_test_cases = selected_test_cases_for(scenario, test_cases)

            selected_test_cases.filter_map do |test_case|
              result_dir = File.join(sandbox_path, result_dir_for(test_case))
              declared = Array(test_case.expected_artifacts)

              if declared.any?
                missing = declared.reject { |relative_path| File.exist?(File.join(sandbox_path, relative_path)) }
              else
                has_any_file = Dir.exist?(result_dir) && Dir.glob(File.join(result_dir, "**", "*"), File::FNM_DOTMATCH).any? { |path| File.file?(path) }
                missing = has_any_file ? [] : ["#{result_dir_for(test_case)}/<no-artifacts>"]
              end

              next if missing.empty?

              {test_case: test_case, missing: missing}
            end
          end

          def build_missing_artifact_test_cases(scenario, artifact_failures)
            failures_by_tc = artifact_failures.each_with_object({}) do |failure, memo|
              memo[failure[:test_case].tc_id] = failure[:missing]
            end

            selected_test_cases_for(scenario, failures_by_tc.keys).map do |test_case|
              missing = failures_by_tc[test_case.tc_id]
              status = missing ? "fail" : "pass"
              {
                id: test_case.tc_id,
                description: test_case.title,
                status: status,
                category: (missing ? "missing-artifact" : nil),
                notes: (missing ? "Missing required artifacts: #{missing.join(', ')}" : "Declared artifacts present")
              }
            end
          end

          def missing_artifact_error_message(artifact_failures)
            artifact_failures.map do |failure|
              "#{failure[:test_case].tc_id}: #{failure[:missing].join(', ')}"
            end.join("\n")
          end

          def selected_test_cases_for(scenario, requested_ids)
            all = Array(scenario.test_cases)
            return all if requested_ids.nil? || requested_ids.empty?

            wanted = requested_ids.map(&:to_s).map(&:upcase)
            all.select { |test_case| wanted.include?(test_case.tc_id.to_s.upcase) }
          end

          def result_dir_for(test_case)
            match = test_case.tc_id.to_s.match(/TC-(\d{1,3})/i)
            index = match ? match[1].to_i : 0
            "results/tc/#{format('%02d', index)}"
          end

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
          rescue => e
            File.write("#{output_path}.error.txt", "#{e.class}: #{e.message}\n")
            raise
          end
        end
      end
    end
  end
end
