# frozen_string_literal: true

require_relative "idea/version"

# External dependencies
require "ace/b36ts"
require "ace/support/items"

# Atoms
require_relative "idea/atoms/idea_id_formatter"
require_relative "idea/atoms/idea_file_pattern"
require_relative "idea/atoms/idea_frontmatter_defaults"

# Models
require_relative "idea/models/idea"

# Molecules
require_relative "idea/molecules/idea_config_loader"
require_relative "idea/molecules/idea_scanner"
require_relative "idea/molecules/idea_resolver"
require_relative "idea/molecules/idea_loader"
require_relative "idea/molecules/idea_creator"
require_relative "idea/molecules/idea_llm_enhancer"
require_relative "idea/molecules/idea_clipboard_reader"
require_relative "idea/molecules/idea_mover"
require_relative "idea/molecules/idea_display_formatter"

# Organisms
require_relative "idea/organisms/idea_manager"

module Ace
  # Idea management gem for ACE.
  # Manages ideas in .ace-ideas/ using raw 6-char b36ts IDs.
  module Idea
    class Error < StandardError; end
  end
end
