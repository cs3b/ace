# frozen_string_literal: true

module Ace
  module Handbook
    module Models
      class PromptTemplate
        attr_reader :provider, :source_path, :frontmatter, :content

        def initialize(provider:, source_path:, frontmatter:, content:)
          @provider = provider
          @source_path = source_path
          @frontmatter = frontmatter
          @content = content
        end

        def name
          File.basename(source_path, ".md")
        end

        def source
          frontmatter["source"].to_s
        end
      end
    end
  end
end
