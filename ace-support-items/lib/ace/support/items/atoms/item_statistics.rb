# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Atoms
        # Pure counting logic for item collections.
        # Groups items by a field and computes completion rates.
        class ItemStatistics
          # @param items [Array] Items responding to a field method
          # @param field [Symbol] Field to group by (e.g., :status, :priority, :type)
          # @return [Hash] { total:, by_field: { "value" => count } }
          def self.count_by(items, field)
            result = { total: items.size, by_field: {} }
            items.each do |item|
              value = item.public_send(field).to_s
              result[:by_field][value] ||= 0
              result[:by_field][value] += 1
            end
            result
          end

          # @param stats [Hash] Output of count_by
          # @param done_values [Array<String>] Status values that count as "complete"
          # @return [Integer] Completion percentage (0-100)
          def self.completion_rate(stats, done_values: ["done"])
            return 0 if stats[:total] == 0

            done_count = done_values.sum { |v| stats[:by_field][v] || 0 }
            (done_count.to_f / stats[:total] * 100).round
          end
        end
      end
    end
  end
end
