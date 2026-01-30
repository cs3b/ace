# frozen_string_literal: true

require "fileutils"
require "set"
require "yaml"

module Ace
  module Coworker
    module Organisms
      # Orchestrates workflow operations on the work queue.
      #
      # Implements the state machine for queue operations:
      # start → advance → complete (with fail/add/retry branches)
      class WorkflowExecutor
        attr_reader :session_manager, :queue_scanner, :step_writer, :job_renumberer

        def initialize(cache_base: nil)
          @session_manager = Molecules::SessionManager.new(cache_base: cache_base)
          @queue_scanner = Molecules::QueueScanner.new
          @step_writer = Molecules::StepWriter.new
          @job_renumberer = Molecules::JobRenumberer.new(
            step_writer: @step_writer,
            queue_scanner: @queue_scanner
          )
        end

        # Start a new workflow session from config file
        #
        # @param config_path [String] Path to job.yaml config
        # @return [Hash] Result with session and first step
        def start(config_path)
          raise ConfigNotFoundError, "Config file not found: #{config_path}" unless File.exist?(config_path)

          config = YAML.safe_load_file(config_path, permitted_classes: [Time, Date])
          session_config = config["session"] || {}
          steps_config = config["steps"] || []

          raise Error, "No steps defined in config" if steps_config.empty?

          # Create session
          session = session_manager.create(
            name: session_config["name"] || File.basename(config_path, ".yaml"),
            description: session_config["description"],
            source_config: config_path
          )

          # Create initial step files
          steps_config.each_with_index do |step, index|
            number = Atoms::NumberGenerator.from_index(index)
            extra = step.reject { |k, _| %w[name instructions].include?(k) }
            step_writer.create(
              jobs_dir: session.jobs_dir,
              number: number,
              name: step["name"],
              instructions: normalize_instructions(step["instructions"]),
              status: :pending,
              extra: extra
            )
          end

          # Mark first step as in_progress
          first_step_file = Dir.glob(File.join(session.jobs_dir, "*.j.md")).min
          step_writer.mark_in_progress(first_step_file) if first_step_file

          # Archive source config into task's jobs directory and update session metadata
          archived_path = archive_source_config(config_path, session.id)
          session = Models::Session.new(
            id: session.id,
            name: session.name,
            description: session.description,
            created_at: session.created_at,
            updated_at: session.updated_at,
            source_config: archived_path,
            cache_dir: session.cache_dir
          )
          session_manager.update(session)

          # Return result
          state = queue_scanner.scan(session.jobs_dir, session: session)
          {
            session: session,
            state: state,
            current: state.current
          }
        end

        # Get current session and queue state
        #
        # @return [Hash] Result with session and state
        def status
          session = session_manager.find_active
          raise NoActiveSessionError, "No active session. Use 'ace-coworker create <job.yaml>' to begin." unless session

          state = queue_scanner.scan(session.jobs_dir, session: session)
          {
            session: session,
            state: state,
            current: state.current
          }
        end

        # Complete current step with report and advance
        #
        # Uses hierarchical completion rules:
        # - A step with children cannot complete until all children are done
        # - After completing a child step, the next step is another pending child or sibling
        # - Parent steps auto-complete when all children are done
        #
        # @param report_path [String] Path to report file
        # @return [Hash] Result with updated state
        def advance(report_path)
          raise Error, "Report file not found: #{report_path}" unless File.exist?(report_path)

          session = session_manager.find_active
          raise NoActiveSessionError, "No active session. Use 'ace-coworker create <job.yaml>' to begin." unless session

          state = queue_scanner.scan(session.jobs_dir, session: session)
          current = state.current
          raise Error, "No step currently in progress. Try 'ace-coworker add' to add a new step or 'ace-coworker retry' to retry a failed step." unless current

          # Enforce hierarchy: cannot mark parent as done with incomplete children
          if state.has_incomplete_children?(current.number)
            incomplete = state.children_of(current.number).reject { |c| c.status == :done }
            incomplete_nums = incomplete.map(&:number).join(", ")
            raise Error, "Cannot complete step #{current.number}: has incomplete children (#{incomplete_nums}). Complete children first or use 'ace-coworker fail' to mark as failed."
          end

          # Read report content
          report_content = File.read(report_path)

          # Mark current step as done
          step_writer.mark_done(current.file_path, report_content: report_content, reports_dir: session.reports_dir)

          # Rescan to get updated state after marking done
          state = queue_scanner.scan(session.jobs_dir, session: session)

          # Auto-complete parent steps if all their children are done
          auto_complete_parents(state, session)

          # Re-scan to get fresh state after auto-completions
          # (auto_complete_parents modifies files, so state is stale)
          state = queue_scanner.scan(session.jobs_dir, session: session)

          # Find next step to work on using hierarchical rules
          # Uses next_workable to respect hierarchy (skip parents with incomplete children)
          next_step = find_next_step(state, current.number)
          if next_step
            step_writer.mark_in_progress(next_step.file_path)
          end

          # Update session timestamp
          session_manager.update(session)

          # Return updated state
          new_state = queue_scanner.scan(session.jobs_dir, session: session)
          {
            session: session,
            state: new_state,
            completed: current,
            current: new_state.current
          }
        end

        # Mark current step as failed
        #
        # @param message [String] Error message
        # @return [Hash] Result with updated state
        def fail(message)
          session = session_manager.find_active
          raise NoActiveSessionError, "No active session. Use 'ace-coworker create <job.yaml>' to begin." unless session

          state = queue_scanner.scan(session.jobs_dir, session: session)
          current = state.current
          raise Error, "No step currently in progress. Try 'ace-coworker add' to add a new step or 'ace-coworker retry' to retry a failed step." unless current

          # Mark step as failed
          step_writer.mark_failed(current.file_path, error_message: message)

          # Update session timestamp
          session_manager.update(session)

          # Return updated state (no automatic advancement after failure)
          new_state = queue_scanner.scan(session.jobs_dir, session: session)
          {
            session: session,
            state: new_state,
            failed: current
          }
        end

        # Add a new step dynamically
        #
        # @param name [String] Step name
        # @param instructions [String] Step instructions
        # @param after [String, nil] Insert after this step number (optional)
        # @param as_child [Boolean] Insert as child of 'after' step (default: false, sibling)
        # @return [Hash] Result with new step
        def add(name, instructions, after: nil, as_child: false)
          session = session_manager.find_active
          raise NoActiveSessionError, "No active session. Use 'ace-coworker create <job.yaml>' to begin." unless session

          state = queue_scanner.scan(session.jobs_dir, session: session)
          existing_numbers = queue_scanner.step_numbers(session.jobs_dir)

          # Validate --after job exists
          if after && !existing_numbers.include?(after)
            raise StepNotFoundError, "Job #{after} not found. Available jobs: #{existing_numbers.join(', ')}"
          end

          new_number, renumbered = calculate_insertion_point(
            after: after,
            as_child: as_child,
            state: state,
            existing_numbers: existing_numbers
          )

          # Renumber existing jobs if needed (uses molecule with rollback support)
          if renumbered.any?
            job_renumberer.renumber(session.jobs_dir, renumbered)
            # Refresh existing numbers after renumbering
            existing_numbers = queue_scanner.step_numbers(session.jobs_dir)
          end

          # Determine initial status upfront to avoid redundant I/O
          initial_status = state.current ? :pending : :in_progress

          # Build added_by metadata for audit trail
          added_by = if after && as_child
                       "child_of:#{after}"
                     elsif after
                       "injected_after:#{after}"
                     else
                       "dynamic"
                     end

          # Create new step file with correct status
          file_path = step_writer.create(
            jobs_dir: session.jobs_dir,
            number: new_number,
            name: name,
            instructions: instructions,
            status: initial_status,
            added_by: added_by,
            parent: as_child ? after : nil
          )

          # Update session timestamp
          session_manager.update(session)

          # Return updated state
          new_state = queue_scanner.scan(session.jobs_dir, session: session)
          new_step = new_state.steps.find { |s| s.number == new_number }

          {
            session: session,
            state: new_state,
            added: new_step,
            renumbered: renumbered
          }
        end

        # Retry a failed step (creates new step linked to original)
        #
        # @param step_ref [String] Step number or reference to retry
        # @return [Hash] Result with new retry step
        def retry_step(step_ref)
          session = session_manager.find_active
          raise NoActiveSessionError, "No active session. Use 'ace-coworker create <job.yaml>' to begin." unless session

          state = queue_scanner.scan(session.jobs_dir, session: session)

          # Find the step to retry
          original = state.find_by_number(step_ref.to_s)
          raise StepNotFoundError, "Step #{step_ref} not found in queue" unless original

          # Get existing numbers
          existing_numbers = queue_scanner.step_numbers(session.jobs_dir)

          # Insert after all current steps (at end of queue before pending)
          # Find last done or failed step
          base_number = if state.current
                          state.current.number
                        elsif state.last_done
                          state.last_done.number
                        else
                          original.number
                        end

          new_number = Atoms::NumberGenerator.next_after(base_number, existing_numbers)

          # Create retry step with link to original
          file_path = step_writer.create(
            jobs_dir: session.jobs_dir,
            number: new_number,
            name: original.name,
            instructions: original.instructions,
            status: :pending,
            added_by: "retry_of:#{original.number}"
          )

          # Update session timestamp
          session_manager.update(session)

          # Return updated state
          new_state = queue_scanner.scan(session.jobs_dir, session: session)
          retry_step = new_state.steps.find { |s| s.number == new_number }

          {
            session: session,
            state: new_state,
            retry: retry_step,
            original: original
          }
        end

        private

        # Archive source config into the task's jobs/ directory.
        # If config is already in a jobs/ directory, keeps it in place.
        # Otherwise moves job.yaml to <task>/jobs/<session_id>-job.yml for provenance.
        #
        # @param config_path [String] Path to the original job.yaml
        # @param session_id [String] Session identifier for filename prefix
        # @return [String] Path to archived file
        def archive_source_config(config_path, session_id)
          expanded_path = File.expand_path(config_path)
          parent_dir = File.dirname(expanded_path)

          # If already in a jobs/ directory, keep it there
          return expanded_path if File.basename(parent_dir) == "jobs"

          # Otherwise, move to task's jobs/ directory
          jobs_dir = File.join(parent_dir, "jobs")
          FileUtils.mkdir_p(jobs_dir)

          dest = File.join(jobs_dir, "#{session_id}-job.yml")
          FileUtils.mv(expanded_path, dest)
          dest
        end

        # Normalize instructions to a string.
        # Accepts arrays (joined with newlines) or strings (returned as-is).
        #
        # @param instructions [Array<String>, String, nil] Raw instructions from config
        # @return [String] Normalized instruction text
        def normalize_instructions(instructions)
          return "" if instructions.nil?

          instructions.is_a?(Array) ? instructions.join("\n") : instructions.to_s
        end

        # Auto-complete parent steps when all their children are done.
        # Walks up the hierarchy marking parents as done, handling multi-level
        # completion in a single pass (grandparents become eligible when parents complete).
        #
        # @param state [Models::QueueState] Current queue state
        # @param session [Models::Session] Current session
        def auto_complete_parents(state, session)
          completed_any = true
          # Track completed step numbers in this pass (avoids fragile ivar mutation)
          completed_this_pass = Set.new

          # Safety guard: max iterations = total steps to prevent infinite loops
          max_iterations = state.steps.size

          # Loop until no more parents can be completed
          # This handles multi-level hierarchies where completing a parent
          # makes the grandparent eligible for completion
          iterations = 0
          while completed_any && iterations < max_iterations
            iterations += 1
            completed_any = false

            # Find all pending/in_progress parent steps that have children
            eligible_parents = state.steps.select do |s|
              (s.status == :pending || s.status == :in_progress) &&
                !completed_this_pass.include?(s.number)
            end

            eligible_parents.each do |step|
              children = state.children_of(step.number)
              next if children.empty?

              # If all children are done (or completed this pass), mark parent as done too
              all_done = children.all? do |c|
                c.status == :done || completed_this_pass.include?(c.number)
              end

              if all_done
                step_writer.mark_done(
                  step.file_path,
                  report_content: "Auto-completed: all child jobs finished.",
                  reports_dir: session.reports_dir
                )
                completed_this_pass << step.number
                completed_any = true
              end
            end
          end

          # Warn if safety limit was reached while still completing parents
          if iterations >= max_iterations && completed_any
            warn "[ace-coworker] Warning: auto_complete_parents reached iteration limit (#{max_iterations}). " \
                 "Some parent jobs may not have been auto-completed."
          end
        end

        # Find the next step to work on using hierarchical rules.
        #
        # @param state [Models::QueueState] Current queue state
        # @param completed_number [String] Number of just-completed step
        # @return [Models::Step, nil] Next step to work on
        def find_next_step(state, completed_number)
          # First priority: pending children of the completed step
          children = state.children_of(completed_number)
          pending_child = children.find { |c| c.status == :pending }
          return pending_child if pending_child

          # Second priority: next workable step (respects hierarchy)
          # Uses next_workable to skip parents that have incomplete children
          state.next_workable
        end

        # Calculate insertion point for a new step.
        #
        # @param after [String, nil] Insert after this step number
        # @param as_child [Boolean] Insert as child (true) or sibling (false)
        # @param state [Models::QueueState] Current queue state
        # @param existing_numbers [Array<String>] Existing step numbers
        # @return [Array<String, Array>] [new_number, jobs_to_renumber]
        def calculate_insertion_point(after:, as_child:, state:, existing_numbers:)
          if after
            if as_child
              # Insert as first child of 'after'
              new_number = Atoms::JobNumbering.next_child(after, existing_numbers)
              [new_number, []]
            else
              # Insert as sibling after 'after'
              new_number = Atoms::JobNumbering.next_sibling(after)

              # Check if this number already exists
              if existing_numbers.include?(new_number)
                # Need to renumber
                renumber_list = Atoms::JobNumbering.jobs_to_renumber(new_number, existing_numbers)
                [new_number, renumber_list]
              else
                [new_number, []]
              end
            end
          else
            # Default behavior: insert after current or last done
            base_number = if state.current
                            state.current.number
                          elsif state.last_done
                            state.last_done.number
                          else
                            "000" # Will generate 001
                          end

            new_number = Atoms::NumberGenerator.next_after(base_number, existing_numbers)
            [new_number, []]
          end
        end
      end
    end
  end
end
