# frozen_string_literal: true

require "time"

module Ace
  module Idea
    module Atoms
      # Provides default frontmatter values for idea spec files.
      # Generates the canonical YAML frontmatter block for new ideas.
      module IdeaFrontmatterDefaults
        # Build frontmatter hash for a new idea
        # @param id [String] Raw 6-char b36ts ID
        # @param title [String] Idea title
        # @param tags [Array<String>] List of tags (default: [])
        # @param status [String] Initial status (default: "pending")
        # @param created_at [Time] Creation time (default: now)
        # @return [Hash] Frontmatter hash ready for YAML serialization
        def self.build(id:, title:, tags: [], status: "pending", created_at: Time.now.utc)
          {
            "id" => id,
            "status" => status,
            "title" => title,
            "tags" => Array(tags),
            "created_at" => created_at.strftime("%Y-%m-%d %H:%M:%S")
          }
        end

        # Serialize frontmatter hash to YAML block string.
        # Delegates to the shared FrontmatterSerializer atom.
        # @param frontmatter [Hash] Frontmatter data
        # @return [String] YAML frontmatter block including delimiters
        def self.serialize(frontmatter)
          require "ace/support/items"
          Ace::Support::Items::Atoms::FrontmatterSerializer.serialize(frontmatter)
        end
      end
    end
  end
end
