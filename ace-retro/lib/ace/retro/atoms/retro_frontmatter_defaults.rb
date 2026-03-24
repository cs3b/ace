# frozen_string_literal: true

require "time"

module Ace
  module Retro
    module Atoms
      # Provides default frontmatter values for retro files.
      # Generates the canonical YAML frontmatter block for new retros.
      module RetroFrontmatterDefaults
        # Build frontmatter hash for a new retro
        # @param id [String] Raw 6-char b36ts ID
        # @param title [String] Retro title
        # @param type [String] Retro type (standard, conversation-analysis, self-review)
        # @param tags [Array<String>] List of tags (default: [])
        # @param status [String] Initial status (default: "active")
        # @param created_at [Time] Creation time (default: now)
        # @return [Hash] Frontmatter hash ready for YAML serialization
        def self.build(id:, title:, type: "standard", tags: [], status: "active",
                       created_at: Time.now.utc)
          {
            "id" => id,
            "title" => title,
            "type" => type,
            "tags" => Array(tags),
            "created_at" => created_at.strftime("%Y-%m-%d %H:%M:%S"),
            "status" => status
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
