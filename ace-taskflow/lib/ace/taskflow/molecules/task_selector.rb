# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Pure logic for selecting next task from a list
      # Unit testable - no filesystem access
      class TaskSelector
        # Select the next task to work on from a list of tasks
        # @param tasks [Array<Hash>] List of task hashes
        # @return [Hash, nil] Next task or nil
        def self.select_next(tasks)
          return nil if tasks.nil? || tasks.empty?

          # Prioritize in-progress tasks
          in_progress = tasks.select { |t| t[:status] == "in-progress" }
          return in_progress.first unless in_progress.empty?

          # For pending tasks, sort by sort value first, then by ID
          pending = tasks.select { |t| t[:status] == "pending" }
          return nil if pending.empty?

          # Sort pending tasks: those with sort values first (ascending), then by task ID
          sorted_pending = pending.sort do |a, b|
            if a[:sort] && b[:sort]
              a[:sort] <=> b[:sort]
            elsif a[:sort]
              -1  # a has sort, comes first
            elsif b[:sort]
              1   # b has sort, comes first
            else
              # Neither has sort, compare by task ID number
              extract_task_number(a[:id]) <=> extract_task_number(b[:id])
            end
          end

          sorted_pending.first
        end

        # Extract task number from task ID for sorting
        # @param id [String] Task ID (e.g., "v.0.9.0+task.003")
        # @return [Integer] Task number
        def self.extract_task_number(id)
          return 999999 unless id

          id_str = id.to_s
          match = id_str.match(/task\.(\d+)$/)
          match ? match[1].to_i : (id_str.to_i || 999999)
        end
      end
    end
  end
end
