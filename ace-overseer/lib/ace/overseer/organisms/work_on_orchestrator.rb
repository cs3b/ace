# frozen_string_literal: true

module Ace
  module Overseer
    module Organisms
      class WorkOnOrchestrator
        def initialize(worktree_provisioner: nil, tmux_window_opener: nil, assignment_launcher: nil,
                       task_loader: nil, config: nil, assignment_detector: nil)
          @worktree_provisioner = worktree_provisioner || Molecules::WorktreeProvisioner.new
          @tmux_window_opener = tmux_window_opener || Molecules::TmuxWindowOpener.new
          @assignment_launcher = assignment_launcher || Molecules::AssignmentLauncher.new
          @task_loader = task_loader || Ace::Taskflow::Molecules::TaskLoader.new(task_root_path)
          @config = config || Ace::Overseer.config
          @assignment_detector = assignment_detector
        end

        def call(task_ref:, task_refs: nil, cli_preset: nil, on_progress: nil)
          progress = on_progress || ->(_msg) {}

          requested_refs = normalize_requested_refs(task_ref, task_refs)
          raise Error, "No valid task references provided" if requested_refs.empty?

          progress.call("Loading task #{requested_refs.join(', ')}...")
          resolved_refs = resolve_requested_refs(requested_refs)
          primary_ref = requested_refs.first
          primary_task = resolved_refs.first[:task]

          preset_name = Atoms::PresetResolver.resolve(
            task_frontmatter: primary_task[:metadata] || {},
            cli_preset: cli_preset,
            default: @config["default_assign_preset"] || "work-on-task"
          )
          guard_multi_task_preset!(preset_name, requested_refs.length)

          expanded_taskrefs = expand_task_refs_in_order(resolved_refs)
          primary_subtask_refs = extract_subtask_refs(primary_task)

          progress.call("Provisioning worktree...")
          worktree = @worktree_provisioner.provision(primary_ref)
          if worktree[:created]
            progress.call("Worktree created at #{worktree[:worktree_path]}")
          else
            progress.call("Worktree exists at #{worktree[:worktree_path]}")
          end

          progress.call("Opening tmux window...")
          @tmux_window_opener.open(worktree_path: worktree[:worktree_path])

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
                                  first_phase: existing.dig("current_phase", "number"),
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
            first_phase: assignment_result[:first_phase],
            assignment_created: assignment_result[:created]
          }
        end

        private

        def task_root_path
          project_root = ENV["PROJECT_ROOT_PATH"]
          base = project_root ? File.expand_path(project_root) : Dir.pwd
          File.join(base, ".ace-taskflow")
        end

        def extract_subtask_refs(task)
          return nil unless task[:is_orchestrator] && task[:subtask_ids]&.any?

          task[:subtask_ids].filter_map { |id| Ace::Taskflow::Atoms::TaskReferenceParser.extract_number(id) }
        end

        def normalize_requested_refs(task_ref, task_refs)
          raw = task_refs && !task_refs.empty? ? task_refs : [task_ref]
          raw
            .flat_map { |entry| entry.to_s.split(",") }
            .map(&:strip)
            .reject(&:empty?)
        end

        def resolve_requested_refs(requested_refs)
          requested_refs.map do |ref|
            parsed = parse_task_ref!(ref)
            task = @task_loader.find_task_by_reference(ref.to_s)
            raise Error, "Task not found: #{ref}" unless task

            { ref: ref.to_s, task: task, parsed: parsed }
          end
        end

        def parse_task_ref!(ref)
          parsed = Ace::Taskflow::Atoms::TaskReferenceParser.parse(ref.to_s)
          raise Error, "Invalid task reference token: #{ref}" unless parsed

          parsed
        rescue ArgumentError => e
          raise Error, e.message
        end

        def expand_task_refs_in_order(resolved_refs)
          resolved_refs.flat_map do |entry|
            ref = entry[:ref]
            task = entry[:task]
            parsed = entry[:parsed]

            if parsed[:subtask]
              [ref]
            elsif task[:is_orchestrator] && task[:subtask_ids]&.any?
              extract_subtask_refs(task)
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
                "Use a preset with `taskrefs` (e.g., --preset work-on-tasks)."
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
              "current_phase" => result[:current] && {
                "number" => result[:current].number,
                "name" => result[:current].name
              }
            }
          rescue Ace::Assign::NoActiveAssignmentError
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
