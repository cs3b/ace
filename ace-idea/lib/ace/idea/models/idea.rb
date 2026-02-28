# frozen_string_literal: true

module Ace
  module Idea
    module Models
      # Value object representing an idea
      # Holds all metadata and content for a single idea
      Idea = Struct.new(
        :id,             # Raw 6-char b36ts ID (e.g., "8ppq7w")
        :status,         # Status string: "pending", "in-progress", "done", "obsolete"
        :title,          # Human-readable title
        :tags,           # Array of tag strings
        :content,        # Body content (markdown, excluding frontmatter)
        :path,           # Directory path for the idea folder
        :file_path,      # Full path to the .idea.s.md spec file
        :special_folder, # Special folder if any (e.g., "_maybe", nil)
        :created_at,     # Time object for creation time
        :attachments,    # Array of attachment filenames in the idea folder
        :metadata,       # Additional frontmatter fields as Hash
        keyword_init: true
      ) do
        # Display-friendly representation
        def to_s
          "Idea(#{id}: #{title})"
        end

        # Short reference (last 3 chars of ID)
        def shortcut
          id[-3..] if id
        end

        # Check if idea is in a special folder
        def special?
          !special_folder.nil?
        end
      end
    end
  end
end
