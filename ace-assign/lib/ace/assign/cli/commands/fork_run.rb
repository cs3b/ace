# frozen_string_literal: true

require "fileutils"
require "yaml"

module Ace
  module Assign
    module CLI
      module Commands
        # Prepare and validate a subtree-scoped fork execution session.
        class ForkRun < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base
          include AssignmentTarget

          STALL_REASON_MAX = 2000

          desc "Prepare fork execution for an entire subtree"

          option :root, desc: "Fork subtree root phase number (e.g., 010.01)"
          option :assignment, desc: "Target specific assignment ID"
          option :provider, desc: "LLM provider:model override (e.g., codex:gpt-5, claude:sonnet)"
          option :cli_args, desc: "Extra CLI args for provider process"
          option :timeout, type: :integer, desc: "Execution timeout in seconds"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(launcher: nil)
            super()
            @launcher = launcher || Molecules::ForkSessionLauncher.new
          end

          def call(**options)
            target = resolve_assignment_target(options)
            executor = build_executor_for_target(target)
            result = executor.status
            assignment = result[:assignment]
            state = result[:state]
            current = result[:current]

            root_phase = resolve_root_phase(state, current, options[:root], target.scope)
            ensure_root_is_fork!(root_phase)

            if state.subtree_complete?(root_phase.number)
              puts "Subtree #{root_phase.number} is already complete." unless options[:quiet]
              return
            end

            unless options[:quiet]
              next_phase = state.next_workable_in_subtree(root_phase.number)
              puts "Starting fork subtree execution: #{root_phase.number} - #{root_phase.name}"
              puts "Assignment: #{assignment.id}"
              puts "Provider: #{options[:provider] || Ace::Assign.config.dig('execution', 'provider') || Molecules::ForkSessionLauncher::DEFAULT_PROVIDER}"
              puts "Timeout: #{options[:timeout] || Ace::Assign.config.dig('execution', 'timeout') || Molecules::ForkSessionLauncher::DEFAULT_TIMEOUT}s"
              puts "Next phase: #{next_phase.number} - #{next_phase.name}" if next_phase
            end

            active_in_subtree = state.in_progress_in_subtree(root_phase.number)
            if active_in_subtree.size > 1
              active_refs = active_in_subtree.map { |phase| "#{phase.number}(#{phase.name})" }.join(", ")
              raise InvalidPhaseStateError, "Cannot fork-run subtree #{root_phase.number}: multiple phases are already in progress (#{active_refs})."
            end

            # Mark first workable child as in_progress only when no subtree phase is active.
            if active_in_subtree.empty?
              first_workable = state.next_workable_in_subtree(root_phase.number)
              if first_workable && first_workable.number != root_phase.number
                phase_writer = Molecules::PhaseWriter.new
                phase_writer.mark_in_progress(first_workable.file_path)
              end
            end

            launch_result = launcher.launch(
              assignment_id: assignment.id,
              fork_root: root_phase.number,
              provider: options[:provider],
              cli_args: options[:cli_args],
              timeout: options[:timeout],
              cache_dir: assignment.cache_dir
            )
            record_fork_pid_info(root_phase, launch_result)

            refreshed = executor.status
            refreshed_state = refreshed[:state]

            if refreshed_state.subtree_failed?(root_phase.number)
              failed = refreshed_state.subtree_phases(root_phase.number).select { |s| s.status == :failed }
              failed_refs = failed.map { |p| "#{p.number}(#{p.name})" }.join(", ")
              raise Error, "Fork subtree #{root_phase.number} failed: #{failed_refs}"
            end

            unless refreshed_state.subtree_complete?(root_phase.number)
              active = refreshed_state.current
              active_msg = active ? " Current phase: #{active.number} (#{active.name})." : ""
              last_msg = read_last_message(assignment.cache_dir, root_phase.number)
              stall_reason = build_stall_reason(last_msg)

              if stall_reason && active
                phase_writer = Molecules::PhaseWriter.new
                phase_writer.update_frontmatter(active.file_path, { "stall_reason" => stall_reason })
              end

              error_msg = "Fork subtree #{root_phase.number} did not complete within spawned session.#{active_msg}"
              error_msg += "\n\nAgent's last message:\n#{stall_reason}" if stall_reason
              raise Error, error_msg
            end

            # Clear any stale stall_reason left by a previous failed attempt.
            phase_writer = Molecules::PhaseWriter.new
            refreshed_state.subtree_phases(root_phase.number).each do |phase|
              phase_writer.update_frontmatter(phase.file_path, { "stall_reason" => nil })
            end

            puts "Fork subtree #{root_phase.number} completed successfully." unless options[:quiet]
          end

          private

          attr_reader :launcher

          def read_last_message(cache_dir, fork_root)
            return nil unless cache_dir

            last_msg_file = File.join(cache_dir, "sessions", "#{fork_root}-last-message.md")
            return nil unless File.exist?(last_msg_file)

            content = File.read(last_msg_file).strip
            content.empty? ? nil : content
          rescue SystemCallError
            nil
          end

          def build_stall_reason(last_msg)
            return nil unless last_msg

            if last_msg.length > STALL_REASON_MAX
              last_msg[0, STALL_REASON_MAX] + "... (truncated)"
            else
              last_msg
            end
          end

          def resolve_root_phase(state, current, explicit_root, scoped_root)
            if explicit_root && scoped_root && explicit_root.strip != scoped_root.strip
              raise Error, "Conflicting subtree roots: --root #{explicit_root.strip} and scope #{scoped_root.strip}"
            end

            root_ref = explicit_root&.strip
            root_ref = scoped_root&.strip if root_ref.nil? || root_ref.empty?

            if root_ref && !root_ref.empty?
              root = state.find_by_number(root_ref)
              raise PhaseNotFoundError, "Phase #{root_ref} not found in queue" unless root

              return root
            end

            # Fallback for legacy behavior when no root is explicitly scoped.
            raise Error, "No current phase. Use --root <phase-number> or --assignment <id>@<phase-number>." unless current

            root = state.nearest_fork_ancestor(current.number)
            raise Error, "Current phase is not in a forked subtree. Provide --root or --assignment <id>@<phase-number>." unless root

            root
          end

          def ensure_root_is_fork!(root_phase)
            return if root_phase.fork?

            raise Error, "Phase #{root_phase.number} is not fork-enabled (context: fork missing)."
          end

          def record_fork_pid_info(root_phase, launch_result)
            pid_info = launch_result.is_a?(Hash) ? launch_result[:fork_pid_info] : nil
            return unless pid_info

            pid_file = write_pid_file(root_phase, pid_info)
            phase_writer = Molecules::PhaseWriter.new
            phase_writer.record_fork_pid_info(
              root_phase.file_path,
              launch_pid: pid_info[:launch_pid] || Process.pid,
              tracked_pids: pid_info[:tracked_pids] || [],
              pid_file: pid_file
            )
          rescue StandardError
            # Keep fork-run resilient even if telemetry persistence fails.
            nil
          end

          def write_pid_file(root_phase, pid_info)
            phase_dir = File.dirname(root_phase.file_path)
            assignment_dir = File.expand_path("..", phase_dir)
            pids_dir = File.join(assignment_dir, "pids")
            FileUtils.mkdir_p(pids_dir)

            phase_ref = root_phase.number.to_s.gsub(/[^0-9.]/, "")
            file_name = "#{phase_ref}.pid.yml"
            pid_file = File.join(pids_dir, file_name)
            payload = {
              "assignment_phase" => root_phase.number,
              "phase_name" => root_phase.name,
              "launch_pid" => (pid_info[:launch_pid] || Process.pid).to_i,
              "tracked_pids" => Array(pid_info[:tracked_pids]).map(&:to_i).uniq.sort,
              "captured_at" => Time.now.utc.iso8601
            }
            File.write(pid_file, payload.to_yaml)
            pid_file
          end
        end
      end
    end
  end
end
