# frozen_string_literal: true

require "time"

module Ace
  module Taskflow
    module Molecules
      class FileNamer
        def initialize(config)
          @config = config
        end

        def generate(metadata = {})
          timestamp_format = @config.dig("file_naming", "timestamp_format") || "%Y%m%d-%H%M%S"
          timestamp = Time.now.strftime(timestamp_format)
          directory = idea_directory

          # BUG FIX: ALWAYS generate directory paths (never flat files)
          # This fixes the bug where ideas were sometimes created as flat files
          # Generate folder name with timestamp + theme
          if metadata[:folder_slug]
            # Use LLM-generated hierarchical slugs
            dirname = "#{timestamp}-#{metadata[:folder_slug]}"
          else
            # Fallback: use title for folder slug
            title = sanitize_title(metadata[:title])
            dirname = if title && !title.empty?
                        "#{timestamp}-#{title}"
                      else
                        "#{timestamp}-idea"
                      end
          end
          File.join(directory, dirname)
        end

        private

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