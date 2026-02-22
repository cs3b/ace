# frozen_string_literal: true

module Ace
  module Overseer
    module CLI
      module Commands
        class WorkOn < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Create worktree, open tmux window, and prepare assignment"

          option :task, aliases: ["-t"], required: true, desc: "Task reference (e.g., 230)"
          option :preset, aliases: ["-p"], desc: "Assignment preset name"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def initialize(orchestrator: nil)
            super()
            @orchestrator = orchestrator || Organisms::WorkOnOrchestrator.new
          end

          def call(task: nil, preset: nil, **options)
            if task.to_s.strip.empty?
              raise Ace::Core::CLI::Error.new("--task is required. Usage: ace-overseer work-on --task <ref>")
            end

            progress = options[:quiet] ? nil : ->(msg) { puts msg }
            result = @orchestrator.call(task_ref: task, cli_preset: preset, on_progress: progress)

            return if options[:quiet]

            puts "Done. Switch to tmux window and run /ace-assign-drive"
          rescue Ace::Core::CLI::Error
            raise
          rescue StandardError => e
            raise Ace::Core::CLI::Error.new(e.message)
          end
        end
      end
    end
  end
end
