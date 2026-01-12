# frozen_string_literal: true

require "time"
require "ace/support/timestamp"
require_relative "../atoms/slug_sanitizer"

module Ace
  module Taskflow
    module Molecules
      class FileNamer
        def initialize(config, time_provider: Time)
          @config = config
          @time_provider = time_provider
        end

        def generate(metadata = {})
          id = generate_id
          directory = idea_directory

          # BUG FIX: ALWAYS generate directory paths (never flat files)
          # This fixes the bug where ideas were sometimes created as flat files
          # Generate folder name with id + theme
          if metadata[:folder_slug]
            # Use LLM-generated hierarchical slugs (defensively sanitized)
            safe_slug = sanitize_slug(metadata[:folder_slug])
            # Fallback to title-based naming if sanitization results in empty string
            if safe_slug.empty?
              title = sanitize_title(metadata[:title])
              # Also apply SlugSanitizer to title for path traversal protection
              safe_title = title ? sanitize_slug(title) : nil
              dirname = if safe_title && !safe_title.empty?
                          "#{id}-#{safe_title}"
                        else
                          "#{id}-idea"
                        end
            else
              dirname = "#{id}-#{safe_slug}"
            end
          else
            # Fallback: use title for folder slug (also sanitize for path traversal protection)
            title = sanitize_title(metadata[:title])
            safe_title = title ? sanitize_slug(title) : nil
            dirname = if safe_title && !safe_title.empty?
                        "#{id}-#{safe_title}"
                      else
                        "#{id}-idea"
                      end
          end
          File.join(directory, dirname)
        end

        # Generate a Base36 compact ID (6 characters)
        # @return [String] 6-char Base36 compact ID
        def generate_id
          Ace::Support::Timestamp.encode(@time_provider.now)
        end

        # Detect the format of an ID string
        # @param id_string [String] The ID to analyze
        # @return [Symbol, nil] :compact, :timestamp, or nil
        def self.detect_id_format(id_string)
          Ace::Support::Timestamp.detect_format(id_string)
        end

        private

        # Defensive sanitization for slugs to prevent path traversal
        # Delegates to SlugSanitizer atom for consistency across codebase
        # @param slug [String] The slug to sanitize
        # @return [String] Sanitized slug safe for filesystem operations
        def sanitize_slug(slug)
          Ace::Taskflow::Atoms::SlugSanitizer.sanitize(slug)
        end

        def sanitize_title(title)
          return nil if title.nil? || title.empty?

          max_length = @config.dig("file_naming", "title_max_length") || 50

          # Convert to string, downcase, and replace non-alphanumeric chars with hyphens
          sanitized = title.to_s.downcase
                          .gsub(/[^\w\s-]/, "") # Remove non-word chars except spaces and hyphens
                          .gsub(/[\s_]+/, "-")  # Replace spaces and underscores with hyphens
                          .gsub(/-+/, "-")      # Collapse multiple hyphens
                          .gsub(/^-|-$/, "")    # Remove leading/trailing hyphens

          # Truncate to configured max length
          sanitized[0..(max_length - 1)]
        end

        def idea_directory
          # Check both flat config and nested under "idea" key
          @config["directory"] || @config.dig("idea", "directory") || "./ideas"
        end
      end
    end
  end
end