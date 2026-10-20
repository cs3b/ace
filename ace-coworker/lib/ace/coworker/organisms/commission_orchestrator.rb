# frozen_string_literal: true

require "ace/support/cli/toolchain"

require "fileutils"
require "tmpdir"

module Ace
  module Coworker
    module Organisms
      # Orchestrates `ace-coworker commission`: expand a role preset plus the
      # commission identity (task, assignment, overseer) into the documented
      # .ace-local/coworker/config.yml. A single-role writer primitive for
      # the location ace-coworker already owns: no sequencing, no
      # active-driver detection, no role policies (those belong to the
      # planner, L4.2/L4.3).
      class CommissionOrchestrator
        Commission = Struct.new(
          :role, :task, :assignment, :overseer, :config_path, :config,
          :preset_source, :dry_run, :written,
          keyword_init: true
        ) do
            def to_h
              {
                "role" => role,
                "task" => task,
                "assignment" => assignment,
                "overseer" => overseer,
                "config_path" => config_path,
                "config" => config,
                "preset_source" => preset_source,
                "dry_run" => dry_run,
                "written" => written
              }
            end
          end

        # @param project_root [String] absolute project root
        # @param preset_loader [Molecules::RolePresetLoader]
        # @param task_probe [Molecules::TaskProbe]
        # @param assignment_metadata [Molecules::AssignmentMetadata]
        # @param config_path [String, nil] explicit target (absolute or
        #   root-relative); default from the config cascade
        def initialize(project_root:, preset_loader:, task_probe:, assignment_metadata:,
          config_path: nil, config_loader: nil)
          @project_root = project_root
          @preset_loader = preset_loader
          @task_probe = task_probe
          @assignment_metadata = assignment_metadata
          @config_loader = config_loader ||
            Molecules::ConfigLoader.new(project_root: project_root, defaults: Ace::Coworker.config)
          @config_path = config_path
        end

        # @return [Commission]
        # @raise [Error] on unknown role, identity mismatch, invalid
        #   assembly, a refused overwrite, a config path escaping the
        #   project root, or a directory config target
        def call(role:, task:, assignment:, overseer:, start_prompt: nil, force: false, dry_run: false)
          preset = @preset_loader.fetch(role)

          # Canonicalize the task identity first: the assignment match and
          # the written config use the resolved full id, so a short ref
          # (e.g. "ccc") commissioning the recorded task (8xh.t.ccc) is
          # accepted while a genuinely foreign task stays rejected.
          resolved = @task_probe.resolve(task)
          raise Error, "task '#{task}' not found in this worktree" if resolved.nil?

          canonical_task = resolved.id.to_s
          @assignment_metadata.verify_task_match!(assignment, canonical_task)

          prompt = start_prompt.to_s.strip.empty? ? render_prompt(preset, role, canonical_task, assignment, overseer) : start_prompt

          config = build_config(preset, role: role, task: canonical_task, assignment: assignment,
            overseer: overseer, prompt: prompt)
          errors = Atoms::ConfigSchema.errors(config)
          unless errors.empty?
            raise Error, "commissioned config is invalid: #{errors.join('; ')}"
          end

          target = resolve_target
          write_config(target, config, force: force) unless dry_run

          Commission.new(
            role: role, task: canonical_task, assignment: assignment, overseer: overseer,
            config_path: relativize(target), config: config,
            preset_source: preset["source"], dry_run: dry_run,
            written: dry_run ? false : true
          )
        end

        private

        def render_prompt(preset, role, task, assignment, overseer)
          Atoms::PromptTemplate.render(preset["start_prompt"],
            {"task" => task, "assignment" => assignment, "role" => role, "overseer" => overseer})
        end

        def build_config(preset, role:, task:, assignment:, overseer:, prompt:)
          config = {
            "role" => role,
            "instructions" => preset["instructions"],
            "start_prompt" => prompt,
            "task" => task,
            "assignment" => assignment,
            "overseer" => overseer
          }
          config["toolchain"] = "installed" if Ace::Support::Cli::Toolchain.installed?
          config["reporting"] = {"channel" => preset["reporting"]} unless preset["reporting"].to_s.empty?
          config["errors"] = {"on_failure" => preset["errors"]} unless preset["errors"].to_s.empty?
          config
        end

        def resolve_target
          target = @config_path ? File.expand_path(@config_path, @project_root) : @config_loader.config_path
          unless target.start_with?("#{@project_root}/")
            raise Error, "config path '#{relativize(target)}' escapes the project root"
          end

          target
        end

        def write_config(target, config, force:)
          if File.directory?(target)
            raise Error, "config path '#{relativize(target)}' is a directory; --config must name a file"
          end

          # The exist? -> mv sequence below has a TOCTOU window on the
          # overwrite refusal: commission is a single-planner local write
          # primitive, so concurrent writers on the same config are out of
          # scope by design; this check is a guard, not a hard guarantee.
          if File.exist?(target) && !force
            raise Error, "refusing to overwrite '#{relativize(target)}'; use --force"
          end

          FileUtils.mkdir_p(File.dirname(target))
          content = YAML.safe_dump(config)
          Dir.mktmpdir(".commission", File.dirname(target)) do |tmp|
            temp = File.join(tmp, "config.yml")
            File.write(temp, content)
            FileUtils.mv(temp, target)
          end
        end

        def relativize(path)
          path.start_with?(@project_root) ? path.delete_prefix("#{@project_root}/") : path
        end
      end
    end
  end
end
