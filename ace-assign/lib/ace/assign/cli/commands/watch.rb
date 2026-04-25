# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Inspect watcher scope state and report deterministic stop/failure boundaries.
        class Watch < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include AssignmentTarget

          DEFAULT_POLL_INTERVAL = 300

          desc "Watch assignment or subtree continuation state"

          option :assignment, desc: "Target specific assignment ID"
          option :root, desc: "Watch a specific fork subtree root (e.g., 010.01)"
          option :poll_interval, type: :integer, desc: "Polling interval in seconds"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(**options)
            poll_interval = normalize_poll_interval(options[:poll_interval])
            target = resolve_assignment_target(options)
            executor = build_executor_for_target(target)
            result = executor.status
            assignment = result[:assignment]
            state = result[:state]
            current = result[:current]

            if scoped_watch?(target, options[:root])
              watch_scoped(
                assignment: assignment,
                state: state,
                current: current,
                target: target,
                explicit_root: options[:root],
                poll_interval: poll_interval,
                quiet: options[:quiet]
              )
            else
              watch_assignment(
                assignment: assignment,
                state: state,
                poll_interval: poll_interval,
                quiet: options[:quiet]
              )
            end
          end

          private

          def normalize_poll_interval(raw)
            value = raw.nil? ? DEFAULT_POLL_INTERVAL : raw
            interval = Integer(value)
            raise Error, "Poll interval must be a positive integer." unless interval.positive?

            interval
          rescue ArgumentError, TypeError
            raise Error, "Poll interval must be a positive integer."
          end

          def scoped_watch?(target, explicit_root)
            !explicit_root.to_s.strip.empty? || !target.scope.to_s.strip.empty?
          end

          def watch_scoped(assignment:, state:, current:, target:, explicit_root:, poll_interval:, quiet:)
            root_step = resolve_root_step(state, current, explicit_root, target.scope)
            ensure_root_is_fork!(root_step)
            scope_ref = "#{assignment.id}@#{root_step.number}"

            print_startup(scope_ref, poll_interval, quiet: quiet)

            if state.subtree_failed?(root_step.number)
              failed_refs = failed_step_refs(state.subtree_steps(root_step.number))
              raise Error, "Watched scope #{scope_ref} has failed work: #{failed_refs}"
            end

            if state.subtree_complete?(root_step.number)
              puts "Watch target #{scope_ref} is already complete." unless quiet
              return
            end

            boundary = inline_manual_boundary_for_subtree(state, root_step.number)
            unless remaining_fork_work_in_subtree?(state, root_step.number)
              if boundary
                puts "No fork work remains in watched scope #{scope_ref}. Remaining inline/manual boundary: #{boundary.number} #{boundary.name}." unless quiet
              else
                puts "No fork work remains in watched scope #{scope_ref}." unless quiet
              end
              return
            end

            raise Error, "Watched scope #{scope_ref} still has fork work remaining."
          end

          def watch_assignment(assignment:, state:, poll_interval:, quiet:)
            assignment_ref = assignment.id
            print_startup(assignment_ref, poll_interval, quiet: quiet)

            if state.failed.any?
              raise Error, "Watched assignment #{assignment_ref} has failed work: #{failed_step_refs(state.failed)}"
            end

            if state.complete?
              puts "Watch target #{assignment_ref} is already complete." unless quiet
              return
            end

            boundary = inline_manual_boundary_for_assignment(state)
            unless remaining_fork_work_in_assignment?(state)
              if boundary
                puts "No fork work remains in watched assignment #{assignment_ref}. Remaining inline/manual boundary: #{boundary.number} #{boundary.name}." unless quiet
              else
                puts "No fork work remains in watched assignment #{assignment_ref}." unless quiet
              end
              return
            end

            raise Error, "Watched assignment #{assignment_ref} still has fork work remaining."
          end

          def print_startup(target_ref, poll_interval, quiet:)
            return if quiet

            puts "Watching #{target_ref} (poll interval: #{poll_interval}s)"
          end

          def failed_step_refs(steps)
            steps.select { |step| step.status == :failed }.map { |step| "#{step.number} #{step.name}" }.join(", ")
          end

          def remaining_fork_work_in_subtree?(state, root_number)
            state.subtree_steps(root_number).any? do |step|
              next false if step.number == root_number

              step.fork? && %i[pending active].include?(step.status)
            end
          end

          def inline_manual_boundary_for_subtree(state, root_number)
            active_boundary = state.active_in_subtree(root_number).find do |step|
              step.number != root_number && !step.fork?
            end
            return active_boundary if active_boundary

            next_step = state.next_workable_in_subtree(root_number)
            return next_step if next_step && !next_step.fork?

            nil
          end

          def remaining_fork_work_in_assignment?(state)
            state.steps.any? { |step| step.fork? && %i[pending active].include?(step.status) }
          end

          def inline_manual_boundary_for_assignment(state)
            active_boundary = state.active_steps.find { |step| !step.fork? }
            return active_boundary if active_boundary

            next_step = state.next_workable
            return next_step if next_step && !next_step.fork?

            nil
          end
        end
      end
    end
  end
end
