# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Atoms
        # SlugSanitizer provides strict kebab-case slug sanitization for filesystem safety.
        # Ensures consistent slug handling across the codebase.
        #
        # Features:
        # - Removes path traversal characters (dots, slashes, backslashes)
        # - Enforces lowercase, numbers, and hyphens only
        # - Collapses multiple hyphens and trims leading/trailing hyphens
        # - Returns empty string for entirely invalid input (caller should handle fallback)
        class SlugSanitizer
          MAX_LENGTH = 55

          # Sanitize a slug string to strict kebab-case.
          #
          # @param slug [String, nil] The slug to sanitize
          # @param max_length [Integer] Maximum length for the slug (default: MAX_LENGTH)
          # @return [String] Sanitized slug (empty string if input is nil or entirely invalid)
          #
          # @example
          #   SlugSanitizer.sanitize("My Topic-Slug")
          #   # => "my-topic-slug"
          #
          #   SlugSanitizer.sanitize("../../etc/passwd")
          #   # => "etc-passwd"
          #
          #   SlugSanitizer.sanitize("../")
          #   # => "" (empty - caller should use fallback)
          def self.sanitize(slug, max_length: MAX_LENGTH)
            return "" if slug.nil? || slug.empty?

            # Remove any characters that could enable path traversal: dots, slashes, backslashes
            # Then validate against allowed pattern (lowercase, numbers, hyphens only)
            cleaned = slug.to_s.gsub(/[.\\\/]/, "").strip
            # Further sanitize to only allowed characters (lowercase letters, numbers, hyphens)
            result = cleaned.downcase.gsub(/[^a-z0-9-]/, "-").squeeze("-").gsub(/^-|-$/, "")
            truncate_at_word_boundary(result, max_length)
          end

          # Truncate at word boundary (last hyphen before max_length) to avoid mid-word cuts.
          #
          # @param result [String] The sanitized slug
          # @param max_length [Integer] Maximum allowed length
          # @return [String] Truncated slug
          def self.truncate_at_word_boundary(result, max_length)
            return result if result.length <= max_length

            truncated = result[0...max_length]
            # Find last hyphen to avoid cutting mid-word
            last_hyphen = truncated.rindex("-")
            if last_hyphen && last_hyphen > 0
              truncated[0...last_hyphen]
            else
              truncated
            end
          end

          private_class_method :truncate_at_word_boundary
        end
      end
    end
  end
end
