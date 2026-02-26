# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Shared parsing/helpers for --assignment target.
        #
        # Supported syntax:
        # - <assignment-id>
        # - <assignment-id>@<phase-number>
        module AssignmentTarget
          Target = Struct.new(:assignment_id, :scope, keyword_init: true)

          private

          def resolve_assignment_target(options)
            assignment_raw = options[:assignment]
            unless assignment_raw.nil? || assignment_raw.to_s.strip.empty?
              return parse_assignment_target(assignment_raw)
            end

            filter_raw = options[:filter]
            return Target.new(assignment_id: nil, scope: nil) if filter_raw.nil? || filter_raw.to_s.strip.empty?

            parse_filter_target(filter_raw)
          end

          def parse_assignment_target(raw)
            value = raw.to_s.strip
            raise Ace::Core::CLI::Error, "Assignment target cannot be empty" if value.empty?

            assignment_id, scope = value.split("@", 2)
            assignment_id = assignment_id&.strip
            scope = scope&.strip

            raise Ace::Core::CLI::Error, "Assignment target requires assignment ID before '@'" if assignment_id.nil? || assignment_id.empty?
            raise Ace::Core::CLI::Error, "Assignment target scope after '@' cannot be empty" if value.include?("@") && (scope.nil? || scope.empty?)

            Target.new(assignment_id: assignment_id, scope: scope)
          end

          # Backward-compatible parser for legacy status filter argument shapes:
          # - "010.01" -> current assignment, scoped subtree
          # - "(abc123@)010.01" -> specific assignment + scoped subtree
          # - "abc123@010.01" -> explicit assignment target
          def parse_filter_target(raw)
            value = raw.to_s.strip
            raise Ace::Core::CLI::Error, "Status filter cannot be empty" if value.empty?

            if value.start_with?("(")
              match = value.match(/\A\(([^@\)]+)@\)(.+)\z/)
              raise Ace::Core::CLI::Error, "Invalid filter format: #{value}" unless match

              assignment_id = match[1]&.strip
              scope = match[2]&.strip
              raise Ace::Core::CLI::Error, "Status filter assignment ID cannot be empty" if assignment_id.nil? || assignment_id.empty?
              raise Ace::Core::CLI::Error, "Status filter scope cannot be empty" if scope.nil? || scope.empty?

              return Target.new(assignment_id: assignment_id, scope: scope)
            end

            return parse_assignment_target(value) if value.include?("@")

            Target.new(assignment_id: nil, scope: value)
          end

          def build_executor_for_target(target)
            return Organisms::AssignmentExecutor.new unless target.assignment_id

            manager = Molecules::AssignmentManager.new
            assignment = manager.load(target.assignment_id)
            raise AssignmentNotFoundError, "Assignment '#{target.assignment_id}' not found" unless assignment

            executor = Organisms::AssignmentExecutor.new
            executor.assignment_manager.define_singleton_method(:find_active) { assignment }
            executor
          end
        end
      end
    end
  end
end
