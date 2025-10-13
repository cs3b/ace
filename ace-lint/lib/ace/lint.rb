# frozen_string_literal: true

require_relative 'lint/version'

# Load ace-core for config management
require 'ace/core'

# Models
require_relative 'lint/models/validation_error'
require_relative 'lint/models/lint_result'

# Atoms
require_relative 'lint/atoms/type_detector'
require_relative 'lint/atoms/kramdown_parser'
require_relative 'lint/atoms/yaml_parser'
require_relative 'lint/atoms/frontmatter_extractor'

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

    # Load general ace-lint configuration using ace-core config cascade
    # Follows ace-* pattern: ./.ace/lint/config.yml → ~/.ace/lint/config.yml
    # @return [Hash] Configuration hash
    def self.config
      @config ||= begin
        base_config = Ace::Core.config
        base_config.get('ace', 'lint') || {}
      rescue StandardError => e
        warn "Warning: Could not load ace-lint config: #{e.message}"
        {}
      end
    end

    # Load kramdown-specific configuration
    # Config location: .ace/lint/kramdown.yml
    # @return [Hash] Kramdown configuration
    def self.kramdown_config
      @kramdown_config ||= begin
        base_config = Ace::Core.config
        base_config.get('ace', 'lint', 'kramdown') || default_kramdown_config
      rescue StandardError => e
        warn "Warning: Could not load kramdown config: #{e.message}"
        default_kramdown_config
      end
    end

    # Default kramdown configuration when no config file exists
    # @return [Hash] Default kramdown configuration
    def self.default_kramdown_config
      {
        'input' => 'GFM',
        'line_width' => 120,
        'auto_ids' => false,
        'hard_wrap' => false,
        'parse_block_html' => true,
        'parse_span_html' => true
      }
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
      @kramdown_config = nil
    end
  end
end
