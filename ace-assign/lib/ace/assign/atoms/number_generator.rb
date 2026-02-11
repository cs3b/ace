# frozen_string_literal: true

module Ace
  module Assign
    module Atoms
      # Pure functions for generating phase numbers.
      #
      # Follows the numbering convention:
      # - Main phases: 010, 020, 030 (10-step gaps for injection room)
      # - Sub-phases: 010.01, 010.02 (2-digit padding)
      # - Sub-sub-phases: 010.01.01 (3 levels max)
      # - Dynamic injection: 041 after 040
      module NumberGenerator
        # Default increment between main phases
        DEFAULT_INCREMENT = 10

        # Default starting number
        DEFAULT_START = 10

        # Generate the next main phase number
        #
        # @param last [String, nil] Last main phase number (e.g., "040")
        # @param increment [Integer] Step increment (default: 10)
        # @return [String] Next main phase number (e.g., "050")
        def self.next_main(last, increment: DEFAULT_INCREMENT)
          return format("%03d", DEFAULT_START) if last.nil?

          # Extract the main number (before any dots)
          main_part = last.split(".").first
          current = main_part.to_i

          # Round up to next increment
          next_num = ((current / increment) + 1) * increment
          format("%03d", next_num)
        end

        # Generate the next number after a given phase (for dynamic injection)
        #
        # @param base [String] Base phase number (e.g., "040")
        # @param existing [Array<String>] Existing phase numbers
        # @return [String] Next available number (e.g., "041")
        def self.next_after(base, existing = [])
          # Extract main part
          main_part = base.split(".").first.to_i

          # Find existing numbers in the range base+1 to base+9
          range_numbers = existing.map { |n| n.split(".").first.to_i }
                                  .select { |n| n > main_part && n < main_part + 10 }

          # Find next available
          next_num = main_part + 1
          while range_numbers.include?(next_num)
            next_num += 1
          end

          format("%03d", next_num)
        end

        # Generate a sub-phase number
        #
        # @param parent [String] Parent phase number (e.g., "030")
        # @param sequence [Integer] Sub-phase sequence (1, 2, 3...)
        # @return [String] Sub-phase number (e.g., "030.01")
        def self.subtask(parent, sequence)
          "#{parent}.#{format('%02d', sequence)}"
        end

        # Generate a sub-sub-phase number
        #
        # @param parent [String] Parent sub-phase number (e.g., "030.01")
        # @param sequence [Integer] Sub-sub-phase sequence
        # @return [String] Sub-sub-phase number (e.g., "030.01.01")
        def self.sub_subtask(parent, sequence)
          "#{parent}.#{format('%02d', sequence)}"
        end

        # Parse a phase number into its components
        #
        # @param number [String] Phase number (e.g., "030.01.02")
        # @return [Hash] Parsed components
        def self.parse(number)
          parts = number.split(".").map(&:to_i)
          {
            main: parts.first,
            parts: parts,
            depth: parts.size
          }
        end

        # Check if a number is a sub-phase of another
        #
        # @param number [String] Phase number to check
        # @param parent [String] Potential parent number
        # @return [Boolean] True if number is a sub-phase of parent
        def self.subtask_of?(number, parent)
          number.start_with?("#{parent}.")
        end

        # Format a number from index (0-based) to phase number
        #
        # @param index [Integer] Zero-based index
        # @param increment [Integer] Step increment
        # @return [String] Phase number
        def self.from_index(index, increment: DEFAULT_INCREMENT)
          format("%03d", (index + 1) * increment)
        end
      end
    end
  end
end
