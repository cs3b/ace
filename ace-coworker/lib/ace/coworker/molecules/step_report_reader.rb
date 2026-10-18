# frozen_string_literal: true

module Ace
  module Coworker
    module Molecules
      # Locates the in-flight step's report file
      # (.ace-local/assign/<id>/reports/<n>-*.r.md). Read-only; ace-assign
      # owns the files. Same id-containment rule as StepEvidenceReader.
      class StepReportReader
        def initialize(project_root:)
          @project_root = project_root
        end

        # @return [Hash, nil] {path} for the step's report, nil absent
        # @raise [Error] on an invalid assignment id (containment)
        def read(assignment_id, step_number)
          number = step_number.to_s.strip
          return nil if number.empty?
          unless number.match?(/\A[\w.-]+\z/)
            raise Error, "invalid step number '#{number}'"
          end

          id = assignment_id.to_s
          unless id.match?(/\A[\w.-]+\z/) && !id.match?(/\A\.+\z/)
            raise Error, "invalid assignment id '#{id}'"
          end

          reports_dir = File.join(@project_root, ".ace-local", "assign", id, "reports")
          return nil unless Dir.exist?(reports_dir)

          path = Dir.glob(File.join(reports_dir, "#{step_number}-*.r.md")).sort.first
          return nil unless path

          {"path" => path}
        end
      end
    end
  end
end
