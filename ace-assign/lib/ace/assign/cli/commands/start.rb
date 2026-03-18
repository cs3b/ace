# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Start a pending step
        class Start < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include AssignmentTarget

          desc "Start next workable pending step"

          argument :step, required: false, desc: "Step number to start (active assignment only)"
          option :assignment, desc: "Target specific assignment ID"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(step: nil, **options)
            if step && options[:assignment]
              raise Error, "Positional STEP targeting is only supported for active assignment. Use --assignment without STEP for cross-assignment start."
            end

            target = resolve_assignment_target(options)
            executor = build_executor_for_target(target)
            result = executor.start_step(step_number: step, fork_root: target.scope)

            return if options[:quiet]

            started = result[:started]
            puts "Step #{started.number} (#{started.name}) started"
            puts
            puts "Instructions:"
            puts started.instructions
          end
        end
      end
    end
  end
end
