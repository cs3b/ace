# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Filters feedback items by priority level with optional range support.
      #
      # Supports exact matching ("high") and inclusive range matching ("high+").
      # Range matching includes the specified priority and all higher priorities.
      #
      # Priority hierarchy (highest to lowest): critical > high > medium > low
      #
      # @example Exact matching
      #   PriorityFilter.matches?("high", "high")
      #   #=> true
      #
      #   PriorityFilter.matches?("medium", "high")
      #   #=> false
      #
      # @example Range matching with + suffix
      #   PriorityFilter.matches?("high", "medium+")
      #   #=> true (high >= medium)
      #
      #   PriorityFilter.matches?("critical", "medium+")
      #   #=> true (critical >= medium)
      #
      #   PriorityFilter.matches?("low", "medium+")
      #   #=> false (low < medium)
      #
      class PriorityFilter
        # Priority levels in descending order (highest first)
        PRIORITY_ORDER = {
          "critical" => 4,
          "high" => 3,
          "medium" => 2,
          "low" => 1
        }.freeze

        VALID_PRIORITIES = PRIORITY_ORDER.keys.freeze

        # Parse a priority filter string into its components
        #
        # @param filter_string [String] Priority filter like "medium" or "medium+"
        # @return [Hash, nil] Hash with :priority and :inclusive keys, or nil if invalid
        #
        # @example Exact match
        #   PriorityFilter.parse("high")
        #   #=> { priority: "high", inclusive: false }
        #
        # @example Range match
        #   PriorityFilter.parse("medium+")
        #   #=> { priority: "medium", inclusive: true }
        #
        # @example Invalid priority
        #   PriorityFilter.parse("urgent")
        #   #=> nil
        def self.parse(filter_string)
          return nil if filter_string.nil? || filter_string.empty?

          # Check for + suffix (inclusive range)
          inclusive = filter_string.end_with?("+")
          priority = inclusive ? filter_string.chomp("+") : filter_string

          # Validate priority
          return nil unless VALID_PRIORITIES.include?(priority)

          {priority: priority, inclusive: inclusive}
        end

        # Check if an item priority matches a filter string
        #
        # @param item_priority [String] The priority of the item ("critical", "high", etc.)
        # @param filter_string [String] The filter string ("high" or "high+")
        # @return [Boolean] True if the item priority matches the filter
        #
        # @example Exact match
        #   PriorityFilter.matches?("high", "high")
        #   #=> true
        #
        #   PriorityFilter.matches?("medium", "high")
        #   #=> false
        #
        # @example Range match
        #   PriorityFilter.matches?("critical", "high+")
        #   #=> true
        #
        #   PriorityFilter.matches?("high", "high+")
        #   #=> true
        #
        #   PriorityFilter.matches?("medium", "high+")
        #   #=> false
        def self.matches?(item_priority, filter_string)
          return false if item_priority.nil? || filter_string.nil?

          parsed = parse(filter_string)
          return false if parsed.nil?

          item_level = PRIORITY_ORDER[item_priority]
          filter_level = PRIORITY_ORDER[parsed[:priority]]

          # Unknown item priority doesn't match
          return false if item_level.nil?

          if parsed[:inclusive]
            # Range match: item priority must be >= filter priority
            item_level >= filter_level
          else
            # Exact match
            item_priority == parsed[:priority]
          end
        end
      end
    end
  end
end
