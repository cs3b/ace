# frozen_string_literal: true

require_relative 'lint/version'

# Load ace-config for configuration cascade management
require 'ace/support/config'

# Models
require_relative 'lint/models/validation_error'
require_relative 'lint/models/lint_result'

# Atoms
require_relative 'lint/atoms/type_detector'
require_relative 'lint/atoms/kramdown_parser'
require_relative 'lint/atoms/yaml_parser'
require_relative 'lint/atoms/frontmatter_extractor'
require_relative 'lint/atoms/pattern_matcher'
require_relative 'lint/atoms/validator_registry'
require_relative 'lint/atoms/config_locator'

# Molecules
require_relative 'lint/molecules/markdown_linter'
require_relative 'lint/molecules/yaml_linter'
require_relative 'lint/molecules/frontmatter_validator'
require_relative 'lint/molecules/kramdown_formatter'
require_relative 'lint/molecules/group_resolver'
require_relative 'lint/molecules/validator_chain'

# Organisms
require_relative 'lint/organisms/lint_orchestrator'
require_relative 'lint/organisms/result_reporter'
require_relative 'lint/organisms/lint_doctor'

# Commands
require_relative 'lint/cli/commands/lint'
require_relative 'lint/cli/commands/doctor'

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
    # Uses Ace::Support::Config.create() for configuration cascade resolution
    # @return [Hash] Configuration hash with defaults merged
    def self.config
      @config ||= begin
        gem_root = Gem.loaded_specs["ace-lint"]&.gem_dir ||
                   File.expand_path("../..", __dir__)

        resolver = Ace::Support::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve config for lint namespace
        config = resolver.resolve_namespace("lint")
        config.data
      rescue StandardError => e
        warn "Warning: Could not load ace-lint config: #{e.message}" if debug?
        # Fall back to gem defaults instead of empty hash to prevent silent config erasure
        load_gem_defaults_fallback("lint", "config.yml")
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

        resolver = Ace::Support::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve kramdown-specific config
        config = resolver.resolve_namespace("lint", filename: "kramdown")
        config.data
      rescue StandardError => e
        warn "Warning: Could not load kramdown config: #{e.message}" if debug?
        # Fall back to gem defaults instead of empty hash to prevent silent config erasure
        load_gem_defaults_fallback("lint", "kramdown.yml")
      end
    end

    # Load Ruby-specific configuration using ace-config cascade
    # Follows ADR-022: Configuration Default and Override Pattern
    # Config location: .ace/lint/ruby.yml
    # @return [Hash] Ruby configuration hash with defaults merged
    def self.ruby_config
      @ruby_config ||= begin
        gem_root = Gem.loaded_specs["ace-lint"]&.gem_dir ||
                   File.expand_path("../..", __dir__)

        resolver = Ace::Support::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve ruby-specific config
        config = resolver.resolve_namespace("lint", filename: "ruby")
        config.data
      rescue StandardError => e
        warn "Warning: Could not load ruby config: #{e.message}" if debug?
        # Fall back to gem defaults instead of empty hash to prevent silent config erasure
        load_gem_defaults_fallback("lint", "ruby.yml")
      end
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
      @kramdown_config = nil
      @ruby_config = nil
    end

    # Load gem defaults directly as fallback when cascade resolution fails
    # This ensures configuration is never silently erased due to YAML errors
    # or user config issues
    # @param namespace [String] Config namespace (e.g., "lint")
    # @param filename [String] Config filename (e.g., "config.yml", "kramdown.yml")
    # @return [Hash] Defaults hash or empty hash if defaults also fail
    def self.load_gem_defaults_fallback(namespace, filename)
      gem_root = Gem.loaded_specs["ace-lint"]&.gem_dir ||
                 File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", namespace, filename)

      return {} unless File.exist?(defaults_path)

      YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
    rescue StandardError
      {} # Only return empty hash if even defaults fail to load
    end
    private_class_method :load_gem_defaults_fallback
  end
end
