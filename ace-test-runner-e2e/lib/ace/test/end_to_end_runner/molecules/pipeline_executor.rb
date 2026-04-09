# frozen_string_literal: true

require "ace/llm"
require "ace/llm/query_interface"
require "json"
require "digest"
require "fileutils"

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
            selected_test_cases = selected_test_cases_for(scenario, test_cases)

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
            write_tc_start_manifests(
              selected_test_cases: selected_test_cases,
              sandbox_path: sandbox_path,
              started_at: started_at,
              providers: {runner: @runner_provider, verifier: @verifier_provider}
            )
            append_stage_command_records(
              selected_test_cases: selected_test_cases,
              sandbox_path: sandbox_path,
              stage: "runner",
              provider: @runner_provider,
              prompt_path: runner[:prompt_path],
              output_path: runner[:output_path],
              working_dir: merged_env["PROJECT_ROOT_PATH"] || sandbox_path
            )
            run_llm(
              provider: @runner_provider,
              prompt_path: runner[:prompt_path],
              system_path: runner[:system_path],
              output_path: runner[:output_path],
              cli_args: cli_args,
              env_vars: merged_env
            )
            artifact_snapshot = write_artifact_manifests(
              selected_test_cases: selected_test_cases,
              sandbox_path: sandbox_path
            )

            artifact_failures = detect_missing_artifacts(
              scenario: scenario,
              sandbox_path: sandbox_path,
              test_cases: test_cases,
              artifact_snapshot: artifact_snapshot,
              runner_completed: true
            )
            unless artifact_failures.empty?
              write_failure_final_manifests(
                selected_test_cases: selected_test_cases,
                sandbox_path: sandbox_path,
                artifact_failures: artifact_failures,
                completed_at: Time.now
              )
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
            append_stage_command_records(
              selected_test_cases: selected_test_cases,
              sandbox_path: sandbox_path,
              stage: "verifier",
              provider: @verifier_provider,
              prompt_path: verifier[:prompt_path],
              output_path: verifier[:output_path],
              working_dir: merged_env["PROJECT_ROOT_PATH"] || sandbox_path
            )
            verifier_response = run_llm(
              provider: @verifier_provider,
              prompt_path: verifier[:prompt_path],
              system_path: verifier[:system_path],
              output_path: verifier[:output_path],
              cli_args: cli_args,
              env_vars: merged_env
            )

            result = @report_generator.generate(
              scenario: scenario,
              verifier_output: verifier_response[:text],
              report_dir: report_dir,
              provider: {runner: @runner_provider, verifier: @verifier_provider},
              started_at: started_at,
              completed_at: Time.now
            )
            write_artifact_manifests(
              selected_test_cases: selected_test_cases,
              sandbox_path: sandbox_path
            )
            write_success_final_manifests(
              selected_test_cases: selected_test_cases,
              sandbox_path: sandbox_path,
              result: result,
              completed_at: Time.now
            )
            result
          rescue => e
            write_exception_final_manifests(
              selected_test_cases: selected_test_cases || [],
              sandbox_path: sandbox_path,
              error_message: "#{e.class}: #{e.message}",
              completed_at: Time.now
            )
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

          def detect_missing_artifacts(scenario:, sandbox_path:, test_cases: nil, artifact_snapshot:, runner_completed:)
            selected_test_cases = selected_test_cases_for(scenario, test_cases)

            selected_test_cases.filter_map do |test_case|
              result_dir = File.join(sandbox_path, result_dir_for(test_case))
              declared = Array(test_case.expected_artifacts)
              snapshot = artifact_snapshot.fetch(test_case.tc_id, default_artifact_snapshot(result_dir, sandbox_path, declared))

              if declared.any?
                missing = declared.reject { |relative_path| File.exist?(File.join(sandbox_path, relative_path)) }
              else
                has_any_file = snapshot[:produced].any?
                missing = has_any_file ? [] : ["#{result_dir_for(test_case)}/<no-artifacts>"]
              end

              next if missing.empty?

              failure_class = runner_completed ? "artifact-incomplete" : "setup-error"
              category = runner_completed ? "missing-artifact" : "infrastructure-error"

              {test_case: test_case, missing: missing, snapshot: snapshot, failure_class: failure_class, category: category}
            end
          end

          def build_missing_artifact_test_cases(scenario, artifact_failures)
            failures_by_tc = artifact_failures.each_with_object({}) do |failure, memo|
              memo[failure[:test_case].tc_id] = failure
            end

            selected_test_cases_for(scenario, failures_by_tc.keys).map do |test_case|
              failure = failures_by_tc[test_case.tc_id]
              status = failure ? "fail" : "pass"
              {
                id: test_case.tc_id,
                description: test_case.title,
                status: status,
                category: (failure ? failure[:category] : nil),
                failure_class: (failure ? failure[:failure_class] : nil),
                behavior_status: (failure ? "not_reached" : "pass"),
                evidence_status: (failure ? "incomplete" : "complete"),
                notes: (failure ? "Missing required artifacts: #{failure[:missing].join(', ')}" : "Declared artifacts present")
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

          def result_dir_path(sandbox_path, test_case)
            File.join(sandbox_path, result_dir_for(test_case))
          end

          def default_artifact_snapshot(result_dir, sandbox_path, declared)
            {
              result_dir: relative_path(result_dir, sandbox_path),
              declared: declared,
              produced: []
            }
          end

          def write_tc_start_manifests(selected_test_cases:, sandbox_path:, started_at:, providers:)
            selected_test_cases.each do |test_case|
              result_dir = result_dir_path(sandbox_path, test_case)
              FileUtils.mkdir_p(result_dir)
              write_json(
                File.join(result_dir, "tc.start.json"),
                {
                  tc_id: test_case.tc_id,
                  title: test_case.title,
                  started_at: started_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
                  required_artifacts: Array(test_case.expected_artifacts),
                  providers: providers
                }
              )
            end
          end

          def append_stage_command_records(selected_test_cases:, sandbox_path:, stage:, provider:, prompt_path:, output_path:, working_dir:)
            selected_test_cases.each do |test_case|
              result_dir = result_dir_path(sandbox_path, test_case)
              File.open(File.join(result_dir, "commands.ndjson"), "a") do |f|
                f.puts(
                  JSON.generate(
                    {
                      stage: stage,
                      provider: provider,
                      working_dir: File.expand_path(working_dir),
                      prompt_path: prompt_path,
                      output_path: output_path,
                      recorded_at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
                    }
                  )
                )
              end
            end
          end

          def write_artifact_manifests(selected_test_cases:, sandbox_path:)
            selected_test_cases.each_with_object({}) do |test_case, memo|
              result_dir = result_dir_path(sandbox_path, test_case)
              produced = Dir.glob(File.join(result_dir, "**", "*"), File::FNM_DOTMATCH)
                .select { |path| File.file?(path) }
                .reject { |path| %w[tc.start.json tc.final.json artifacts.json commands.ndjson].include?(File.basename(path)) }
                .sort
                .map do |path|
                  {
                    path: relative_path(path, sandbox_path),
                    size: File.size(path),
                    sha256: Digest::SHA256.file(path).hexdigest
                  }
                end

              snapshot = {
                result_dir: relative_path(result_dir, sandbox_path),
                declared: Array(test_case.expected_artifacts),
                produced: produced
              }
              write_json(File.join(result_dir, "artifacts.json"), snapshot)
              memo[test_case.tc_id] = snapshot
            end
          end

          def write_failure_final_manifests(selected_test_cases:, sandbox_path:, artifact_failures:, completed_at:)
            failures_by_tc = artifact_failures.each_with_object({}) do |failure, memo|
              memo[failure[:test_case].tc_id] = failure
            end

            selected_test_cases.each do |test_case|
              failure = failures_by_tc[test_case.tc_id]
              write_tc_final_manifest(
                sandbox_path: sandbox_path,
                test_case: test_case,
                completed_at: completed_at,
                status: (failure ? "error" : "pass"),
                behavior_status: (failure ? "not_reached" : "pass"),
                evidence_status: (failure ? "incomplete" : "complete"),
                failure_class: failure&.dig(:failure_class),
                category: failure&.dig(:category),
                notes: failure ? "Missing required artifacts: #{failure[:missing].join(', ')}" : "Required artifacts present"
              )
            end
          end

          def write_success_final_manifests(selected_test_cases:, sandbox_path:, result:, completed_at:)
            tc_results = Array(result.test_cases).each_with_object({}) { |tc, memo| memo[tc[:id].to_s.upcase] = tc }
            selected_test_cases.each do |test_case|
              tc = tc_results[test_case.tc_id.to_s.upcase]
              behavior_status = if tc.nil?
                "not_reached"
              elsif tc[:status] == "pass"
                "pass"
              else
                "fail"
              end
              failure_class = if tc.nil? || tc[:status] == "pass"
                nil
              elsif tc[:category].to_s == "test-spec-error"
                "invalid-contract"
              else
                "behavior-fail"
              end

              write_tc_final_manifest(
                sandbox_path: sandbox_path,
                test_case: test_case,
                completed_at: completed_at,
                status: tc&.dig(:status) || "error",
                behavior_status: behavior_status,
                evidence_status: "complete",
                failure_class: failure_class,
                category: tc&.dig(:category),
                notes: tc&.dig(:notes).to_s
              )
            end
          end

          def write_exception_final_manifests(selected_test_cases:, sandbox_path:, error_message:, completed_at:)
            selected_test_cases.each do |test_case|
              write_tc_final_manifest(
                sandbox_path: sandbox_path,
                test_case: test_case,
                completed_at: completed_at,
                status: "error",
                behavior_status: "not_reached",
                evidence_status: "incomplete",
                failure_class: "setup-error",
                category: "infrastructure-error",
                notes: error_message
              )
            end
          end

          def write_tc_final_manifest(sandbox_path:, test_case:, completed_at:, status:, behavior_status:, evidence_status:, failure_class:, category:, notes:)
            write_json(
              File.join(result_dir_path(sandbox_path, test_case), "tc.final.json"),
              {
                tc_id: test_case.tc_id,
                completed_at: completed_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
                status: status,
                behavior_status: behavior_status,
                evidence_status: evidence_status,
                failure_class: failure_class,
                category: category,
                notes: notes.to_s
              }
            )
          end

          def write_json(path, payload)
            File.write(path, JSON.pretty_generate(payload) + "\n")
          end

          def relative_path(path, root)
            File.expand_path(path).sub("#{File.expand_path(root)}/", "")
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
