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
          @task_loader = task_loader || Ace::Taskflow::Molecules::TaskLoader.new
          @config = config || Ace::Overseer.config
          @assignment_detector = assignment_detector
        end

        def call(task_ref:, cli_preset: nil, on_progress: nil)
          progress = on_progress || ->(_msg) {}

          progress.call("Loading task #{task_ref}...")
          task = @task_loader.find_task_by_reference(task_ref.to_s)
          raise Error, "Task not found: #{task_ref}" unless task

          preset_name = Atoms::PresetResolver.resolve(
            task_frontmatter: task[:metadata] || {},
            cli_preset: cli_preset,
            default: @config["default_assign_preset"] || "work-on-task"
          )

          progress.call("Provisioning worktree...")
          worktree = @worktree_provisioner.provision(task_ref)
          if worktree[:created]
            progress.call("Worktree created at #{worktree[:worktree_path]}")
          else
            progress.call("Worktree exists at #{worktree[:worktree_path]}")
          end

          window_name = Atoms::WindowNameFormatter.format(
            task_ref,
            format: @config["window_name_format"] || "t{task_id}"
          )
          session_name = @config["tmux_session_name"] || "ace"

          progress.call("Opening tmux window '#{window_name}' in session '#{session_name}'...")
          @tmux_window_opener.open(
            worktree_path: worktree[:worktree_path],
            window_name: window_name,
            session_name: session_name,
            preset: @config["window_preset"] || "cc"
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
                                  first_phase: existing.dig("current_phase", "number"),
                                  created: false
                                }
                              else
                                progress.call("Launching assignment (preset: #{preset_name})...")
                                launched = @assignment_launcher.launch(
                                  worktree_path: worktree[:worktree_path],
                                  preset_name: preset_name,
                                  task_ref: task_ref.to_s
                                )
                                launched.merge(created: true)
                              end

          {
            task_ref: task_ref.to_s,
            preset: preset_name,
            worktree_path: worktree[:worktree_path],
            branch: worktree[:branch],
            worktree_created: worktree[:created],
            window_name: window_name,
            assignment_id: assignment_result[:assignment_id],
            first_phase: assignment_result[:first_phase],
            assignment_created: assignment_result[:created]
          }
        end

        private

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
