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
          # Sanitize a slug string to strict kebab-case.
          #
          # @param slug [String, nil] The slug to sanitize
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
          def self.sanitize(slug)
            return "" if slug.nil? || slug.empty?

            # Remove any characters that could enable path traversal: dots, slashes, backslashes
            # Then validate against allowed pattern (lowercase, numbers, hyphens only)
            cleaned = slug.to_s.gsub(/[.\\\/]/, "").strip
            # Further sanitize to only allowed characters (lowercase letters, numbers, hyphens)
            cleaned.downcase.gsub(/[^a-z0-9-]/, "-").gsub(/-+/, "-").gsub(/^-|-$/, "")
          end
        end
      end
    end
  end
end
