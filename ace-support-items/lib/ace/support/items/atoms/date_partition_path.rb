# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Atoms
        # Computes a date-based partition path using B36TS month+week split.
        # Result: "8p/4" (month / week components joined with "/")
        class DatePartitionPath
          DEFAULT_LEVELS = %i[month week].freeze

          # @param time [Time] The time to partition
          # @param levels [Array<Symbol>] B36TS split levels (default: [:month, :week])
          # @return [String] Path string e.g. "8p/4"
          def self.compute(time, levels: DEFAULT_LEVELS)
            require "ace/b36ts"
            result = Ace::B36ts.encode_split(time, levels: levels)
            levels.map { |l| result[l].to_s }.join("/")
          end
        end
      end
    end
  end
end
