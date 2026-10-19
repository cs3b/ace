# frozen_string_literal: true

require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        class Commission < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Instantiate a role preset into the coworker run config"

          option :role, desc: "Role preset name (required)"
          option :task, desc: "Task reference that must resolve in this worktree (required)"
          option :assignment, desc: "Assignment id pinned to the role (required)"
          option :overseer, desc: "Overseer reporting address (required)"
          option :"start-prompt", desc: "Literal start prompt overriding the preset template"
          option :config, desc: "Config path (default from cascade: .ace-local/coworker/config.yml)"
          option :force, type: :boolean, default: false, desc: "Allow overwriting an existing config"
          option :"dry-run", type: :boolean, default: false,
            desc: "Render the resolved config without writing"
          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(orchestrator: nil)
            super()
            @orchestrator = orchestrator
          end

          def call(role: nil, task: nil, assignment: nil, overseer: nil, **options)
            role = role.to_s.strip
            task = task.to_s.strip
            assignment = assignment.to_s.strip
            overseer = overseer.to_s.strip
            required = [["--role", role], ["--task", task],
              ["--assignment", assignment], ["--overseer", overseer]].each_with_object([]) do |(flag, value), missing|
              missing << flag if value.empty?
            end
            unless required.empty?
              raise Ace::Support::Cli::Error,
                "#{required.join(', ')} #{required.size == 1 ? 'is' : 'are'} required. " \
                "Usage: ace-coworker commission --role worker --task <ref> --assignment <id> --overseer <addr>"
            end

            orchestrator = @orchestrator || build_orchestrator(options[:config])
            result = orchestrator.call(
              role: role, task: task, assignment: assignment, overseer: overseer,
              start_prompt: options[:"start-prompt"],
              force: options[:force] == true, dry_run: options[:"dry-run"] == true
            )

            return if options[:quiet]

            render(result, options[:format])
          rescue Ace::Coworker::Error => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def build_orchestrator(config_path)
            project_root = Molecules::ProjectRoot.new.resolve
            Organisms::CommissionOrchestrator.new(
              project_root: project_root,
              preset_loader: Molecules::RolePresetLoader.new(project_root: project_root),
              task_probe: Molecules::TaskProbe.new(project_root: project_root),
              assignment_metadata: Molecules::AssignmentMetadata.new(project_root: project_root),
              config_path: config_path
            )
          end

          def render(result, format)
            if format == "json"
              puts JSON.pretty_generate(result.to_h)
            else
              puts render_table(result)
            end
          end

          def render_table(result)
            lines = ["Coworker commission"]
            lines << "  role:          #{result.role} (preset source: #{result.preset_source})"
            lines << "  task:          #{result.task}"
            lines << "  assignment:    #{result.assignment}"
            lines << "  overseer:      #{result.overseer}"
            lines << "  config_path:   #{result.config_path}"
            lines << format("  result:        %s", result.dry_run ? "resolved (dry-run, nothing written)" : "written")
            result.config.each do |key, value|
              rendered = value.is_a?(Hash) ? value.map { |k, v| "#{k}=#{v}" }.join(" ") : value
              lines << "    #{key}: #{rendered}"
            end
            lines.join("\n")
          end
        end
      end
    end
  end
end
