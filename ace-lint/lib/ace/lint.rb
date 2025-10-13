# frozen_string_literal: true

require_relative 'lint/version'

# Models
require_relative 'lint/models/validation_error'
require_relative 'lint/models/lint_result'

# Atoms
require_relative 'lint/atoms/type_detector'
require_relative 'lint/atoms/kramdown_parser'
require_relative 'lint/atoms/yaml_parser'
require_relative 'lint/atoms/frontmatter_extractor'
require_relative 'lint/atoms/config_loader'

# Molecules
require_relative 'lint/molecules/markdown_linter'
require_relative 'lint/molecules/yaml_linter'
require_relative 'lint/molecules/frontmatter_validator'
require_relative 'lint/molecules/kramdown_formatter'

# Organisms
require_relative 'lint/organisms/lint_orchestrator'
require_relative 'lint/organisms/result_reporter'

# Commands
require_relative 'lint/commands/lint_command'

# CLI
require_relative 'lint/cli'

module Ace
  module Lint
    class Error < StandardError; end
  end
end
