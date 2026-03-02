# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Atoms
        # Generates B36TS position values for pinning items in sort order.
        # Position values are 6-char B36TS strings that sort lexicographically = chronologically.
        module PositionGenerator
          # Increment/decrement in seconds for before/after positioning.
          # ~2 seconds precision in B36TS, so 4 seconds ensures a distinct value.
          OFFSET_SECONDS = 4

          # Generate a very early position (sorts before all normal timestamps).
          # Uses a fixed early time to ensure it sorts first.
          # @return [String] 6-char B36TS position
          def self.first
            require "ace/b36ts"
            # Year 2020, Jan 1 — well before any real item creation
            early_time = Time.utc(2020, 1, 1)
            Ace::B36ts.encode(early_time)
          end

          # Generate a position at current time (sorts after all existing items).
          # @return [String] 6-char B36TS position
          def self.last
            require "ace/b36ts"
            Ace::B36ts.encode(Time.now.utc)
          end

          # Generate a position just after the given position.
          # @param pos [String] Existing 6-char B36TS position
          # @return [String] 6-char B36TS position slightly after pos
          def self.after(pos)
            require "ace/b36ts"
            time = Ace::B36ts.decode(pos)
            Ace::B36ts.encode(time + OFFSET_SECONDS)
          end

          # Generate a position just before the given position.
          # @param pos [String] Existing 6-char B36TS position
          # @return [String] 6-char B36TS position slightly before pos
          def self.before(pos)
            require "ace/b36ts"
            time = Ace::B36ts.decode(pos)
            Ace::B36ts.encode(time - OFFSET_SECONDS)
          end

          # Generate a position between two existing positions.
          # @param a [String] Lower 6-char B36TS position
          # @param b [String] Upper 6-char B36TS position
          # @return [String] 6-char B36TS position between a and b
          def self.between(a, b)
            require "ace/b36ts"
            time_a = Ace::B36ts.decode(a)
            time_b = Ace::B36ts.decode(b)
            midpoint = Time.at((time_a.to_f + time_b.to_f) / 2).utc
            Ace::B36ts.encode(midpoint)
          end
        end
      end
    end
  end
end
