# frozen_string_literal: true

require "ace/support/timestamp"

module Ace
  module PromptPrep
    module Atoms
      # Generates Base36 compact IDs for prompt archiving
      #
      # Uses ace-timestamp to generate 6-character compact IDs (e.g., "i50jj3")
      # These IDs serve as session identifiers for archived prompts
      module SessionIdGenerator
        # Generate Base36 ID for current time
        #
        # @param time [Time] Optional time in UTC (default: current UTC time)
        # @return [Hash] Hash with :timestamp key containing 6-char Base36 ID
        # @note Time is expected to be in UTC for consistent ID generation
        def self.call(time: nil)
          time ||= Time.now.utc
          {
            timestamp: Ace::Support::Timestamp.encode(time)
          }
        end

        # Check if a string is a valid Base36 ID
        #
        # @param value [String] ID string to validate
        # @return [Boolean] true if valid Base36 ID
        def self.valid?(value)
          return false unless value.is_a?(String)

          Ace::Support::Timestamp.valid?(value)
        end
      end
    end
  end
end
