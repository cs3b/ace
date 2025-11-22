# frozen_string_literal: true

require "digest/md5"

module Ace
  module Prompt
    module Atoms
      # Generate MD5 hash for content to use as cache key
      class ContentHasher
        # Generate MD5 hash of content
        # @param content [String] Content to hash
        # @return [String] Hex digest of MD5 hash
        def self.hash(content)
          Digest::MD5.hexdigest(content)
        end
      end
    end
  end
end
