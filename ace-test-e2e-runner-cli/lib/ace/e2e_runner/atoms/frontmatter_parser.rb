# frozen_string_literal: true

require "date"
require "yaml"

module Ace
  module E2eRunner
    module Atoms
      class FrontmatterParser
        FRONTMATTER_DELIM = "---"

        def parse(content)
          frontmatter, = split(content)
          frontmatter
        end

        def strip(content)
          _, body = split(content)
          body
        end

        def split(content)
          return [{}, content] unless content.start_with?("#{FRONTMATTER_DELIM}\n")

          lines = content.lines
          return [{}, content] if lines.length < 3

          frontmatter_lines = []
          body_lines = []
          in_frontmatter = false
          delimiter_count = 0

          lines.each_with_index do |line, index|
            if line.strip == FRONTMATTER_DELIM
              delimiter_count += 1
              in_frontmatter = delimiter_count == 1
              next if index == 0 || delimiter_count == 2
            end

            if delimiter_count == 1
              frontmatter_lines << line
            elsif delimiter_count >= 2
              body_lines << line
            end
          end

          frontmatter = if frontmatter_lines.any?
                          YAML.safe_load(frontmatter_lines.join, permitted_classes: [Date], aliases: true) || {}
                        else
                          {}
                        end

          [frontmatter, body_lines.join]
        rescue StandardError
          [{}, content]
        end
      end
    end
  end
end
