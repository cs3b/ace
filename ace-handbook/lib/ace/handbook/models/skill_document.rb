# frozen_string_literal: true

module Ace
  module Handbook
    module Models
      class SkillDocument
        attr_reader :source_path, :frontmatter, :body

        def initialize(source_path:, frontmatter:, body:)
          @source_path = source_path
          @frontmatter = frontmatter
          @body = body
        end

        def name
          frontmatter.fetch("name")
        end

        def source
          frontmatter.fetch("source", "unknown").to_s
        end
      end
    end
  end
end
