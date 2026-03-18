# frozen_string_literal: true

require "fileutils"
require "yaml"

module Ace
  module Assign
    module CLI
      module Commands
        # Prepare and validate a subtree-scoped fork execution session.
        class ForkRun < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include AssignmentTarget

          STALL_REASON_MAX = 2000

          desc "Prepare fork execution for an entire subtree"

          option :root, desc: "Fork subtree root step number (e.g., 010.01)"
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

            root_step = resolve_root_step(state, current, options[:root], target.scope)
            ensure_root_is_fork!(root_step)

            if state.subtree_complete?(root_step.number)
              puts "Subtree #{root_step.number} is already complete." unless options[:quiet]
              return
            end

            unless options[:quiet]
              next_step = state.next_workable_in_subtree(root_step.number)
              puts "Starting fork subtree execution: #{root_step.number} - #{root_step.name}"
              puts "Assignment: #{assignment.id}"
              puts "Provider: #{options[:provider] || Ace::Assign.config.dig('execution', 'provider') || Molecules::ForkSessionLauncher::DEFAULT_PROVIDER}"
              puts "Timeout: #{options[:timeout] || Ace::Assign.config.dig('execution', 'timeout') || Molecules::ForkSessionLauncher::DEFAULT_TIMEOUT}s"
              puts "Next step: #{next_step.number} - #{next_step.name}" if next_step
            end

            active_in_subtree = state.in_progress_in_subtree(root_step.number)
            if active_in_subtree.size > 1
              active_refs = active_in_subtree.map { |step| "#{step.number}(#{step.name})" }.join(", ")
              raise StepErrors::InvalidState, "Cannot fork-run subtree #{root_step.number}: multiple steps are already in progress (#{active_refs})."
            end

            # Mark the next workable step as in_progress only when no subtree step is active.
            # For leaf fork roots, this activates the root itself.
            if active_in_subtree.empty?
              first_workable = state.next_workable_in_subtree(root_step.number)
              if first_workable
                step_writer = Molecules::StepWriter.new
                step_writer.mark_in_progress(first_workable.file_path)
              end
            end

            launch_result = launcher.launch(
              assignment_id: assignment.id,
              fork_root: root_step.number,
              provider: options[:provider],
              cli_args: options[:cli_args],
              timeout: options[:timeout],
              cache_dir: assignment.cache_dir
            )
            record_fork_pid_info(root_step, launch_result)

            refreshed = executor.status
            refreshed_state = refreshed[:state]

            if refreshed_state.subtree_failed?(root_step.number)
              failed = refreshed_state.subtree_steps(root_step.number).select { |s| s.status == :failed }
              failed_refs = failed.map { |p| "#{p.number}(#{p.name})" }.join(", ")
              raise Error, "Fork subtree #{root_step.number} failed: #{failed_refs}"
            end

            unless refreshed_state.subtree_complete?(root_step.number)
              active = refreshed_state.in_progress_in_subtree(root_step.number).first || refreshed_state.current
              active_msg = active ? " Current step: #{active.number} (#{active.name})." : ""
              last_msg = read_last_message(assignment.cache_dir, root_step.number)
              stall_reason = build_stall_reason(last_msg)
              session_meta = read_session_metadata(assignment.cache_dir, root_step.number)

              if stall_reason && active
                step_writer = Molecules::StepWriter.new
                step_writer.update_frontmatter(active.file_path, { "stall_reason" => stall_reason })
              end

              session_info = session_meta&.dig("session_id") ? " Session: #{session_meta["session_id"]}" : ""
              error_msg = "Fork subtree #{root_step.number} did not complete within spawned session.#{active_msg}#{session_info}"
              error_msg += "\n\nAgent's last message:\n#{stall_reason}" if stall_reason
              raise Error, error_msg
            end

            # Clear any stale stall_reason left by a previous failed attempt.
            stale_steps = refreshed_state.subtree_steps(root_step.number).select(&:stall_reason)
            if stale_steps.any?
              step_writer = Molecules::StepWriter.new
              stale_steps.each do |step|
                step_writer.update_frontmatter(step.file_path, { "stall_reason" => nil })
              end
            end

            puts "Fork subtree #{root_step.number} completed successfully." unless options[:quiet]
          end

          private

          attr_reader :launcher

          def read_session_metadata(cache_dir, fork_root)
            return nil unless cache_dir

            meta_file = File.join(cache_dir, "sessions", "#{fork_root}-session.yml")
            return nil unless File.exist?(meta_file)

            YAML.safe_load_file(meta_file)
          rescue SystemCallError, Psych::SyntaxError
            nil
          end

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

          def resolve_root_step(state, current, explicit_root, scoped_root)
            if explicit_root && scoped_root && explicit_root.strip != scoped_root.strip
              raise Error, "Conflicting subtree roots: --root #{explicit_root.strip} and scope #{scoped_root.strip}"
            end

            root_ref = explicit_root&.strip
            root_ref = scoped_root&.strip if root_ref.nil? || root_ref.empty?

            if root_ref && !root_ref.empty?
              root = state.find_by_number(root_ref)
              raise StepErrors::NotFound, "Step #{root_ref} not found in queue" unless root

              return root
            end

            # Fallback for legacy behavior when no root is explicitly scoped.
            raise Error, "No current step. Use --root <step-number> or --assignment <id>@<step-number>." unless current

            root = state.nearest_fork_ancestor(current.number)
            raise Error, "Current step is not in a forked subtree. Provide --root or --assignment <id>@<step-number>." unless root

            root
          end

          def ensure_root_is_fork!(root_step)
            return if root_step.fork?

            raise Error, "Step #{root_step.number} is not fork-enabled (context: fork missing)."
          end

          def record_fork_pid_info(root_step, launch_result)
            pid_info = launch_result.is_a?(Hash) ? launch_result[:fork_pid_info] : nil
            return unless pid_info

            pid_file = write_pid_file(root_step, pid_info)
            step_writer = Molecules::StepWriter.new
            step_writer.record_fork_pid_info(
              root_step.file_path,
              launch_pid: pid_info[:launch_pid] || Process.pid,
              tracked_pids: pid_info[:tracked_pids] || [],
              pid_file: pid_file
            )
          rescue StandardError
            # Keep fork-run resilient even if telemetry persistence fails.
            nil
          end

          def write_pid_file(root_step, pid_info)
            step_dir = File.dirname(root_step.file_path)
            assignment_dir = File.expand_path("..", step_dir)
            pids_dir = File.join(assignment_dir, "pids")
            FileUtils.mkdir_p(pids_dir)

            step_ref = root_step.number.to_s.gsub(/[^0-9.]/, "")
            file_name = "#{step_ref}.pid.yml"
            pid_file = File.join(pids_dir, file_name)
            payload = {
              "assignment_step" => root_step.number,
              "step_name" => root_step.name,
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
