# frozen_string_literal: true

require "yaml"

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
          number = step_number.to_s.strip
          return nil if number.empty?
          unless number.match?(/\A[\w.-]+\z/)
            raise Error, "invalid step number '#{number}'"
          end

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
        # the operator-visible cause. Parse the frontmatter as YAML so
        # quoted/multiline values survive; fall back to a regex line scan.
        def error_from_step_file(path)
          content = File.read(path)
          frontmatter = content.split(/^---\s*$/m)[1].to_s
          parsed = YAML.safe_load(frontmatter, permitted_classes: [Date, Time], aliases: false)
          cause = parsed.is_a?(Hash) ? parsed["error"].to_s.strip : ""
          cause = content.match(/^error:\s*(.+)$/)[1].to_s.strip if cause.empty?
          cause.empty? ? nil : cause
        rescue StandardError
          match = content.match(/^error:\s*(.+)$/)
          match && !match[1].strip.empty? ? match[1].strip : nil
        end
      end
    end
  end
end
