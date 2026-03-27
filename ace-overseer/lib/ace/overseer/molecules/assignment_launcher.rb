# frozen_string_literal: true

require "ace/support/fs"

module Ace
  module Overseer
    module Molecules
      class AssignmentLauncher
        def initialize(assignment_executor: nil, task_manager: nil)
          @assignment_executor = assignment_executor
          @task_manager = task_manager
        end

        def launch(worktree_path:, preset_name:, task_ref:, subtask_refs: nil, task_refs: nil)
          with_worktree_context(worktree_path) do
            requested_refs = effective_task_refs(task_ref, subtask_refs, task_refs)
            requested_refs = [task_ref] unless preset_supports_taskrefs?(preset_name: preset_name)

            creator = Ace::Assign::Organisms::TaskAssignmentCreator.new(
              task_manager: @task_manager,
              executor: @assignment_executor
            )
            result = creator.call(
              task_refs: requested_refs,
              preset_name: preset_name,
              primary_task_ref: task_ref
            )
            current = result[:current]

            {
              assignment_id: result[:assignment].id,
              first_step: current ? "#{current.number}-#{current.name}" : nil,
              job_path: result[:job_path]
            }
          end
        rescue Ace::Support::Cli::Error => e
          raise Error, e.message
        end

        def preset_supports_taskrefs?(preset_name:, worktree_path: nil)
          if worktree_path
            with_worktree_context(worktree_path) do
              parameter_names(Ace::Assign::Atoms::PresetLoader.load(preset_name)).include?("taskrefs")
            end
          else
            parameter_names(Ace::Assign::Atoms::PresetLoader.load(preset_name)).include?("taskrefs")
          end
        rescue Ace::Support::Cli::Error => e
          raise Error, e.message
        end

        private

        def parameter_names(preset)
          (preset["parameters"] || {}).keys
        end

        def effective_task_refs(task_ref, subtask_refs, task_refs)
          return task_refs if task_refs&.any?
          return subtask_refs if subtask_refs&.any?

          [task_ref]
        end

        def with_worktree_context(worktree_path)
          original_project_root = ENV["PROJECT_ROOT_PATH"]
          Dir.chdir(worktree_path) do
            ENV["PROJECT_ROOT_PATH"] = worktree_path.to_s
            Ace::Support::Fs::Molecules::ProjectRootFinder.clear_cache!
            Ace::Assign.reset_config!
            yield
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
