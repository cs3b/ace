# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Models
        # Value object representing a loaded document with parsed frontmatter,
        # body content, title, and file metadata.
        LoadedDocument = Struct.new(
          :frontmatter,    # Hash - parsed YAML frontmatter
          :body,           # String - document body after frontmatter
          :title,          # String - from frontmatter["title"], H1 heading, or folder name
          :file_path,      # String - path to spec file
          :dir_path,       # String - path to item directory
          :attachments,    # Array<String> - non-spec filenames in directory
          keyword_init: true
        ) do
          # Access frontmatter values by key (string or symbol)
          # @param key [String, Symbol] Frontmatter key
          # @return [Object, nil] Value or nil
          def [](key)
            frontmatter[key.to_s] || frontmatter[key.to_sym]
          end
        end
      end
    end
  end
end
