# frozen_string_literal: true

module Ace
  module Taskflow
    module Models
      # Idea data structure
      class Idea
        attr_reader :content, :title, :timestamp, :location, :path,
                    :author, :tags, :category, :status

        def initialize(attributes = {})
          @content = attributes[:content]
          @title = attributes[:title] || extract_title(content)
          @timestamp = attributes[:timestamp] || Time.now
          @location = attributes[:location] || "active"
          @path = attributes[:path]
          @author = attributes[:author]
          @tags = attributes[:tags] || []
          @category = attributes[:category] || "general"
          @status = attributes[:status] || "unprocessed"
        end

        # Convert to hash
        def to_h
          {
            content: content,
            title: title,
            timestamp: timestamp,
            location: location,
            path: path,
            author: author,
            tags: tags,
            category: category,
            status: status
          }
        end

        # Check if idea is processed
        def processed?
          status == "processed"
        end

        # Check if idea is archived
        def archived?
          status == "archived"
        end

        # Check if idea is unprocessed
        def unprocessed?
          status == "unprocessed"
        end

        # Get formatted timestamp
        def formatted_timestamp(format = "%Y-%m-%d %H:%M:%S")
          timestamp.strftime(format)
        end

        # Get filename-safe title
        def filename_title
          title.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')[0..49]
        end

        # Generate filename
        def generate_filename
          timestamp_part = timestamp.strftime("%Y%m%d-%H%M%S")
          "#{timestamp_part}-#{filename_title}.md"
        end

        # Compare ideas for sorting
        def <=>(other)
          return 0 unless other.is_a?(Idea)

          # Sort by timestamp (newest first)
          other.timestamp <=> timestamp
        end

        # Convert to task metadata
        def to_task_metadata
          {
            title: title,
            priority: "medium",
            estimate: "TBD",
            dependencies: [],
            original_idea: path,
            captured_at: formatted_timestamp,
            author: author,
            tags: tags.join(", ")
          }
        end

        private

        def extract_title(content)
          return "Untitled Idea" if content.nil? || content.empty?

          # Take first line or first 50 chars
          first_line = content.split("\n").first || content
          title = first_line[0..49] if first_line.length > 50
          (title || first_line).strip
        end
      end
    end
  end
end