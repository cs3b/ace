# frozen_string_literal: true

module Ace
  module Prompt
    module Atoms
      # Generates timestamps in YYYYMMDD-HHMMSS format
      module TimestampGenerator
        # Generate timestamp for current time
        #
        # @param time [Time] Optional time to format (default: Time.now)
        # @return [Hash] Hash with :timestamp key
        def self.call(time: Time.now)
          {
            timestamp: time.strftime("%Y%m%d-%H%M%S")
          }
        end
      end
    end
  end
end
