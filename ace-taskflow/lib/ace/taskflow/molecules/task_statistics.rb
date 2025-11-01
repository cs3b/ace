# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Pure logic for calculating task statistics
      # Unit testable - no filesystem access
      class TaskStatistics
        # Calculate statistics from a list of tasks
        # @param tasks [Array<Hash>] List of task hashes
        # @return [Hash] Statistics hash
        def self.calculate(tasks)
          return empty_stats if tasks.nil? || tasks.empty?

          stats = {
            total: tasks.size,
            by_status: {},
            by_priority: {},
            by_release: {}
          }

          tasks.each do |task|
            # Count by status
            status = task[:status] || "unknown"
            stats[:by_status][status] ||= 0
            stats[:by_status][status] += 1

            # Count by priority
            priority = task[:priority] || "unknown"
            stats[:by_priority][priority] ||= 0
            stats[:by_priority][priority] += 1

            # Count by release
            ctx = task[:release] || "unknown"
            stats[:by_release][ctx] ||= 0
            stats[:by_release][ctx] += 1
          end

          stats
        end

        # Get empty statistics structure
        # @return [Hash] Empty stats
        def self.empty_stats
          {
            total: 0,
            by_status: {},
            by_priority: {},
            by_release: {}
          }
        end
      end
    end
  end
end
