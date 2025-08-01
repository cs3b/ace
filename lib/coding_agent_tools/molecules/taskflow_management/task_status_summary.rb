# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module TaskflowManagement
      # TaskStatusSummary molecule provides status counting and summary formatting functionality
      # Following ATOM architecture as a molecule that operates on collections of task data
      class TaskStatusSummary
        # Status summary data structure
        StatusSummary = Struct.new(:counts, :total, :formatted_text) do
          def empty?
            total.zero?
          end
        end

        # Generate status summary from a collection of tasks
        # @param tasks [Array<TaskData>] Collection of task data objects
        # @return [StatusSummary] Summary with counts and formatted text
        def self.generate_summary(tasks)
          return StatusSummary.new({}, 0, 'Status: No tasks found') if tasks.nil? || tasks.empty?

          # Count tasks by status
          status_counts = Hash.new(0)
          tasks.each do |task|
            status = normalize_status(task.status)
            status_counts[status] += 1
          end

          total_count = tasks.size
          formatted_text = format_summary(status_counts, total_count)

          StatusSummary.new(status_counts, total_count, formatted_text)
        end

        private_class_method def self.normalize_status(status)
          # Handle nil/empty status values gracefully
          return 'unknown' if status.nil? || status.to_s.strip.empty?

          # Normalize status to consistent format
          status.to_s.strip.downcase.gsub(/[^a-z0-9_-]/, '_')
        end

        private_class_method def self.format_summary(status_counts, total_count)
          # Sort statuses for consistent ordering (alphabetical for predictability)
          sorted_statuses = status_counts.keys.sort

          # Build formatted status parts
          status_parts = sorted_statuses.map do |status|
            count = status_counts[status]
            "#{count} #{status}"
          end

          # Join with commas and add total
          status_text = status_parts.join(', ')
          "Status: #{status_text} (#{total_count} total)"
        end
      end
    end
  end
end
