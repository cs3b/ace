# frozen_string_literal: true

require_relative "retro/version"

# External dependencies
require "ace/b36ts"
require "ace/support/items"

# Atoms
require_relative "retro/atoms/retro_id_formatter"
require_relative "retro/atoms/retro_file_pattern"
require_relative "retro/atoms/retro_frontmatter_defaults"
require_relative "retro/atoms/retro_validation_rules"

# Models
require_relative "retro/models/retro"

# Molecules
require_relative "retro/molecules/retro_config_loader"
require_relative "retro/molecules/retro_scanner"
require_relative "retro/molecules/retro_resolver"
require_relative "retro/molecules/retro_loader"
require_relative "retro/molecules/retro_creator"
require_relative "retro/molecules/retro_mover"
require_relative "retro/molecules/retro_display_formatter"
require_relative "retro/molecules/retro_frontmatter_validator"
require_relative "retro/molecules/retro_structure_validator"
require_relative "retro/molecules/retro_doctor_fixer"
require_relative "retro/molecules/retro_doctor_reporter"

# Organisms
require_relative "retro/organisms/retro_manager"
require_relative "retro/organisms/retro_doctor"

module Ace
  # Retro management gem for ACE.
  # Manages retrospectives in .ace-retros/ using raw 6-char b36ts IDs.
  module Retro
    class Error < StandardError; end
  end
end
