# frozen_string_literal: true

require "fileutils"
require "json"
require "time"
require "ace/llm"
require "ace/llm/query_interface"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Executes standalone scenarios using the deterministic pipeline.
        class PipelineExecutor
          # @param provider [String]
          # @param verifier_provider [String, nil]
          # @param timeout [Integer]
          # @param sandbox_builder [Molecules::PipelineSandboxBuilder]
          # @param prompt_bundler [Molecules::PipelinePromptBundler]
          # @param report_generator [Molecules::PipelineReportGenerator]
          def initialize(provider:, verifier_provider: nil, timeout:, sandbox_builder: nil, prompt_bundler: nil,
            report_generator: nil)
            @provider = provider
            @verifier_provider = verifier_provider || provider
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
            FileUtils.mkdir_p(report_dir)
            write_command_record(report_dir, "runner", provider: @provider, cli_args: cli_args)
            write_tc_manifests(report_dir, scenario, test_cases: test_cases)

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
              env_vars: merged_env,
              provider: @provider
            )
            snapshot_artifacts(report_dir, sandbox_path, scenario)

            missing_artifacts = missing_declared_artifacts(sandbox_path, scenario, test_cases: test_cases)
            unless missing_artifacts.empty?
              return @report_generator.write_failure_report(
                scenario: scenario,
                report_dir: report_dir,
                provider: @verifier_provider,
                started_at: started_at,
                completed_at: Time.now,
                error_message: "Declared artifacts were not produced: #{missing_artifacts.join(", ")}",
                failure_category: "missing-artifact",
                test_cases: missing_artifact_cases(missing_artifacts),
                metadata: base_metadata(report_dir)
              )
            end

            verifier = @prompt_bundler.prepare_verifier(
              scenario: scenario,
              sandbox_path: sandbox_path,
              test_cases: test_cases
            )
            write_command_record(report_dir, "verifier", provider: @verifier_provider, cli_args: cli_args)
            verifier_response = run_llm(
              prompt_path: verifier[:prompt_path],
              system_path: verifier[:system_path],
              output_path: verifier[:output_path],
              cli_args: cli_args,
              env_vars: merged_env,
              provider: @verifier_provider
            )

            @report_generator.generate(
              scenario: scenario,
              verifier_output: verifier_response[:text],
              report_dir: report_dir,
              provider: @verifier_provider,
              started_at: started_at,
              completed_at: Time.now,
              metadata: base_metadata(report_dir)
            )
          rescue => e
            begin
              @report_generator.write_failure_report(
                scenario: scenario,
                report_dir: report_dir,
                provider: @verifier_provider,
                started_at: started_at || Time.now,
                completed_at: Time.now,
                error_message: "#{e.class}: #{e.message}",
                failure_category: "runner-error",
                metadata: base_metadata(report_dir)
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

          def run_llm(prompt_path:, system_path:, output_path:, cli_args:, env_vars:, provider:)
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

          def write_tc_manifests(report_dir, scenario, test_cases:)
            selected = select_test_cases(scenario, test_cases)
            selected.each do |test_case|
              manifest = {
                tc_id: test_case.tc_id,
                title: test_case.title,
                declared_artifacts: test_case.declared_artifacts,
                goal_format: test_case.goal_format
              }
              File.write(
                File.join(report_dir, "#{test_case.short_id}.manifest.json"),
                JSON.pretty_generate(manifest)
              )
            end
          end

          def write_command_record(report_dir, phase, provider:, cli_args:)
            record = {
              phase: phase,
              provider: provider,
              cli_args: cli_args,
              timeout: @timeout,
              recorded_at: Time.now.utc.iso8601
            }
            File.write(
              File.join(report_dir, "#{phase}.command.json"),
              JSON.pretty_generate(record)
            )
          end

          def snapshot_artifacts(report_dir, sandbox_path, scenario)
            snapshot = select_test_cases(scenario, nil).to_h do |test_case|
              [test_case.tc_id, test_case.declared_artifacts.select { |path| File.exist?(File.join(sandbox_path, path)) }]
            end
            File.write(File.join(report_dir, "artifact-snapshot.json"), JSON.pretty_generate(snapshot))
          end

          def missing_declared_artifacts(sandbox_path, scenario, test_cases:)
            select_test_cases(scenario, test_cases).flat_map do |test_case|
              test_case.declared_artifacts.reject do |path|
                File.exist?(File.join(sandbox_path, path))
              end
            end.uniq.sort
          end

          def missing_artifact_cases(paths)
            paths.map do |path|
              {id: path, description: path, status: "fail", notes: path, category: "missing-artifact"}
            end
          end

          def select_test_cases(scenario, test_cases)
            return Array(scenario.test_cases) if test_cases.nil? || test_cases.empty?

            wanted = test_cases.map { |value| value.to_s.upcase }
            Array(scenario.test_cases).select { |tc| wanted.include?(tc.tc_id.to_s.upcase) }
          end

          def base_metadata(report_dir)
            {
              "runner_provider" => @provider,
              "verifier_provider" => @verifier_provider,
              "report_dir" => report_dir
            }
          end
        end
      end
    end
  end
end
