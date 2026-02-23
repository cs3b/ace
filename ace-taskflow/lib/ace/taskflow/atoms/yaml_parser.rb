# frozen_string_literal: true

# Backward compatibility shim: YamlParser has been renamed to FrontmatterParser
# to eliminate naming confusion with the canonical YamlParser in ace-support-config.
require_relative "frontmatter_parser"

module Ace
  module Taskflow
    module Atoms
      YamlParser = FrontmatterParser
    end
  end
end
