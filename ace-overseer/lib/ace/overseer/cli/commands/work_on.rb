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

          def call(task:, preset: nil, **options)
            result = @orchestrator.call(task_ref: task, cli_preset: preset)

            return if options[:quiet]

            puts "Worktree ready for task #{result[:task_ref]}."
            puts "Worktree: #{result[:worktree_path]} (branch: #{result[:branch]})"
            puts "Tmux window opened: #{result[:window_name]}"
            if result[:assignment_created]
              puts "Assignment prepared (preset: #{result[:preset]})."
              puts "Assignment created: #{result[:assignment_id]}"
            else
              puts "Assignment already active in worktree: #{result[:assignment_id]}"
            end
            puts
            puts "Next step: switch to tmux window '#{result[:window_name]}' and run /ace:assign-drive"
          rescue StandardError => e
            raise Ace::Core::CLI::Error.new(e.message)
          end
        end
      end
    end
  end
end
