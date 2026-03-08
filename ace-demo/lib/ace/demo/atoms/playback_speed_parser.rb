# frozen_string_literal: true

module Ace
  module Demo
    module Atoms
      module PlaybackSpeedParser
        SPEED_FACTORS = {
          "1x" => 1.0,
          "2x" => 2.0,
          "4x" => 4.0,
          "8x" => 8.0
        }.freeze

        module_function

        def parse(value)
          return nil if value.nil?

          normalized = value.to_s.strip.downcase
          return nil if normalized.empty?

          factor = SPEED_FACTORS[normalized]
          raise ArgumentError, "Invalid playback speed: #{value}. Use one of: #{SPEED_FACTORS.keys.join(', ')}." unless factor

          { label: normalized, factor: factor }
        end
      end
    end
  end
end
