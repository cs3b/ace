# frozen_string_literal: true

require "yaml"
require "fileutils"
require "tempfile"
require "ace/support/fs"

module Ace
  module Overseer
    module Molecules
      class AssignmentLauncher
        def initialize(assignment_executor: nil)
          @assignment_executor = assignment_executor
        end

        def launch(worktree_path:, preset_name:, task_ref:, subtask_refs: nil, task_refs: nil)
          with_worktree_context(worktree_path) do
            preset = load_preset!(preset_name)
            params = build_parameters(preset, task_ref, subtask_refs, task_refs)
            validate_parameters!(preset, params)

            steps = Ace::Assign::Atoms::PresetExpander.expand(preset, params)
            session_name = "#{preset_name}-#{task_ref}"
            job_path = write_job_file(session_name: session_name, description: preset["description"], steps: steps)

            executor = @assignment_executor || Ace::Assign::Organisms::AssignmentExecutor.new
            result = executor.start(job_path)
            current = result[:current]

            {
              assignment_id: result[:assignment].id,
              first_step: current ? "#{current.number}-#{current.name}" : nil,
              job_path: job_path
            }
          end
        end

        def preset_supports_taskrefs?(preset_name:, worktree_path: nil)
          if worktree_path
            with_worktree_context(worktree_path) do
              parameter_names(load_preset!(preset_name)).include?("taskrefs")
            end
          else
            parameter_names(load_preset!(preset_name)).include?("taskrefs")
          end
        end

        private

        def build_parameters(preset, task_ref, subtask_refs, task_refs)
          param_defs = preset["parameters"] || {}
          params = {}
          params["taskref"] = task_ref if param_defs.key?("taskref")
          if param_defs.key?("taskrefs")
            params["taskrefs"] = if task_refs&.any?
                                   task_refs
                                 elsif subtask_refs&.any?
                                   subtask_refs
                                 else
                                   [task_ref]
                                 end
          end
          params
        end

        def parameter_names(preset)
          (preset["parameters"] || {}).keys
        end

        def validate_parameters!(preset, params)
          errors = Ace::Assign::Atoms::PresetExpander.validate_parameters(preset, params)
          return if errors.empty?

          raise Error, errors.join(", ")
        end

        def write_job_file(session_name:, description:, steps:)
          job = {
            "session" => {
              "name" => session_name,
              "description" => description || "Prepared by ace-overseer"
            },
            "steps" => steps
          }

          dir = File.join(Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current, ".ace-local", "overseer")
          FileUtils.mkdir_p(dir)
          path = File.join(dir, "#{session_name}-job.yml")
          payload = YAML.dump(job)
          Tempfile.create(["#{session_name}-job", ".yml"], dir) do |tmp|
            tmp.write(payload)
            tmp.flush
            tmp.fsync
            FileUtils.mv(tmp.path, path)
          end
          path
        end

        def load_preset!(preset_name)
          path = preset_paths(preset_name).find { |candidate| File.exist?(candidate) }
          raise Error, "Assignment preset not found: #{preset_name}" unless path

          YAML.safe_load_file(path)
        end

        def preset_paths(preset_name)
          filename = "#{preset_name}.yml"
          paths = [
            File.join(Dir.pwd, ".ace", "assign", "presets", filename),
            File.join(Dir.pwd, "ace-assign", ".ace-defaults", "assign", "presets", filename),
            File.join(Dir.pwd, ".ace-defaults", "assign", "presets", filename)
          ]

          gem_root = Gem.loaded_specs["ace-assign"]&.gem_dir
          if gem_root
            paths << File.join(gem_root, ".ace-defaults", "assign", "presets", filename)
          end

          paths.uniq
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
