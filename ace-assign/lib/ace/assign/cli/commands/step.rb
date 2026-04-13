# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Print instructions for the current, next, or an explicit step.
        class Step < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include AssignmentTarget

          desc "Show instructions for the current, next, or explicit step"

          argument :step, required: false, desc: "Exact step number to inspect"
          option :assignment, desc: "Target specific assignment ID"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(step: nil, **options)
            target = resolve_assignment_target(options)
            view = resolve_assignment_view(target)
            inspected = resolve_step(view, step, target)

            return if options[:quiet]

            if inspected
              puts inspected.instructions
            else
              puts no_work_message(view)
            end
          end

          private

          def resolve_step(view, explicit_step, target)
            if explicit_step && !explicit_step.to_s.strip.empty?
              step = view.state.find_by_number(explicit_step)
              raise StepErrors::NotFound, "Step #{explicit_step} not found in queue" unless step

              if target.scope && !target.scope.strip.empty? && !view.scoped_state.in_subtree?(target.scope, step.number)
                raise StepErrors::NotFound, "Step #{explicit_step} is outside subtree #{target.scope}"
              end

              return step
            end

            view.current_step
          end

          def no_work_message(view)
            state_label = view.scoped_state.assignment_state.to_s
            last_done = view.scoped_state.last_done ? "#{view.scoped_state.last_done.number} #{view.scoped_state.last_done.name}" : "none"
            [
              "Assignment: #{view.assignment.id} | Status: #{state_label} | Progress: #{view.scoped_state.done.size}/#{view.scoped_state.size} done",
              "Last done: #{last_done} | No current or next workable step"
            ].join("\n")
          end
        end
      end
    end
  end
end
