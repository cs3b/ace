# frozen_string_literal: true

module Ace
  module Coworker
    module Molecules
      # Reads failed-step evidence from the assignment's own step state
      # (`.ace-local/assign/<id>/steps/<n>-*.st.md`, written by
      # `ace-assign fail --message`). Read-only; ace-assign owns the files.
      class StepEvidenceReader
        def initialize(project_root:)
          @project_root = project_root
        end

        # @param assignment_id [String]
        # @param step_number [String, Integer, nil]
        # @return [String, nil] the recorded error cause (nil when absent)
        # @raise [Error] on an invalid assignment id (containment)
        def read(assignment_id, step_number)
          return nil if step_number.to_s.strip.empty?

          id = assignment_id.to_s
          unless id.match?(/\A[\w.-]+\z/) && !id.match?(/\A\.+\z/)
            raise Error, "invalid assignment id '#{id}'"
          end

          steps_dir = File.join(@project_root, ".ace-local", "assign", id, "steps")
          return nil unless Dir.exist?(steps_dir)

          path = Dir.glob(File.join(steps_dir, "#{step_number}-*.st.md")).sort.first
          return nil unless path

          error_from_step_file(path)
        end

        private

        # The `error:` frontmatter line written by ace-assign fail carries
        # the operator-visible cause; fall back to the whole file content.
        def error_from_step_file(path)
          content = File.read(path)
          match = content.match(/^error:\s*(.+)$/)
          cause = match ? match[1].strip : content.strip
          cause.empty? ? nil : cause
        end
      end
    end
  end
end
