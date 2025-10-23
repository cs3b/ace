# frozen_string_literal: true

require_relative "markdown/version"

# Atoms
require_relative "markdown/atoms/frontmatter_extractor"
require_relative "markdown/atoms/frontmatter_serializer"
require_relative "markdown/atoms/section_extractor"
require_relative "markdown/atoms/document_validator"

# Molecules
require_relative "markdown/molecules/frontmatter_editor"
require_relative "markdown/molecules/section_editor"
require_relative "markdown/molecules/kramdown_processor"
require_relative "markdown/molecules/document_builder"

# Organisms
require_relative "markdown/organisms/document_editor"
require_relative "markdown/organisms/safe_file_writer"

# Models
require_relative "markdown/models/markdown_document"
require_relative "markdown/models/section"

module Ace
  module Support
    module Markdown
      class Error < StandardError; end
      class ValidationError < Error; end
      class SectionNotFoundError < Error; end
      class FileOperationError < Error; end
    end
  end
end
