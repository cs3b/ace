# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Molecules
        # Sorts items using pinned-first + auto-sort logic.
        # Pinned items (those with a position value) sort first by position ascending.
        # Unpinned items sort second by computed score descending.
        class SmartSorter
          # @param items [Array] Items to sort
          # @param score_fn [Proc] ->(item) { Float } computes auto-sort score
          # @param pin_accessor [Proc] ->(item) { String|nil } reads position field
          # @return [Array] Pinned items (by position asc) + unpinned items (by score desc)
          def self.sort(items, score_fn:, pin_accessor:)
            return [] if items.nil? || items.empty?

            pinned = []
            unpinned = []

            items.each do |item|
              pos = pin_accessor.call(item)
              if pos && !pos.to_s.empty?
                pinned << item
              else
                unpinned << item
              end
            end

            sorted_pinned = pinned.sort_by { |item| pin_accessor.call(item).to_s }
            sorted_unpinned = unpinned.sort_by { |item| -score_fn.call(item) }

            sorted_pinned + sorted_unpinned
          end
        end
      end
    end
  end
end
