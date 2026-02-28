# frozen_string_literal: true

require_relative "items/version"

# Atoms
require_relative "items/atoms/slug_sanitizer"
require_relative "items/atoms/field_argument_parser"
require_relative "items/atoms/special_folder_detector"
require_relative "items/atoms/frontmatter_parser"
require_relative "items/atoms/frontmatter_serializer"
require_relative "items/atoms/filter_parser"
require_relative "items/atoms/title_extractor"

# Models
require_relative "items/models/scan_result"
require_relative "items/models/loaded_document"

# Molecules
require_relative "items/molecules/directory_scanner"
require_relative "items/molecules/shortcut_resolver"
require_relative "items/molecules/document_loader"
require_relative "items/molecules/filter_applier"
require_relative "items/molecules/item_sorter"
require_relative "items/molecules/base_formatter"

module Ace
  module Support
    # Items provides shared infrastructure for item management (tasks, ideas, etc.)
    # across ace-* gems. Built on b36ts-based IDs and folder conventions.
    module Items
    end
  end
end
