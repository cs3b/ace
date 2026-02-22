# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Prepare and validate a subtree-scoped fork execution session.
        class ForkRun < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base
          include AssignmentTarget

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

            launcher.launch(
              assignment_id: assignment.id,
              fork_root: root_phase.number,
              provider: options[:provider],
              cli_args: options[:cli_args],
              timeout: options[:timeout]
            )

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
              raise Error, "Fork subtree #{root_phase.number} did not complete within spawned session.#{active_msg}"
            end

            puts "Fork subtree #{root_phase.number} completed successfully." unless options[:quiet]
          end

          private

          attr_reader :launcher

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
        end
      end
    end
  end
end
