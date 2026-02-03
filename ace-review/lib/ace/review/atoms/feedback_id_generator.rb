# frozen_string_literal: true

require "ace/support/timestamp"

module Ace
  module Review
    module Atoms
      # Generates unique 8-character Base36 IDs for feedback items.
      #
      # Uses ace-support-timestamp to generate timestamp-based IDs with
      # millisecond precision that sort chronologically. This enables
      # natural ordering of feedback items by creation time.
      #
      # @example Generate a new ID
      #   FeedbackIdGenerator.generate
      #   #=> "i50jj3ab"
      #
      # @example IDs are chronologically sortable
      #   id1 = FeedbackIdGenerator.generate
      #   sleep(0.1)
      #   id2 = FeedbackIdGenerator.generate
      #   id1 < id2 #=> true
      #
      class FeedbackIdGenerator
        # Generate a new 8-character Base36 ID based on current timestamp
        # with millisecond precision
        #
        # @return [String] 8-character Base36 ID (e.g., "i50jj3ab")
        def self.generate
          Ace::Support::Timestamp.encode(Time.now.utc, format: :ms)
        end

        # Generate a new ID for a specific time (useful for testing)
        #
        # @param time [Time] The time to encode
        # @return [String] 8-character Base36 ID
        def self.generate_for(time)
          Ace::Support::Timestamp.encode(time.utc, format: :ms)
        end
      end
    end
  end
end
