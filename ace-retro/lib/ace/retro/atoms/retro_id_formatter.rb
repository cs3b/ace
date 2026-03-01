# frozen_string_literal: true

require "ace/b36ts"

module Ace
  module Retro
    module Atoms
      # Generates and formats raw b36ts IDs for retros.
      # Retros use raw 6-char b36ts IDs without type markers.
      # Example: "8ppq7w" (no ".t." or ".i." separator)
      class RetroIdFormatter
        # Generate a new raw 6-char b36ts ID for a retro
        # @param time [Time] Time to encode (default: now)
        # @return [String] 6-character raw b36ts ID (e.g., "8ppq7w")
        def self.generate(time = Time.now.utc)
          Ace::B36ts.encode(time, format: :"2sec")
        end

        # Validate that a string is a valid raw retro ID
        # @param id [String] The ID to validate
        # @return [Boolean] True if valid 6-char b36ts ID
        def self.valid?(id)
          return false if id.nil? || id.empty?

          Ace::B36ts.valid?(id)
        end

        # Decode a raw retro ID to the time it was created
        # @param id [String] Raw 6-char b36ts ID
        # @return [Time] The time encoded in the ID
        def self.decode_time(id)
          Ace::B36ts.decode(id)
        end
      end
    end
  end
end
