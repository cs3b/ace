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
        end
      end
    end
  end
end
