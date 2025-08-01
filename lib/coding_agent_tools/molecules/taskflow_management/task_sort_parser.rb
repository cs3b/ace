# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module TaskflowManagement
      # TaskSortParser parses sort strings into structured sort data
      # This is a molecule - it provides a focused operation for parsing sort syntax
      class TaskSortParser
        # Sort criteria structure
        SortCriteria = Struct.new(:attribute, :direction, :raw_sort) do
          def ascending?
            direction == :asc
          end

          def descending?
            direction == :desc
          end

          def implementation_order?
            attribute == 'implementation-order'
          end

          def get_sort_value(task_data)
            return nil if implementation_order?

            # Get the attribute value from task data
            attribute_value = get_attribute_value(task_data, attribute)

            # Handle special attributes
            case attribute
            when 'id'
              # For task IDs, extract sequential number for better sorting
              parse_task_sequential_number(attribute_value)
            when 'status'
              # Map status to priority for sorting
              status_priority(attribute_value)
            when 'priority'
              # Map priority to numeric value
              priority_value(attribute_value)
            else
              # For other attributes, use the value as-is
              attribute_value
            end
          end

          private

          def get_attribute_value(task_data, attribute)
            # First try direct attribute access
            return task_data.send(attribute) if task_data.respond_to?(attribute)

            # Then try frontmatter
            if task_data.respond_to?(:frontmatter) && task_data.frontmatter
              return task_data.frontmatter[attribute] || task_data.frontmatter[attribute.to_s]
            end

            # Return nil if attribute not found
            nil
          end

          def parse_task_sequential_number(task_id_str)
            return Float::INFINITY unless task_id_str&.is_a?(String)

            match = task_id_str.match(/\+task\.(\d+)$/)
            match ? match[1].to_i : Float::INFINITY
          end

          def status_priority(status)
            case status&.downcase
            when 'in-progress' then 0
            when 'pending' then 1
            when 'blocked' then 2
            when 'done' then 3
            else 4
            end
          end

          def priority_value(priority)
            case priority&.downcase
            when 'high' then 0
            when 'medium' then 1
            when 'low' then 2
            else 3
            end
          end
        end

        # Parse sort string into SortCriteria
        # @param sort_string [String] Sort in format "attribute:direction" or "attribute"
        # @return [SortCriteria, nil] Parsed sort or nil if invalid
        def self.parse_sort(sort_string)
          return nil unless sort_string&.is_a?(String)

          # Handle special case for implementation-order
          if sort_string.strip == 'implementation-order'
            return SortCriteria.new('implementation-order', :asc, sort_string)
          end

          # Split on colon
          parts = sort_string.split(':', 2)
          attribute = parts[0]&.strip
          direction_str = parts[1]&.strip

          return nil if attribute.empty?

          # Default direction is ascending
          direction = :asc
          if direction_str && !direction_str.empty?
            case direction_str.downcase
            when 'asc', 'ascending'
              direction = :asc
            when 'desc', 'descending'
              direction = :desc
            else
              return nil # Invalid direction
            end
          end

          SortCriteria.new(attribute, direction, sort_string)
        end

        # Parse multiple sort criteria from comma-separated string
        # @param sort_string [String] Sort string like "priority:desc,id:asc"
        # @return [Array<SortCriteria>] Array of parsed sort criteria
        def self.parse_sorts(sort_string)
          return [] unless sort_string&.is_a?(String)

          sorts = []
          sort_parts = sort_string.split(',')

          sort_parts.each do |part|
            parsed = parse_sort(part.strip)
            sorts << parsed if parsed
          end

          sorts
        end

        # Validate sort attribute names against known task attributes
        # @param sorts [Array<SortCriteria>] Sorts to validate
        # @return [Array<String>] Array of error messages (empty if valid)
        def self.validate_sorts(sorts)
          return [] unless sorts&.is_a?(Array)

          errors = []
          known_attributes = %w[id status dependencies title priority estimate sort implementation-order]

          sorts.each do |sort|
            unless known_attributes.include?(sort.attribute) || sort.attribute.match?(/^[a-zA-Z_][a-zA-Z0-9_]*$/)
              errors << "Invalid sort attribute: #{sort.attribute}"
            end
          end

          errors
        end
      end
    end
  end
end
