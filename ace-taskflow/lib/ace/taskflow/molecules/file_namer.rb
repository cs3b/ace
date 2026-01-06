# frozen_string_literal: true

require "time"
require "ace/timestamp"

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
            # Use LLM-generated hierarchical slugs
            dirname = "#{id}-#{metadata[:folder_slug]}"
          else
            # Fallback: use title for folder slug
            title = sanitize_title(metadata[:title])
            dirname = if title && !title.empty?
                        "#{id}-#{title}"
                      else
                        "#{id}-idea"
                      end
          end
          File.join(directory, dirname)
        end

        # Generate a Base36 compact ID (6 characters)
        # @return [String] 6-char Base36 compact ID
        def generate_id
          Ace::Timestamp.encode(@time_provider.now)
        end

        # Detect the format of an ID string
        # @param id_string [String] The ID to analyze
        # @return [Symbol, nil] :compact, :timestamp, or nil
        def self.detect_id_format(id_string)
          Ace::Timestamp.detect_format(id_string)
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