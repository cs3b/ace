# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module TaskflowManagement
      # TaskFilterParser parses filter strings into structured filter data
      # This is a molecule - it provides a focused operation for parsing filter syntax
      class TaskFilterParser
        # Filter data structure
        FilterCriteria = Struct.new(:attribute, :value, :negated, :raw_filter) do
          def matches?(task_data)
            # Get the attribute value from task data
            attribute_value = get_attribute_value(task_data, attribute)
            
            # Handle OR values (pipe-separated)
            if value.include?('|')
              or_values = value.split('|').map(&:strip)
              matches = or_values.any? do |or_value|
                if attribute_value.is_a?(Array)
                  attribute_value.any? { |v| value_matches?(v, or_value) }
                else
                  value_matches?(attribute_value, or_value)
                end
              end
            elsif attribute_value.is_a?(Array)
              matches = attribute_value.any? { |v| value_matches?(v, value) }
            else
              matches = value_matches?(attribute_value, value)
            end
            
            # Apply negation if specified
            negated ? !matches : matches
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
          
          def value_matches?(attr_value, filter_value)
            # Handle nil values
            return false if attr_value.nil?
            
            # Convert both to strings for comparison
            attr_str = attr_value.to_s.downcase
            filter_str = filter_value.to_s.downcase
            
            # Exact match
            attr_str == filter_str
          end
        end
        
        # Parse filter string into FilterCriteria
        # @param filter_string [String] Filter in format "attribute:value" or "attribute:!value"
        # @return [FilterCriteria, nil] Parsed filter or nil if invalid
        def self.parse_filter(filter_string)
          return nil unless filter_string&.is_a?(String)
          
          # Split on first colon
          parts = filter_string.split(':', 2)
          return nil unless parts.length == 2
          
          attribute = parts[0]&.strip
          value_part = parts[1]&.strip
          
          return nil if attribute.empty? || value_part.empty?
          
          # Check for negation
          negated = false
          if value_part.start_with?('!')
            negated = true
            value_part = value_part[1..]&.strip
            return nil if value_part.empty?
          end
          
          FilterCriteria.new(attribute, value_part, negated, filter_string)
        end
        
        # Parse multiple filter strings
        # @param filter_strings [Array<String>] Array of filter strings
        # @return [Array<FilterCriteria>] Array of parsed filters
        def self.parse_filters(filter_strings)
          return [] unless filter_strings&.is_a?(Array)
          
          filters = []
          filter_strings.each do |filter_string|
            parsed = parse_filter(filter_string)
            filters << parsed if parsed
          end
          
          filters
        end
        
        # Validate filter attribute names against known task attributes
        # @param filters [Array<FilterCriteria>] Filters to validate
        # @return [Array<String>] Array of error messages (empty if valid)
        def self.validate_filters(filters)
          return [] unless filters&.is_a?(Array)
          
          errors = []
          known_attributes = %w[id status dependencies title priority estimate sort]
          
          filters.each do |filter|
            unless known_attributes.include?(filter.attribute) || filter.attribute.match?(/^[a-zA-Z_][a-zA-Z0-9_]*$/)
              errors << "Invalid filter attribute: #{filter.attribute}"
            end
          end
          
          errors
        end
      end
    end
  end
end