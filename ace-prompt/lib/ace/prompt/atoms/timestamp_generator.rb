# frozen_string_literal: true

module Ace
  module Prompt
    module Atoms
      # Generate timestamp in YYYYMMDD-HHMMSS format for archive filenames
      class TimestampGenerator
        # Generate timestamp for current time
        # @return [String] Timestamp in format YYYYMMDD-HHMMSS
        def self.generate(time = Time.now)
          time.strftime("%Y%m%d-%H%M%S")
        end

        # Generate timestamp with enhancement suffix
        # @param iteration [Integer] Enhancement iteration number (1, 2, 3, etc.)
        # @return [String] Timestamp with _e001, _e002, etc. suffix
        def self.generate_with_enhancement(iteration, time = Time.now)
          base = generate(time)
          "#{base}_e#{iteration.to_s.rjust(3, '0')}"
        end
      end
    end
  end
end
