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
        attr_reader :assignment_manager, :queue_scanner, :phase_writer, :phase_renumberer, :skill_source_resolver

        def initialize(cache_base: nil)
          @assignment_manager = Molecules::AssignmentManager.new(cache_base: cache_base)
          @queue_scanner = Molecules::QueueScanner.new
          @phase_writer = Molecules::PhaseWriter.new
          @skill_source_resolver = Molecules::SkillAssignSourceResolver.new
          @phase_catalog = nil
          @phase_renumberer = Molecules::PhaseRenumberer.new(
            phase_writer: @phase_writer,
            queue_scanner: @queue_scanner
          )
        end

        # Start a new workflow assignment from config file
        #
        # @param config_path [String] Path to job.yaml config
        # @param parent_id [String, nil] Parent assignment ID for hierarchy linking
        # @return [Hash] Result with assignment and first phase
        def start(config_path, parent_id: nil)
          raise ConfigErrors::NotFound, "Config file not found: #{config_path}" unless File.exist?(config_path)

          config = YAML.safe_load_file(config_path, permitted_classes: [Time, Date])

          assignment_config = config["assignment"] || {}
          phases_config = config["phases"] || []

          raise Error, "No phases defined in config" if phases_config.empty?

          # Enrich phases using declared workflow/skill assign metadata.
          phases_config = enrich_declared_sub_phases(phases_config)

          # Expand sub-phase declarations into batch parent + child phases
          phases_config = expand_sub_phases(phases_config)
          phases_config = materialize_skill_backed_phases(phases_config)

          # Create assignment
          assignment = assignment_manager.create(
            name: assignment_config["name"] || File.basename(config_path, ".yaml"),
            description: assignment_config["description"],
            source_config: config_path,
            parent: parent_id
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

          # Mark first workable phase as in_progress.
          # This skips batch parent containers that have incomplete children.
          initial_state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          first_workable = initial_state.next_workable
          phase_writer.mark_in_progress(first_workable.file_path) if first_workable

          # Archive source config into task's phases directory and update assignment metadata
          archived_path = archive_source_config(config_path, assignment.id)
          assignment = Models::Assignment.new(
            id: assignment.id,
            name: assignment.name,
            description: assignment.description,
            created_at: assignment.created_at,
            updated_at: assignment.updated_at,
            source_config: archived_path,
            cache_dir: assignment.cache_dir,
            parent: assignment.parent
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
          raise AssignmentErrors::NoActive, "No active assignment. Use 'ace-assign create <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          {
            assignment: assignment,
            state: state,
            current: state.current
          }
        end

        # Start a pending phase.
        #
        # Rules:
        # - Fails if any phase is already in progress (strict mode)
        # - Starts an explicit pending target when provided
        # - Otherwise starts the next workable pending phase
        #
        # @param phase_number [String, nil] Optional target phase number
        # @param fork_root [String, nil] Optional subtree root scope
        # @return [Hash] Result with started phase and updated state
        def start_phase(phase_number: nil, fork_root: nil)
          assignment = assignment_manager.find_active
          raise AssignmentErrors::NoActive, "No active assignment. Use 'ace-assign create <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          raise PhaseErrors::InvalidState, "Cannot start: phase #{state.current.number} is already in progress. Finish or fail it first." if state.current

          fork_root = fork_root&.strip
          target_phase = if phase_number && !phase_number.to_s.strip.empty?
                           find_target_phase_for_start(state, phase_number, fork_root)
                         elsif fork_root && !fork_root.empty?
                           raise PhaseErrors::NotFound, "Subtree root #{fork_root} not found in assignment." unless state.find_by_number(fork_root)
                           state.next_workable_in_subtree(fork_root)
                         else
                           state.next_workable
                         end

          unless target_phase
            if fork_root && !fork_root.empty?
              raise PhaseErrors::InvalidState, "No pending workable phase found in subtree #{fork_root}."
            end
            raise PhaseErrors::InvalidState, "No pending workable phase found."
          end

          phase_writer.mark_in_progress(target_phase.file_path)
          assignment_manager.update(assignment)

          new_state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          {
            assignment: assignment,
            state: new_state,
            started: new_state.find_by_number(target_phase.number),
            current: new_state.current
          }
        end

        # Finish an in-progress phase and advance queue state.
        #
        # @param report_content [String] Completion report content
        # @param phase_number [String, nil] Optional in-progress phase number to finish
        # @param fork_root [String, nil] Optional subtree root to constrain advancement
        # @return [Hash] Result with completed phase and updated state
        def finish_phase(report_content:, phase_number: nil, fork_root: nil)
          assignment = assignment_manager.find_active
          raise AssignmentErrors::NoActive, "No active assignment. Use 'ace-assign create <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          current = find_target_phase_for_finish(state, phase_number, fork_root)
          raise Error, "No phase currently in progress. Try 'ace-assign start' or 'ace-assign retry'." unless current

          # Enforce hierarchy: cannot mark parent as done with incomplete children
          if state.has_incomplete_children?(current.number)
            incomplete = state.children_of(current.number).reject { |c| c.status == :done }
            incomplete_nums = incomplete.map(&:number).join(", ")
            raise Error, "Cannot complete phase #{current.number}: has incomplete children (#{incomplete_nums}). Complete children first or use 'ace-assign fail' to mark as failed."
          end

          # Mark current phase as done
          phase_writer.mark_done(current.file_path, report_content: report_content, reports_dir: assignment.reports_dir)

          # Rescan to get updated state after marking done
          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)

          # Auto-complete parent phases if all their children are done
          auto_complete_parents(state, assignment)

          # Re-scan to get fresh state after auto-completions
          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)

          fork_root = fork_root&.strip
          # Find next phase to work on using hierarchical rules.
          # When fork_root is provided, keep advancement inside that subtree.
          next_phase = if fork_root && !fork_root.empty? && state.find_by_number(fork_root)
                         find_next_phase_in_subtree(state, current.number, fork_root)
                       else
                         find_next_phase(state, current.number)
                       end
          if next_phase
            phase_writer.mark_in_progress(next_phase.file_path)
          end

          assignment_manager.update(assignment)

          new_state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          {
            assignment: assignment,
            state: new_state,
            completed: current,
            current: new_state.current
          }
        end

        # Complete current phase with report and advance
        #
        # Legacy bridge: preserves single-call semantics for fork-run callers.
        # Previously, advance() auto-started the next phase as a side effect.
        # The new start/finish split makes this explicit, but advance() retains
        # the auto-start behavior for subtree entry so fork-run workflows
        # (which call advance() with fork_root) continue to work unchanged.
        #
        # @param report_path [String] Path to report file
        # @param fork_root [String, nil] Optional subtree root to constrain advancement
        # @return [Hash] Result with updated state
        def advance(report_path, fork_root: nil)
          raise ConfigErrors::NotFound, "Report file not found: #{report_path}" unless File.exist?(report_path)

          # Auto-start the next workable subtree phase when fork_root is given but
          # no phase in the subtree is yet in_progress (subtree entry case).
          fork_root_str = fork_root&.strip
          if fork_root_str && !fork_root_str.empty?
            assignment = assignment_manager.find_active
            if assignment
              state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
              active_in_subtree = state.in_progress_in_subtree(fork_root_str)
              if active_in_subtree.size > 1
                active_refs = active_in_subtree.map { |phase| "#{phase.number}(#{phase.name})" }.join(", ")
                raise PhaseErrors::InvalidState, "Cannot advance subtree #{fork_root_str}: multiple phases are in progress (#{active_refs})."
              end

              if active_in_subtree.empty?
                next_workable = state.next_workable_in_subtree(fork_root_str)
                phase_writer.mark_in_progress(next_workable.file_path) if next_workable
              end
            end
          end

          finish_phase(report_content: File.read(report_path), fork_root: fork_root)
        end

        # Mark current phase as failed
        #
        # @param message [String] Error message
        # @return [Hash] Result with updated state
        def fail(message)
          assignment = assignment_manager.find_active
          raise AssignmentErrors::NoActive, "No active assignment. Use 'ace-assign create <job.yaml>' to begin." unless assignment

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
          raise AssignmentErrors::NoActive, "No active assignment. Use 'ace-assign create <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          existing_numbers = queue_scanner.phase_numbers(assignment.phases_dir)

          # Validate --after phase exists
          if after && !existing_numbers.include?(after)
            raise PhaseErrors::NotFound, "Phase #{after} not found. Available phases: #{existing_numbers.join(', ')}"
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

          rebalance_after_child_injection(assignment: assignment, state: state, parent_number: after) if as_child && after

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
          raise AssignmentErrors::NoActive, "No active assignment. Use 'ace-assign create <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)

          # Find the phase to retry
          original = state.find_by_number(phase_ref.to_s)
          raise PhaseErrors::NotFound, "Phase #{phase_ref} not found in queue" unless original

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

        # Enrich phases by resolving workflow-level or legacy skill-level assign source metadata.
        #
        # If a phase has `workflow: ...` or `skill: ...` and no explicit sub_phases,
        # this resolves the workflow and applies
        # workflow `assign.sub-phases` as phase sub_phases for deterministic runtime expansion.
        #
        # @param phases_config [Array<Hash>] Original phases from config
        # @return [Array<Hash>] Enriched phases
        def enrich_declared_sub_phases(phases_config)
          phases_config.map do |phase|
            next phase unless phase.is_a?(Hash)

            sub_phases = phase["sub_phases"] || phase["sub-phases"]
            next phase if sub_phases.is_a?(Array) && sub_phases.any?

            assign_config = resolve_phase_assign_config(phase)
            next phase unless assign_config

            resolved_sub_phases = assign_config[:sub_phases]
            next phase unless resolved_sub_phases.is_a?(Array) && resolved_sub_phases.any?

            enriched = phase.merge("sub_phases" => resolved_sub_phases)
            enriched["context"] ||= assign_config[:context] if assign_config[:context]
            enriched
          end
        end

        # Expand phases with sub_phases into batch parent + child structure.
        #
        # When a phase declares `sub_phases` (from workflow frontmatter), it becomes
        # a batch parent with fork context, and each sub-phase becomes a child phase.
        # This reuses the existing batch-parent pattern from compose.
        #
        # Numbers are pre-assigned based on the original index position so that
        # subsequent phases keep their expected numbering (e.g., 010, 020, 030)
        # regardless of how many children are expanded.
        #
        # @param phases_config [Array<Hash>] Original phases from config
        # @return [Array<Hash>] Expanded phases with parent-child numbers
        def expand_sub_phases(phases_config)
          # Check if any phase has sub_phases; return early if none
          has_sub_phases = phases_config.any? do |phase|
            subs = phase["sub_phases"] || phase["sub-phases"]
            subs.is_a?(Array) && subs.any?
          end
          return phases_config unless has_sub_phases

          expanded = []

          phases_config.each_with_index do |phase, index|
            sub_phases = phase["sub_phases"] || phase["sub-phases"]
            parent_number = phase["number"] || Atoms::NumberGenerator.from_index(index)

            if sub_phases.is_a?(Array) && sub_phases.any?
              # Create split parent orchestration node
              parent_context = phase["context"] || "fork"
              parent_instructions = phase["instructions"]
              parent_phase = build_split_parent_phase(
                phase: phase,
                parent_number: parent_number,
                parent_context: parent_context,
                sub_phases: sub_phases
              )
              expanded << parent_phase

              # Create child phases under the parent
              sub_phases.each_with_index do |sub_name, sub_idx|
                child_number = Atoms::NumberGenerator.subtask(parent_number, sub_idx + 1)
                expanded << build_child_sub_phase(
                  sub_name: sub_name,
                  child_number: child_number,
                  parent_number: parent_number,
                  parent_phase: phase,
                  parent_instructions: parent_instructions,
                  parent_context: parent_context
                )
              end
            else
              # Pre-assign number to non-sub-phase entries to maintain position
              expanded << phase.merge("number" => parent_number)
            end
          end

          expanded
        end

        # Build a split parent orchestration phase.
        #
        # Parent nodes with sub_phases are subtree delegation roots and should not
        # execute the original skill directly. The parent instructions explain
        # how to drive the subtree; the original goals are preserved for context.
        #
        # @param phase [Hash] Original parent phase config
        # @param parent_number [String] Parent phase number
        # @param parent_context [String] Parent execution context
        # @param sub_phases [Array<String>] Declared sub-phase names
        # @return [Hash] Parent phase config for runtime queue
        def build_split_parent_phase(phase:, parent_number:, parent_context:, sub_phases:)
          source_skill = phase["skill"]
          original_text = normalize_instructions(phase["instructions"]).strip
          definition = find_phase_definition("split-subtree-root") || {}

          lines = split_parent_instruction_lines(
            definition: definition,
            parent_number: parent_number,
            parent_context: parent_context,
            source_skill: source_skill,
            sub_phases: sub_phases
          )

          unless original_text.empty?
            lines << ""
            lines << (definition["goal_header"] || "Goal to satisfy through child phases:")
            original_text.lines.map(&:strip).reject(&:empty?).each do |line|
              lines << "- #{line}"
            end
          end

          parent_phase = phase.merge(
            "number" => parent_number,
            "context" => parent_context,
            "instructions" => lines.join("\n")
          )
          parent_phase.delete("sub_phases")
          parent_phase.delete("sub-phases")
          parent_phase.delete("skill")
          parent_phase.delete("workflow")
          parent_phase["source_skill"] = source_skill if source_skill
          parent_phase["split_phase_type"] = definition["name"] || "split-subtree-root"
          parent_phase
        end

        # Render split parent instructions from catalog with fallback defaults.
        #
        # @param definition [Hash] Catalog definition for split parent phase
        # @param parent_number [String] Parent phase number
        # @param parent_context [String] Parent execution context
        # @param source_skill [String, nil] Source skill of original parent phase
        # @param sub_phases [Array<String>] Child phase names
        # @return [Array<String>] Rendered instruction lines
        def split_parent_instruction_lines(definition:, parent_number:, parent_context:, source_skill:, sub_phases:)
          instructions = definition["instructions"].is_a?(Hash) ? definition["instructions"] : {}
          context_key = parent_context == "fork" ? "fork" : "inline"
          template_lines = Array(instructions["common"]) + Array(instructions[context_key])
          template_lines = default_split_parent_instruction_lines(parent_context) if template_lines.empty?

          template_lines = template_lines.map(&:to_s)
          template_lines.reject! { |line| line.include?("{{source_skill}}") && source_skill.to_s.strip.empty? }

          variables = {
            "parent_number" => parent_number,
            "parent_context" => parent_context,
            "source_skill" => source_skill.to_s,
            "sub_phases" => sub_phases.join(", ")
          }

          template_lines
            .map { |line| interpolate_template_line(line, variables) }
            .map(&:strip)
            .reject(&:empty?)
        end

        # Default split parent instruction lines used when catalog entry is missing.
        #
        # @param parent_context [String]
        # @return [Array<String>]
        def default_split_parent_instruction_lines(parent_context)
          lines = [
            "Subtree root orchestrator phase.",
            "This phase is orchestration-only.",
            "Do not execute the parent workflow directly in this phase.",
            "Child phases: {{sub_phases}}."
          ]

          if parent_context == "fork"
            lines.concat(
              [
                "Delegate this subtree into forked context:",
                "- ace-assign fork-run --assignment <assignment-id>@{{parent_number}}",
                "Inside the forked agent, continue execution within this subtree scope only."
              ]
            )
          else
            lines << "Execute only child phases under this node."
          end

          lines
        end

        # Apply simple {{token}} template substitution.
        #
        # @param line [String]
        # @param variables [Hash]
        # @return [String]
        def interpolate_template_line(line, variables)
          rendered = line.dup
          variables.each do |key, value|
            rendered = rendered.gsub("{{#{key}}}", value.to_s)
          end
          rendered
        end

        # Build a concrete child phase from a sub-phase name.
        #
        # Child phases inherit parent task context in instructions so skills can
        # extract concrete parameters (e.g., task refs) during execution.
        # Skill and context defaults are sourced from the phase catalog when available.
        #
        # @param sub_name [String] Child sub-phase name
        # @param child_number [String] Generated child phase number
        # @param parent_number [String] Parent phase number
        # @param parent_phase [Hash] Parent phase config
        # @param parent_instructions [String, Array<String>, nil] Parent instructions
        # @param parent_context [String, nil] Parent execution context
        # @return [Hash] Child phase config
        def build_child_sub_phase(sub_name:, child_number:, parent_number:, parent_phase:, parent_instructions:, parent_context:)
          phase_def = find_phase_definition(sub_name)
          parent_task_ref = extract_parent_taskref(parent_phase, parent_instructions)
          instructions = if phase_def&.dig("skill")
                           build_skill_backed_child_notes(sub_name, parent_instructions, task_ref: parent_task_ref)
                         else
                           build_child_instructions(sub_name, parent_instructions, phase_def, task_ref: parent_task_ref)
                         end
          child = {
            "number" => child_number,
            "name" => sub_name,
            "instructions" => instructions,
            "parent" => parent_number
          }
          child["taskref"] = parent_task_ref if parent_task_ref

          if phase_def
            child["workflow"] = phase_def["workflow"] if phase_def["workflow"]
            child["skill"] = phase_def["skill"] if phase_def["skill"] && !phase_def["workflow"]

            context_default = phase_def.dig("context", "default")
            child["context"] = context_default if context_default && parent_context != "fork"
          end

          child
        end

        # Build child instructions with parent context and phase focus.
        #
        # @param sub_name [String] Child sub-phase name
        # @param parent_instructions [String, Array<String>, nil] Parent instructions
        # @param phase_def [Hash, nil] Catalog definition for this sub-phase
        # @param task_ref [String, nil] Explicit task reference from parent metadata
        # @return [String] Rendered instructions
        def build_child_instructions(sub_name, parent_instructions, phase_def, task_ref: nil)
          parent_text = normalize_instructions(parent_instructions).strip
          focus = phase_def && phase_def["description"] ? phase_def["description"] : "Execute #{sub_name} sub-phase."
          focus = focus.gsub("<taskref>", task_ref) if task_ref && !task_ref.empty?
          context = compact_task_context(parent_text, task_ref: task_ref)
          action = child_action_instructions(sub_name, parent_text, task_ref: task_ref)

          sections = []
          sections << "Task context:\n#{context}" unless context.empty?
          sections << "Sub-phase focus:\n#{focus}"
          sections << "Action:\n#{action}"
          sections.join("\n\n")
        end

        def build_skill_backed_child_notes(sub_name, parent_instructions, task_ref: nil)
          parent_text = normalize_instructions(parent_instructions).strip
          context = compact_task_context(parent_text, task_ref: task_ref)
          notes = child_specific_notes(sub_name, parent_text)

          sections = []
          sections << "Task context:\n#{context}" unless context.empty?
          sections << "Assignment-specific context:\n#{notes}" unless notes.empty?
          sections.join("\n\n")
        end

        # Build compact task context for child sub-phases.
        # Avoid copying parent orchestration boilerplate into every child phase.
        #
        # @param parent_text [String]
        # @param task_ref [String, nil]
        # @return [String]
        def compact_task_context(parent_text, task_ref: nil)
          unless task_ref.nil? || task_ref.to_s.strip.empty?
            return "Task reference: #{task_ref}"
          end

          return "" if parent_text.nil? || parent_text.empty?

          task_refs = parent_text.scan(/\b\d+\.\d+\b/).uniq
          return "Task reference: #{task_refs.join(', ')}" if task_refs.any?

          relevant_lines = parent_text.lines.map(&:strip).reject(&:empty?).reject do |line|
            line == "Task context:" || line == "Assignment-specific context:"
          end
          first_line = relevant_lines.first
          return "" unless first_line

          return first_line if first_line.start_with?("Task request:", "Task reference:")

          "Task request: #{first_line}"
        end

        # Build explicit, step-specific action instructions.
        #
        # @param sub_name [String]
        # @param parent_text [String]
        # @param task_ref [String, nil]
        # @return [String]
        def child_action_instructions(sub_name, parent_text, task_ref: nil)
          task_refs = if task_ref && !task_ref.to_s.strip.empty?
                        [task_ref.to_s]
                      else
                        parent_text.to_s.scan(/\b\d+\.\d+\b/).uniq
                      end
          task_hint = task_refs.any? ? " for task #{task_refs.join(', ')}" : ""

          case sub_name
          when "onboard"
            "- Load project context#{task_hint} using the phase workflow instructions.\n- Confirm required files and workflow context are available."
          when "plan-task"
            "- Analyze requirements#{task_hint}.\n- Plan against the behavioral spec structure: cover Interface Contract, Error Handling, Edge Cases, and operating modes (dry-run, force, verbose, quiet) where relevant.\n- If the spec is missing details needed for implementation, include them in a \"Behavioral Gaps\" section instead of silently working around omissions.\n- Produce a concrete implementation plan with acceptance checks."
          when "work-on-task"
            "- Implement the required changes#{task_hint}.\n- Verify behavior with relevant checks/tests before reporting completion."
          when "pre-commit-review"
            pre_commit_review_action_instructions(task_hint: task_hint)
          when "verify-test"
            "- Identify modified packages#{task_hint}.\n- For each modified package, run: cd <package> && ace-test --profile 6\n- If no package-level code changes are present, mark this phase skipped with a clear reason."
          when /\Arelease(?:-.+)?\z/
            "- Release all modified packages and update both package and root changelogs.\n- Follow semantic versioning expectations for this phase."
          else
            "- Execute the #{sub_name} step."
          end
        end

        def child_specific_notes(sub_name, parent_text)
          return "" if parent_text.nil? || parent_text.empty?

          lines = parent_text.lines.map(&:strip).reject(&:empty?)
          relevant = lines.filter_map do |line|
            if line.match?(/\AChild #{Regexp.escape(sub_name)}:/i)
              "- #{line.sub(/\AChild #{Regexp.escape(sub_name)}:\s*/i, "")}"
            elsif line.start_with?("Focus:")
              "- #{line}"
            end
          end

          relevant.join("\n")
        end

        def materialize_skill_backed_phases(phases_config)
          phases_config.map do |phase|
            materialize_skill_backed_phase(phase)
          end
        end

        def materialize_skill_backed_phase(phase)
          return phase unless phase.is_a?(Hash)
          return phase if phase["split_phase_type"]

          rendering = resolve_phase_rendering(phase)
          return phase unless rendering

          rendered_instructions = render_skill_backed_phase_instructions(
            phase: phase,
            rendering: rendering
          )

          materialized = phase.merge(
            "instructions" => rendered_instructions,
            "workflow" => rendering["workflow"]
          )
          materialized["source_skill"] = rendering["source_skill"] || rendering["skill"] if rendering["source_skill"] || rendering["skill"]
          materialized["source_workflow"] = rendering["workflow"] if rendering["workflow"] && !rendering["workflow"].empty?
          materialized.delete("skill")
          materialized
        end

        def resolve_phase_rendering(phase)
          explicit_workflow = phase["workflow"]&.to_s&.strip
          if explicit_workflow && !explicit_workflow.empty?
            canonical_phase = find_phase_definition(phase["name"]&.to_s)
            source_skill = phase["source_skill"]&.to_s&.strip
            source_skill = canonical_phase&.dig("source_skill") if source_skill.nil? || source_skill.empty?
            rendering = skill_source_resolver.resolve_workflow_rendering(
              explicit_workflow,
              phase_name: phase["name"]&.to_s,
              source_skill: source_skill
            )
            return canonical_phase ? canonical_phase.merge(rendering || {}) : rendering if rendering
          end

          explicit_skill = phase["skill"]&.to_s&.strip
          if explicit_skill && !explicit_skill.empty?
            return skill_source_resolver.resolve_skill_rendering(explicit_skill)
          end

          skill_source_resolver.resolve_phase_rendering(phase["name"]&.to_s)
        end

        def render_skill_backed_phase_instructions(phase:, rendering:)
          if phase_render_mode(rendering) == "phase_template"
            return render_phase_template_instructions(phase: phase, rendering: rendering)
          end

          sections = []

          task_ref = extract_parent_taskref(phase, phase["instructions"])
          task_context = task_ref && !task_ref.empty? ? "Task reference: #{task_ref}" : compact_task_context(normalize_instructions(phase["instructions"]), task_ref: task_ref)
          sections << "Task context:\n#{task_context}" unless task_context.empty?

          body = rendering["body"].to_s.strip
          sections << body unless body.empty?

          assignment_notes = assignment_specific_notes(
            phase_name: phase["name"]&.to_s,
            instructions: phase["instructions"]
          )
          sections << "Assignment-specific context:\n#{assignment_notes}" unless assignment_notes.empty?

          sections.join("\n\n")
        end

        def render_phase_template_instructions(phase:, rendering:)
          sections = []

          task_ref = extract_parent_taskref(phase, phase["instructions"])
          task_context = task_ref && !task_ref.empty? ? "Task reference: #{task_ref}" : compact_task_context(normalize_instructions(phase["instructions"]), task_ref: task_ref)
          sections << "Task context:\n#{task_context}" unless task_context.empty?

          description = rendering["description"].to_s.strip
          sections << "Phase focus:\n#{description}" unless description.empty?

          steps = render_phase_template_steps(rendering["steps"])
          sections << "Steps:\n#{steps}" unless steps.empty?

          skip_guidance = render_phase_template_skip_guidance(rendering["when_to_skip"])
          sections << "Skip when:\n#{skip_guidance}" unless skip_guidance.empty?

          assignment_notes = assignment_specific_notes(
            phase_name: phase["name"]&.to_s,
            instructions: phase["instructions"]
          )
          sections << "Assignment-specific context:\n#{assignment_notes}" unless assignment_notes.empty?

          sections.join("\n\n")
        end

        def render_phase_template_steps(steps)
          Array(steps).filter_map do |step|
            next unless step.is_a?(Hash)

            description = step["description"]&.to_s&.strip
            next if description.nil? || description.empty?

            line = "- #{description}"
            conditional = step["conditional"]&.to_s&.strip
            note = step["note"]&.to_s&.strip
            line += " If #{conditional}." unless conditional.nil? || conditional.empty?
            line += " #{note}" unless note.nil? || note.empty?
            line
          end.join("\n")
        end

        def render_phase_template_skip_guidance(conditions)
          Array(conditions).filter_map do |condition|
            text = condition&.to_s&.strip
            next if text.nil? || text.empty?

            "- #{text}"
          end.join("\n")
        end

        def phase_render_mode(rendering)
          mode = rendering["render"]&.to_s&.strip
          return "workflow_body" if mode.nil? || mode.empty?

          mode
        end

        def assignment_specific_notes(phase_name:, instructions:)
          text = normalize_instructions(instructions).strip
          return "" if text.empty?

          filtered = text.lines.filter_map do |line|
            normalized = normalize_assignment_overlay_line(line)
            next if normalized.nil? || normalized.empty?
            next if normalized.start_with?("Task reference:", "Task request:")

            normalized
          end

          if phase_name == "work-on-task"
            filtered = filtered.reject do |line|
              line.start_with?("Implement task ") || line.start_with?("When complete, mark the task as done:")
            end
          end

          filtered = filtered.uniq
          filtered.map { |line| "- #{line}" }.join("\n")
        end

        def normalize_assignment_overlay_line(line)
          stripped = line.to_s.strip
          return nil if stripped.empty?
          return nil if stripped == "Task context:" || stripped == "Assignment-specific context:"

          stripped = stripped.sub(/\A-\s*/, "")
          stripped = stripped.sub(/\A-\s*/, "")
          stripped.strip
        end

        def resolve_phase_assign_config(phase)
          explicit_workflow = phase["workflow"]&.to_s&.strip
          if explicit_workflow && !explicit_workflow.empty?
            return skill_source_resolver.resolve_workflow_assign_config(
              explicit_workflow,
              phase_name: phase["name"]&.to_s,
              source_skill: phase["source_skill"]&.to_s
            )
          end

          skill_name = phase["skill"]&.to_s
          return nil if skill_name.nil? || skill_name.empty?

          skill_source_resolver.resolve_assign_config(skill_name)
        end

        def pre_commit_review_action_instructions(task_hint:)
          subtree_cfg = normalized_subtree_config
          allowlist = subtree_cfg[:native_review_clients]
          allowlist_text = allowlist.empty? ? "<none>" : allowlist.join(", ")

          lines = []
          lines << "- Resolve subtree review config#{task_hint}: pre_commit_review=#{subtree_cfg[:pre_commit_review]}, mode=#{subtree_cfg[:pre_commit_review_provider]}, block=#{subtree_cfg[:pre_commit_review_block]}."
          if subtree_cfg[:pre_commit_review] == false || subtree_cfg[:pre_commit_review_provider] == "skip"
            lines << "- Pre-commit review is disabled by config; mark this phase skipped with the config reason and continue."
            return lines.join("\n")
          end

          lines << "- Detect active client/provider from fork session metadata first (`.ace-local/assign/<assignment-id>/sessions/<fork-root>-session.yml`, key: provider)."
          lines << "- If session metadata is unavailable, fallback to `execution.provider` from assign config."
          lines << "- Allowed native review clients: #{allowlist_text}."
          lines << "- If detected client is allowed and mode is `auto` or `native`, run native `/review` on the current diff."
          lines << "- If client is not allowed or native `/review` is unavailable, skip this phase gracefully and continue."
          lines << "- Summarize findings with severity counts and keep raw output when structure is incomplete."
          lines << "- If `pre_commit_review_block` is true and a critical finding is confidently detected, fail this phase with evidence to block release."
          lines.join("\n")
        end

        def normalized_subtree_config
          subtree = Ace::Assign.config["subtree"]
          subtree = {} unless subtree.is_a?(Hash)

          config = {
            pre_commit_review: subtree.key?("pre_commit_review") ? subtree["pre_commit_review"] : true,
            pre_commit_review_provider: (subtree["pre_commit_review_provider"] || "auto").to_s,
            pre_commit_review_block: subtree.key?("pre_commit_review_block") ? subtree["pre_commit_review_block"] : false,
            native_review_clients: Array(subtree["native_review_clients"]).map(&:to_s).map(&:strip).reject(&:empty?)
          }

          if config[:pre_commit_review] && config[:native_review_clients].empty?
            warn "[ace-assign] pre_commit_review enabled but native_review_clients is empty - review will always skip"
          end

          config
        end

        # Resolve task reference from explicit metadata first, then parent instruction text.
        #
        # @param parent_phase [Hash]
        # @param parent_instructions [String, Array<String>, nil]
        # @return [String, nil]
        def extract_parent_taskref(parent_phase, parent_instructions)
          explicit = parent_phase["taskref"] || parent_phase["task_ref"]
          explicit_value = explicit.to_s.strip
          return explicit_value unless explicit_value.empty?

          parent_text = normalize_instructions(parent_instructions)
          inferred = parent_text.scan(/\b\d+\.\d+\b/).uniq
          return nil if inferred.empty?

          inferred.join(", ")
        end

        # Lookup phase definition from catalog by phase name.
        #
        # @param phase_name [String] Name of phase
        # @return [Hash, nil] Catalog definition
        def find_phase_definition(phase_name)
          Atoms::CatalogLoader.find_by_name(phase_catalog, phase_name)
        end

        # Load phase catalog from project override or gem defaults.
        #
        # @return [Array<Hash>] Loaded phase definitions
        def phase_catalog
          @phase_catalog ||= begin
            project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
            gem_root = Gem.loaded_specs["ace-assign"]&.gem_dir || File.expand_path("../../../..", __dir__)

            project_catalog = File.join(project_root, ".ace", "assign", "catalog", "phases")
            default_catalog = File.join(gem_root, ".ace-defaults", "assign", "catalog", "phases")

            default_phases = Atoms::CatalogLoader.load_all(default_catalog)
            base_catalog = if File.directory?(project_catalog)
                             project_phases = Atoms::CatalogLoader.load_all(project_catalog)
                             merge_phase_catalog(default_phases, project_phases)
                           else
                             default_phases
                           end

            canonical_phases = skill_source_resolver.assign_phase_catalog
            merge_phase_catalog(base_catalog, canonical_phases)
          end
        end

        # Merge default and project phase catalogs by phase name.
        # Later definitions override earlier ones with matching names.
        #
        # @param default_phases [Array<Hash>]
        # @param project_phases [Array<Hash>]
        # @return [Array<Hash>]
        def merge_phase_catalog(default_phases, project_phases)
          index = {}
          order = []

          default_phases.each do |phase|
            name = phase["name"]
            next if name.nil? || name.empty?

            index[name] = phase
            order << name
          end

          project_phases.each do |phase|
            name = phase["name"]
            next if name.nil? || name.empty?

            order << name unless index.key?(name)
            index[name] = deep_merge_phase_definition(index[name], phase)
          end

          order.map { |name| index[name] }.compact
        end

        def deep_merge_phase_definition(base, override)
          return override unless base.is_a?(Hash)
          return base unless override.is_a?(Hash)

          merged = base.dup
          override.each do |key, value|
            merged[key] =
              if merged[key].is_a?(Hash) && value.is_a?(Hash)
                deep_merge_phase_definition(merged[key], value)
              else
                value
              end
          end
          merged
        end

        # Archive source config into the task's jobs/ directory.
        # If config is already in a jobs/ or phases/ directory, keeps it in place.
        # Otherwise moves job.yaml to <task>/jobs/<assignment_id>-job.yml for provenance.
        #
        # @param config_path [String] Path to the original job.yaml
        # @param assignment_id [String] Assignment identifier for filename prefix
        # @return [String] Path to archived file
        def archive_source_config(config_path, assignment_id)
          expanded_path = File.expand_path(config_path)
          parent_dir = File.dirname(expanded_path)

          # Keep pre-rendered hidden/job specs and legacy phase archives stable.
          return expanded_path if %w[jobs phases].include?(File.basename(parent_dir))

          # Otherwise, move to task's jobs/ directory.
          jobs_dir = File.join(parent_dir, "jobs")
          FileUtils.mkdir_p(jobs_dir)

          dest = File.join(jobs_dir, "#{assignment_id}-job.yml")
          FileUtils.mv(expanded_path, dest)
          dest
        end

        def rebalance_after_child_injection(assignment:, state:, parent_number:)
          current = state.current
          return unless current && current.number == parent_number

          phase_writer.mark_pending(current.file_path)
          rebalanced_state = queue_scanner.scan(assignment.phases_dir, assignment: assignment)
          next_phase = rebalanced_state.next_workable_in_subtree(parent_number)
          phase_writer.mark_in_progress(next_phase.file_path) if next_phase
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

        def find_target_phase_for_start(state, phase_number, fork_root)
          target = state.find_by_number(phase_number)
          raise PhaseErrors::NotFound, "Phase #{phase_number} not found in queue" unless target

          if fork_root && !fork_root.empty?
            raise PhaseErrors::NotFound, "Subtree root #{fork_root} not found in assignment." unless state.find_by_number(fork_root)
            raise PhaseErrors::InvalidState, "Phase #{target.number} is outside scoped subtree #{fork_root}." unless state.in_subtree?(fork_root, target.number)
          end
          raise PhaseErrors::InvalidState, "Cannot start phase #{target.number}: status is #{target.status}, expected pending." unless target.status == :pending
          if state.has_incomplete_children?(target.number)
            raise PhaseErrors::InvalidState, "Cannot start phase #{target.number}: has incomplete children."
          end

          target
        end

        def find_target_phase_for_finish(state, phase_number, fork_root)
          fork_root = fork_root&.strip
          if phase_number && !phase_number.to_s.strip.empty?
            target = state.find_by_number(phase_number)
            raise PhaseErrors::NotFound, "Phase #{phase_number} not found in queue" unless target
            if fork_root && !fork_root.empty? && !state.in_subtree?(fork_root, target.number)
              raise PhaseErrors::InvalidState, "Phase #{target.number} is outside scoped subtree #{fork_root}."
            end
            raise PhaseErrors::InvalidState, "Cannot finish phase #{target.number}: status is #{target.status}, expected in_progress." unless target.status == :in_progress

            return target
          end

          current = state.current
          if fork_root && !fork_root.empty?
            raise PhaseErrors::NotFound, "Subtree root #{fork_root} not found in assignment." unless state.find_by_number(fork_root)
            active_in_subtree = state.in_progress_in_subtree(fork_root)
            if active_in_subtree.size > 1
              active_refs = active_in_subtree.map { |phase| "#{phase.number}(#{phase.name})" }.join(", ")
              raise PhaseErrors::InvalidState, "Cannot finish in subtree #{fork_root}: multiple phases are in progress (#{active_refs})."
            end
            if current.nil? || !state.in_subtree?(fork_root, current.number)
              current = state.current_in_subtree(fork_root)
            end
            return nil if current.nil?
          end

          current
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

        # Find next phase within a constrained subtree.
        #
        # @param state [Models::QueueState] Current queue state
        # @param completed_number [String] Number of just-completed phase
        # @param root_number [String] Root of fork-scoped subtree
        # @return [Models::Phase, nil] Next phase in subtree, or nil when subtree done
        def find_next_phase_in_subtree(state, completed_number, root_number)
          # First priority: pending direct children of completed phase within subtree
          children = state.children_of(completed_number)
          pending_child = children.find { |c| c.status == :pending && state.in_subtree?(root_number, c.number) }
          return pending_child if pending_child

          # Second priority: next workable phase within subtree
          state.next_workable_in_subtree(root_number)
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
