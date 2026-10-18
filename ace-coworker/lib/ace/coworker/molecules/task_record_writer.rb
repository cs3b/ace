# frozen_string_literal: true

require "fileutils"

module Ace
  module Coworker
    module Molecules
      # Atomic writer of the durable per-assignment record inside the task's
      # own folder (<task_path>/coworker/<assignment_id>.md). Never touches
      # task spec files, frontmatter, or status — the record is the
      # contract-sanctioned per-task progress location.
      class TaskRecordWriter
        def initialize(task_path:)
          @task_path = task_path
        end

        def record_path(assignment_id)
          id = validated(assignment_id)
          File.join(@task_path, "coworker", "#{id}.md")
        end

        def write(assignment_id, content)
          path = record_path(assignment_id)
          FileUtils.mkdir_p(File.dirname(path))
          tmp_path = "#{path}.tmp.#{Process.pid}"
          File.write(tmp_path, content)
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
