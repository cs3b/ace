# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Atoms
        # Parses the `--active-within` activity window into hours.
        #
        # Accepted forms: `Nm` (minutes), `Nh` (hours), `Nd` (days), and bare
        # integers (interpreted as hours). The canonical label echoes the
        # operator's unit so the table header reads the way it was requested
        # (`3d` -> "3d", `5` -> "5h").
        #
        # @example Parse a window
        #   DurationParser.parse("18h") # => {hours: 18.0, label: "18h"}
        #   DurationParser.parse("90m") # => {hours: 1.5, label: "90m"}
        #   DurationParser.parse("5")   # => {hours: 5.0, label: "5h"}
        #
        # @example Invalid window
        #   DurationParser.parse("abc") # raises ArgumentError
        module DurationParser
          # Default activity window label
          DEFAULT_LABEL = "18h"

          # Accepted duration shape: positive integer + optional unit
          PATTERN = /\A(\d+)([mhd])?\z/

          class << self
            # Default activity window in hours (no unit = hours follows).
            # @return [Hash] parsed default window
            def default
              parse(DEFAULT_LABEL)
            end

            # Parse a duration string into hours.
            #
            # @param value [String, nil] raw CLI value
            # @return [Hash] `{hours: Float, label: String}`
            # @raise [ArgumentError] when the value is empty, zero, negative, or
            #   not one of the accepted forms
            def parse(value)
              raw = value.to_s.strip
              raise invalid_duration(value) if raw.empty?

              match = PATTERN.match(raw)
              raise invalid_duration(value) unless match

              amount = Integer(match[1], 10)
              unit = match[2]
              raise invalid_duration(value) if amount <= 0

              {hours: hours_for(amount, unit), label: "#{amount}#{display_unit(unit)}"}
            end

            private

            # @return [Float] duration expressed in hours
            def hours_for(amount, unit)
              case unit
              when "m" then amount / 60.0
              when "d" then amount * 24.0
              else amount.to_f # "h" or bare integer
              end
            end

            # @return [String] unit to echo back (bare integers render as hours)
            def display_unit(unit)
              unit || "h"
            end

            def invalid_duration(value)
              ArgumentError.new(
                "invalid duration '#{value}'. Use forms like 30m, 18h, 2d, or bare hours."
              )
            end
          end
        end
      end
    end
  end
end
