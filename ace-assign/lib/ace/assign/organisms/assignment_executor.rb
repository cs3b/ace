# frozen_string_literal: true

require "fileutils"
require "yaml"

module Ace
  module Assign
    module Organisms
      # Orchestrates workflow operations on the work queue.
      #
      # Implements the state machine for queue operations:
      # start → advance → complete (with fail/add/retry branches)
      class AssignmentExecutor
        DEFAULT_DYNAMIC_STEP_INSTRUCTIONS = "Complete this step and finish with: ace-assign finish --message report.md".freeze
        PROJECT_ROOT_SIGNAL = "project_root".freeze
        CATALOG_SIGNAL = "catalog".freeze

        attr_reader :assignment_manager, :queue_scanner, :step_writer, :step_renumberer, :skill_source_resolver

        class << self
          def clear_caches!
            @cache_store = { step_catalog_cache: {} }
          end

          def cache_store
            @cache_store ||= { step_catalog_cache: {} }
          end

          private

          def cached_value(store_key, key)
            cache_store[store_key][key]
          end

          def store_cached_value(store_key, key, value)
            cache_store[store_key][key] = value
          end
        end

        def initialize(cache_base: nil, skill_source_resolver: nil, step_catalog: nil)
          @assignment_manager = Molecules::AssignmentManager.new(cache_base: cache_base)
          @queue_scanner = Molecules::QueueScanner.new
          @step_writer = Molecules::StepWriter.new
          @skill_source_resolver = skill_source_resolver || Molecules::SkillAssignSourceResolver.new
          @step_catalog = nil
          @step_catalog_from_fixture = step_catalog
          @step_catalog_from_fixture_set = !step_catalog.nil?
          @step_catalog_loaded = false
          @step_renumberer = Molecules::StepRenumberer.new(
            step_writer: @step_writer,
            queue_scanner: @queue_scanner
          )
        end

        # Start a new workflow assignment from config file
        #
        # @param config_path [String] Path to job.yaml config
        # @param parent_id [String, nil] Parent assignment ID for hierarchy linking
        # @return [Hash] Result with assignment and first step
        def start(config_path, parent_id: nil)
          raise ConfigErrors::NotFound, "Config file not found: #{config_path}" unless File.exist?(config_path)

          config = YAML.safe_load_file(config_path, permitted_classes: [Time, Date])

          assignment_config = config["assignment"] || {}
          steps_config = config["steps"] || []

          raise Error, "No steps defined in config" if steps_config.empty?

          # Enrich steps using declared workflow/skill assign metadata.
          steps_config = enrich_declared_sub_steps(steps_config)

          # Expand sub-step declarations into batch parent + child steps
          steps_config = expand_sub_steps(steps_config)
          steps_config = materialize_skill_backed_steps(steps_config)

          # Create assignment
          assignment = assignment_manager.create(
            name: assignment_config["name"] || File.basename(config_path, ".yaml"),
            description: assignment_config["description"],
            source_config: config_path,
            parent: parent_id
          )

          # Create initial step files
          # Steps may have pre-assigned numbers (from expansion) or need auto-numbering
          steps_config.each_with_index do |step, index|
            # Use pre-assigned number if present, otherwise generate from index
            number = step["number"] || Atoms::NumberGenerator.from_index(index)
            extra = step.reject { |k, _| %w[name instructions number].include?(k) }
            step_writer.create(
              steps_dir: assignment.steps_dir,
              number: number,
              name: step["name"],
              instructions: normalize_instructions(step["instructions"]),
              status: :pending,
              extra: extra
            )
          end

          # Mark first workable step as in_progress.
          # This skips batch parent containers that have incomplete children.
          initial_state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          first_workable = initial_state.next_workable
          step_writer.mark_in_progress(first_workable.file_path) if first_workable

          # Archive source config into task's steps directory and update assignment metadata
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
          state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
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
          raise AssignmentErrors::NoActive, "No active assignment. Use 'ace-assign create --yaml <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          {
            assignment: assignment,
            state: state,
            current: state.current
          }
        end

        # Start a pending step.
        #
        # Rules:
        # - Fails if any step is already in progress (strict mode)
        # - Starts an explicit pending target when provided
        # - Otherwise starts the next workable pending step
        #
        # @param step_number [String, nil] Optional target step number
        # @param fork_root [String, nil] Optional subtree root scope
        # @return [Hash] Result with started step and updated state
        def start_step(step_number: nil, fork_root: nil)
          assignment = assignment_manager.find_active
          raise AssignmentErrors::NoActive, "No active assignment. Use 'ace-assign create --yaml <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          raise StepErrors::InvalidState, "Cannot start: step #{state.current.number} is already in progress. Finish or fail it first." if state.current

          fork_root = fork_root&.strip
          target_step = if step_number && !step_number.to_s.strip.empty?
            find_target_step_for_start(state, step_number, fork_root)
          elsif fork_root && !fork_root.empty?
            raise StepErrors::NotFound, "Subtree root #{fork_root} not found in assignment." unless state.find_by_number(fork_root)
            state.next_workable_in_subtree(fork_root)
          else
            state.next_workable
          end

          unless target_step
            if fork_root && !fork_root.empty?
              raise StepErrors::InvalidState, "No pending workable step found in subtree #{fork_root}."
            end
            raise StepErrors::InvalidState, "No pending workable step found."
          end

          step_writer.mark_in_progress(target_step.file_path)
          assignment_manager.update(assignment)

          new_state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          {
            assignment: assignment,
            state: new_state,
            started: new_state.find_by_number(target_step.number),
            current: new_state.current
          }
        end

        # Finish an in-progress step and advance queue state.
        #
        # @param report_content [String] Completion report content
        # @param step_number [String, nil] Optional in-progress step number to finish
        # @param fork_root [String, nil] Optional subtree root to constrain advancement
        # @return [Hash] Result with completed step and updated state
        def finish_step(report_content:, step_number: nil, fork_root: nil)
          assignment = assignment_manager.find_active
          raise AssignmentErrors::NoActive, "No active assignment. Use 'ace-assign create --yaml <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          current = find_target_step_for_finish(state, step_number, fork_root)
          raise Error, "No step currently in progress. Try 'ace-assign start' or 'ace-assign retry'." unless current

          # Enforce hierarchy: cannot mark parent as done with incomplete children
          if state.has_incomplete_children?(current.number)
            incomplete = state.children_of(current.number).reject { |c| c.status == :done }
            incomplete_nums = incomplete.map(&:number).join(", ")
            raise Error, "Cannot complete step #{current.number}: has incomplete children (#{incomplete_nums}). Complete children first or use 'ace-assign fail' to mark as failed."
          end

          # Mark current step as done
          step_writer.mark_done(current.file_path, report_content: report_content, reports_dir: assignment.reports_dir)

          # Rescan to get updated state after marking done
          state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)

          # Auto-complete parent steps if all their children are done
          auto_complete_parents(state, assignment)

          # Re-scan to get fresh state after auto-completions
          state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)

          fork_root = fork_root&.strip
          # Find next step to work on using hierarchical rules.
          # When fork_root is provided, keep advancement inside that subtree.
          next_step = if fork_root && !fork_root.empty? && state.find_by_number(fork_root)
            find_next_step_in_subtree(state, current.number, fork_root)
          else
            find_next_step(state, current.number)
          end
          if next_step
            step_writer.mark_in_progress(next_step.file_path)
          end

          assignment_manager.update(assignment)

          new_state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          {
            assignment: assignment,
            state: new_state,
            completed: current,
            current: new_state.current
          }
        end

        # Complete current step with report and advance
        #
        # Legacy bridge: preserves single-call semantics for fork-run callers.
        # Previously, advance() auto-started the next step as a side effect.
        # The new start/finish split makes this explicit, but advance() retains
        # the auto-start behavior for subtree entry so fork-run workflows
        # (which call advance() with fork_root) continue to work unchanged.
        #
        # @param report_path [String] Path to report file
        # @param fork_root [String, nil] Optional subtree root to constrain advancement
        # @return [Hash] Result with updated state
        def advance(report_path, fork_root: nil)
          raise ConfigErrors::NotFound, "Report file not found: #{report_path}" unless File.exist?(report_path)

          # Auto-start the next workable subtree step when fork_root is given but
          # no step in the subtree is yet in_progress (subtree entry case).
          fork_root_str = fork_root&.strip
          if fork_root_str && !fork_root_str.empty?
            assignment = assignment_manager.find_active
            if assignment
              state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
              active_in_subtree = state.in_progress_in_subtree(fork_root_str)
              if active_in_subtree.size > 1
                active_refs = active_in_subtree.map { |step| "#{step.number}(#{step.name})" }.join(", ")
                raise StepErrors::InvalidState, "Cannot advance subtree #{fork_root_str}: multiple steps are in progress (#{active_refs})."
              end

              if active_in_subtree.empty?
                next_workable = state.next_workable_in_subtree(fork_root_str)
                step_writer.mark_in_progress(next_workable.file_path) if next_workable
              end
            end
          end

          finish_step(report_content: File.read(report_path), fork_root: fork_root)
        end

        # Mark current step as failed
        #
        # @param message [String] Error message
        # @return [Hash] Result with updated state
        def fail(message)
          assignment = assignment_manager.find_active
          raise AssignmentErrors::NoActive, "No active assignment. Use 'ace-assign create --yaml <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          current = state.current
          raise Error, "No step currently in progress. Try 'ace-assign add' to add a new step or 'ace-assign retry' to retry a failed step." unless current

          # Mark step as failed
          step_writer.mark_failed(current.file_path, error_message: message)

          # Update assignment timestamp
          assignment_manager.update(assignment)

          # Return updated state (no automatic advancement after failure)
          new_state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          {
            assignment: assignment,
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
        def add(name, instructions, after: nil, as_child: false, added_by: nil, extra: {})
          assignment = assignment_manager.find_active
          raise AssignmentErrors::NoActive, "No active assignment. Use 'ace-assign create --yaml <job.yaml>' to begin." unless assignment

          step_name = name.to_s.strip
          raise Error, "Step name cannot be empty." if step_name.empty?

          state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          existing_numbers = queue_scanner.step_numbers(assignment.steps_dir)

          # Validate --after step exists
          if after && !existing_numbers.include?(after)
            raise StepErrors::NotFound, "Step #{after} not found. Available steps: #{existing_numbers.join(", ")}"
          end

          new_number, renumbered = calculate_insertion_point(
            after: after,
            as_child: as_child,
            state: state,
            existing_numbers: existing_numbers
          )

          # Renumber existing steps if needed (uses molecule with rollback support)
          if renumbered.any?
            step_renumberer.renumber(assignment.steps_dir, renumbered)
            # Refresh existing numbers after renumbering
            queue_scanner.step_numbers(assignment.steps_dir)
          end

          # Determine initial status upfront to avoid redundant I/O
          initial_status = state.current ? :pending : :in_progress

          # Build added_by metadata for audit trail
          added_by ||= if after && as_child
            "child_of:#{after}"
          elsif after
            "injected_after:#{after}"
          else
            "dynamic"
          end

          extra_frontmatter = normalize_batch_extra_fields(extra)

          # Create new step file with correct status
          step_writer.create(
            steps_dir: assignment.steps_dir,
            number: new_number,
            name: step_name,
            instructions: instructions,
            status: initial_status,
            added_by: added_by,
            parent: as_child ? after : nil,
            extra: extra_frontmatter
          )

          rebalance_after_child_injection(assignment: assignment, state: state, parent_number: after) if as_child && after

          # Update assignment timestamp
          assignment_manager.update(assignment)

          # Return updated state
          new_state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          new_step = new_state.steps.find { |s| s.number == new_number }

          {
            assignment: assignment,
            state: new_state,
            added: new_step,
            renumbered: renumbered
          }
        end

        # Add multiple steps dynamically from a pre-parsed steps array.
        #
        # @param steps [Array<Hash>] Step definitions loaded from YAML
        # @param after [String, nil] Insert after this step number
        # @param as_child [Boolean] Insert as children of +after+
        # @param source_file [String, nil] Source YAML path (for added_by audit metadata)
        # @note Structural validation is performed for the full batch before any writes.
        #   Runtime I/O failures can still interrupt insertion after partial writes.
        # @return [Hash] Result with added steps and final state
        def add_batch(steps:, after: nil, as_child: false, source_file: nil)
          unless steps.is_a?(Array) && steps.any?
            source_label = source_file.to_s.strip.empty? ? "batch input" : source_file
            raise Error, "No steps defined in #{source_label}"
          end

          if as_child && (after.nil? || after.to_s.strip.empty?)
            raise Error, "Child insertion requires an after step reference."
          end

          prevalidate_batch_trees!(steps)

          added_steps = []
          renumbered = []
          sibling_cursor = after

          steps.each_with_index do |step_config, index|
            inserted = insert_batch_step_tree(
              step_config,
              after: as_child ? after : sibling_cursor,
              as_child: as_child,
              added_by: nil,
              location: "steps[#{index}]"
            )
            added_steps.concat(inserted[:added])
            renumbered.concat(inserted[:renumbered])
            sibling_cursor = inserted[:root_number] unless as_child
          end

          assignment = assignment_manager.find_active
          state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          {
            assignment: assignment,
            state: state,
            added: added_steps,
            renumbered: renumbered.uniq
          }
        end

        # Retry a failed step (creates new step linked to original)
        #
        # @param step_ref [String] Step number or reference to retry
        # @return [Hash] Result with new retry step
        def retry_step(step_ref)
          assignment = assignment_manager.find_active
          raise AssignmentErrors::NoActive, "No active assignment. Use 'ace-assign create --yaml <job.yaml>' to begin." unless assignment

          state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)

          # Find the step to retry
          original = state.find_by_number(step_ref.to_s)
          raise StepErrors::NotFound, "Step #{step_ref} not found in queue" unless original

          # Get existing numbers
          existing_numbers = queue_scanner.step_numbers(assignment.steps_dir)

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
          step_writer.create(
            steps_dir: assignment.steps_dir,
            number: new_number,
            name: original.name,
            instructions: original.instructions,
            status: :pending,
            added_by: "retry_of:#{original.number}"
          )

          # Update assignment timestamp
          assignment_manager.update(assignment)

          # Return updated state
          new_state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          retry_step = new_state.steps.find { |s| s.number == new_number }

          {
            assignment: assignment,
            state: new_state,
            retry: retry_step,
            original: original
          }
        end

        private

        # Enrich steps by resolving workflow-level or legacy skill-level assign source metadata.
        #
        # If a step has `workflow: ...` or `skill: ...` and no explicit sub_steps,
        # this resolves the workflow and applies
        # workflow `assign.sub-steps` as step sub_steps for deterministic runtime expansion.
        #
        # @param steps_config [Array<Hash>] Original steps from config
        # @return [Array<Hash>] Enriched steps
        def enrich_declared_sub_steps(steps_config)
          steps_config.map do |step|
            next step unless step.is_a?(Hash)

            sub_steps = step["sub_steps"] || step["sub-steps"]
            if sub_steps.is_a?(Array) && sub_steps.any?
              explicit = step.dup
              explicit["sub_steps_origin"] ||= "explicit"
              next explicit
            end

            assign_config = resolve_step_assign_config(step)
            next step unless assign_config

            resolved_sub_steps = assign_config[:sub_steps]
            next step unless resolved_sub_steps.is_a?(Array) && resolved_sub_steps.any?

            enriched = step.merge(
              "sub_steps" => resolved_sub_steps,
              "sub_steps_origin" => "inferred"
            )
            enriched["context"] ||= assign_config[:context] if assign_config[:context]
            enriched
          end
        end

        # Expand steps with sub_steps into batch parent + child structure.
        #
        # When a step declares `sub_steps` (from workflow frontmatter), it becomes
        # a batch parent with fork context, and each sub-step becomes a child step.
        # This reuses the existing batch-parent pattern from compose.
        #
        # Numbers are pre-assigned based on the original index position so that
        # subsequent steps keep their expected numbering (e.g., 010, 020, 030)
        # regardless of how many children are expanded.
        #
        # @param steps_config [Array<Hash>] Original steps from config
        # @return [Array<Hash>] Expanded steps with parent-child numbers
        def expand_sub_steps(steps_config)
          # Check if any step has sub_steps; return early if none
          has_sub_steps = steps_config.any? do |step|
            subs = step["sub_steps"] || step["sub-steps"]
            subs.is_a?(Array) && subs.any?
          end
          return steps_config unless has_sub_steps

          expanded = []

          steps_config.each_with_index do |step, index|
            sub_steps = step["sub_steps"] || step["sub-steps"]
            parent_number = step["number"] || Atoms::NumberGenerator.from_index(index)

            if sub_steps.is_a?(Array) && sub_steps.any?
              # Create split parent orchestration node
              parent_context = step["context"] || "fork"
              parent_instructions = step["instructions"]
              sub_steps_origin = step["sub_steps_origin"] || "explicit"
              parent_step = build_split_parent_step(
                step: step,
                parent_number: parent_number,
                parent_context: parent_context,
                sub_steps: sub_steps
              )
              expanded << parent_step

              # Create child steps under the parent
              sub_steps.each_with_index do |sub_name, sub_idx|
                child_number = Atoms::NumberGenerator.subtask(parent_number, sub_idx + 1)
                expanded << build_child_sub_step(
                  sub_name: sub_name,
                  child_number: child_number,
                  parent_number: parent_number,
                  parent_step: step,
                  parent_instructions: parent_instructions,
                  parent_context: parent_context,
                  sub_steps_origin: sub_steps_origin
                )
              end
            else
              # Pre-assign number to non-sub-step entries to maintain position
              expanded << step.merge("number" => parent_number)
            end
          end

          expanded
        end

        # Build a split parent orchestration step.
        #
        # Parent nodes with sub_steps are subtree delegation roots and should not
        # execute the original skill directly. The parent instructions explain
        # how to drive the subtree; the original goals are preserved for context.
        #
        # @param step [Hash] Original parent step config
        # @param parent_number [String] Parent step number
        # @param parent_context [String] Parent execution context
        # @param sub_steps [Array<String>] Declared sub-step names
        # @return [Hash] Parent step config for runtime queue
        def build_split_parent_step(step:, parent_number:, parent_context:, sub_steps:)
          source_skill = step["source_skill"] || step["skill"]
          if (source_skill.nil? || source_skill.to_s.strip.empty?) && step["source"].to_s.start_with?("skill://")
            source_skill = step["source"].to_s.delete_prefix("skill://").strip
          end
          original_text = normalize_instructions(step["instructions"]).strip
          definition = find_step_definition("split-subtree-root") || {}

          lines = split_parent_instruction_lines(
            definition: definition,
            parent_number: parent_number,
            parent_context: parent_context,
            source_skill: source_skill,
            sub_steps: sub_steps
          )

          unless original_text.empty?
            lines << ""
            lines << (definition["goal_header"] || "Goal to satisfy through child steps:")
            original_text.lines.map(&:strip).reject(&:empty?).each do |line|
              lines << "- #{line}"
            end
          end

          parent_step = step.merge(
            "number" => parent_number,
            "context" => parent_context,
            "instructions" => lines.join("\n")
          )
          parent_step.delete("sub_steps")
          parent_step.delete("sub-steps")
          parent_step.delete("source")
          parent_step.delete("skill")
          parent_step.delete("workflow")
          parent_step["source_skill"] = source_skill if source_skill
          parent_step["split_step_type"] = definition["name"] || "split-subtree-root"
          parent_step
        end

        # Render split parent instructions from catalog with fallback defaults.
        #
        # @param definition [Hash] Catalog definition for split parent step
        # @param parent_number [String] Parent step number
        # @param parent_context [String] Parent execution context
        # @param source_skill [String, nil] Source skill of original parent step
        # @param sub_steps [Array<String>] Child step names
        # @return [Array<String>] Rendered instruction lines
        def split_parent_instruction_lines(definition:, parent_number:, parent_context:, source_skill:, sub_steps:)
          instructions = definition["instructions"].is_a?(Hash) ? definition["instructions"] : {}
          context_key = (parent_context == "fork") ? "fork" : "inline"
          template_lines = Array(instructions["common"]) + Array(instructions[context_key])
          template_lines = default_split_parent_instruction_lines(parent_context) if template_lines.empty?

          template_lines = template_lines.map(&:to_s)
          template_lines.reject! { |line| line.include?("{{source_skill}}") && source_skill.to_s.strip.empty? }

          variables = {
            "parent_number" => parent_number,
            "parent_context" => parent_context,
            "source_skill" => source_skill.to_s,
            "sub_steps" => sub_steps.join(", ")
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
            "Subtree root orchestrator step.",
            "This step is orchestration-only.",
            "Do not execute the parent workflow directly in this step.",
            "Child steps: {{sub_steps}}."
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
            lines << "Execute only child steps under this node."
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

        # Build a concrete child step from a sub-step name.
        #
        # Child steps inherit parent task context in instructions so skills can
        # extract concrete parameters (e.g., task refs) during execution.
        # Skill and context defaults are sourced from the step catalog when available.
        #
        # @param sub_name [String] Child sub-step name
        # @param child_number [String] Generated child step number
        # @param parent_number [String] Parent step number
        # @param parent_step [Hash] Parent step config
        # @param parent_instructions [String, Array<String>, nil] Parent instructions
        # @param parent_context [String, nil] Parent execution context
        # @param sub_steps_origin [String] Whether the subtree was declared explicitly or inferred
        # @return [Hash] Child step config
        def build_child_sub_step(sub_name:, child_number:, parent_number:, parent_step:, parent_instructions:, parent_context:, sub_steps_origin: "inferred")
          step_def = find_step_definition(sub_name)
          parent_task_ref = extract_parent_taskref(parent_step, parent_instructions)
          instructions = if step_def&.dig("skill")
            build_skill_backed_child_notes(sub_name, parent_instructions, task_ref: parent_task_ref)
          else
            build_child_instructions(sub_name, parent_instructions, step_def, task_ref: parent_task_ref)
          end
          child = {
            "number" => child_number,
            "name" => sub_name,
            "instructions" => instructions,
            "parent" => parent_number,
            "sub_steps_origin" => sub_steps_origin
          }
          child["taskref"] = parent_task_ref if parent_task_ref

          if step_def
            child["workflow"] = step_def["workflow"] if step_def["workflow"]
            preserve_explicit_skill = (sub_steps_origin == "explicit")
            child["skill"] = step_def["skill"] if step_def["skill"] && (preserve_explicit_skill || !step_def["workflow"])
            child["source"] = if step_def["source"]
              step_def["source"]
            elsif step_def["workflow"]
              step_def["workflow"]
            elsif step_def["skill"]
              "skill://#{step_def["skill"]}"
            end

            context_default = step_def.dig("context", "default")
            child["context"] = context_default if context_default && !fork_context_value?(parent_context)
            fork_context = step_def.dig("context", "fork")
            if child["context"] == "fork" && fork_context.is_a?(Hash) && !fork_context.empty?
              # Generated child sub-steps have no explicit frontmatter overrides.
              # Apply the catalog fork context directly (overwrite semantics) so
              # delegated children inherit the scheduler/provider policy configured
              # for that child step type.
              child["fork"] = fork_context
            end
          end

          child
        end

        # Build child instructions with parent context and step focus.
        #
        # @param sub_name [String] Child sub-step name
        # @param parent_instructions [String, Array<String>, nil] Parent instructions
        # @param step_def [Hash, nil] Catalog definition for this sub-step
        # @param task_ref [String, nil] Explicit task reference from parent metadata
        # @return [String] Rendered instructions
        def build_child_instructions(sub_name, parent_instructions, step_def, task_ref: nil)
          parent_text = normalize_instructions(parent_instructions).strip
          focus = (step_def && step_def["description"]) ? step_def["description"] : "Execute #{sub_name} sub-step."
          focus = focus.gsub("<taskref>", task_ref) if task_ref && !task_ref.empty?
          context = compact_task_context(parent_text, task_ref: task_ref)
          action = child_action_instructions(sub_name, parent_text, task_ref: task_ref)

          sections = []
          sections << "Task context:\n#{context}" unless context.empty?
          sections << "Sub-step focus:\n#{focus}"
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

        # Build compact task context for child sub-steps.
        # Avoid copying parent orchestration boilerplate into every child step.
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
          return "Task reference: #{task_refs.join(", ")}" if task_refs.any?

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
          task_hint = task_refs.any? ? " for task #{task_refs.join(", ")}" : ""

          case sub_name
          when "onboard"
            "- Load project context#{task_hint} using the step workflow instructions.\n- Confirm required files and workflow context are available."
          when "plan-task"
            "- Analyze requirements#{task_hint}.\n- Plan against the behavioral spec structure: cover Interface Contract, Error Handling, Edge Cases, and operating modes (dry-run, force, verbose, quiet) where relevant.\n- If the spec is missing details needed for implementation, include them in a \"Behavioral Gaps\" section instead of silently working around omissions.\n- Produce a concrete implementation plan with acceptance checks."
          when "work-on-task"
            "- Implement the required changes#{task_hint}.\n- Verify behavior with relevant checks/tests before reporting completion.\n- Before marking complete, verify working tree is clean (`git status --short`). If dirty, commit remaining changes with `ace-git-commit`."
          when "pre-commit-review"
            pre_commit_review_action_instructions(task_hint: task_hint)
          when "verify-test"
            "- Identify modified packages#{task_hint}.\n- For each modified package, run: cd <package> && ace-test --profile 6\n- If no package-level code changes are present, mark this step skipped with a clear reason."
          when /\Arelease(?:-.+)?\z/
            "- Release all modified packages and update both package and root changelogs.\n- Follow semantic versioning expectations for this step.\n- When auto-detecting packages, include `git diff origin/main...HEAD --name-only` in addition to working-tree state — prior steps may have already committed changes."
          when "verify-e2e"
            "- Check change scope: run `git diff origin/main --name-only` to list modified files.\n" \
            "- **Skip criteria**: If ALL modified files match `*.md`, `*.yml` (non-CI config), `.ace-tasks/**`, or `.ace-retros/**`, skip E2E verification — mark step done with \"skipped: docs/task-spec only changes, no runnable code affected\".\n" \
            "- Otherwise: detect modified packages, run E2E scenarios for each package with `test-e2e/scenarios/` scenarios (or legacy `test/e2e/` scenarios during migration)#{task_hint}.\n" \
            "- If no modified package has E2E scenarios, mark step done with \"skipped: no E2E scenarios for modified packages\"."
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

        def materialize_skill_backed_steps(steps_config)
          steps_config.map do |step|
            materialize_skill_backed_step(step)
          end
        end

        def materialize_skill_backed_step(step)
          return step unless step.is_a?(Hash)
          return step if step["split_step_type"]

          rendering = resolve_step_rendering(step)
          return step unless rendering

          rendered_instructions = render_skill_backed_step_instructions(
            step: step,
            rendering: rendering
          )

          materialized = step.merge(
            "instructions" => rendered_instructions,
            "workflow" => rendering["workflow"]
          )
          resolved_source = resolved_step_source(step, rendering)
          materialized["source"] = resolved_source if resolved_source && !resolved_source.empty?
          unless split_child_without_explicit_fork?(step)
            context_default = rendering.dig("context", "default")
            materialized["context"] ||= context_default if context_default
            fork_context = rendering.dig("context", "fork")
            if materialized["context"] == "fork" && fork_context.is_a?(Hash) && !fork_context.empty?
              # For materialized explicit steps, preserve frontmatter-provided fork config
              # (`||=` semantics). Rendering contributes defaults only when the step
              # itself did not declare fork options.
              materialized["fork"] ||= fork_context
            end
          end
          materialized["source_skill"] = rendering["source_skill"] || rendering["skill"] if rendering["source_skill"] || rendering["skill"]
          materialized["source_workflow"] = rendering["workflow"] if rendering["workflow"] && !rendering["workflow"].empty?
          materialized.delete("skill") unless preserve_explicit_child_skill?(step)
          materialized
        end

        def resolve_step_rendering(step)
          explicit_source = step["source"]&.to_s&.strip
          if explicit_source && !explicit_source.empty?
            canonical_step = find_step_definition_with_source_fallback(step, explicit_source: explicit_source)
            if canonical_step && split_child_without_explicit_fork?(step)
              canonical_step = canonical_step.dup
              canonical_step.delete("context")
              canonical_step.delete("fork")
            end
            source_skill = step["source_skill"]&.to_s&.strip
            source_skill = canonical_step&.dig("source_skill") if source_skill.nil? || source_skill.empty?
            rendering = skill_source_resolver.resolve_source_rendering(
              explicit_source,
              step_name: step["name"]&.to_s,
              source_skill: source_skill
            )
            return canonical_step ? canonical_step.merge(rendering || {}) : rendering if rendering
          end

          explicit_workflow = step["workflow"]&.to_s&.strip
          if explicit_workflow && !explicit_workflow.empty?
            canonical_step = find_step_definition(step["name"]&.to_s)
            if canonical_step && split_child_without_explicit_fork?(step)
              canonical_step = canonical_step.dup
              canonical_step.delete("context")
              canonical_step.delete("fork")
            end
            source_skill = step["source_skill"]&.to_s&.strip
            source_skill = canonical_step&.dig("source_skill") if source_skill.nil? || source_skill.empty?
            rendering = skill_source_resolver.resolve_workflow_rendering(
              explicit_workflow,
              step_name: step["name"]&.to_s,
              source_skill: source_skill
            )
            return canonical_step ? canonical_step.merge(rendering || {}) : rendering if rendering
          end

          explicit_skill = step["skill"]&.to_s&.strip
          if explicit_skill && !explicit_skill.empty?
            canonical_step = find_step_definition(step["name"]&.to_s)
            if canonical_step && step["parent"] && !step.key?("context") && !step.key?("fork")
              canonical_step = canonical_step.dup
              canonical_step.delete("context")
              canonical_step.delete("fork")
            end
            rendering = skill_source_resolver.resolve_skill_rendering(explicit_skill)
            return canonical_step ? canonical_step.merge(rendering || {}) : rendering if rendering
          end

          skill_source_resolver.resolve_step_rendering(step["name"]&.to_s)
        end

        def split_child_without_explicit_fork?(step)
          step["parent"] && !step.key?("context") && !step.key?("fork")
        end

        def preserve_explicit_child_skill?(step)
          step["parent"] && step["sub_steps_origin"] == "explicit"
        end

        def fork_context_value?(value)
          normalized = value.to_s.strip.downcase
          normalized = normalized.delete_prefix(":")
          normalized == "fork"
        end

        def render_skill_backed_step_instructions(step:, rendering:)
          if step_render_mode(rendering) == "step_template"
            return render_step_template_instructions(step: step, rendering: rendering)
          end

          sections = []

          task_ref = extract_parent_taskref(step, step["instructions"])
          task_context = (task_ref && !task_ref.empty?) ? "Task reference: #{task_ref}" : compact_task_context(normalize_instructions(step["instructions"]), task_ref: task_ref)
          sections << "Task context:\n#{task_context}" unless task_context.empty?

          body = rendering["body"].to_s.strip
          sections << body unless body.empty?

          assignment_notes = assignment_specific_notes(
            step_name: step["name"]&.to_s,
            instructions: step["instructions"]
          )
          sections << "Assignment-specific context:\n#{assignment_notes}" unless assignment_notes.empty?

          sections.join("\n\n")
        end

        def render_step_template_instructions(step:, rendering:)
          sections = []

          task_ref = extract_parent_taskref(step, step["instructions"])
          task_context = (task_ref && !task_ref.empty?) ? "Task reference: #{task_ref}" : compact_task_context(normalize_instructions(step["instructions"]), task_ref: task_ref)
          sections << "Task context:\n#{task_context}" unless task_context.empty?

          description = rendering["description"].to_s.strip
          sections << "Step focus:\n#{description}" unless description.empty?

          steps = render_step_template_steps(rendering["steps"])
          sections << "Steps:\n#{steps}" unless steps.empty?

          skip_guidance = render_step_template_skip_guidance(rendering["when_to_skip"])
          sections << "Skip when:\n#{skip_guidance}" unless skip_guidance.empty?

          assignment_notes = assignment_specific_notes(
            step_name: step["name"]&.to_s,
            instructions: step["instructions"]
          )
          sections << "Assignment-specific context:\n#{assignment_notes}" unless assignment_notes.empty?

          sections.join("\n\n")
        end

        def render_step_template_steps(steps)
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

        def render_step_template_skip_guidance(conditions)
          Array(conditions).filter_map do |condition|
            text = condition&.to_s&.strip
            next if text.nil? || text.empty?

            "- #{text}"
          end.join("\n")
        end

        def step_render_mode(rendering)
          mode = rendering["render"]&.to_s&.strip
          return "workflow_body" if mode.nil? || mode.empty?

          mode
        end

        def assignment_specific_notes(step_name:, instructions:)
          text = normalize_instructions(instructions).strip
          return "" if text.empty?

          filtered = text.lines.filter_map do |line|
            normalized = normalize_assignment_overlay_line(line)
            next if normalized.nil? || normalized.empty?
            next if normalized.start_with?("Task reference:", "Task request:")

            normalized
          end

          if step_name == "work-on-task"
            filtered = filtered.reject do |line|
              line.start_with?("Implement task ", "When complete, mark the task as done:")
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

        def resolve_step_assign_config(step)
          source_ref = step["source"]&.to_s&.strip
          if source_ref && !source_ref.empty?
            return skill_source_resolver.resolve_source_assign_config(
              source_ref,
              step_name: step["name"]&.to_s,
              source_skill: step["source_skill"]&.to_s
            )
          end

          explicit_workflow = step["workflow"]&.to_s&.strip
          if explicit_workflow && !explicit_workflow.empty?
            return skill_source_resolver.resolve_workflow_assign_config(
              explicit_workflow,
              step_name: step["name"]&.to_s,
              source_skill: step["source_skill"]&.to_s
            )
          end

          skill_name = step["skill"]&.to_s
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
            lines << "- Pre-commit review is disabled by config; mark this step skipped with the config reason and continue."
            return lines.join("\n")
          end

          lines << "- Detect active client/provider from fork session metadata first (`.ace-local/assign/<assignment-id>/sessions/<fork-root>-session.yml`, key: provider)."
          lines << "- If session metadata is unavailable, fallback to `execution.provider` from assign config."
          lines << "- Allowed native review clients: #{allowlist_text}."
          lines << "- If detected client is allowed and mode is `auto` or `native`, review uncommitted changes and find issues (use the `/review` agent slash command — this is a conversation command, NOT a bash command)."
          lines << "- If the `/review` agent command is not available in the current execution environment, run `ace-lint` on modified files as a fallback quality gate, then continue."
          lines << "- Summarize findings with severity counts and keep raw output when structure is incomplete."
          lines << "- If `pre_commit_review_block` is true and a critical finding is confidently detected, fail this step with evidence to block release."
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
        # @param parent_step [Hash]
        # @param parent_instructions [String, Array<String>, nil]
        # @return [String, nil]
        def extract_parent_taskref(parent_step, parent_instructions)
          explicit = parent_step["taskref"] || parent_step["task_ref"]
          explicit_value = explicit.to_s.strip
          return explicit_value unless explicit_value.empty?

          parent_text = normalize_instructions(parent_instructions)
          inferred = parent_text.scan(/\b\d+\.\d+\b/).uniq
          return nil if inferred.empty?

          inferred.join(", ")
        end

        # Lookup step definition from catalog by step name.
        #
        # @param step_name [String] Name of step
        # @return [Hash, nil] Catalog definition
        def find_step_definition(step_name)
          Atoms::CatalogLoader.find_by_name(step_catalog, step_name)
        end

        def find_step_definition_with_source_fallback(step, explicit_source:)
          step_name = step["name"]&.to_s
          canonical_step = find_step_definition(step_name)
          return canonical_step if canonical_step

          source = explicit_source.to_s.strip
          return nil if source.empty?

          source_skill = step["source_skill"]&.to_s&.strip
          source_skill = source.delete_prefix("skill://").strip if source_skill.to_s.empty? && source.start_with?("skill://")

          step_catalog.find do |entry|
            next unless entry.is_a?(Hash)

            entry_source = entry["source"]&.to_s&.strip
            entry_workflow = entry["workflow"]&.to_s&.strip
            entry_source_skill = entry["source_skill"]&.to_s&.strip
            entry_skill = entry["skill"]&.to_s&.strip

            next true if entry_source == source || entry_workflow == source
            next true if !source_skill.to_s.empty? && (entry_source_skill == source_skill || entry_skill == source_skill)

            false
          end
        end

        # Load step catalog from project override or gem defaults.
        #
        # @return [Array<Hash>] Loaded step definitions
        def step_catalog
          return @step_catalog if @step_catalog_loaded

          if @step_catalog_from_fixture_set
            @step_catalog_loaded = true
            @step_catalog = @step_catalog_from_fixture
            return @step_catalog
          end

          cached = self.class.send(:cached_value, :step_catalog_cache, step_catalog_signature)
          return @step_catalog = cached if cached

          @step_catalog_loaded = true
          @step_catalog = load_step_catalog
          self.class.send(:store_cached_value, :step_catalog_cache, step_catalog_signature, @step_catalog)
          @step_catalog
        end

        def step_catalog_signature
          [
            PROJECT_ROOT_SIGNAL,
            project_catalog_signature,
            default_catalog_signature,
            step_catalog_cache_token,
            CATALOG_SIGNAL
          ].join("|")
        end

        def project_catalog_signature
          @project_catalog_signature ||= catalog_signature(File.join(project_root, ".ace", "assign", "catalog", "steps"))
        end

        def default_catalog_signature
          @default_catalog_signature ||= catalog_signature(File.join(gem_root, ".ace-defaults", "assign", "catalog", "steps"))
        end

        def load_step_catalog
          project_catalog = File.join(project_root, ".ace", "assign", "catalog", "steps")
          default_catalog = File.join(gem_root, ".ace-defaults", "assign", "catalog", "steps")

          canonical_steps = @skill_source_resolver.assign_step_catalog
          default_steps = Atoms::CatalogLoader.load_all(default_catalog, canonical_steps: false)
          base_catalog = merge_step_catalog(default_steps, canonical_steps)

          if File.directory?(project_catalog)
            project_steps = Atoms::CatalogLoader.load_all(project_catalog, canonical_steps: false)
            merge_step_catalog(base_catalog, project_steps)
          else
            base_catalog
          end
        end

        def catalog_signature(catalog_dir)
          return "missing" unless File.directory?(catalog_dir)

          Dir.glob(File.join(catalog_dir, "*.step.yml")).sort.map do |path|
            "#{path}:#{file_signature(path)}"
          end.join("|")
        end

        def file_signature(path)
          stat = File.stat(path)
          "#{stat.mtime.to_f}:#{stat.size}"
        rescue
          "missing"
        end

        def step_catalog_cache_token
          token = if @skill_source_resolver.respond_to?(:cache_signature)
            @skill_source_resolver.cache_signature
          else
            "resolver:#{@skill_source_resolver.object_id}"
          end

          "resolver:#{token}"
        end

        def project_root
          @project_root ||= Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
        end

        def gem_root
          @gem_root ||= Gem.loaded_specs["ace-assign"]&.gem_dir || File.expand_path("../../../..", __dir__)
        end

        # Merge default and project step catalogs by step name.
        # Later definitions override earlier ones with matching names.
        #
        # @param default_steps [Array<Hash>]
        # @param project_steps [Array<Hash>]
        # @return [Array<Hash>]
        def merge_step_catalog(default_steps, project_steps)
          index = {}
          order = []

          default_steps.each do |step|
            name = step["name"]
            next if name.nil? || name.empty?

            index[name] = step
            order << name
          end

          project_steps.each do |step|
            name = step["name"]
            next if name.nil? || name.empty?

            order << name unless index.key?(name)
            index[name] = deep_merge_step_definition(index[name], step)
          end

          order.map { |name| index[name] }.compact
        end

        def deep_merge_step_definition(base, override)
          return override unless base.is_a?(Hash)
          return base unless override.is_a?(Hash)

          merged = base.dup
          override.each do |key, value|
            merged[key] =
              if merged[key].is_a?(Hash) && value.is_a?(Hash)
                deep_merge_step_definition(merged[key], value)
              else
                value
              end
          end
          merged
        end

        # Archive source config into the task's jobs/ directory.
        # If config is already in a jobs/ or steps/ directory, keeps it in place.
        # Otherwise moves job.yaml to <task>/jobs/<assignment_id>-job.yml for provenance.
        #
        # @param config_path [String] Path to the original job.yaml
        # @param assignment_id [String] Assignment identifier for filename prefix
        # @return [String] Path to archived file
        def archive_source_config(config_path, assignment_id)
          expanded_path = File.expand_path(config_path)
          parent_dir = File.dirname(expanded_path)

          # Keep pre-rendered hidden/job specs and legacy step archives stable.
          return expanded_path if %w[jobs steps].include?(File.basename(parent_dir))

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

          step_writer.mark_pending(current.file_path)
          rebalanced_state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          next_step = rebalanced_state.next_workable_in_subtree(parent_number)
          step_writer.mark_in_progress(next_step.file_path) if next_step
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

        def insert_batch_step_tree(step_config, after:, as_child:, added_by:, location:)
          normalized = normalize_batch_step_hash(step_config, location: location)
          normalized = apply_inferred_parent_for_sibling_insert(normalized, after: after, as_child: as_child)

          if canonical_batch_insert_requested?(normalized)
            canonical_inserted = insert_canonical_batch_step_tree(
              normalized,
              after: after,
              as_child: as_child,
              added_by: added_by,
              location: location
            )
            return canonical_inserted if canonical_inserted
          end

          prepared = materialize_batch_step_config(normalized)
          instructions = normalize_instructions(prepared["instructions"])

          result = add(
            prepared["name"],
            instructions,
            after: after,
            as_child: as_child,
            added_by: added_by,
            extra: prepared
          )

          root_step = result[:added]
          added_steps = [root_step]
          renumbered = Array(result[:renumbered])

          normalize_batch_sub_steps(prepared, location: location).each_with_index do |child_config, index|
            child_inserted = insert_batch_step_tree(
              child_config,
              after: root_step.number,
              as_child: true,
              added_by: added_by,
              location: "#{location}.sub_steps[#{index}]"
            )
            added_steps.concat(child_inserted[:added])
            renumbered.concat(child_inserted[:renumbered])
          end

          {added: added_steps, renumbered: renumbered, root_number: root_step.number}
        end

        def canonical_batch_insert_requested?(step_config)
          raw_sub_steps = step_config["sub_steps"] || step_config["sub-steps"]
          has_declared_sub_steps = raw_sub_steps.is_a?(Array) && raw_sub_steps.any?
          has_source = !step_config["source"].to_s.strip.empty?
          has_workflow = !step_config["workflow"].to_s.strip.empty?
          has_skill = !step_config["skill"].to_s.strip.empty?

          has_declared_sub_steps || has_source || has_workflow || has_skill
        end

        def resolved_step_source(step, rendering)
          explicit_source = step["source"]&.to_s&.strip
          return explicit_source unless explicit_source.nil? || explicit_source.empty?

          rendered_source = rendering["source"]&.to_s&.strip
          return rendered_source unless rendered_source.nil? || rendered_source.empty?

          workflow_source = rendering["workflow"]&.to_s&.strip
          return workflow_source unless workflow_source.nil? || workflow_source.empty?

          skill_name = rendering["skill"]&.to_s&.strip
          return nil if skill_name.nil? || skill_name.empty?

          "skill://#{skill_name}"
        end

        def insert_canonical_batch_step_tree(step_config, after:, as_child:, added_by:, location:)
          materialized_tree = materialize_canonical_batch_tree(step_config, location: location)
          return nil if materialized_tree.nil? || materialized_tree.empty?

          root_template = materialized_tree.find { |step| step["parent"].nil? } || materialized_tree.first
          root_instructions = normalize_instructions(root_template["instructions"])
          root_instructions = default_dynamic_step_instructions if root_instructions.strip.empty?

          root_result = add(
            root_template["name"],
            root_instructions,
            after: after,
            as_child: as_child,
            added_by: added_by,
            extra: root_template
          )

          root_step = root_result[:added]
          added_steps = [root_step]
          renumbered = Array(root_result[:renumbered])

          root_number = root_template["number"]
          children = materialized_tree
            .select { |step| step["parent"] == root_number }
            .sort_by { |step| step["number"].to_s }

          children.each do |child_template|
            child_instructions = normalize_instructions(child_template["instructions"])
            child_instructions = default_dynamic_step_instructions if child_instructions.strip.empty?
            child_result = add(
              child_template["name"],
              child_instructions,
              after: root_step.number,
              as_child: true,
              added_by: added_by,
              extra: child_template
            )

            added_steps << child_result[:added]
            renumbered.concat(Array(child_result[:renumbered]))
          end

          {added: added_steps, renumbered: renumbered, root_number: root_step.number}
        end

        def materialize_canonical_batch_tree(step_config, location:)
          canonical_input, child_overrides = prepare_canonical_batch_input(step_config, location: location)
          return nil unless canonical_input

          expanded = expand_sub_steps([canonical_input])
          expanded = apply_canonical_child_overrides(expanded, child_overrides)
          materialize_skill_backed_steps(expanded)
        end

        def prepare_canonical_batch_input(step_config, location:)
          enriched = enrich_declared_sub_steps([step_config]).first
          raw_sub_steps = enriched["sub_steps"] || enriched["sub-steps"]
          descriptors = parse_canonical_sub_step_descriptors(raw_sub_steps, location: "#{location}.sub_steps")
          return [nil, {}] if descriptors.nil?

          names = descriptors[:names]
          overrides = descriptors[:overrides]
          canonical = enriched.dup
          if names
            canonical["sub_steps"] = names
            canonical.delete("sub-steps")
          end

          [canonical, overrides]
        end

        def parse_canonical_sub_step_descriptors(raw_sub_steps, location:)
          return {names: nil, overrides: {}} if raw_sub_steps.nil?
          return nil unless raw_sub_steps.is_a?(Array)

          names = []
          overrides = {}

          raw_sub_steps.each_with_index do |entry, index|
            case entry
            when String
              name = entry.to_s.strip
              raise Error, "sub_steps entry at #{location}[#{index}] cannot be empty" if name.empty?

              names << name
            when Hash
              normalized = normalize_batch_step_hash(entry, location: "#{location}[#{index}]")
              return nil if normalized.key?("sub_steps") || normalized.key?("sub-steps")

              names << normalized["name"]
              overrides[index] = normalized
            else
              return nil
            end
          end

          {names: names, overrides: overrides}
        end

        def apply_canonical_child_overrides(expanded_steps, overrides)
          return expanded_steps if overrides.empty?

          root = expanded_steps.find { |step| step["parent"].nil? } || expanded_steps.first
          root_number = root["number"]
          children = expanded_steps
            .select { |step| step["parent"] == root_number }
            .sort_by { |step| step["number"].to_s }

          merged_children = children.each_with_index.map do |child, index|
            override = overrides[index]
            next child unless override

            child.merge(override).merge(
              "number" => child["number"],
              "parent" => child["parent"]
            )
          end

          [root] + merged_children
        end

        def materialize_batch_step_config(step_config)
          prepared = materialize_skill_backed_step(step_config)
          instructions = normalize_instructions(prepared["instructions"])
          prepared["instructions"] = default_dynamic_step_instructions if instructions.strip.empty?
          prepared
        end

        def prevalidate_batch_trees!(steps)
          steps.each_with_index do |step_config, index|
            prevalidate_batch_step_tree(step_config, location: "steps[#{index}]")
          end
        end

        def prevalidate_batch_step_tree(step_config, location:)
          normalized = normalize_batch_step_hash(step_config, location: location)

          if canonical_batch_insert_requested?(normalized)
            materialized_tree = materialize_canonical_batch_tree(normalized, location: location)
            return if materialized_tree
          end

          prepared = materialize_batch_step_config(normalized)
          normalize_batch_sub_steps(prepared, location: location).each_with_index do |child_config, index|
            prevalidate_batch_step_tree(child_config, location: "#{location}.sub_steps[#{index}]")
          end
        end

        def normalize_batch_step_hash(step_config, location:)
          unless step_config.is_a?(Hash)
            raise Error, "Invalid step definition at #{location}: expected mapping"
          end

          normalized = step_config.each_with_object({}) do |(key, value), memo|
            memo[key.to_s] = value
          end

          name = normalized["name"].to_s.strip
          raise Error, "Step name is required at #{location}" if name.empty?

          normalized["name"] = name
          normalized
        end

        def normalize_batch_sub_steps(step_config, location:)
          raw = step_config["sub_steps"] || step_config["sub-steps"]
          return [] unless raw

          unless raw.is_a?(Array)
            raise Error, "sub_steps must be an array at #{location}"
          end

          raw.each_with_index.map do |entry, index|
            case entry
            when String
              name = entry.to_s.strip
              raise Error, "sub_steps entry at #{location}[#{index}] cannot be empty" if name.empty?

              {
                "name" => name,
                "instructions" => "Execute #{name} step."
              }
            when Hash
              normalized = normalize_batch_step_hash(entry, location: "#{location}[#{index}]")
              materialize_batch_step_config(normalized)
            else
              raise Error, "Invalid sub_steps entry at #{location}[#{index}]: expected string or mapping"
            end
          end
        end

        def normalize_batch_extra_fields(step_config)
          return {} unless step_config.is_a?(Hash)
          return {} if step_config.empty?

          reserved_keys = %w[name instructions number status parent added_by sub_steps sub-steps]
          step_config.each_with_object({}) do |(key, value), memo|
            key_str = key.to_s
            next if reserved_keys.include?(key_str)
            memo[key_str] = value
          end
        end

        def apply_inferred_parent_for_sibling_insert(step_config, after:, as_child:)
          return step_config unless step_config.is_a?(Hash)
          return step_config if as_child
          return step_config if after.nil? || after.to_s.strip.empty?
          return step_config if step_config.key?("parent")

          inferred_parent = infer_parent_from_anchor(after)
          return step_config if inferred_parent.nil? || inferred_parent.to_s.strip.empty?

          step_config.merge("parent" => inferred_parent)
        end

        def infer_parent_from_anchor(anchor_number)
          assignment = assignment_manager.find_active
          return nil unless assignment

          state = queue_scanner.scan(assignment.steps_dir, assignment: assignment)
          anchor = state.find_by_number(anchor_number.to_s.strip)
          anchor&.parent
        end

        def default_dynamic_step_instructions
          DEFAULT_DYNAMIC_STEP_INSTRUCTIONS
        end

        def find_target_step_for_start(state, step_number, fork_root)
          target = state.find_by_number(step_number)
          raise StepErrors::NotFound, "Step #{step_number} not found in queue" unless target

          if fork_root && !fork_root.empty?
            raise StepErrors::NotFound, "Subtree root #{fork_root} not found in assignment." unless state.find_by_number(fork_root)
            raise StepErrors::InvalidState, "Step #{target.number} is outside scoped subtree #{fork_root}." unless state.in_subtree?(fork_root, target.number)
          end
          raise StepErrors::InvalidState, "Cannot start step #{target.number}: status is #{target.status}, expected pending." unless target.status == :pending
          if state.has_incomplete_children?(target.number)
            raise StepErrors::InvalidState, "Cannot start step #{target.number}: has incomplete children."
          end

          target
        end

        def find_target_step_for_finish(state, step_number, fork_root)
          fork_root = fork_root&.strip
          if step_number && !step_number.to_s.strip.empty?
            target = state.find_by_number(step_number)
            raise StepErrors::NotFound, "Step #{step_number} not found in queue" unless target
            if fork_root && !fork_root.empty? && !state.in_subtree?(fork_root, target.number)
              raise StepErrors::InvalidState, "Step #{target.number} is outside scoped subtree #{fork_root}."
            end
            raise StepErrors::InvalidState, "Cannot finish step #{target.number}: status is #{target.status}, expected in_progress." unless target.status == :in_progress

            return target
          end

          current = state.current
          if fork_root && !fork_root.empty?
            raise StepErrors::NotFound, "Subtree root #{fork_root} not found in assignment." unless state.find_by_number(fork_root)
            active_in_subtree = state.in_progress_in_subtree(fork_root)
            if active_in_subtree.size > 1
              active_refs = active_in_subtree.map { |step| "#{step.number}(#{step.name})" }.join(", ")
              raise StepErrors::InvalidState, "Cannot finish in subtree #{fork_root}: multiple steps are in progress (#{active_refs})."
            end
            if current.nil? || !state.in_subtree?(fork_root, current.number)
              current = state.current_in_subtree(fork_root)
            end
            return nil if current.nil?
          end

          current
        end

        # Auto-complete parent steps when all their children are done.
        # Walks up the hierarchy marking parents as done, handling multi-level
        # completion in a single pass (grandparents become eligible when parents complete).
        #
        # @param state [Models::QueueState] Current queue state
        # @param assignment [Models::Assignment] Current assignment
        def auto_complete_parents(state, assignment)
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
                  report_content: "Auto-completed: all child steps finished.",
                  reports_dir: assignment.reports_dir
                )
                completed_this_pass << step.number
                completed_any = true
              end
            end
          end

          # Warn if safety limit was reached while still completing parents
          if iterations >= max_iterations && completed_any
            warn "[ace-assign] Warning: auto_complete_parents reached iteration limit (#{max_iterations}). " \
                 "Some parent steps may not have been auto-completed."
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

        # Find next step within a constrained subtree.
        #
        # @param state [Models::QueueState] Current queue state
        # @param completed_number [String] Number of just-completed step
        # @param root_number [String] Root of fork-scoped subtree
        # @return [Models::Step, nil] Next step in subtree, or nil when subtree done
        def find_next_step_in_subtree(state, completed_number, root_number)
          # First priority: pending direct children of completed step within subtree
          children = state.children_of(completed_number)
          pending_child = children.find { |c| c.status == :pending && state.in_subtree?(root_number, c.number) }
          return pending_child if pending_child

          # Second priority: next workable step within subtree
          state.next_workable_in_subtree(root_number)
        end

        # Calculate insertion point for a new step.
        #
        # @param after [String, nil] Insert after this step number
        # @param as_child [Boolean] Insert as child (true) or sibling (false)
        # @param state [Models::QueueState] Current queue state
        # @param existing_numbers [Array<String>] Existing step numbers
        # @return [Array<String, Array>] [new_number, steps_to_renumber]
        def calculate_insertion_point(after:, as_child:, state:, existing_numbers:)
          if after
            if as_child
              # Insert as first child of 'after'
              begin
                new_number = Atoms::StepNumbering.next_child(after, existing_numbers)
              rescue ArgumentError => e
                raise Error, e.message
              end
              [new_number, []]
            else
              # Insert as sibling after 'after'
              new_number = Atoms::StepNumbering.next_sibling(after)

              # Check if this number already exists
              if existing_numbers.include?(new_number)
                # Need to renumber
                renumber_list = Atoms::StepNumbering.steps_to_renumber(new_number, existing_numbers)
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
