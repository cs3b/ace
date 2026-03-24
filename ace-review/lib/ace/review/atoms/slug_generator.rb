# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Generates URL-safe slugs from text strings
      #
      # Handles edge cases:
      # - Special characters replaced with hyphens
      # - Consecutive hyphens collapsed
      # - Leading/trailing hyphens removed
      # - Length truncation for filesystem safety
      class SlugGenerator
        DEFAULT_MAX_LENGTH = 64

        # Generate a URL-safe slug from text
        #
        # @param text [String] The text to convert to a slug
        # @param max_length [Integer] Maximum slug length (default: 64)
        # @return [String] URL-safe slug
        #
        # @example Basic usage
        #   SlugGenerator.generate("google:gemini-2.5-flash")
        #   #=> "google-gemini-2-5-flash"
        #
        # @example With special characters
        #   SlugGenerator.generate("model::name@provider")
        #   #=> "model-name-provider"
        #
        # @example With leading/trailing special chars
        #   SlugGenerator.generate("@model-name@")
        #   #=> "model-name"
        #
        # @example Long text truncation
        #   SlugGenerator.generate("very-long-model-name...", max_length: 10)
        #   #=> "very-long" (truncated, trailing hyphen removed)
        def self.generate(text, max_length: DEFAULT_MAX_LENGTH)
          return "" if text.nil? || text.empty?

          text
            .gsub(/[^a-zA-Z0-9\-_]/, "-").squeeze("-")              # Collapse consecutive hyphens
            .gsub(/\A-|-\z/, "")          # Remove leading/trailing hyphens
            .downcase
            .slice(0, max_length)         # Truncate to max length
            .gsub(/-\z/, "")              # Remove trailing hyphen after truncation
        end
      end
    end
  end
end
