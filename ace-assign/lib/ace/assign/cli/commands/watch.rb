# frozen_string_literal: true

require "yaml"

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

            def initialize(launcher: nil, sleeper: nil, pid_probe: nil)
              super()
              @launcher = launcher
              @sleeper = sleeper || ->(seconds) { sleep(seconds) }
              @pid_probe = pid_probe || method(:pid_alive?)
            end

            def call(**options)
              poll_interval = normalize_poll_interval(options[:poll_interval])
              target = resolve_assignment_target(options)

              if scoped_watch?(target, options[:root])
                watch_scoped(target: target, explicit_root: options[:root], poll_interval: poll_interval, quiet: options[:quiet])
              else
                watch_assignment(target: target, poll_interval: poll_interval, quiet: options[:quiet])
              end
            end

            private

            attr_reader :launcher, :sleeper, :pid_probe

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

            def watch_scoped(target:, explicit_root:, poll_interval:, quiet:)
              executor = build_executor_for_target(target)
              assignment = nil
              scope_ref = nil

              loop do
                result = executor.status
                assignment = result[:assignment]
                state = result[:state]
                current = result[:current]
                root_step = resolve_root_step(state, current, explicit_root, target.scope)
                ensure_root_is_fork!(root_step)
                scope_ref ||= "#{assignment.id}@#{root_step.number}"

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

                if active_fork_root = active_fork_root_for_scope(state, root_step.number)
                  if fork_telemetry_alive?(assignment.cache_dir, active_fork_root)
                    puts "Waiting for active fork subtree #{active_fork_root.number} in watched scope #{scope_ref}." unless quiet
                    sleeper.call(poll_interval)
                    next
                  end

                  puts "Recovering watched scope #{scope_ref} from assignment state via subtree #{active_fork_root.number}." unless quiet
                  launch_fork_subtree(assignment_id: assignment.id, root_number: active_fork_root.number, quiet: quiet)
                  next
                end

                next_root = next_fork_root_for_scope(state, root_step.number)
                raise Error, "Watched scope #{scope_ref} still has fork work remaining." unless next_root

                puts "Launching next fork subtree #{next_root.number} for watched scope #{scope_ref}." unless quiet
                launch_fork_subtree(assignment_id: assignment.id, root_number: next_root.number, quiet: quiet)
              end
            end

            def watch_assignment(target:, poll_interval:, quiet:)
              executor = build_executor_for_target(target)
              assignment_ref = nil

              loop do
                result = executor.status
                assignment = result[:assignment]
                state = result[:state]
                assignment_ref ||= assignment.id
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

                if active_fork_root = active_fork_root_for_assignment(state)
                  if fork_telemetry_alive?(assignment.cache_dir, active_fork_root)
                    puts "Waiting for active fork subtree #{active_fork_root.number} in watched assignment #{assignment_ref}." unless quiet
                    sleeper.call(poll_interval)
                    next
                  end

                  puts "Recovering watched assignment #{assignment_ref} from assignment state via subtree #{active_fork_root.number}." unless quiet
                  launch_fork_subtree(assignment_id: assignment.id, root_number: active_fork_root.number, quiet: quiet)
                  next
                end

                next_root = next_fork_root_for_assignment(state)
                raise Error, "Watched assignment #{assignment_ref} still has fork work remaining." unless next_root

                puts "Launching next fork subtree #{next_root.number} for watched assignment #{assignment_ref}." unless quiet
                launch_fork_subtree(assignment_id: assignment.id, root_number: next_root.number, quiet: quiet)
              end
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

            def active_fork_root_for_scope(state, root_number)
              current = state.current_in_subtree(root_number)
              fork_scope_root(state, current)
            end

            def next_fork_root_for_scope(state, root_number)
              candidate = state.next_workable_in_subtree(root_number)
              return nil unless candidate

              fork_scope_root(state, candidate)
            end

            def active_fork_root_for_assignment(state)
              current = state.current
              fork_scope_root(state, current)
            end

            def next_fork_root_for_assignment(state)
              candidate = state.next_workable
              return nil unless candidate

              fork_scope_root(state, candidate)
            end

            def fork_telemetry_alive?(cache_dir, root_step)
              tracked_pids = Array(root_step.fork_tracked_pids).dup
              tracked_pids << root_step.fork_launch_pid if root_step.fork_launch_pid
              pid_file = root_step.fork_pid_file.to_s.strip
              tracked_pids.concat(read_pid_file_pids(pid_file)) unless pid_file.empty?
              tracked_pids.map!(&:to_i)
              tracked_pids.reject!(&:zero?)
              tracked_pids.uniq!

              tracked_pids.any? do |pid|
                begin
                  pid_probe.call(pid)
                rescue Errno::EPERM
                  true
                end
              end
            end

            def read_pid_file_pids(pid_file)
              return [] unless File.exist?(pid_file)

              payload = YAML.safe_load_file(pid_file) || {}
              Array(payload["tracked_pids"]) + Array(payload["launch_pid"])
            rescue Psych::SyntaxError, SystemCallError
              []
            end

            def pid_alive?(pid)
              Process.kill(0, pid.to_i)
              true
            rescue Errno::EPERM
              true
            rescue Errno::ESRCH, RangeError, TypeError
              false
            end

            def launch_fork_subtree(assignment_id:, root_number:, quiet:)
              fork_run_command = ForkRun.new(launcher: launcher)
              fork_run_command.call(assignment: assignment_id, root: root_number, quiet: quiet)
            end
          end
        end
      end
    end
  end
