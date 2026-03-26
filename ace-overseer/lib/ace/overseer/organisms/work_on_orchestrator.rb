# frozen_string_literal: true

module Ace
  module Overseer
    module Organisms
      class WorkOnOrchestrator
        # B36TS subtask pattern: "8pp.t.q7w.a" (parent 9-char ID + dot + single char)
        SUBTASK_PATTERN = /^[0-9a-z]{3}\.[a-z]\.[0-9a-z]{3}\.[a-z0-9]$/

        def initialize(worktree_provisioner: nil, tmux_window_opener: nil, assignment_launcher: nil,
          task_loader: nil, config: nil, assignment_detector: nil)
          @worktree_provisioner = worktree_provisioner || Molecules::WorktreeProvisioner.new
          @tmux_window_opener = tmux_window_opener || Molecules::TmuxWindowOpener.new
          @assignment_launcher = assignment_launcher || Molecules::AssignmentLauncher.new
          @task_manager = task_loader || Ace::Task::Organisms::TaskManager.new
          @config = config || Ace::Overseer.config
          @assignment_detector = assignment_detector
        end

        def call(task_ref:, task_refs: nil, cli_preset: nil, on_progress: nil)
          progress = on_progress || ->(_msg) {}

          requested_refs = normalize_requested_refs(task_ref, task_refs)
          raise Error, "No valid task references provided" if requested_refs.empty?

          progress.call("Loading task #{requested_refs.join(", ")}...")
          resolved_refs, skipped_terminal = resolve_requested_refs(requested_refs)

          if resolved_refs.empty?
            raise Error, "All requested tasks are already terminal (done/skipped/cancelled): #{skipped_terminal.join(", ")}. No assignment created."
          end

          if skipped_terminal.any?
            progress.call("Skipped terminal tasks (done/skipped/cancelled): #{skipped_terminal.join(", ")}")
          end

          primary_ref = resolved_refs.first[:ref]
          primary_task = resolved_refs.first[:task]

          preset_name = Atoms::PresetResolver.resolve(
            task_frontmatter: primary_task.respond_to?(:metadata) ? (primary_task.metadata || {}) : {},
            cli_preset: cli_preset,
            default: @config["default_assign_preset"] || "work-on-task"
          )
          guard_multi_task_preset!(preset_name, requested_refs.length)

          expanded_taskrefs = expand_task_refs_in_order(resolved_refs)
          primary_subtask_refs = extract_subtask_refs(primary_task)
          tmux_preset = @config.dig("tmux_window_presets", preset_name)

          progress.call("Provisioning worktree...")
          worktree = @worktree_provisioner.provision(primary_ref)
          if worktree[:created]
            progress.call("Worktree created at #{worktree[:worktree_path]}")
          else
            progress.call("Worktree exists at #{worktree[:worktree_path]}")
          end

          progress.call("Opening tmux window...")
          @tmux_window_opener.open(
            worktree_path: worktree[:worktree_path],
            preset: tmux_preset
          )

          progress.call("Checking assignment status...")
          existing = if @assignment_detector
            @assignment_detector.call(worktree[:worktree_path])
          else
            existing_assignment(worktree[:worktree_path])
          end
          assignment_result = if existing
            progress.call("Assignment already active: #{existing.dig("assignment", "id")}")
            {
              assignment_id: existing.dig("assignment", "id"),
              first_step: existing.dig("current_step", "number"),
              created: false
            }
          else
            progress.call("Launching assignment (preset: #{preset_name})...")
            launched = @assignment_launcher.launch(
              worktree_path: worktree[:worktree_path],
              preset_name: preset_name,
              task_ref: primary_ref.to_s,
              subtask_refs: primary_subtask_refs,
              task_refs: expanded_taskrefs
            )
            launched.merge(created: true)
          end

          {
            task_ref: primary_ref.to_s,
            task_refs: expanded_taskrefs,
            preset: preset_name,
            worktree_path: worktree[:worktree_path],
            branch: worktree[:branch],
            worktree_created: worktree[:created],
            assignment_id: assignment_result[:assignment_id],
            first_step: assignment_result[:first_step],
            assignment_created: assignment_result[:created]
          }
        end

        private

        def extract_subtask_refs(task)
          subtasks = task.respond_to?(:subtasks) ? task.subtasks : nil
          return nil unless subtasks&.any?

          active = subtasks.reject { |st| Ace::Task::Atoms::TaskValidationRules.terminal_status?(st.status.to_s) }
          active.any? ? active.map(&:id) : nil
        end

        def normalize_requested_refs(task_ref, task_refs)
          raw = (task_refs && !task_refs.empty?) ? task_refs : [task_ref]
          raw
            .flat_map { |entry| entry.to_s.split(",") }
            .map(&:strip)
            .reject(&:empty?)
        end

        def resolve_requested_refs(requested_refs)
          resolved = []
          skipped_terminal = []

          requested_refs.each do |ref|
            is_subtask = subtask_ref?(ref)
            task = @task_manager.show(ref.to_s)
            raise Error, "Task not found: #{ref}" unless task

            if task.status == "draft"
              raise Error, "Task #{ref} has status 'draft' and has not been reviewed. " \
                           "Review the spec first with /as-task-review #{ref} " \
                           "(or ace-bundle wfi://task/review), then retry."
            end

            if Ace::Task::Atoms::TaskValidationRules.terminal_status?(task.status.to_s)
              skipped_terminal << ref.to_s
              next
            end

            resolved << {ref: ref.to_s, task: task, is_subtask: is_subtask}
          end

          [resolved, skipped_terminal]
        end

        def subtask_ref?(ref)
          ref.to_s.match?(SUBTASK_PATTERN)
        end

        def expand_task_refs_in_order(resolved_refs)
          resolved_refs.flat_map do |entry|
            ref = entry[:ref]
            task = entry[:task]

            if entry[:is_subtask]
              [ref]
            elsif task.respond_to?(:subtasks) && task.subtasks&.any?
              task.subtasks
                .reject { |st| Ace::Task::Atoms::TaskValidationRules.terminal_status?(st.status.to_s) }
                .map(&:id)
            else
              [ref]
            end
          end
        end

        def guard_multi_task_preset!(preset_name, input_count)
          return unless input_count > 1

          supports_taskrefs = @assignment_launcher.preset_supports_taskrefs?(preset_name: preset_name)
          return if supports_taskrefs

          raise Error,
            "Preset '#{preset_name}' accepts only single taskref. " \
            "Use a preset with `taskrefs` (e.g., --preset work-on-task)."
        end

        def existing_assignment(worktree_path)
          original_project_root = ENV["PROJECT_ROOT_PATH"]
          Dir.chdir(worktree_path) do
            ENV["PROJECT_ROOT_PATH"] = worktree_path.to_s
            Ace::Support::Fs::Molecules::ProjectRootFinder.clear_cache!
            Ace::Assign.reset_config!
            executor = Ace::Assign::Organisms::AssignmentExecutor.new
            result = executor.status
            {
              "assignment" => {
                "id" => result[:assignment].id,
                "name" => result[:assignment].name,
                "state" => result[:state].assignment_state.to_s
              },
              "current_step" => result[:current] && {
                "number" => result[:current].number,
                "name" => result[:current].name
              }
            }
          rescue Ace::Assign::AssignmentErrors::NoActive
            nil
          ensure
            ENV["PROJECT_ROOT_PATH"] = original_project_root
            Ace::Support::Fs::Molecules::ProjectRootFinder.clear_cache!
            Ace::Assign.reset_config!
          end
        end
      end
    end
  end
end
