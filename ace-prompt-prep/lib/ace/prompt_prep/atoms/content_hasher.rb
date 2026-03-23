# frozen_string_literal: true

require "digest"

module Ace
  module PromptPrep
    module Atoms
      # Generates SHA256 hash for content
      module ContentHasher
        # Generate hash for content
        #
        # @param content [String, nil] Content to hash
        # @return [Hash] Hash with :hash key
        def self.call(content:)
          if content.nil? || content.empty?
            {hash: ""}
          else
            {hash: Digest::SHA256.hexdigest(content)}
          end
        end
      end
    end
  end
end
