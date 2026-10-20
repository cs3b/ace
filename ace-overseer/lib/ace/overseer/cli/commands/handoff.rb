# frozen_string_literal: true

module Ace
  module Overseer
    module CLI
      module Commands
        class Handoff < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Hand the task worktree to the next role in the sequence"

          option :task, aliases: ["-t"], desc: "Task reference whose worktree receives the next role"
          option :runtime, desc: "Terminal backend (auto, tmux, herdr)"
          option :dry_run, type: :boolean, default: false, desc: "Check handoff readiness without effects"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(orchestrator: nil, config: nil)
            super()
            @orchestrator = orchestrator || Organisms::HandoffOrchestrator.new
            @config = config
          end

          def call(task: nil, runtime: nil, dry_run: false, **options)
            selected_runtime = runtime || (@config || Ace::Overseer.config)["runtime"] || "auto"
            unless %w[auto tmux herdr].include?(selected_runtime)
              raise Ace::Support::Cli::Error, "unsupported runtime: #{selected_runtime}"
            end

            Atoms::RepoGuard.ensure_repo!

            task_ref = task.to_s.strip
            if task_ref.empty?
              raise Ace::Support::Cli::Error.new("--task is required. Usage: ace-overseer handoff --task <ref>")
            end

            progress = options[:quiet] ? nil : ->(msg) { puts msg }
            result = @orchestrator.call(
              task_ref: task_ref,
              dry_run: dry_run,
              on_progress: progress,
              runtime: selected_runtime
            )

            return if options[:quiet]

            if result[:status] == "sequence_complete"
              puts "Sequence complete. No role left to hand the worktree to."
              return
            end

            next_leg = result[:next]
            unless next_leg && next_leg["start_config"]
              raise Ace::Support::Cli::Error,
                "handoff result is missing the next leg start config - refusing to print a guessed command"
            end

            puts "Handoff ready. In the worktree terminal run:"
            puts "  #{Ace::Support::Cli::Toolchain.shell_command("ace-coworker", "start", "--config", next_leg["start_config"])}"
          rescue Ace::Support::Cli::Error
            raise
          rescue => e
            raise Ace::Support::Cli::Error.new(e.message)
          end
        end
      end
    end
  end
end
