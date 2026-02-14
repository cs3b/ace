# frozen_string_literal: true

require "ace/b36ts"

module Ace
  module Review
    module Atoms
      # Generates unique 8-character Base36 IDs for feedback items.
      #
      # Uses ace-b36ts to generate timestamp-based IDs with
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
          Ace::B36ts.encode(Time.now.utc, format: :ms)
        end

        # Generate a new ID for a specific time (useful for testing)
        #
        # @param time [Time] The time to encode
        # @return [String] 8-character Base36 ID
        def self.generate_for(time)
          Ace::B36ts.encode(time.utc, format: :ms)
        end

        # Generate a sequence of unique, sequential IDs
        #
        # Uses ace-b36ts's encode_sequence to generate IDs that are
        # guaranteed unique even when created in rapid succession. Each ID is
        # strictly greater than the previous (lexicographically).
        #
        # @param count [Integer] Number of IDs to generate
        # @return [Array<String>] Array of unique 8-character Base36 IDs
        # @raise [ArgumentError] If count <= 0
        #
        # @example Generate 5 unique IDs
        #   ids = FeedbackIdGenerator.generate_sequence(5)
        #   ids.length #=> 5
        #   ids.uniq.length #=> 5  # All unique
        #   ids == ids.sort #=> true  # Already sorted
        def self.generate_sequence(count)
          Ace::B36ts::Atoms::CompactIdEncoder.encode_sequence(
            Time.now.utc,
            count: count,
            format: :ms
          )
        end
      end
    end
  end
end
