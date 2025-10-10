# frozen_string_literal: true

require_relative "task_filter_parser"

module CodingAgentTools
  module Molecules
    module TaskflowManagement
      # TaskFilterEngine applies filters to task collections
      # This is a molecule - it provides a focused operation for filtering tasks
      class TaskFilterEngine
        # Apply filters to a collection of tasks
        # @param tasks [Array] Array of task data objects
        # @param filters [Array<TaskFilterParser::FilterCriteria>] Array of filters to apply
        # @return [Array] Filtered tasks
        def self.apply_filters(tasks, filters)
          return tasks if !filters || filters.empty?

          tasks.select do |task|
            # Task must match ALL filters (AND logic)
            filters.all? { |filter| filter.matches?(task) }
          end
        end

        # Apply filters from filter strings
        # @param tasks [Array] Array of task data objects
        # @param filter_strings [Array<String>] Array of filter strings to parse and apply
        # @return [Hash] Hash with :tasks and :errors keys
        def self.apply_filter_strings(tasks, filter_strings)
          return {tasks: tasks, errors: []} if !filter_strings || filter_strings.empty?

          # Parse filters
          filters = TaskFilterParser.parse_filters(filter_strings)

          # Validate filters
          errors = TaskFilterParser.validate_filters(filters)
          return {tasks: [], errors: errors} unless errors.empty?

          # Apply filters
          filtered_tasks = apply_filters(tasks, filters)

          {tasks: filtered_tasks, errors: []}
        end

        # Get default filters for next command (pending and in-progress tasks)
        # @return [Array<String>] Default filter strings for next command
        def self.default_next_filters
          # Use a special OR filter syntax for status
          ["status:pending|in-progress"]
        end

        # Check if filters would return any actionable tasks
        # @param tasks [Array] Array of task data objects
        # @param filters [Array<TaskFilterParser::FilterCriteria>] Array of filters
        # @return [Boolean] True if any tasks would pass the filters
        def self.has_actionable_tasks?(tasks, filters)
          !apply_filters(tasks, filters).empty?
        end
      end
    end
  end
end
