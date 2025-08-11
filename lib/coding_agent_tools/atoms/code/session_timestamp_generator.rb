# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    module Code
      # Generates timestamp strings for session naming
      # This is an atom - it has no dependencies on other gem components
      class SessionTimestampGenerator
        # Generate timestamp in YYYYMMDD-HHMMSS format
        # @return [String] formatted timestamp
        def generate
          Time.now.strftime("%Y%m%d-%H%M%S")
        end

        # Generate ISO8601 timestamp
        # @return [String] ISO8601 formatted timestamp
        def generate_iso8601
          Time.now.iso8601
        end

        # Generate timestamp for a specific time
        # @param time [Time] the time to format
        # @return [String] formatted timestamp
        def generate_for_time(time)
          time.strftime("%Y%m%d-%H%M%S")
        end
      end
    end
  end
end
