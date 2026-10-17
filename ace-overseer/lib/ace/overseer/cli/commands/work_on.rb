# frozen_string_literal: true

module Ace
  module Overseer
    module CLI
      module Commands
        class WorkOn < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Start local task work"

          option :task, aliases: ["-t"], type: :array,
            desc: "Task reference(s), repeatable and comma-separated (e.g., 230 --task 231,232)"
          option :preset, aliases: ["-p"], desc: "Assignment preset name"
          option :runtime, desc: "Terminal backend (auto, tmux, herdr)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(orchestrator: nil, config: nil)
            super()
            @orchestrator = orchestrator || Organisms::WorkOnOrchestrator.new
            @config = config
          end

          def call(task: nil, preset: nil, runtime: nil, **options)
            raise Ace::Support::Cli::Error, "--work is obsolete; select task or preset" if options.key?(:work)
            selected_runtime = runtime || (@config || Ace::Overseer.config)["runtime"] || "auto"
            unless %w[auto tmux herdr].include?(selected_runtime)
              raise Ace::Support::Cli::Error, "unsupported runtime: #{selected_runtime}"
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
