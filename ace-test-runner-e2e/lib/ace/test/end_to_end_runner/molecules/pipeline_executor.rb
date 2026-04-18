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
          AMBIENT_TMUX_ENV_VARS = %w[TMUX TMUX_PANE].freeze

          # @param provider [String]
          # @param verifier_provider [String, nil]
          # @param timeout [Integer]
          # @param sandbox_builder [Molecules::PipelineSandboxBuilder]
          # @param prompt_bundler [Molecules::PipelinePromptBundler]
          # @param report_generator [Molecules::PipelineReportGenerator]
          def initialize(provider:, verifier_provider: nil, timeout:, sandbox_builder: nil, prompt_bundler: nil,
            report_generator: nil, sandbox_backend_factory: nil)
            @provider = provider
            @verifier_provider = verifier_provider || provider
            @timeout = timeout
            @sandbox_builder = sandbox_builder || PipelineSandboxBuilder.new
            @prompt_bundler = prompt_bundler || PipelinePromptBundler.new
            @report_generator = report_generator || PipelineReportGenerator.new
            @sandbox_backend_factory = sandbox_backend_factory || lambda { |sandbox_path, source_root: nil|
              Molecules::BwrapSandboxBackend.new(sandbox_root: sandbox_path, source_root: source_root)
            }
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

            build_env = if prepared_sandbox?(sandbox_path, env_vars)
              @sandbox_builder.prepare_existing_sandbox(
                scenario: scenario,
                sandbox_path: sandbox_path,
                test_cases: test_cases
              )
            else
              @sandbox_builder.build(
                scenario: scenario,
                sandbox_path: sandbox_path,
                test_cases: test_cases
              )
            end
            merged_env = sanitize_subprocess_env((env_vars || {}).merge(build_env))
            sandbox_backend = @sandbox_backend_factory.call(
              sandbox_path,
              source_root: merged_env["ACE_E2E_SOURCE_ROOT"] || merged_env[:ACE_E2E_SOURCE_ROOT]
            )
            merged_env = sandbox_backend.prepared_env(merged_env)

            runner = @prompt_bundler.prepare_runner(
              scenario: scenario,
              sandbox_path: sandbox_path,
              test_cases: test_cases
            )
            runner_response = run_llm(
              prompt_path: runner[:prompt_path],
              system_path: runner[:system_path],
              output_path: runner[:output_path],
              cli_args: cli_args,
              env_vars: merged_env,
              subprocess_command_prefix: sandbox_backend.command_prefix(chdir: sandbox_path, env: merged_env),
              provider: @provider
            )
            runner_observations = extract_runner_observations(runner_response[:text])
            artifact_contract = snapshot_artifacts(report_dir, sandbox_path, scenario, test_cases: test_cases)

            verifier = @prompt_bundler.prepare_verifier(
              scenario: scenario,
              sandbox_path: sandbox_path,
              test_cases: test_cases,
              runner_observations: runner_observations,
              artifact_contract: artifact_contract
            )
            write_command_record(report_dir, "verifier", provider: @verifier_provider, cli_args: cli_args)
            verifier_response = run_llm(
              prompt_path: verifier[:prompt_path],
              system_path: verifier[:system_path],
              output_path: verifier[:output_path],
              cli_args: cli_args,
              env_vars: merged_env,
              subprocess_command_prefix: sandbox_backend.command_prefix(chdir: sandbox_path, env: merged_env),
              provider: @verifier_provider
            )

            @report_generator.generate(
              scenario: scenario,
              verifier_output: verifier_response[:text],
              report_dir: report_dir,
              provider: @verifier_provider,
              started_at: started_at,
              completed_at: Time.now,
              metadata: base_metadata(
                report_dir,
                runner_observations: runner_observations,
                artifact_contract: artifact_contract
              )
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

          def run_llm(prompt_path:, system_path:, output_path:, cli_args:, env_vars:, subprocess_command_prefix:, provider:)
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
              subprocess_command_prefix: subprocess_command_prefix,
              working_dir: sandbox_dir
            )
          end

          def write_tc_manifests(report_dir, scenario, test_cases:)
            selected = select_test_cases(scenario, test_cases)
            selected.each do |test_case|
              manifest = {
                tc_id: test_case.tc_id,
                title: test_case.title,
                declared_artifacts: Array(test_case.declared_artifacts),
                optional_artifacts: Array(test_case.optional_artifacts),
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

          def snapshot_artifacts(report_dir, sandbox_path, scenario, test_cases:)
            snapshot = select_test_cases(scenario, test_cases).to_h do |test_case|
              required = Array(test_case.declared_artifacts).sort
              optional = Array(test_case.optional_artifacts).sort
              present_required = required.select { |path| File.exist?(File.join(sandbox_path, path)) }
              present_optional = optional.select { |path| File.exist?(File.join(sandbox_path, path)) }
              missing_required = required - present_required

              [test_case.tc_id, {
                "present_artifacts" => (present_required + present_optional).sort,
                "required_artifacts" => required,
                "present_required_artifacts" => present_required,
                "missing_required_artifacts" => missing_required,
                "optional_artifacts" => optional,
                "present_optional_artifacts" => present_optional
              }]
            end
            File.write(File.join(report_dir, "artifact-snapshot.json"), JSON.pretty_generate(snapshot))
            snapshot
          end

          def select_test_cases(scenario, test_cases)
            return Array(scenario.test_cases) if test_cases.nil? || test_cases.empty?

            wanted = test_cases.map { |value| value.to_s.upcase }
            Array(scenario.test_cases).select { |tc| wanted.include?(tc.tc_id.to_s.upcase) }
          end

          def base_metadata(report_dir, runner_observations: nil, artifact_contract: nil)
            metadata = {
              "runner_provider" => @provider,
              "verifier_provider" => @verifier_provider,
              "report_dir" => report_dir
            }
            if runner_observations && !runner_observations.empty?
              metadata["runner_observations"] = runner_observations
            end
            if artifact_contract
              metadata["missing_required_artifacts"] = artifact_contract.to_h.transform_values do |entry|
                Array(entry["missing_required_artifacts"])
              end.reject { |_tc_id, paths| paths.empty? }
            end
            metadata
          end

          def sanitize_subprocess_env(env_vars)
            sanitized = env_vars.reject { |key, _value| AMBIENT_TMUX_ENV_VARS.include?(key.to_s) }
            AMBIENT_TMUX_ENV_VARS.each { |key| sanitized[key] = nil }
            sanitized
          end

          def prepared_sandbox?(sandbox_path, env_vars)
            return false unless env_vars.is_a?(Hash) && !env_vars.empty?

            env_root = env_vars["PROJECT_ROOT_PATH"] || env_vars[:PROJECT_ROOT_PATH]
            return false if env_root.to_s.strip.empty?

            File.expand_path(env_root) == File.expand_path(sandbox_path)
          end

          def extract_runner_observations(text)
            Atoms::SkillResultParser.parse(text)[:observations].to_s
          rescue Atoms::ResultParser::ParseError
            ""
          end
        end
      end
    end
  end
end
