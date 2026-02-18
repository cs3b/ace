# frozen_string_literal: true

module Ace
  module Overseer
    module Atoms
      module WindowNameFormatter
        def self.format(task_id, format:)
          task_ref = task_id.to_s.strip
          template = format.to_s

          raise ArgumentError, "task_id is required" if task_ref.empty?
          raise ArgumentError, "format is required" if template.empty?

          template.gsub("{task_id}", task_ref)
        end
      end
    end
  end
end
