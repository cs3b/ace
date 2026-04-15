# frozen_string_literal: true

require "yaml"

module Ace
  module Assign
    module CLI
      module Commands
        # Watches fork-enabled assignment work and continues through the next
        # forkable subtree without handing control back to the caller between
        # child completions. It intentionally stops when only inline/manual work
        # remains because that work belongs to /as-assign-drive rather than the
        # deterministic CLI.
        class Watch < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include AssignmentTarget

          DEFAULT_POLL_INTERVAL = 300

          desc "Watch active forked work and continue to the next forkable subtree"

          option :root, desc: "Watch a specific fork subtree root step number (e.g., 010.01)"
          option :assignment, desc: "Target specific assignment ID"
          option :poll_interval, type: :integer, default: DEFAULT_POLL_INTERVAL, desc: "Polling interval in seconds while a fork session is still running"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(fork_runner: nil, sleeper: nil, pid_alive_checker: nil)
            super()
            @fork_runner = fork_runner || method(:run_fork_subtree)
            @sleeper = sleeper || ->(seconds) { sleep(seconds) }
            @pid_alive_checker = pid_alive_checker || method(:pid_alive?)
          end

          def call(**options)
            poll_interval = normalize_poll_interval(options[:poll_interval])
            target = resolve_assignment_target(options)
            executor = build_executor_for_target(target)
            watch_root = resolve_watch_root(executor, target, options[:root])
            announced = false

            loop do
              result = executor.status
              assignment = result[:assignment]
              state = result[:state]

              root_step = watch_root ? state.find_by_number(watch_root) : nil
              announce_watch_scope(assignment.id, watch_root, quiet: options[:quiet]) unless announced || options[:quiet]
              announced = true

              fail_for_failed_state!(state, root_step)

              if watch_complete?(state, root_step)
                puts completion_message(assignment.id, watch_root) unless options[:quiet]
                return
              end

              if (active_root = active_fork_root(state, root_step))
                if fork_session_alive?(active_root)
                  puts "Waiting #{poll_interval}s for fork subtree #{active_root.number} to finish..." unless options[:quiet]
                  sleeper.call(poll_interval)
                  next
                end

                puts "Recovering fork subtree #{active_root.number} from assignment state..." unless options[:quiet]
                fork_runner.call(active_root.number, assignment.id, quiet: options[:quiet], debug: options[:debug])
                next
              end

              if (pending_root = pending_fork_root(state, root_step))
                puts "Launching fork subtree #{pending_root.number}..." unless options[:quiet]
                fork_runner.call(pending_root.number, assignment.id, quiet: options[:quiet], debug: options[:debug])
                next
              end

              puts stop_message(assignment.id, state, root_step) unless options[:quiet]
              return
            end
          end

          private

          attr_reader :fork_runner, :sleeper, :pid_alive_checker

          def normalize_poll_interval(value)
            raw = value
            raw = DEFAULT_POLL_INTERVAL if raw.nil? || raw.to_s.strip.empty?
            seconds = raw.to_i
            raise Ace::Support::Cli::Error, "--poll-interval must be greater than 0" if seconds <= 0

            seconds
          end

          def resolve_watch_root(executor, target, explicit_root)
            if explicit_root && target.scope && explicit_root.to_s.strip != target.scope.to_s.strip
              raise Ace::Support::Cli::Error, "Conflicting subtree roots: --root #{explicit_root} and scope #{target.scope}"
            end

            root_number = explicit_root.to_s.strip
            root_number = target.scope.to_s.strip if root_number.empty?
            return nil if root_number.empty?

            state = executor.status[:state]
            root_step = state.find_by_number(root_number)
            raise StepErrors::NotFound, "Step #{root_number} not found in queue" unless root_step
            raise Ace::Support::Cli::Error, "Step #{root_step.number} is not fork-enabled (context: fork missing)." unless root_step.fork?

            root_step.number
          end

          def fail_for_failed_state!(state, root_step)
            if root_step
              return unless state.subtree_failed?(root_step.number)

              failed_refs = state.subtree_steps(root_step.number)
                .select { |step| step.status == :failed }
                .map { |step| "#{step.number}(#{step.name})" }
              raise Ace::Support::Cli::Error, "Fork subtree #{root_step.number} failed: #{failed_refs.join(', ')}"
            end

            return unless state.failed.any?

            failed_refs = state.failed.map { |step| "#{step.number}(#{step.name})" }
            raise Ace::Support::Cli::Error, "Assignment has failed step(s): #{failed_refs.join(', ')}"
          end

          def watch_complete?(state, root_step)
            if root_step
              state.subtree_complete?(root_step.number)
            else
              state.complete?
            end
          end

          def active_fork_root(state, root_step)
            current = if root_step
              state.current_in_subtree(root_step.number)
            else
              state.current
            end
            return nil unless current

            state.nearest_fork_ancestor(current.number)
          end

          def pending_fork_root(state, root_step)
            next_step = if root_step
              state.next_workable_in_subtree(root_step.number)
            else
              state.next_workable
            end
            return nil unless next_step

            next_step.fork? ? next_step : state.nearest_fork_ancestor(next_step.number)
          end

          def fork_session_alive?(root_step)
            candidate_pids = [root_step.fork_launch_pid, *Array(root_step.fork_tracked_pids)].compact.uniq
            candidate_pids.any? { |pid| pid_alive_checker.call(pid) }
          end

          def pid_alive?(pid)
            Process.kill(0, Integer(pid))
            true
          rescue Errno::ESRCH, Errno::EPERM, TypeError, ArgumentError
            false
          end

          def run_fork_subtree(root_number, assignment_id, quiet:, debug:)
            Commands::ForkRun.new.call(
              root: root_number,
              assignment: assignment_id,
              quiet: quiet,
              debug: debug
            )
          end

          def announce_watch_scope(assignment_id, watch_root, quiet:)
            return if quiet

            if watch_root
              puts "Watching fork subtree #{watch_root} in assignment #{assignment_id}."
            else
              puts "Watching assignment #{assignment_id} for forked continuation."
            end
          end

          def completion_message(assignment_id, watch_root)
            if watch_root
              "Fork subtree #{watch_root} is complete for assignment #{assignment_id}."
            else
              "Assignment #{assignment_id} is complete."
            end
          end

          def stop_message(assignment_id, state, root_step)
            current = root_step ? state.current_in_subtree(root_step.number) : state.current
            next_step = root_step ? state.next_workable_in_subtree(root_step.number) : state.next_workable

            if current
              "No fork work remains to watch for assignment #{assignment_id}. Current step #{current.number} (#{current.name}) requires inline/manual execution."
            elsif next_step
              "No fork work remains to watch for assignment #{assignment_id}. Next step #{next_step.number} (#{next_step.name}) requires inline/manual execution."
            elsif root_step
              "Fork subtree #{root_step.number} has no remaining fork work to watch."
            else
              "Assignment #{assignment_id} has no remaining fork work to watch."
            end
          end
        end
      end
    end
  end
end
