# frozen_string_literal: true

require "ace/task"
require "fileutils"
require "securerandom"
require "tempfile"
require "yaml"

require_relative "../atoms/preset_loader"
require_relative "../atoms/preset_expander"

module Ace
  module Assign
    module Organisms
      class TaskAssignmentCreator
        DEFAULT_PRESET = "work-on-task"
        SUBTASK_PATTERN = /^[0-9a-z]{3}\.[a-z]\.[0-9a-z]{3}\.[a-z0-9]$/

        def initialize(task_manager: nil, executor: nil)
          @task_manager = task_manager || Ace::Task::Organisms::TaskManager.new
          @executor = executor || AssignmentExecutor.new
        end

        def call(task_refs:, preset_name: DEFAULT_PRESET, primary_task_ref: nil)
          requested_refs = normalize_requested_refs(task_refs)
          raise Ace::Support::Cli::Error, "--task requires at least one task reference" if requested_refs.empty?

          preset = Atoms::PresetLoader.load(preset_name)
          resolved_refs, skipped_terminal = resolve_requested_refs(requested_refs)

          if resolved_refs.empty?
            raise Ace::Support::Cli::Error,
              "All requested tasks are already terminal (done/skipped/cancelled): #{skipped_terminal.join(', ')}. No assignment created."
          end

          primary_ref = primary_task_ref.to_s.strip
          primary_ref = resolved_refs.first[:ref] if primary_ref.empty?

          guard_multi_task_preset!(preset_name, preset, resolved_refs.length)

          expanded_taskrefs = if preset_supports_taskrefs?(preset)
            expand_task_refs_in_order(resolved_refs)
          else
            [primary_ref]
          end

          params = build_parameters(preset, primary_ref, expanded_taskrefs)
          validate_parameters!(preset, params)

          steps = Atoms::PresetExpander.expand(preset, params)
          job_path = write_job_file(
            session_name: "#{preset_name}-#{primary_ref}",
            description: preset["description"],
            steps: steps
          )

          result = @executor.start(job_path)
          result.merge(
            skipped_terminal: skipped_terminal,
            primary_ref: primary_ref,
            task_refs: expanded_taskrefs,
            job_path: job_path
          )
        end

        private

        def normalize_requested_refs(task_refs)
          Array(task_refs)
            .flat_map { |entry| entry.to_s.split(",") }
            .map(&:strip)
            .reject(&:empty?)
        end

        def resolve_requested_refs(requested_refs)
          resolved = []
          skipped_terminal = []

          requested_refs.each do |ref|
            task = @task_manager.show(ref.to_s)
            raise Ace::Support::Cli::Error, "Task not found: #{ref}" unless task

            if task.status.to_s == "draft"
              raise Ace::Support::Cli::Error,
                "Task #{ref} has status 'draft' and has not been reviewed. " \
                "Review the spec first with /as-task-review #{ref} " \
                "(or ace-bundle wfi://task/review), then retry."
            end

            if Ace::Task::Atoms::TaskValidationRules.terminal_status?(task.status.to_s)
              skipped_terminal << ref.to_s
              next
            end

            resolved << {ref: ref.to_s, task: task, is_subtask: subtask_ref?(ref)}
          end

          [resolved, skipped_terminal]
        end

        def subtask_ref?(ref)
          ref.to_s.match?(SUBTASK_PATTERN)
        end

        def preset_supports_taskrefs?(preset)
          (preset["parameters"] || {}).key?("taskrefs")
        end

        def guard_multi_task_preset!(preset_name, preset, input_count)
          return unless input_count > 1 && !preset_supports_taskrefs?(preset)

          raise Ace::Support::Cli::Error,
            "Preset '#{preset_name}' accepts only single taskref. " \
            "Use a preset with `taskrefs` (e.g., --preset work-on-task)."
        end

        def expand_task_refs_in_order(resolved_refs)
          resolved_refs.flat_map do |entry|
            ref = entry[:ref]
            task = entry[:task]

            if entry[:is_subtask]
              [ref]
            elsif task.respond_to?(:subtasks) && task.subtasks&.any?
              active_subtasks = task.subtasks
                .reject { |st| Ace::Task::Atoms::TaskValidationRules.terminal_status?(st.status.to_s) }
                .map(&:id)
              active_subtasks.empty? ? [ref] : active_subtasks
            else
              [ref]
            end
          end
        end

        def build_parameters(preset, primary_ref, task_refs)
          param_defs = preset["parameters"] || {}
          params = {}
          params["taskref"] = primary_ref if param_defs.key?("taskref")
          params["taskrefs"] = task_refs if param_defs.key?("taskrefs")
          params
        end

        def validate_parameters!(preset, params)
          errors = Atoms::PresetExpander.validate_parameters(preset, params)
          return if errors.empty?

          raise Ace::Support::Cli::Error, errors.join(", ")
        end

        def write_job_file(session_name:, description:, steps:)
          job = {
            "session" => {
              "name" => session_name,
              "description" => description || "Prepared by ace-assign create --task"
            },
            "steps" => steps
          }

          dir = File.join(Ace::Assign.cache_dir, "jobs")
          FileUtils.mkdir_p(dir)
          path = File.join(dir, "#{session_name}-#{SecureRandom.hex(4)}-job.yml")
          payload = YAML.dump(job)

          Tempfile.create(["#{session_name}-job", ".yml"], dir) do |tmp|
            tmp.write(payload)
            tmp.flush
            tmp.fsync
            FileUtils.mv(tmp.path, path)
          end

          path
        end
      end
    end
  end
end
