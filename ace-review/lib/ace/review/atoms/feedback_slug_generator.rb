# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Generates URL-safe slugs from feedback item titles.
      #
      # Creates slugs suitable for use in filenames and URLs, handling
      # edge cases like unicode, special characters, and length limits.
      #
      # @example Basic usage
      #   FeedbackSlugGenerator.generate("Missing error handling")
      #   #=> "missing-error-handling"
      #
      # @example Long titles are truncated
      #   FeedbackSlugGenerator.generate("A very long title that exceeds forty characters limit")
      #   #=> "a-very-long-title-that-exceeds-forty" (truncated to 40 chars)
      #
      # @example Unicode is transliterated or removed
      #   FeedbackSlugGenerator.generate("Fix bug in caf\u00e9 module")
      #   #=> "fix-bug-in-caf-module"
      #
      class FeedbackSlugGenerator
        DEFAULT_MAX_LENGTH = 40

        # Generate a URL-safe slug from a title
        #
        # @param title [String] The title to convert to a slug
        # @param max_length [Integer] Maximum slug length (default: 40)
        # @return [String] URL-safe slug
        #
        # @example Basic title
        #   FeedbackSlugGenerator.generate("Fix authentication bug")
        #   #=> "fix-authentication-bug"
        #
        # @example With special characters
        #   FeedbackSlugGenerator.generate("Add try/catch block (urgent!)")
        #   #=> "add-try-catch-block-urgent"
        #
        # @example Empty or nil input
        #   FeedbackSlugGenerator.generate(nil)
        #   #=> ""
        #   FeedbackSlugGenerator.generate("")
        #   #=> ""
        def self.generate(title, max_length: DEFAULT_MAX_LENGTH)
          return "" if title.nil? || title.empty?

          title
            .unicode_normalize(:nfkd)           # Decompose unicode (e.g., é -> e + combining accent)
            .encode("ASCII", undef: :replace, replace: "") # Strip non-ASCII
            .gsub(/[^a-zA-Z0-9\-_\s]/, "")      # Remove special chars (keep spaces for now)
            .gsub(/[\s_]+/, "-").squeeze("-")                     # Collapse consecutive hyphens
            .gsub(/\A-|-\z/, "")                 # Remove leading/trailing hyphens
            .downcase
            .slice(0, max_length)                # Truncate to max length
            .gsub(/-\z/, "")                     # Remove trailing hyphen after truncation
        end
      end
    end
  end
end
