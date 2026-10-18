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

        # @return [Hash, nil] {path, peek} for the step's report, nil absent
        # @raise [Error] on an invalid assignment id (containment)
        def read(assignment_id, step_number)
          return nil if step_number.to_s.strip.empty?

          id = assignment_id.to_s
          unless id.match?(/\A[\w.-]+\z/) && !id.match?(/\A\.+\z/)
            raise Error, "invalid assignment id '#{id}'"
          end

          reports_dir = File.join(@project_root, ".ace-local", "assign", id, "reports")
          return nil unless Dir.exist?(reports_dir)

          path = Dir.glob(File.join(reports_dir, "#{step_number}-*.r.md")).sort.first
          return nil unless path

          peek = File.read(path).lines.map(&:strip).reject(&:empty?).first
          {"path" => path, "peek" => peek}
        end
      end
    end
  end
end
