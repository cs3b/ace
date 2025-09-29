# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Calculate sort values for rescheduling operations
      class SortValueCalculator
        # Calculate sort value to place item at the beginning
        # @param items [Array<Hash>] List of items with sort values
        # @return [Float] Sort value to place before all items
        def calculate_first_position(items)
          return 10.0 if items.empty?

          min_sort = items.map { |item| item[:sort] || 99999 }.min
          min_sort - 10.0
        end

        # Calculate sort value to place item at the end
        # @param items [Array<Hash>] List of items with sort values
        # @return [Float] Sort value to place after all items
        def calculate_last_position(items)
          return 10.0 if items.empty?

          max_sort = items.map { |item| item[:sort] || 0 }.max
          max_sort + 10.0
        end

        # Calculate sort value to place item after another item
        # @param items [Array<Hash>] List of items with sort values
        # @param after_item [Hash] Item to place after
        # @return [Float] Sort value to place after the target item
        def calculate_after_position(items, after_item)
          after_sort = after_item[:sort] || 50.0

          # Find the next item's sort value
          sorted_items = items.sort_by { |i| i[:sort] || 99999 }
          after_index = sorted_items.index(after_item)

          if after_index && after_index < sorted_items.length - 1
            next_item = sorted_items[after_index + 1]
            next_sort = next_item[:sort] || after_sort + 20.0
            # Place halfway between
            (after_sort + next_sort) / 2.0
          else
            # Place after with standard increment
            after_sort + 10.0
          end
        end

        # Calculate sort value to place item before another item
        # @param items [Array<Hash>] List of items with sort values
        # @param before_item [Hash] Item to place before
        # @return [Float] Sort value to place before the target item
        def calculate_before_position(items, before_item)
          before_sort = before_item[:sort] || 50.0

          # Find the previous item's sort value
          sorted_items = items.sort_by { |i| i[:sort] || 99999 }
          before_index = sorted_items.index(before_item)

          if before_index && before_index > 0
            prev_item = sorted_items[before_index - 1]
            prev_sort = prev_item[:sort] || before_sort - 20.0
            # Place halfway between
            (prev_sort + before_sort) / 2.0
          else
            # Place before with standard decrement
            before_sort - 10.0
          end
        end

        # Rebalance sort values if they get too close together
        # @param items [Array<Hash>] List of items to rebalance
        # @return [Array<Hash>] Items with rebalanced sort values
        def rebalance_sort_values(items)
          return items if items.empty?

          sorted_items = items.sort_by { |i| i[:sort] || 99999 }
          base_value = 10.0
          increment = 10.0

          sorted_items.each_with_index do |item, index|
            item[:sort] = base_value + (index * increment)
          end

          sorted_items
        end

        # Check if sort values need rebalancing (too close together)
        # @param items [Array<Hash>] List of items to check
        # @return [Boolean] True if rebalancing is needed
        def needs_rebalancing?(items)
          return false if items.size < 2

          sorted_items = items.sort_by { |i| i[:sort] || 99999 }

          (0...sorted_items.length - 1).each do |i|
            current_sort = sorted_items[i][:sort] || 0
            next_sort = sorted_items[i + 1][:sort] || 0

            # If items are closer than 0.01, we need rebalancing
            return true if (next_sort - current_sort).abs < 0.01
          end

          false
        end
      end
    end
  end
end