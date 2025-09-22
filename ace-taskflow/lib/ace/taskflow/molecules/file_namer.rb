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
          title = sanitize_title(metadata[:title])
          directory = idea_directory

          filename = if title && !title.empty?
                       "#{timestamp}-#{title}.md"
                     else
                       "#{timestamp}-idea.md"
                     end

          File.join(directory, filename)
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
          @config["directory"] || "./ideas"
        end
      end
    end
  end
end