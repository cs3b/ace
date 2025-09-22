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
          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
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

          # Convert to string, downcase, and replace non-alphanumeric chars with hyphens
          sanitized = title.to_s.downcase
                          .gsub(/[^\w\s-]/, "") # Remove non-word chars except spaces and hyphens
                          .gsub(/[\s_]+/, "-")  # Replace spaces and underscores with hyphens
                          .gsub(/-+/, "-")      # Collapse multiple hyphens
                          .gsub(/^-|-$/, "")    # Remove leading/trailing hyphens

          # Truncate to reasonable length (50 chars)
          sanitized[0..49]
        end

        def idea_directory
          @config.dig("taskflow", "idea", "directory") || "./ideas"
        end
      end
    end
  end
end