# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Pure functions for hierarchical job numbering operations.
      #
      # Supports nested job structure where jobs can have sub-jobs:
      # - Main jobs: 010, 020, 030
      # - Nested jobs: 010.01, 010.02, 010.03
      # - Deeply nested: 010.01.01 (if needed)
      #
      # This enables verification-as-job patterns where parent jobs
      # wait for all children to complete before advancing.
      #
      # @example
      #   JobNumbering.parse("010.02")
      #   # => { parent: "010", index: 2, depth: 1, full: "010.02" }
      #
      #   JobNumbering.next_sibling("010.02")
      #   # => "010.03"
      #
      #   JobNumbering.first_child("010")
      #   # => "010.01"
      #
      #   JobNumbering.child_of?("010.02", "010")
      #   # => true
      module JobNumbering
        # Maximum allowed nesting depth for job numbers.
        # Prevents unbounded hierarchy (e.g., 010.01.01.01.01...).
        # Depth 0 = top-level (010), 1 = first nest (010.01), 2 = second nest (010.01.01).
        # Maximum is 010.01.01 (3 levels total).
        MAX_DEPTH = 2

        # Maximum siblings per level.
        # Child indexes use %02d format (01-99). Top-level uses %03d (001-999).
        # Exceeding these limits will cause lexicographical sorting issues.
        MAX_SIBLINGS_TOP_LEVEL = 999
        MAX_SIBLINGS_NESTED = 99

        # Parse a job number into its components.
        #
        # @param number [String] Job number (e.g., "010", "010.02", "010.02.03")
        # @return [Hash] Parsed components with keys:
        #   - :parent [String, nil] Parent job number (nil for top-level jobs)
        #   - :index [Integer] The final sequence number
        #   - :depth [Integer] Nesting depth (0 for top-level, 1 for first nest, etc.)
        #   - :full [String] Original full number
        #
        # @example Top-level job
        #   parse("010") # => { parent: nil, index: 10, depth: 0, full: "010" }
        #
        # @example Nested job
        #   parse("010.02") # => { parent: "010", index: 2, depth: 1, full: "010.02" }
        #
        # @example Deeply nested job
        #   parse("010.02.03") # => { parent: "010.02", index: 3, depth: 2, full: "010.02.03" }
        def self.parse(number)
          parts = number.to_s.split(".")

          {
            parent: parts.length > 1 ? parts[0..-2].join(".") : nil,
            index: parts.last.to_i,
            depth: parts.length - 1,
            full: number.to_s
          }
        end

        # Generate the next sibling job number.
        #
        # @param number [String] Current job number
        # @return [String] Next sibling number with same parent
        #
        # @example Top-level
        #   next_sibling("010") # => "011"
        #
        # @example Nested
        #   next_sibling("010.02") # => "010.03"
        #
        # @example Deeply nested
        #   next_sibling("010.02.03") # => "010.02.04"
        #
        # @raise [ArgumentError] If incrementing would exceed sibling limits
        def self.next_sibling(number)
          parsed = parse(number)
          new_index = parsed[:index] + 1
          limit = parsed[:parent] ? MAX_SIBLINGS_NESTED : MAX_SIBLINGS_TOP_LEVEL

          if new_index > limit
            raise ArgumentError, "Cannot create sibling: would exceed maximum siblings " \
                                 "(#{limit}) at this level (current index: #{parsed[:index]})"
          end

          if parsed[:parent]
            "#{parsed[:parent]}.#{format('%02d', new_index)}"
          else
            # Top-level numbers use 3-digit padding
            format("%03d", new_index)
          end
        end

        # Generate the first child job number.
        #
        # @param number [String] Parent job number
        # @return [String] First child number (e.g., "010" -> "010.01")
        # @raise [ArgumentError] If adding a child would exceed MAX_DEPTH
        #
        # @example
        #   first_child("010") # => "010.01"
        #   first_child("010.02") # => "010.02.01"
        def self.first_child(number)
          parent_depth = parse(number)[:depth]
          child_depth = parent_depth + 1
          if child_depth > MAX_DEPTH
            raise ArgumentError, "Cannot create child: would exceed maximum nesting depth of #{MAX_DEPTH} " \
                                 "(parent '#{number}' is at depth #{parent_depth})"
          end
          "#{number}.01"
        end

        # Generate the next child job number based on existing children.
        #
        # @param parent [String] Parent job number
        # @param existing_children [Array<String>] Existing child numbers
        # @return [String] Next child number
        # @raise [ArgumentError] If adding a child would exceed MAX_DEPTH
        #
        # @example
        #   next_child("010", []) # => "010.01"
        #   next_child("010", ["010.01", "010.02"]) # => "010.03"
        def self.next_child(parent, existing_children = [])
          parent_depth = parse(parent)[:depth]
          child_depth = parent_depth + 1
          if child_depth > MAX_DEPTH
            raise ArgumentError, "Cannot create child: would exceed maximum nesting depth of #{MAX_DEPTH} " \
                                 "(parent '#{parent}' is at depth #{parent_depth})"
          end

          return first_child(parent) if existing_children.empty?

          # Find highest existing child index
          max_index = existing_children
                      .select { |n| child_of?(n, parent) && direct_child_of?(n, parent) }
                      .map { |n| parse(n)[:index] }
                      .max || 0

          "#{parent}.#{format('%02d', max_index + 1)}"
        end

        # Check if a job number is a child (direct or nested) of another.
        #
        # @param child [String] Potential child number
        # @param parent [String] Potential parent number
        # @return [Boolean] True if child is descended from parent
        #
        # @example
        #   child_of?("010.02", "010")     # => true
        #   child_of?("010.02.03", "010")  # => true
        #   child_of?("010.02.03", "010.02") # => true
        #   child_of?("020", "010")        # => false
        #   child_of?("010", "010")        # => false (not a child of itself)
        def self.child_of?(child, parent)
          child.to_s.start_with?("#{parent}.")
        end

        # Check if a job number is a direct (immediate) child of another.
        #
        # @param child [String] Potential child number
        # @param parent [String] Potential parent number
        # @return [Boolean] True if child is immediate child of parent
        #
        # @example
        #   direct_child_of?("010.02", "010")     # => true
        #   direct_child_of?("010.02.03", "010")  # => false (grandchild)
        #   direct_child_of?("010.02.03", "010.02") # => true
        def self.direct_child_of?(child, parent)
          return false unless child_of?(child, parent)

          # Direct child has exactly one more level
          child_parsed = parse(child)
          parent_parsed = parse(parent)

          child_parsed[:depth] == parent_parsed[:depth] + 1
        end

        # Get all direct children of a parent from a list of numbers.
        #
        # @param parent [String] Parent job number
        # @param all_numbers [Array<String>] All job numbers to filter
        # @return [Array<String>] Direct children of parent
        #
        # @example
        #   direct_children("010", ["010.01", "010.02", "010.01.01", "020"])
        #   # => ["010.01", "010.02"]
        def self.direct_children(parent, all_numbers)
          all_numbers.select { |n| direct_child_of?(n, parent) }
        end

        # Get the parent number of a job, if it has one.
        #
        # @param number [String] Job number
        # @return [String, nil] Parent number or nil for top-level jobs
        #
        # @example
        #   parent_of("010.02") # => "010"
        #   parent_of("010") # => nil
        def self.parent_of(number)
          parse(number)[:parent]
        end

        # Check if a number is a top-level (root) job.
        #
        # @param number [String] Job number
        # @return [Boolean] True if top-level
        #
        # @example
        #   top_level?("010") # => true
        #   top_level?("010.01") # => false
        def self.top_level?(number)
          parse(number)[:depth] == 0
        end

        # Generate a job number to insert after another job.
        # This creates a sibling at the same nesting level.
        #
        # Note: This method does not check for collisions. Use jobs_to_renumber
        # to determine which existing jobs need to be shifted when inserting.
        #
        # @param after [String] Job number to insert after
        # @return [String] New job number (next sibling)
        #
        # @example Insert after 010.01
        #   insert_after("010.01") # => "010.02"
        #
        # @example Insert after top-level job
        #   insert_after("010") # => "011"
        def self.insert_after(after)
          next_sibling(after)
        end

        # Find job numbers that need to be renumbered when inserting at a position.
        # Returns jobs that have numbers >= the insertion point.
        #
        # @param at_number [String] Number where new job will be inserted
        # @param existing [Array<String>] All existing job numbers
        # @return [Array<String>] Numbers that need to be shifted (in ascending order)
        #
        # @example
        #   jobs_to_renumber("010.02", ["010.01", "010.02", "010.03"])
        #   # => ["010.02", "010.03"]
        def self.jobs_to_renumber(at_number, existing)
          parsed_at = parse(at_number)
          parent = parsed_at[:parent]

          existing
            .select { |n|
              parsed = parse(n)
              # Same parent (or both top-level) and index >= insertion point
              parsed[:parent] == parent && parsed[:index] >= parsed_at[:index]
            }
            .sort_by { |n| parse(n)[:index] }
        end

        # Generate the shifted number for a job being renumbered.
        #
        # @param number [String] Original job number
        # @param shift [Integer] Amount to shift by (default: 1)
        # @return [String] New shifted number
        # @raise [ArgumentError] If shifting would exceed sibling limits
        #
        # @example
        #   shift_number("010.02", 1) # => "010.03"
        #   shift_number("020", 1) # => "021"
        def self.shift_number(number, shift = 1)
          parsed = parse(number)
          new_index = parsed[:index] + shift
          limit = parsed[:parent] ? MAX_SIBLINGS_NESTED : MAX_SIBLINGS_TOP_LEVEL

          if new_index > limit
            raise ArgumentError, "Cannot shift job number: would exceed maximum siblings " \
                                 "(#{limit}) at this level (new index would be: #{new_index})"
          end

          if parsed[:parent]
            "#{parsed[:parent]}.#{format('%02d', new_index)}"
          else
            format("%03d", new_index)
          end
        end
      end
    end
  end
end
