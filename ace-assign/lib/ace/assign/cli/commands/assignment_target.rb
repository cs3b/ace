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
          Target = Struct.new(:assignment_id, :scope, keyword_init: true)
          View = Struct.new(:assignment, :state, :scoped_state, :current_step, :scope_root, keyword_init: true)

          private

          def resolve_assignment_target(options)
            assignment_raw = options[:assignment]
            unless assignment_raw.nil? || assignment_raw.to_s.strip.empty?
              return parse_assignment_target(assignment_raw)
            end

            Target.new(assignment_id: nil, scope: nil)
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
              current_step: scoped[:current],
              scope_root: scoped[:root]
            )
          end

          def scoped_status_view(state, scope)
            return {state: state, current: state.current || state.next_workable, root: nil} if scope.nil? || scope.strip.empty?

            root = state.find_by_number(scope.strip)
            raise StepErrors::NotFound, "Step #{scope} not found in queue" unless root

            scoped_steps = state.subtree_steps(root.number)
            scoped_state = Models::QueueState.new(steps: scoped_steps, assignment: state.assignment)
            current = scoped_state.current || scoped_state.next_workable

            {state: scoped_state, current: current, root: root.number}
          end

          def fork_scope_root(state, current_step)
            return nil unless current_step
            return current_step if current_step.fork?

            state.nearest_fork_ancestor(current_step.number)
          end

          def scoped_fork_metadata_step(state, current_step, scope, scope_root)
            return nil unless current_step

            if scope && !scope.strip.empty?
              return state.find_by_number(scope_root || scope.strip)
            end

            fork_scope_root(state, current_step)
          end

          def effective_fork_provider_for(current_step, scoped_fork_step)
            return nil unless current_step

            provider = current_step.fork_provider || scoped_fork_step&.fork_provider
            provider.to_s.strip.empty? ? nil : provider
          end
        end
      end
    end
  end
end
