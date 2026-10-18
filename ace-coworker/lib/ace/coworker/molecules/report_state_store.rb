# frozen_string_literal: true

require "fileutils"
require "json"

module Ace
  module Coworker
    module Molecules
      # Helper state for reporting runs (.ace-local/coworker/reports/
      # <assignment_id>.json): the derived result and the created HITL event
      # id, driving create-vs-resend on reruns. Coworker owns this location.
      class ReportStateStore
        def initialize(project_root:)
          @project_root = project_root
        end

        def state_path(assignment_id)
          id = validated(assignment_id)
          File.join(@project_root, ".ace-local", "coworker", "reports", "#{id}.json")
        end

        def read(assignment_id)
          path = state_path(assignment_id)
          return nil unless File.file?(path)

          JSON.parse(File.read(path))
        rescue JSON::ParserError
          nil
        end

        def write(assignment_id, state)
          path = state_path(assignment_id)
          FileUtils.mkdir_p(File.dirname(path))
          tmp_path = "#{path}.tmp.#{Process.pid}"
          File.write(tmp_path, JSON.pretty_generate(state))
          File.rename(tmp_path, path)
          path
        end

        private

        def validated(assignment_id)
          id = assignment_id.to_s
          unless id.match?(/\A[\w.-]+\z/) && !id.match?(/\A\.+\z/)
            raise Error, "invalid assignment id '#{id}'"
          end

          id
        end
      end
    end
  end
end
