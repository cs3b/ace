# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Shared parsing/helpers for --assignment target.
        #
        # Supported syntax:
        # - <assignment-id>
        # - <assignment-id>@<step-number>
        module AssignmentTarget
          DEFAULT_TARGET_ENV = "ACE_ASSIGN_DEFAULT_TARGET"
          Target = Struct.new(:assignment_id, :scope, keyword_init: true)
          View = Struct.new(:assignment, :state, :scoped_state, :active_steps, :next_step, :focus_step, :scope_root, keyword_init: true)

          private

          def resolve_assignment_target(options)
            assignment_raw = options[:assignment]
            explicit_target = unless assignment_raw.nil? || assignment_raw.to_s.strip.empty?
              parse_assignment_target(assignment_raw)
            end

            env_target = env_assignment_target
            if explicit_target && env_target && target_identity(explicit_target) != target_identity(env_target)
              raise Ace::Support::Cli::Error,
                "Conflicting assignment targets: --assignment #{target_identity(explicit_target)} " \
                "does not match #{DEFAULT_TARGET_ENV}=#{target_identity(env_target)}"
            end

            explicit_target || env_target || Target.new(assignment_id: nil, scope: nil)
          end

          def parse_assignment_target(raw)
            value = raw.to_s.strip
            raise Ace::Support::Cli::Error, "Assignment target cannot be empty" if value.empty?

            assignment_id, scope = value.split("@", 2)
            assignment_id = assignment_id&.strip
            scope = scope&.strip

            raise Ace::Support::Cli::Error, "Assignment target requires assignment ID before '@'" if assignment_id.nil? || assignment_id.empty?
            raise Ace::Support::Cli::Error, "Assignment target scope after '@' cannot be empty" if value.include?("@") && (scope.nil? || scope.empty?)

            Target.new(assignment_id: assignment_id, scope: scope)
          end

          def env_assignment_target
            raw = ENV[DEFAULT_TARGET_ENV].to_s.strip
            return nil if raw.empty?

            parse_assignment_target(raw)
          end

          def target_identity(target)
            return "" unless target

            scope = target.scope.to_s.strip
            return target.assignment_id.to_s if scope.empty?

            "#{target.assignment_id}@#{scope}"
          end

          def build_executor_for_target(target)
            return Organisms::AssignmentExecutor.new unless target.assignment_id

            manager = Molecules::AssignmentManager.new
            assignment = manager.load(target.assignment_id)
            raise AssignmentErrors::NotFound, "Assignment '#{target.assignment_id}' not found" unless assignment

            executor = Organisms::AssignmentExecutor.new
            executor.assignment_manager.define_singleton_method(:find_active) { assignment }
            executor
          end

          def resolve_assignment_view(target)
            executor = build_executor_for_target(target)
            result = executor.status
            state = result[:state]
            scoped = scoped_status_view(state, target.scope)

            View.new(
              assignment: result[:assignment],
              state: state,
              scoped_state: scoped[:state],
              active_steps: scoped[:active_steps],
              next_step: scoped[:next_step],
              focus_step: scoped[:focus_step],
              scope_root: scoped[:root]
            )
          end

          def scoped_status_view(state, scope)
            if scope.nil? || scope.strip.empty?
              active_steps = state.active_steps
              next_step = active_steps.empty? ? state.next_workable : nil
              return {state: state, active_steps: active_steps, next_step: next_step, focus_step: state.current || next_step, root: nil}
            end

            root = state.find_by_number(scope.strip)
            raise StepErrors::NotFound, "Step #{scope} not found in queue" unless root

            scoped_steps = state.subtree_steps(root.number)
            scoped_state = Models::QueueState.new(steps: scoped_steps, assignment: state.assignment)
            active_steps = scoped_state.active_steps
            next_step = active_steps.empty? ? state.next_workable_in_subtree(root.number) : nil

            {state: scoped_state, active_steps: active_steps, next_step: next_step, focus_step: scoped_state.current || next_step, root: root.number}
          end

          def fork_scope_root(state, step)
            return nil unless step
            return step if step.fork?

            state.nearest_fork_ancestor(step.number)
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

            raise Error, "No active step. Use --root <step-number> or --assignment <id>@<step-number>." unless current

            root = state.nearest_fork_ancestor(current.number)
            raise Error, "Active step is not in a forked subtree. Provide --root or --assignment <id>@<step-number>." unless root

            root
          end

          def ensure_root_is_fork!(root_step)
            return if root_step.fork?

            raise Error, "Step #{root_step.number} is not fork-enabled (context: fork missing)."
          end

          def scoped_fork_metadata_step(state, step, scope, scope_root)
            return nil unless step

            if scope && !scope.strip.empty?
              return state.find_by_number(scope_root || scope.strip)
            end

            fork_scope_root(state, step)
          end

          def effective_fork_provider_for(step, scoped_fork_step)
            return nil unless step

            provider = step.fork_provider || scoped_fork_step&.fork_provider
            provider.to_s.strip.empty? ? nil : provider
          end
        end
      end
    end
  end
end
