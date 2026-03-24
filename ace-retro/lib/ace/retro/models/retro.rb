# frozen_string_literal: true

module Ace
  module Retro
    module Models
      # Value object representing a retrospective
      # Holds all metadata and content for a single retro
      Retro = Struct.new(
        :id,              # Raw 6-char b36ts ID (e.g., "8ppq7w")
        :status,          # Status string: "active", "done"
        :title,           # Human-readable title
        :type,            # Retro type: "standard", "conversation-analysis", "self-review"
        :tags,            # Array of tag strings
        :content,         # Body content (markdown, excluding frontmatter)
        :path,            # Directory path for the retro folder
        :file_path,       # Full path to the .retro.md file
        :special_folder,  # Special folder if any (e.g., "_archive", nil)
        :created_at,      # Time object for creation time
        :folder_contents, # Array of additional filenames in the retro folder
        :metadata,        # Additional frontmatter fields as Hash
        keyword_init: true
      ) do
        # Display-friendly representation
        def to_s
          "Retro(#{id}: #{title})"
        end

        # Short reference (last 3 chars of ID)
        def shortcut
          id[-3..] if id
        end

        # Check if retro is in a special folder
        def special?
          !special_folder.nil?
        end
      end
    end
  end
end
