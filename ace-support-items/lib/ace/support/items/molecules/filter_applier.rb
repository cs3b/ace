# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Molecules
        # Applies parsed filter specifications to collections of items.
        # Supports AND/OR operations, negation, array matching, and
        # a configurable value accessor for any object type.
        class FilterApplier
          # Apply filter specifications to items
          # @param items [Array] Items to filter
          # @param filter_specs [Array<Hash>] Filter specifications from FilterParser
          # @param value_accessor [Proc, nil] Custom accessor: ->(item, key) { value }
          # @return [Array] Filtered items
          def self.apply(items, filter_specs, value_accessor: nil)
            return items if filter_specs.nil? || filter_specs.empty?
            return [] if items.nil? || items.empty?

            accessor = value_accessor || method(:default_value_accessor)

            items.select do |item|
              filter_specs.all? { |spec| matches_filter?(item, spec, accessor) }
            end
          end

          # Check if item matches a single filter specification
          private_class_method def self.matches_filter?(item, filter_spec, accessor)
            key = filter_spec[:key]
            values = filter_spec[:values]
            negated = filter_spec[:negated]
            or_mode = filter_spec[:or_mode]

            item_value = accessor.call(item, key)

            match = if item_value.is_a?(Array)
              matches_array?(item_value, values, or_mode)
            else
              matches_value?(item_value, values, or_mode)
            end

            negated ? !match : match
          end

          # Check if array contains any of the filter values
          private_class_method def self.matches_array?(item_array, filter_values, or_mode)
            array_strings = item_array.map { |v| normalize_value(v) }

            if or_mode
              filter_values.any? { |fv| array_strings.include?(normalize_value(fv)) }
            else
              array_strings.include?(normalize_value(filter_values.first))
            end
          end

          # Check if value matches any of the filter values
          private_class_method def self.matches_value?(item_value, filter_values, or_mode)
            normalized_item = normalize_value(item_value)

            if or_mode
              filter_values.any? { |fv| normalized_item == normalize_value(fv) }
            else
              normalized_item == normalize_value(filter_values.first)
            end
          end

          # Normalize value for comparison (case-insensitive, trimmed)
          private_class_method def self.normalize_value(value)
            return "" if value.nil?
            value.to_s.strip.downcase
          end

          # Default value accessor: tries hash keys, methods, frontmatter, metadata
          private_class_method def self.default_value_accessor(item, key)
            # Hash-like access (symbol then string)
            if item.respond_to?(:[])
              val = begin
                item[key.to_sym]
              rescue
                nil
              end
              return val unless val.nil?

              val = begin
                item[key.to_s]
              rescue
                nil
              end
              return val unless val.nil?
            end

            # Method access
            if item.respond_to?(key.to_sym)
              return item.send(key.to_sym)
            end

            # Frontmatter access
            if item.respond_to?(:frontmatter) && item.frontmatter.is_a?(Hash)
              val = item.frontmatter[key.to_s] || item.frontmatter[key.to_sym]
              return val unless val.nil?
            end

            # Metadata access (for taskflow-style items)
            if item.respond_to?(:metadata) && item.metadata.is_a?(Hash)
              return item.metadata[key.to_s] || item.metadata[key.to_sym]
            end

            # Nested metadata in hash
            if item.respond_to?(:dig)
              item.dig(:metadata, key) || item.dig(:metadata, key.to_sym)
            end
          end
        end
      end
    end
  end
end
