# frozen_string_literal: true

require_relative "lint/version"

# Load ace-config for configuration cascade management
require "ace/support/config"

# Load ace-b36ts for compact ID generation
require "ace/b36ts"

# Models
require_relative "lint/models/validation_error"
require_relative "lint/models/lint_result"

# Atoms
require_relative "lint/atoms/type_detector"
require_relative "lint/atoms/kramdown_parser"
require_relative "lint/atoms/yaml_validator"
require_relative "lint/atoms/frontmatter_extractor"
require_relative "lint/atoms/pattern_matcher"
require_relative "lint/atoms/validator_registry"
require_relative "lint/atoms/config_locator"
require_relative "lint/atoms/skill_schema_loader"
require_relative "lint/atoms/allowed_tools_validator"
require_relative "lint/atoms/comment_validator"

# Molecules
require_relative "lint/molecules/markdown_linter"
require_relative "lint/molecules/yaml_linter"
require_relative "lint/molecules/frontmatter_validator"
require_relative "lint/molecules/kramdown_formatter"
require_relative "lint/molecules/markdown_surgical_fixer"
require_relative "lint/molecules/group_resolver"
require_relative "lint/molecules/validator_chain"
require_relative "lint/molecules/skill_validator"

# Organisms
require_relative "lint/organisms/lint_orchestrator"
require_relative "lint/organisms/result_reporter"
require_relative "lint/organisms/report_generator"
require_relative "lint/organisms/lint_doctor"

# Commands
require_relative "lint/cli/commands/lint"

# CLI
require_relative "lint/cli"

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
    # @return [Hash] Configuration hash with defaults merged
    def self.config
      @config ||= resolve_lint_config(nil, "config.yml")
    end

    # Load kramdown-specific configuration using ace-config cascade
    # Config location: .ace/lint/kramdown.yml
    # @return [Hash] Kramdown configuration hash with defaults merged
    def self.kramdown_config
      @kramdown_config ||= resolve_lint_config("kramdown", "kramdown.yml")
    end

    # Load Ruby-specific configuration using ace-config cascade
    # Config location: .ace/lint/ruby.yml
    # @return [Hash] Ruby configuration hash with defaults merged
    def self.ruby_config
      @ruby_config ||= resolve_lint_config("ruby", "ruby.yml")
    end

    # Load Markdown-specific configuration using ace-config cascade
    # Config location: .ace/lint/markdown.yml
    # @return [Hash] Markdown configuration hash with defaults merged
    def self.markdown_config
      @markdown_config ||= resolve_lint_config("markdown", "markdown.yml")
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
      @kramdown_config = nil
      @ruby_config = nil
      @markdown_config = nil
      Atoms::SkillSchemaLoader.reset_cache!
    end

    # Resolve lint configuration using ace-config cascade
    # Follows ADR-022: Configuration Default and Override Pattern
    # @param filename_base [String, nil] Config filename without extension (nil for default config)
    # @param fallback_filename [String] Fallback filename for gem defaults
    # @return [Hash] Configuration hash with defaults merged
    def self.resolve_lint_config(filename_base, fallback_filename)
      gem_root = Gem.loaded_specs["ace-lint"]&.gem_dir ||
        File.expand_path("../..", __dir__)

      resolver = Ace::Support::Config.create(
        config_dir: ".ace",
        defaults_dir: ".ace-defaults",
        gem_path: gem_root
      )

      config = if filename_base
        resolver.resolve_namespace("lint", filename: filename_base)
      else
        resolver.resolve_namespace("lint")
      end
      config.data
    rescue => e
      warn "Warning: Could not load #{fallback_filename} config: #{e.message}" if debug?
      load_gem_defaults_fallback("lint", fallback_filename)
    end
    private_class_method :resolve_lint_config

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
    rescue
      {} # Only return empty hash if even defaults fail to load
    end
    private_class_method :load_gem_defaults_fallback
  end
end
