# frozen_string_literal: true

module Ace
  module E2eRunner
    module Models
      class TestScenario
        attr_reader :id, :title, :area, :package, :path, :content, :frontmatter

        def initialize(id:, title: nil, area: nil, package: nil, path:, content:, frontmatter: {})
          @id = id
          @title = title
          @area = area
          @package = package
          @path = path
          @content = content
          @frontmatter = frontmatter
        end
      end
    end
  end
end
