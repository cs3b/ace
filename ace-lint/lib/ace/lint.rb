# frozen_string_literal: true

require_relative 'lint/version'

# Load ace-config for configuration cascade management
require 'ace/config'

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

    # Check if debug mode is enabled
    # @return [Boolean] True if debug mode is enabled
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end

    # Load general ace-lint configuration using ace-config cascade
    # Follows ADR-022: Configuration Default and Override Pattern
    # Uses Ace::Config.create() for configuration cascade resolution
    # @return [Hash] Configuration hash with defaults merged
    def self.config
      @config ||= begin
        gem_root = Gem.loaded_specs["ace-lint"]&.gem_dir ||
                   File.expand_path("../..", __dir__)

        resolver = Ace::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve config for lint namespace
        config = resolver.resolve_namespace("lint")
        config.data
      rescue StandardError => e
        warn "Warning: Could not load ace-lint config: #{e.message}" if debug?
        {}
      end
    end

    # Load kramdown-specific configuration using ace-config cascade
    # Follows ADR-022: Configuration Default and Override Pattern
    # Config location: .ace/lint/kramdown.yml
    # @return [Hash] Kramdown configuration hash with defaults merged
    def self.kramdown_config
      @kramdown_config ||= begin
        gem_root = Gem.loaded_specs["ace-lint"]&.gem_dir ||
                   File.expand_path("../..", __dir__)

        resolver = Ace::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve kramdown-specific config
        config = resolver.resolve_namespace("lint", filename: "kramdown")
        config.data
      rescue StandardError => e
        warn "Warning: Could not load kramdown config: #{e.message}" if debug?
        {}
      end
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
      @kramdown_config = nil
    end
  end
end
