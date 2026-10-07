# frozen_string_literal: true

require_relative "../../organisms/launch_recovery"
require_relative "../../organisms/protected_work_on"

module Ace
  module Overseer
    module CLI
      module Commands
        class WorkOn < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Start local task work or retain one original protected launch"

          option :task, aliases: ["-t"], type: :array,
            desc: "Task reference(s), repeatable and comma-separated (e.g., 230 --task 231,232)"
          option :recover_request, desc: "Read retained protected invocation input and original canonical reservation"
          option :preset, aliases: ["-p"], desc: "Assignment preset name"
          option :runtime, desc: "Terminal backend (auto, tmux, herdr)"
          option :project, desc: "Explicit protected project ID"
          option :base_head, desc: "Explicit reviewed code base (must match current source HEAD)"
          option :mutation, desc: "Stable retained protected invocation ID"
          option :dependency_report, type: :array, desc: "Selected task:assignment:step report identities"
          option :agent, desc: "Exact visible protected mapping ID (requires project)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(orchestrator: nil, recovery: nil, protected_work_on: nil, config: nil)
            super()
            @recovery = recovery || Organisms::LaunchRecovery.new
            @orchestrator = orchestrator || Organisms::WorkOnOrchestrator.new
            @protected_work_on = protected_work_on || Organisms::ProtectedWorkOn.new
            @config = config
          end

          def call(task: nil, preset: nil, runtime: nil, project: nil, agent: nil, mutation: nil, base_head: nil, dependency_report: nil, recover_request: nil, **options)
            raise Ace::Support::Cli::Error, "--work is obsolete; select task/project or retained request" if options.key?(:work)
            if recover_request
              if task || preset || project || agent || runtime || mutation || base_head || dependency_report
                raise Ace::Support::Cli::Error, "--recover-request cannot be combined with launch mode overrides"
              end
              # Retained identity/canonical attribution remains mandatory even
              # under --quiet. This path never enters preparation or launch.
              puts JSON.generate(@recovery.call(path: recover_request))
              return
            end
            selected_runtime = runtime || (@config || Ace::Overseer.config)["runtime"] || "auto"
            raise Ace::Support::Cli::Error, "unsupported runtime: #{selected_runtime}" unless %w[auto tmux herdr].include?(selected_runtime)
            if project
              refs = normalize_task_refs(task)
              raise Ace::Support::Cli::Error, "Protected launch requires exactly one reviewed leaf task and no preset override" unless refs.one? && preset.nil?
              reports = Array(dependency_report).map do |entry|
                fields = entry.split(":", -1)
                raise Ace::Support::Cli::Error, "Report identity must be task:assignment:step" unless fields.size == 3 && fields.none?(&:empty?)
                %w[task_id assignment_id number].zip(fields).to_h
              end
              report = ->(identity) { $stdout.write(JSON.generate(identity) + "\n"); $stdout.flush }
              result = @protected_work_on.start(task_ref: refs.first, project: project, agent: agent, runtime: selected_runtime,
                dependency_reports: reports, mutation_id: mutation, base_head: base_head, report: report)
              child = result.fetch("child")
              begin
                puts JSON.generate("type" => "original_launch_observation", "pid" => child.pid, "state" => child.state,
                  "ready" => child.ready, "error" => child.error)
                $stdout.flush
              ensure
                # An output failure after creation cannot discard the original
                # living child or turn local observation into canonical release.
                @protected_work_on.serve(child)
              end
              return
            end
            if agent || mutation || base_head || dependency_report
              raise Ace::Support::Cli::Error, "Protected mapping/invocation/report selection requires --project"
            end

            Atoms::RepoGuard.ensure_repo!

            task_refs = normalize_task_refs(task)
            if task_refs.empty?
              raise Ace::Support::Cli::Error.new("--task is required. Usage: ace-overseer work-on --task <ref>")
            end

            progress = options[:quiet] ? nil : ->(msg) { puts msg }
            @orchestrator.call(
              task_ref: task_refs.first,
              task_refs: task_refs,
              cli_preset: preset,
              on_progress: progress, runtime: selected_runtime
            )

            return if options[:quiet]

            puts "Done. Switch to tmux window and run /ace-assign-drive"
          rescue Ace::Support::Cli::Error
            raise
          rescue => e
            raise Ace::Support::Cli::Error.new(e.message)
          end

          private

          def normalize_task_refs(raw_task)
            Array(raw_task)
              .flat_map { |entry| entry.to_s.split(",") }
              .map(&:strip)
              .reject(&:empty?)
          end
        end
      end
    end
  end
end
