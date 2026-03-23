# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Molecules
        # Sorts collections of items by a field with configurable direction.
        # Nil values sort last regardless of direction.
        class ItemSorter
          # Sort items by a field
          # @param items [Array] Items to sort
          # @param field [String, Symbol] Field name to sort by
          # @param direction [Symbol] :asc or :desc (default: :asc)
          # @param value_accessor [Proc, nil] Custom accessor: ->(item, key) { value }
          # @return [Array] Sorted items
          def self.sort(items, field:, direction: :asc, value_accessor: nil)
            return [] if items.nil? || items.empty?

            accessor = value_accessor || method(:default_value_accessor)

            multiplier = (direction == :desc) ? -1 : 1

            items.sort do |a, b|
              val_a = accessor.call(a, field.to_s)
              val_b = accessor.call(b, field.to_s)

              # Nil values sort last regardless of direction
              if val_a.nil? && val_b.nil?
                0
              elsif val_a.nil?
                1
              elsif val_b.nil?
                -1
              else
                (val_a <=> val_b || 0) * multiplier
              end
            end
          end

          # Default value accessor matching FilterApplier convention
          private_class_method def self.default_value_accessor(item, key)
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

            if item.respond_to?(key.to_sym)
              return item.send(key.to_sym)
            end

            if item.respond_to?(:frontmatter) && item.frontmatter.is_a?(Hash)
              val = item.frontmatter[key.to_s] || item.frontmatter[key.to_sym]
              return val unless val.nil?
            end

            nil
          end
        end
      end
    end
  end
end
