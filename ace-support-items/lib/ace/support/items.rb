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
require_relative "items/atoms/date_partition_path"
require_relative "items/atoms/item_id_formatter"
require_relative "items/atoms/item_id_parser"
require_relative "items/atoms/item_statistics"
require_relative "items/atoms/stats_line_formatter"
require_relative "items/atoms/relative_time_formatter"

# Models
require_relative "items/models/scan_result"
require_relative "items/models/loaded_document"
require_relative "items/models/item_id"

# Molecules
require_relative "items/molecules/directory_scanner"
require_relative "items/molecules/shortcut_resolver"
require_relative "items/molecules/document_loader"
require_relative "items/molecules/filter_applier"
require_relative "items/molecules/item_sorter"
require_relative "items/molecules/base_formatter"
require_relative "items/molecules/field_updater"
require_relative "items/molecules/folder_mover"
require_relative "items/molecules/llm_slug_generator"
require_relative "items/molecules/status_categorizer"
require_relative "items/molecules/git_committer"

module Ace
  module Support
    # Items provides shared infrastructure for item management (tasks, ideas, etc.)
    # across ace-* gems. Built on b36ts-based IDs and folder conventions.
    module Items
    end
  end
end
