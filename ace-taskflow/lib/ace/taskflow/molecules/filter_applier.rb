# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Apply parsed filter specifications to collections of items
      # This molecule orchestrates filtering logic with AND/OR operations
      class FilterApplier
        # Apply filter specifications to items
        # @param items [Array<Hash>] Items to filter (tasks, ideas, releases)
        # @param filter_specs [Array<Hash>] Filter specifications from FilterParser
        # @return [Array<Hash>] Filtered items
        #
        # Filter Logic:
        # - Multiple filters use AND logic (all must match)
        # - Within a filter, OR values use OR logic (any must match)
        # - Supports simple matching, array matching, and negation
        # - Case-insensitive matching with whitespace trimming
        #
        # Examples:
        #   filter_specs = [
        #     {key: "status", values: ["pending", "in-progress"], negated: false, or_mode: true},
        #     {key: "priority", values: ["high"], negated: false, or_mode: false}
        #   ]
        #   apply(tasks, filter_specs)
        #   # Returns tasks where (status is pending OR in-progress) AND priority is high
        #
        def self.apply(items, filter_specs)
          return items if filter_specs.nil? || filter_specs.empty?
          return [] if items.nil? || items.empty?

          items.select do |item|
            matches_all_filters?(item, filter_specs)
          end
        end

        # Check if item matches all filter specifications (AND logic)
        # @param item [Hash] Item to check
        # @param filter_specs [Array<Hash>] Filter specifications
        # @return [Boolean] True if matches all filters
        private_class_method def self.matches_all_filters?(item, filter_specs)
          filter_specs.all? do |filter_spec|
            matches_filter?(item, filter_spec)
          end
        end

        # Check if item matches a single filter specification
        # @param item [Hash] Item to check
        # @param filter_spec [Hash] Single filter specification
        # @return [Boolean] True if matches filter
        private_class_method def self.matches_filter?(item, filter_spec)
          key = filter_spec[:key]
          values = filter_spec[:values]
          negated = filter_spec[:negated]
          or_mode = filter_spec[:or_mode]

          # Get the item's value for this key
          # Support both symbol and string keys in item hash
          item_value = item[key.to_sym] || item[key.to_s] || item.dig(:metadata, key) || item.dig(:metadata, key.to_sym)

          # Determine match based on value type
          match = if item_value.is_a?(Array)
            # Array matching: check if any filter value is in the array
            matches_array?(item_value, values, or_mode)
          else
            # Simple matching: check if item value matches any filter value
            matches_value?(item_value, values, or_mode)
          end

          # Apply negation if needed
          negated ? !match : match
        end

        # Check if array contains any of the filter values
        # @param item_array [Array] Item's array value
        # @param filter_values [Array<String>] Values to match
        # @param or_mode [Boolean] Whether to OR the values
        # @return [Boolean] True if matches
        private_class_method def self.matches_array?(item_array, filter_values, or_mode)
          # Convert array items to strings for comparison
          array_strings = item_array.map { |v| normalize_value(v) }

          if or_mode
            # OR mode: item array must contain at least one filter value
            filter_values.any? do |filter_value|
              normalized_filter = normalize_value(filter_value)
              array_strings.include?(normalized_filter)
            end
          else
            # Single value: check if it's in the array
            normalized_filter = normalize_value(filter_values.first)
            array_strings.include?(normalized_filter)
          end
        end

        # Check if value matches any of the filter values
        # @param item_value [String, Symbol, Numeric, Boolean, nil] Item's value
        # @param filter_values [Array<String>] Values to match
        # @param or_mode [Boolean] Whether to OR the values
        # @return [Boolean] True if matches
        private_class_method def self.matches_value?(item_value, filter_values, or_mode)
          normalized_item_value = normalize_value(item_value)

          if or_mode
            # OR mode: item value must match at least one filter value
            filter_values.any? do |filter_value|
              normalized_filter = normalize_value(filter_value)
              normalized_item_value == normalized_filter
            end
          else
            # Single value: check for equality
            normalized_filter = normalize_value(filter_values.first)
            normalized_item_value == normalized_filter
          end
        end

        # Normalize value for comparison (case-insensitive, trimmed)
        # @param value [Object] Value to normalize
        # @return [String] Normalized string value
        private_class_method def self.normalize_value(value)
          return "" if value.nil?

          value.to_s.strip.downcase
        end
      end
    end
  end
end
