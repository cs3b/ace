# frozen_string_literal: true

require "fileutils"
require "set"
require "yaml"

module Ace
  module Assign
    module Organisms
      # Orchestrates workflow operations on the work queue.
      #
      # Implements the state machine for queue operations:
      # start → advance → complete (with fail/add/retry branches)
      class AssignmentExecutor
        attr_reader :assignment_manager, :queue_scanner, :phase_writer, :phase_renumberer

        def initialize(cache_base: nil)
          @assignment_manager = Molecules::AssignmentManager.new(cache_base: cache_base)
          @queue_scanner = Molecules::QueueScanner.new
          @phase_writer = Molecules::PhaseWriter.new
          @phase_renumberer = Molecules::PhaseRenumberer.new(
            phase_writer: @phase_writer,
            queue_scanner: @queue_scanner
          )
        end

        # Start a new workflow assignment from config file
        #
        # @param config_path [String] Path to job.yaml config
        # @return [Hash] Result with assignment and first phase
        def start(config_path)
          raise ConfigNotFoundError, "Config file not found: #{config_path}" unless File.exist?(config_path)

          config = YAML.safe_load_file(config_path, permitted_classes: [Time, Date])
          assignment_config = config["session"] || {}
          phases_config = config["steps"] || []

          raise Error, "No phases defined in config" if phases_config.empty?

          # Create assignment
          assignment = assignment_manager.create(
            name: assignment_config["name"] || File.basename(config_path, ".yaml"),
            description: assignment_config["description"],
            source_config: config_path
          )

          # Create initial phase files
          # Phases may have pre-assigned numbers (from expansion) or need auto-numbering
          phases_config.each_with_index do |phase, index|
            # Use pre-assigned number if present, otherwise generate from index
            number = phase["number"] || Atoms::NumberGenerator.from_index(index)
            extra = phase.reject { |k, _| %w[name instructions number].include?(k) }
            phase_writer.create(
              phases_dir: assignment.phases_dir,
              number: number,
              name: phase["name"],
              instructions: normalize_instructions(phase["instructions"]),
              status: :pending,
              extra: extra
            )
          end

          # Mark first phase as in_progress
          first_phase_file = Dir.glob(File.join(assignment.phases_dir, "*.ph.md")).min
          phase_writer.mark_in_progress(first_phase_file) if first_phase_file

          # Archive source config into task's phases directory and update assignment metadata
          archived_path = archive_source_config(config_path, assignment.id)
          assignment = Models::Assignment.new(
            id: assignment.id,
            name: assignment.name,
            description: assignment.description,
            created_at: assignment.created_at,
            updated_at: assignment.updated_at,
            source_config: archived_path,
            cache_dir: assignment.cache_dir
          )
          assignment_manager.update(assignment)

          # Return result
          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          {
            assignment: assignment,
            state: state,
            current: state.current
          }
        end

        # Get current assignment and queue state
        #
        # @return [Hash] Result with assignment and state
        def status
          assignment = assignment_manager.find_active
          raise NoActiveAssignmentError, "No active assignment. Use 'ace-assign create <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          {
            assignment: assignment,
            state: state,
            current: state.current
          }
        end

        # Complete current phase with report and advance
        #
        # Uses hierarchical completion rules:
        # - A phase with children cannot complete until all children are done
        # - After completing a child phase, the next phase is another pending child or sibling
        # - Parent phases auto-complete when all children are done
        #
        # @param report_path [String] Path to report file
        # @return [Hash] Result with updated state
        def advance(report_path)
          raise Error, "Report file not found: #{report_path}" unless File.exist?(report_path)

          assignment = assignment_manager.find_active
          raise NoActiveAssignmentError, "No active assignment. Use 'ace-assign create <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          current = state.current
          raise Error, "No phase currently in progress. Try 'ace-assign add' to add a new phase or 'ace-assign retry' to retry a failed phase." unless current

          # Enforce hierarchy: cannot mark parent as done with incomplete children
          if state.has_incomplete_children?(current.number)
            incomplete = state.children_of(current.number).reject { |c| c.status == :done }
            incomplete_nums = incomplete.map(&:number).join(", ")
            raise Error, "Cannot complete phase #{current.number}: has incomplete children (#{incomplete_nums}). Complete children first or use 'ace-assign fail' to mark as failed."
          end

          # Read report content
          report_content = File.read(report_path)

          # Mark current phase as done
          phase_writer.mark_done(current.file_path, report_content: report_content, reports_dir: assignment.reports_dir)

          # Rescan to get updated state after marking done
          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)

          # Auto-complete parent phases if all their children are done
          auto_complete_parents(state, assignment)

          # Re-scan to get fresh state after auto-completions
          # (auto_complete_parents modifies files, so state is stale)
          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)

          # Find next phase to work on using hierarchical rules
          # Uses next_workable to respect hierarchy (skip parents with incomplete children)
          next_phase = find_next_phase(state, current.number)
          if next_phase
            phase_writer.mark_in_progress(next_phase.file_path)
          end

          # Update assignment timestamp
          assignment_manager.update(assignment)

          # Return updated state
          new_state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          {
            assignment: assignment,
            state: new_state,
            completed: current,
            current: new_state.current
          }
        end

        # Mark current phase as failed
        #
        # @param message [String] Error message
        # @return [Hash] Result with updated state
        def fail(message)
          assignment = assignment_manager.find_active
          raise NoActiveAssignmentError, "No active assignment. Use 'ace-assign create <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          current = state.current
          raise Error, "No phase currently in progress. Try 'ace-assign add' to add a new phase or 'ace-assign retry' to retry a failed phase." unless current

          # Mark phase as failed
          phase_writer.mark_failed(current.file_path, error_message: message)

          # Update assignment timestamp
          assignment_manager.update(assignment)

          # Return updated state (no automatic advancement after failure)
          new_state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          {
            assignment: assignment,
            state: new_state,
            failed: current
          }
        end

        # Add a new phase dynamically
        #
        # @param name [String] Phase name
        # @param instructions [String] Phase instructions
        # @param after [String, nil] Insert after this phase number (optional)
        # @param as_child [Boolean] Insert as child of 'after' phase (default: false, sibling)
        # @return [Hash] Result with new phase
        def add(name, instructions, after: nil, as_child: false)
          assignment = assignment_manager.find_active
          raise NoActiveAssignmentError, "No active assignment. Use 'ace-assign create <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          existing_numbers = queue_scanner.phase_numbers(assignment.phases_dir)

          # Validate --after phase exists
          if after && !existing_numbers.include?(after)
            raise PhaseNotFoundError, "Phase #{after} not found. Available phases: #{existing_numbers.join(', ')}"
          end

          new_number, renumbered = calculate_insertion_point(
            after: after,
            as_child: as_child,
            state: state,
            existing_numbers: existing_numbers
          )

          # Renumber existing phases if needed (uses molecule with rollback support)
          if renumbered.any?
            phase_renumberer.renumber(assignment.phases_dir, renumbered)
            # Refresh existing numbers after renumbering
            existing_numbers = queue_scanner.phase_numbers(assignment.phases_dir)
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

          # Create new phase file with correct status
          file_path = phase_writer.create(
            phases_dir: assignment.phases_dir,
            number: new_number,
            name: name,
            instructions: instructions,
            status: initial_status,
            added_by: added_by,
            parent: as_child ? after : nil
          )

          # Update assignment timestamp
          assignment_manager.update(assignment)

          # Return updated state
          new_state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          new_phase = new_state.phases.find { |s| s.number == new_number }

          {
            assignment: assignment,
            state: new_state,
            added: new_phase,
            renumbered: renumbered
          }
        end

        # Retry a failed phase (creates new phase linked to original)
        #
        # @param phase_ref [String] Phase number or reference to retry
        # @return [Hash] Result with new retry phase
        def retry_phase(phase_ref)
          assignment = assignment_manager.find_active
          raise NoActiveAssignmentError, "No active assignment. Use 'ace-assign create <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)

          # Find the phase to retry
          original = state.find_by_number(phase_ref.to_s)
          raise PhaseNotFoundError, "Phase #{phase_ref} not found in queue" unless original

          # Get existing numbers
          existing_numbers = queue_scanner.phase_numbers(assignment.phases_dir)

          # Insert after all current phases (at end of queue before pending)
          # Find last done or failed phase
          base_number = if state.current
                          state.current.number
                        elsif state.last_done
                          state.last_done.number
                        else
                          original.number
                        end

          new_number = Atoms::NumberGenerator.next_after(base_number, existing_numbers)

          # Create retry phase with link to original
          file_path = phase_writer.create(
            phases_dir: assignment.phases_dir,
            number: new_number,
            name: original.name,
            instructions: original.instructions,
            status: :pending,
            added_by: "retry_of:#{original.number}"
          )

          # Update assignment timestamp
          assignment_manager.update(assignment)

          # Return updated state
          new_state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          retry_phase = new_state.phases.find { |s| s.number == new_number }

          {
            assignment: assignment,
            state: new_state,
            retry: retry_phase,
            original: original
          }
        end

        private

        # Archive source config into the task's phases/ directory.
        # If config is already in a phases/ directory, keeps it in place.
        # Otherwise moves job.yaml to <task>/phases/<assignment_id>-job.yml for provenance.
        #
        # @param config_path [String] Path to the original job.yaml
        # @param assignment_id [String] Assignment identifier for filename prefix
        # @return [String] Path to archived file
        def archive_source_config(config_path, assignment_id)
          expanded_path = File.expand_path(config_path)
          parent_dir = File.dirname(expanded_path)

          # If already in a phases/ directory, keep it there
          return expanded_path if File.basename(parent_dir) == "phases"

          # Otherwise, move to task's phases/ directory
          phases_dir = File.join(parent_dir, "phases")
          FileUtils.mkdir_p(phases_dir)

          dest = File.join(phases_dir, "#{assignment_id}-job.yml")
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

        # Auto-complete parent phases when all their children are done.
        # Walks up the hierarchy marking parents as done, handling multi-level
        # completion in a single pass (grandparents become eligible when parents complete).
        #
        # @param state [Models::QueueState] Current queue state
        # @param assignment [Models::Assignment] Current assignment
        def auto_complete_parents(state, assignment)
          completed_any = true
          # Track completed phase numbers in this pass (avoids fragile ivar mutation)
          completed_this_pass = Set.new

          # Safety guard: max iterations = total phases to prevent infinite loops
          max_iterations = state.phases.size

          # Loop until no more parents can be completed
          # This handles multi-level hierarchies where completing a parent
          # makes the grandparent eligible for completion
          iterations = 0
          while completed_any && iterations < max_iterations
            iterations += 1
            completed_any = false

            # Find all pending/in_progress parent phases that have children
            eligible_parents = state.phases.select do |s|
              (s.status == :pending || s.status == :in_progress) &&
                !completed_this_pass.include?(s.number)
            end

            eligible_parents.each do |phase|
              children = state.children_of(phase.number)
              next if children.empty?

              # If all children are done (or completed this pass), mark parent as done too
              all_done = children.all? do |c|
                c.status == :done || completed_this_pass.include?(c.number)
              end

              if all_done
                phase_writer.mark_done(
                  phase.file_path,
                  report_content: "Auto-completed: all child phases finished.",
                  reports_dir: assignment.reports_dir
                )
                completed_this_pass << phase.number
                completed_any = true
              end
            end
          end

          # Warn if safety limit was reached while still completing parents
          if iterations >= max_iterations && completed_any
            warn "[ace-assign] Warning: auto_complete_parents reached iteration limit (#{max_iterations}). " \
                 "Some parent phases may not have been auto-completed."
          end
        end

        # Find the next phase to work on using hierarchical rules.
        #
        # @param state [Models::QueueState] Current queue state
        # @param completed_number [String] Number of just-completed phase
        # @return [Models::Phase, nil] Next phase to work on
        def find_next_phase(state, completed_number)
          # First priority: pending children of the completed phase
          children = state.children_of(completed_number)
          pending_child = children.find { |c| c.status == :pending }
          return pending_child if pending_child

          # Second priority: next workable phase (respects hierarchy)
          # Uses next_workable to skip parents that have incomplete children
          state.next_workable
        end

        # Calculate insertion point for a new phase.
        #
        # @param after [String, nil] Insert after this phase number
        # @param as_child [Boolean] Insert as child (true) or sibling (false)
        # @param state [Models::QueueState] Current queue state
        # @param existing_numbers [Array<String>] Existing phase numbers
        # @return [Array<String, Array>] [new_number, phases_to_renumber]
        def calculate_insertion_point(after:, as_child:, state:, existing_numbers:)
          if after
            if as_child
              # Insert as first child of 'after'
              new_number = Atoms::PhaseNumbering.next_child(after, existing_numbers)
              [new_number, []]
            else
              # Insert as sibling after 'after'
              new_number = Atoms::PhaseNumbering.next_sibling(after)

              # Check if this number already exists
              if existing_numbers.include?(new_number)
                # Need to renumber
                renumber_list = Atoms::PhaseNumbering.phases_to_renumber(new_number, existing_numbers)
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
