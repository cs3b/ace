# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Pure functions for generating step numbers.
      #
      # Follows the numbering convention:
      # - Main tasks: 010, 020, 030 (10-step gaps for injection room)
      # - Subtasks: 010.01, 010.02 (2-digit padding)
      # - Sub-subtasks: 010.01.01 (3 levels max)
      # - Dynamic injection: 041 after 040
      module NumberGenerator
        # Default increment between main tasks
        DEFAULT_INCREMENT = 10

        # Default starting number
        DEFAULT_START = 10

        # Generate the next main task number
        #
        # @param last [String, nil] Last main task number (e.g., "040")
        # @param increment [Integer] Step increment (default: 10)
        # @return [String] Next main task number (e.g., "050")
        #
        # @example
        #   next_main(nil)   # => "010"
        #   next_main("040") # => "050"
        #   next_main("045") # => "050" (rounds up to next increment)
        def self.next_main(last, increment: DEFAULT_INCREMENT)
          return format("%03d", DEFAULT_START) if last.nil?

          # Extract the main number (before any dots)
          main_part = last.split(".").first
          current = main_part.to_i

          # Round up to next increment
          next_num = ((current / increment) + 1) * increment
          format("%03d", next_num)
        end

        # Generate the next number after a given step (for dynamic injection)
        #
        # @param base [String] Base step number (e.g., "040")
        # @param existing [Array<String>] Existing step numbers
        # @return [String] Next available number (e.g., "041")
        #
        # @example
        #   next_after("040", [])              # => "041"
        #   next_after("040", ["041"])         # => "042"
        #   next_after("040", ["041", "042"])  # => "043"
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

        # Generate a subtask number
        #
        # @param parent [String] Parent task number (e.g., "030")
        # @param sequence [Integer] Subtask sequence (1, 2, 3...)
        # @return [String] Subtask number (e.g., "030.01")
        #
        # @example
        #   subtask("030", 1) # => "030.01"
        #   subtask("030", 2) # => "030.02"
        def self.subtask(parent, sequence)
          "#{parent}.#{format('%02d', sequence)}"
        end

        # Generate a sub-subtask number
        #
        # @param parent [String] Parent subtask number (e.g., "030.01")
        # @param sequence [Integer] Sub-subtask sequence
        # @return [String] Sub-subtask number (e.g., "030.01.01")
        #
        # @example
        #   sub_subtask("030.01", 1) # => "030.01.01"
        def self.sub_subtask(parent, sequence)
          "#{parent}.#{format('%02d', sequence)}"
        end

        # Parse a step number into its components
        #
        # @param number [String] Step number (e.g., "030.01.02")
        # @return [Hash] Parsed components
        #
        # @example
        #   parse("030")       # => { main: 30, parts: [30], depth: 1 }
        #   parse("030.01")    # => { main: 30, parts: [30, 1], depth: 2 }
        #   parse("030.01.02") # => { main: 30, parts: [30, 1, 2], depth: 3 }
        def self.parse(number)
          parts = number.split(".").map(&:to_i)
          {
            main: parts.first,
            parts: parts,
            depth: parts.size
          }
        end

        # Check if a number is a subtask of another
        #
        # @param number [String] Step number to check
        # @param parent [String] Potential parent number
        # @return [Boolean] True if number is a subtask of parent
        #
        # @example
        #   subtask_of?("030.01", "030")     # => true
        #   subtask_of?("030.01.01", "030")  # => true
        #   subtask_of?("040", "030")        # => false
        def self.subtask_of?(number, parent)
          number.start_with?("#{parent}.")
        end

        # Format a number from index (0-based) to step number
        #
        # @param index [Integer] Zero-based index
        # @param increment [Integer] Step increment
        # @return [String] Step number
        #
        # @example
        #   from_index(0) # => "010"
        #   from_index(1) # => "020"
        #   from_index(4) # => "050"
        def self.from_index(index, increment: DEFAULT_INCREMENT)
          format("%03d", (index + 1) * increment)
        end
      end
    end
  end
end
