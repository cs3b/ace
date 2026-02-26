# frozen_string_literal: true

require "time"
require "ace/b36ts"
require_relative "../models/simulation_session"
require_relative "../molecules/simulation_session_store"
require_relative "task_manager"
require_relative "../molecules/idea_loader"

module Ace
  module Taskflow
    module Organisms
      # Executes framework-level next-phase simulations and persists run artifacts.
      class NextPhaseSimulationRunner
        VALID_MODES = %w[draft plan work].freeze

        def initialize(session_store: nil, task_manager: nil, idea_loader: nil, time_provider: Time, stage_executor: nil)
          @session_store = session_store || Molecules::SimulationSessionStore.new
          @task_manager = task_manager || Organisms::TaskManager.new
          @idea_loader = idea_loader || Molecules::IdeaLoader.new
          @time_provider = time_provider
          @stage_executor = stage_executor
        end

        def run(source:, modes:, no_writeback: false)
          resolved_source = resolve_source!(source)
          normalized_modes = normalize_modes(modes)
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

          stage_outputs = []
          current_stage = nil

          normalized_modes.each do |mode|
            current_stage = mode
            stage_filename = stage_filename_for(resolved_source[:type], mode)
            stage_payload = execute_stage(resolved_source: resolved_source, mode: mode, run_id: run_id)
            stage_path = @session_store.write_yaml_artifact(session_dir, stage_filename, stage_payload)
            stage_outputs << { mode: mode, file: File.basename(stage_path), status: "ok" }
          end

          synthesis_path = @session_store.write_yaml_artifact(
            session_dir,
            "synthesis.yml",
            {
              run_id: run_id,
              status: "ok",
              stage_count: stage_outputs.length,
              stages: stage_outputs,
              findings: [],
              note: "Framework contract run. Stage-specific synthesis content is added in follow-up subtasks."
            }
          )

          preview_path = @session_store.write_markdown_artifact(
            session_dir,
            "writeback-preview.md",
            build_writeback_preview(resolved_source: resolved_source, modes: normalized_modes, no_writeback: no_writeback)
          )

          summary_path = @session_store.write_markdown_artifact(
            session_dir,
            "run-summary.md",
            build_success_summary(
              run_id: run_id,
              resolved_source: resolved_source,
              modes: normalized_modes,
              stage_outputs: stage_outputs,
              no_writeback: no_writeback
            )
          )

          finished_at = @time_provider.now.utc
          session = session.with_updates(
            status: "done",
            finished_at: finished_at,
            artifacts: {
              request: File.basename(request_path),
              stages: stage_outputs.map { |stage| stage[:file] },
              synthesis: File.basename(synthesis_path),
              writeback_preview: File.basename(preview_path),
              summary: File.basename(summary_path)
            }
          )

          {
            run_id: run_id,
            session_dir: session_dir,
            summary_path: summary_path,
            session: session.to_h
          }
        rescue StandardError => e
          persist_failure_artifacts(
            run_id: run_id,
            session_dir: session_dir,
            source: source,
            modes: modes,
            failed_stage: current_stage,
            error: e
          ) if defined?(run_id) && run_id && defined?(session_dir) && session_dir

          raise
        end

        private

        def normalize_modes(modes)
          parsed = Array(modes).flat_map { |value| value.to_s.split(",") }.map(&:strip).reject(&:empty?)
          parsed = %w[draft plan] if parsed.empty?

          invalid = parsed - VALID_MODES
          unless invalid.empty?
            raise ArgumentError, "Unsupported mode(s): #{invalid.join(', ')}. Valid modes: #{VALID_MODES.join(', ')}"
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

          task = @task_manager.show_task(normalized)
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

        def execute_stage(resolved_source:, mode:, run_id:)
          if @stage_executor
            return @stage_executor.call(resolved_source: resolved_source, mode: mode, run_id: run_id)
          end

          {
            run_id: run_id,
            source: source_excerpt(resolved_source),
            mode: mode,
            status: "simulated",
            findings: [],
            note: "Placeholder stage output for framework contract. Stage-specific logic is implemented in follow-up subtasks."
          }
        end

        def stage_filename_for(source_type, mode)
          "stage-#{source_type}-#{mode}.yml"
        end

        def build_writeback_preview(resolved_source:, modes:, no_writeback:)
          <<~MARKDOWN
            # Write-Back Preview

            - Source: `#{resolved_source[:input]}`
            - Source type: `#{resolved_source[:type]}`
            - Modes: `#{modes.join(',')}`
            - Write-back mode: `#{no_writeback ? 'disabled (--no-writeback)' : 'preview-only'}`

            No downstream task/plan artifacts were created by this simulation run.
          MARKDOWN
        end

        def build_success_summary(run_id:, resolved_source:, modes:, stage_outputs:, no_writeback:)
          stage_lines = stage_outputs.map { |stage| "- `#{stage[:file]}` (#{stage[:status]})" }.join("\n")

          <<~MARKDOWN
            # Run Summary

            - Run ID: `#{run_id}`
            - Source: `#{resolved_source[:input]}`
            - Source type: `#{resolved_source[:type]}`
            - Modes: `#{modes.join(',')}`
            - Write-back: `#{no_writeback ? 'disabled' : 'preview-only'}`
            - Status: `done`

            ## Stage Artifacts
            #{stage_lines}
          MARKDOWN
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
        rescue StandardError
          # Preserve original exception when failure reporting itself fails.
          nil
        end

        def source_excerpt(resolved_source)
          {
            input: resolved_source[:input],
            type: resolved_source[:type],
            kind: resolved_source[:kind],
            id: resolved_source[:id],
            path: resolved_source[:path]
          }.compact
        end
      end
    end
  end
end
