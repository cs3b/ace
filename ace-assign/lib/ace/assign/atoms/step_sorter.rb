# frozen_string_literal: true

module Ace
  module Assign
    module Atoms
      # Pure functions for sorting step files lexicographically.
      #
      # Steps are sorted by their numeric components:
      # 010 < 010.01 < 010.01.01 < 010.02 < 020
      module StepSorter
        # Sort filenames lexicographically by step number
        #
        # @param filenames [Array<String>] Array of filenames
        # @return [Array<String>] Sorted filenames
        def self.sort(filenames)
          filenames.sort_by { |f| sort_key(f) }
        end

        # Generate a sort key for a filename
        #
        # The key is an array of integers that can be compared
        # to produce correct lexicographic ordering.
        #
        # @param filename [String] Filename to generate key for
        # @return [Array<Integer>] Sort key
        def self.sort_key(filename)
          # Extract number from filename (strip .st.md or .r.md extension)
          base = filename.sub(/\.(ph|r)\.md$/, "")
          number_part = base.split("-").first

          # Split by dots and convert to integers
          parts = number_part.split(".").map(&:to_i)

          # Pad to 3 parts for consistent comparison
          parts + Array.new(3 - parts.size, 0)
        end

        # Sort step numbers directly
        #
        # @param numbers [Array<String>] Array of step numbers
        # @return [Array<String>] Sorted step numbers
        def self.sort_numbers(numbers)
          numbers.sort_by { |n| number_key(n) }
        end

        # Generate a sort key for a step number
        #
        # @param number [String] Step number
        # @return [Array<Integer>] Sort key
        def self.number_key(number)
          parts = number.split(".").map(&:to_i)
          parts + Array.new(3 - parts.size, 0)
        end

        # Compare two step numbers
        #
        # @param a [String] First step number
        # @param b [String] Second step number
        # @return [Integer] -1, 0, or 1
        def self.compare(a, b)
          number_key(a) <=> number_key(b)
        end
      end
    end
  end
end
