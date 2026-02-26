# frozen_string_literal: true

require "fileutils"
require "time"
require "ace/b36ts"
require_relative "../models/simulation_session"
require_relative "../molecules/simulation_session_store"
require_relative "../molecules/simulation_synthesis_builder"
require_relative "../molecules/idea_simulation_writeback"
require_relative "../molecules/task_simulation_writeback"
require_relative "../molecules/next_phase_trigger_policy"
require_relative "../molecules/next_phase_stage_executor"
require_relative "task_manager"
require_relative "../molecules/idea_loader"

module Ace
  module Taskflow
    module Organisms
      # Executes framework-level next-phase simulations and persists run artifacts.
      class NextPhaseSimulationRunner
        VALID_MODES = %w[draft plan work].freeze

        def initialize(session_store: nil, task_manager: nil, idea_loader: nil, time_provider: Time, stage_executor: nil,
                       synthesis_builder: nil, idea_writeback: nil, task_writeback: nil, trigger_policy: nil)
          @session_store = session_store || Molecules::SimulationSessionStore.new
          @task_manager = task_manager || Organisms::TaskManager.new
          @idea_loader = idea_loader || Molecules::IdeaLoader.new
          @time_provider = time_provider
          @stage_executor = stage_executor || Molecules::NextPhaseStageExecutor.new
          @synthesis_builder = synthesis_builder || Molecules::SimulationSynthesisBuilder.new
          @idea_writeback = idea_writeback || Molecules::IdeaSimulationWriteback.new
          @task_writeback = task_writeback || Molecules::TaskSimulationWriteback.new
          @trigger_policy = trigger_policy || Molecules::NextPhaseTriggerPolicy.new
        end

        def run(source:, modes:, no_writeback: false, manual: true, cli_enable: false, cli_disable: false)
          resolved_source = resolve_source!(source)
          trigger = @trigger_policy.resolve(
            source_type: resolved_source[:type],
            manual: manual,
            cli_enable: cli_enable,
            cli_disable: cli_disable,
            cli_modes: modes
          )
          return build_skipped_result(source: resolved_source, trigger: trigger) unless trigger[:enabled]

          normalized_modes = normalize_modes(trigger[:modes], source_type: resolved_source[:type])
          run_id, run_started_at, session_dir, session, request_path = init_run_session(
            normalized_modes: normalized_modes, resolved_source: resolved_source, no_writeback: no_writeback
          )
          current_stage = nil

          stages_result = execute_stages(
            normalized_modes: normalized_modes, resolved_source: resolved_source,
            run_id: run_id, session_dir: session_dir,
            on_stage_start: ->(stage) { current_stage = stage }
          )

          current_stage = "writeback"

          session, summary_path = persist_run_artifacts(
            session: session, session_dir: session_dir, run_id: run_id,
            resolved_source: resolved_source, normalized_modes: normalized_modes,
            stages_result: stages_result, no_writeback: no_writeback, request_path: request_path
          )

          { run_id: run_id, session_dir: session_dir, summary_path: summary_path, session: session.to_h }
        rescue StandardError => e
          persist_failure_artifacts(
            run_id: run_id,
            session_dir: session_dir,
            source: source,
            modes: modes,
            failed_stage: current_stage,
            error: e
          ) if run_id && session_dir

          raise
        end

        private

        def init_run_session(normalized_modes:, resolved_source:, no_writeback:)
          run_id = Ace::B36ts.encode(@time_provider.now.utc)
          run_started_at = @time_provider.now.utc
          session_dir = @session_store.create_session_dir!(run_id)
          session = Models::SimulationSession.new(
            run_id: run_id,
            source: resolved_source,
            modes: normalized_modes,
            status: "in_progress",
            started_at: run_started_at
          )
          request_path = @session_store.write_yaml_artifact(
            session_dir,
            "request.yml",
            {
              run_id: run_id,
              source: resolved_source,
              modes: normalized_modes,
              no_writeback: !!no_writeback,
              started_at: run_started_at.iso8601
            }
          )
          [run_id, run_started_at, session_dir, session, request_path]
        end

        def execute_stages(normalized_modes:, resolved_source:, run_id:, session_dir:, on_stage_start: nil)
          stage_outputs = []
          stage_payloads = {}
          current_stage = nil
          stage_failure = nil

          normalized_modes.each do |mode|
            current_stage = mode
            on_stage_start&.call(mode)
            begin
              stage_filename = stage_filename_for(resolved_source[:type], mode)
              stage_payload = execute_stage(
                resolved_source: resolved_source,
                mode: mode,
                run_id: run_id,
                previous_stage_output: stage_payloads[stage_outputs.last&.dig(:mode)]
              )

              # Save prompts if returned (for introspection)
              save_stage_prompts(session_dir, mode, stage_payload)

              stage_path = @session_store.write_yaml_artifact(session_dir, stage_filename, stage_payload)
              stage_status = stage_payload[:status] || stage_payload["status"] || "ok"
              stage_outputs << { mode: mode, file: File.basename(stage_path), status: stage_status }
              stage_payloads[mode] = stage_payload

              # Propagate LLM-reported failures
              if stage_status == "failed"
                failure_detail = Array(stage_payload[:findings] || stage_payload["findings"]).first
                msg = failure_detail ? "LLM stage reported failed: #{failure_detail}" : "LLM stage reported failed status"
                stage_failure = { mode: mode, error: RuntimeError.new(msg) }
                break
              end
            rescue StandardError => e
              if partial_failure_for_mode?(resolved_source: resolved_source, mode: mode, stage_payloads: stage_payloads)
                stage_failure = { mode: mode, error: e }
                stage_outputs << { mode: mode, status: "failed", error: e.message }
                break
              end

              raise
            end
          end

          { stage_outputs: stage_outputs, stage_payloads: stage_payloads,
            current_stage: current_stage, stage_failure: stage_failure }
        end

        def save_stage_prompts(session_dir, mode, stage_payload)
          prompts_dir = File.join(session_dir, ".prompts")
          FileUtils.mkdir_p(prompts_dir)

          if stage_payload[:user_prompt]
            @session_store.write_markdown_artifact(
              session_dir,
              ".prompts/#{mode}-user.md",
              stage_payload[:user_prompt]
            )
          end
          if stage_payload[:system_prompt]
            @session_store.write_markdown_artifact(
              session_dir,
              ".prompts/#{mode}-system.md",
              stage_payload[:system_prompt]
            )
          end
        end

        def persist_run_artifacts(session:, session_dir:, run_id:, resolved_source:, normalized_modes:,
                                  stages_result:, no_writeback:, request_path:)
          stage_outputs = stages_result[:stage_outputs]
          stage_payloads = stages_result[:stage_payloads]
          stage_failure  = stages_result[:stage_failure]

          synthesis_payload = @synthesis_builder.build(
            run_id: run_id,
            source: resolved_source,
            stage_outputs: stage_outputs,
            stage_payloads: stage_payloads,
            partial: !stage_failure.nil?,
            failed_stage: stage_failure&.dig(:mode),
            error: stage_failure&.dig(:error)&.message,
            list_orders: synthesis_list_orders(resolved_source: resolved_source, modes: normalized_modes)
          )
          synthesis_path = @session_store.write_yaml_artifact(session_dir, "synthesis.yml", synthesis_payload)

          artifact_paths = write_stage_artifact_files(
            session_dir: session_dir,
            resolved_source: resolved_source,
            artifacts: synthesis_payload[:artifacts] || {}
          )

          writeback_preview_body = build_writeback_preview(
            resolved_source: resolved_source, modes: normalized_modes,
            no_writeback: no_writeback, synthesis: synthesis_payload, run_id: run_id,
            artifact_paths: artifact_paths
          )
          preview_path = @session_store.write_markdown_artifact(
            session_dir, "writeback-preview.md", writeback_preview_body
          )

          writeback_status = apply_writeback_if_needed(
            resolved_source: resolved_source, no_writeback: no_writeback,
            stage_failure: stage_failure, run_id: run_id,
            modes: normalized_modes, synthesis: synthesis_payload, preview_path: preview_path
          )

          summary_path = @session_store.write_markdown_artifact(
            session_dir,
            "run-summary.md",
            build_success_summary(
              run_id: run_id, resolved_source: resolved_source, modes: normalized_modes,
              stage_outputs: stage_outputs, no_writeback: no_writeback,
              partial: !stage_failure.nil?, writeback_status: writeback_status,
              artifact_paths: artifact_paths
            )
          )

          session = session.with_updates(
            status: stage_failure ? "partial" : "done",
            finished_at: @time_provider.now.utc,
            artifacts: {
              request: File.basename(request_path),
              stages: stage_outputs.map { |s| s[:file] }.compact,
              synthesis: File.basename(synthesis_path),
              stage_artifacts: artifact_paths.map { |p| File.basename(p) },
              writeback_preview: File.basename(preview_path),
              summary: File.basename(summary_path)
            },
            failed_stage: stage_failure&.dig(:mode),
            error: stage_failure&.dig(:error)&.message
          )

          [session, summary_path]
        end

        def normalize_modes(modes, source_type:)
          parsed = Array(modes).flat_map { |value| value.to_s.split(",") }.map(&:strip).reject(&:empty?)
          parsed = %w[draft plan] if parsed.empty?
          parsed = parsed.uniq

          invalid = parsed - VALID_MODES
          unless invalid.empty?
            raise ArgumentError, "Unsupported mode(s): #{invalid.join(', ')}. Valid modes: #{VALID_MODES.join(', ')}"
          end

          if source_type == "idea"
            unless parsed.sort == %w[draft plan]
              raise ArgumentError, "Idea source requires modes draft,plan"
            end
            parsed = %w[draft plan]
          end

          if source_type == "task" && parsed.include?("work") && !parsed.include?("plan")
            raise ArgumentError, "Work mode requires prerequisite plan context. Use modes plan,work."
          end

          parsed
        end

        def resolve_source!(source)
          if source.nil? || source.to_s.strip.empty?
            raise ArgumentError, "Missing --source. Provide a task ref, idea ref, or artifact path."
          end

          normalized = source.to_s.strip
          if File.exist?(normalized)
            type = infer_source_type_from_path(normalized)
            return {
              input: normalized,
              type: type,
              kind: "path",
              path: File.expand_path(normalized)
            }
          end

          task = begin
            @task_manager.show_task(normalized)
          rescue Ace::Core::CLI::Error, ArgumentError, KeyError
            nil
          end
          if task
            return {
              input: normalized,
              type: "task",
              kind: "task_ref",
              id: task[:id] || normalized,
              path: task[:path]
            }
          end

          idea = @idea_loader.find_by_reference(normalized)
          if idea
            return {
              input: normalized,
              type: "idea",
              kind: "idea_ref",
              id: idea[:id] || normalized,
              path: idea[:file_path] || idea[:path]
            }
          end

          raise ArgumentError, "Source '#{normalized}' not found. Provide an existing path, task reference, or idea reference."
        end

        def infer_source_type_from_path(path)
          return "idea" if path.include?("/ideas/") || path.end_with?(".idea.s.md")

          "task"
        end

        def execute_stage(resolved_source:, mode:, run_id:, previous_stage_output: nil)
          @stage_executor.call(
            resolved_source: resolved_source,
            mode: mode,
            run_id: run_id,
            previous_stage_output: previous_stage_output
          )
        end

        def stage_filename_for(source_type, mode)
          "stage-#{source_type}-#{mode}.yml"
        end

        def build_writeback_preview(resolved_source:, modes:, no_writeback:, synthesis:, run_id:, artifact_paths: [])
          full_preview = if resolved_source[:type] == "idea"
            @idea_writeback.build_full_preview(run_id: run_id, modes: modes, synthesis: synthesis)
          elsif resolved_source[:type] == "task"
            @task_writeback.build_full_preview(run_id: run_id, modes: modes, synthesis: synthesis)
          else
            "No write-back section generated (source type: #{resolved_source[:type]})."
          end

          artifact_section = if artifact_paths.any?
            artifact_lines = artifact_paths.map { |p| "- `#{File.basename(p)}`" }.join("\n")
            "\n## Generated Artifact Files\n\n#{artifact_lines}\n"
          else
            ""
          end

          <<~MARKDOWN
            # Write-Back Preview

            - Source: `#{resolved_source[:input]}`
            - Source type: `#{resolved_source[:type]}`
            - Modes: `#{modes.join(',')}`
            - Write-back mode: `#{no_writeback ? 'disabled (--dry-run)' : 'enabled'}`
            #{artifact_section}
            ## Preview Content

            #{full_preview}
          MARKDOWN
        end

        def build_success_summary(run_id:, resolved_source:, modes:, stage_outputs:, no_writeback:, partial:,
                                  writeback_status:, artifact_paths: [])
          stage_lines = stage_outputs.map { |stage| "- `#{stage[:file]}` (#{stage[:status]})" }.join("\n")

          artifact_section = if artifact_paths.any?
            artifact_lines = artifact_paths.map { |p| "- `#{File.basename(p)}`" }.join("\n")
            "\n## Generated Artifacts\n#{artifact_lines}"
          else
            ""
          end

          <<~MARKDOWN
            # Run Summary

            - Run ID: `#{run_id}`
            - Source: `#{resolved_source[:input]}`
            - Source type: `#{resolved_source[:type]}`
            - Modes: `#{modes.join(',')}`
            - Write-back: `#{writeback_status}`
            - Status: `#{partial ? 'partial' : 'done'}`

            ## Stage Artifacts
            #{stage_lines}#{artifact_section}
          MARKDOWN
        end

        def write_stage_artifact_files(session_dir:, resolved_source:, artifacts:)
          source_type = resolved_source[:type]
          artifacts.filter_map do |mode_name, artifact_content|
            next if artifact_content.to_s.strip.empty?

            filename = "stage-#{source_type}-#{mode_name}-artifact.md"
            @session_store.write_markdown_artifact(session_dir, filename, artifact_content.to_s)
          end
        end

        def apply_writeback_if_needed(resolved_source:, no_writeback:, stage_failure:, run_id:, modes:, synthesis:, preview_path:)
          return "disabled" if no_writeback
          return "skipped (unsupported source)" unless %w[idea task].include?(resolved_source[:type])
          return "skipped (partial synthesis)" if stage_failure

          if resolved_source[:type] == "idea"
            @idea_writeback.apply(
              path: resolved_source[:path],
              run_id: run_id,
              modes: modes,
              synthesis: synthesis
            )
          else
            @task_writeback.apply(
              path: resolved_source[:path],
              run_id: run_id,
              modes: modes,
              synthesis: synthesis
            )
          end
          "applied"
        rescue StandardError => e
          raise e.class,
                "Write-back failed for '#{resolved_source[:path]}': #{e.message}. " \
                "Apply changes manually using preview at '#{preview_path}'.",
                e.backtrace
        end

        def partial_failure_for_mode?(resolved_source:, mode:, stage_payloads:)
          return true if resolved_source[:type] == "idea" && mode == "plan" && stage_payloads.key?("draft")
          return true if resolved_source[:type] == "task" && mode == "work" && stage_payloads.key?("plan")

          false
        end

        def synthesis_list_orders(resolved_source:, modes:)
          return {} unless resolved_source[:type] == "idea"

          normalized_modes = Array(modes).map(&:to_s)
          return {} unless normalized_modes.include?("draft") && normalized_modes.include?("plan")

          { questions: :reverse, refinements: :reverse }
        end

        def persist_failure_artifacts(run_id:, session_dir:, source:, modes:, failed_stage:, error:)
          @session_store.write_yaml_artifact(
            session_dir,
            "run-failure.yml",
            {
              run_id: run_id,
              source: source,
              modes: Array(modes),
              failed_stage: failed_stage,
              status: "failed",
              error: error.message,
              error_class: error.class.to_s,
              failed_at: @time_provider.now.utc.iso8601
            }
          )

          @session_store.write_markdown_artifact(
            session_dir,
            "run-summary.md",
            <<~MARKDOWN
              # Run Summary

              - Run ID: `#{run_id}`
              - Status: `failed`
              - Failed stage: `#{failed_stage || "preflight"}`
              - Error: `#{error.message}`

              A failure artifact was written to `run-failure.yml`.
            MARKDOWN
          )
        rescue StandardError => reporting_error
          # Preserve original exception when failure reporting itself fails.
          warn "Warning: failed to persist failure artifacts: #{reporting_error.message}" if $DEBUG
          nil
        end

        def build_skipped_result(source:, trigger:)
          {
            skipped: true,
            reason: "Next-phase simulation disabled by trigger policy",
            source: source,
            trigger: trigger
          }
        end
      end
    end
  end
end
