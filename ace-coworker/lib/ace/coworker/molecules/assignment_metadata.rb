# frozen_string_literal: true

require "yaml"

module Ace
  module Coworker
    module Molecules
      # Reads the assignment's own metadata (.ace-local/assign/<id>/assignment.yaml)
      # for the task↔assignment match check. Read-only: ace-assign owns the files.
      class AssignmentMetadata
        ASSIGN_DIR = File.join(".ace-local", "assign")

        def initialize(project_root:)
          @project_root = project_root
        end

        def assignment_dir(assignment_id)
          File.join(@project_root, ASSIGN_DIR, assignment_id.to_s)
        end

        def assignment_file(assignment_id)
          File.join(assignment_dir(assignment_id), "assignment.yaml")
        end

        # @return [String, nil] the task_id recorded by ace-assign
        # @raise [Error] when the assignment does not exist under .ace-local/assign/
        def task_id!(assignment_id)
          path = assignment_file(assignment_id)
          unless File.file?(path)
            raise Error, "assignment '#{assignment_id}' not found under #{File.join(ASSIGN_DIR, assignment_id)}"
          end

          data = YAML.safe_load_file(path, permitted_classes: [Date], aliases: true) || {}
          data["task_id"].to_s.strip
        end

        # @raise [Error] when the assignment belongs to a different task
        def verify_task_match!(assignment_id, task_ref)
          recorded = task_id!(assignment_id)
          if recorded.empty?
            raise Error, "assignment '#{assignment_id}' has no task_id; cannot match task '#{task_ref}'"
          end
          if recorded != task_ref.to_s
            raise Error, "assignment '#{assignment_id}' belongs to task '#{recorded}', not '#{task_ref}'"
          end

          recorded
        end
      end
    end
  end
end
