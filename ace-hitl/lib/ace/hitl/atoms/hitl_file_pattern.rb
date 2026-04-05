# frozen_string_literal: true

module Ace
  module Hitl
    module Atoms
      class HitlFilePattern
        FILE_EXTENSION = ".hitl.s.md"
        FILE_GLOB = "*#{FILE_EXTENSION}"

        def self.folder_name(id, slug)
          slug.nil? || slug.empty? ? id : "#{id}-#{slug}"
        end

        def self.filename(id, slug)
          "#{folder_name(id, slug)}#{FILE_EXTENSION}"
        end
      end
    end
  end
end
