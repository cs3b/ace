# frozen_string_literal: true

require "yaml"
require_relative "docs/version"
require "ace/support/config" # For config cascade

# CLI Commands (Hanami pattern)
require_relative "docs/cli/commands/status"
require_relative "docs/cli/commands/discover"
require_relative "docs/cli/commands/update"
require_relative "docs/cli/commands/analyze"
require_relative "docs/cli/commands/validate"
require_relative "docs/cli/commands/analyze_consistency"

# CLI
require_relative "docs/cli"

module Ace
  module Docs
    class Error < StandardError; end

    # Main entry point for ace-docs gem
    # Provides documentation management with frontmatter,
    # change analysis, and intelligent updates
    def self.root
      File.expand_path("../..", __dir__)
    end

    # Get configuration using ace-config cascade
    # Follows ADR-022: Configuration Default and Override Pattern
    # Uses Ace::Support::Config.create() for configuration cascade resolution
    # @return [Hash] Configuration hash with defaults merged
    def self.config
      @config ||= begin
        gem_root = Gem.loaded_specs["ace-docs"]&.gem_dir ||
          File.expand_path("../..", __dir__)

        resolver = Ace::Support::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve config for docs namespace
        config = resolver.resolve_namespace("docs")
        config.data
      rescue => e
        warn "ace-docs: Could not load config: #{e.class} - #{e.message}" if debug?
        # Fall back to gem defaults instead of empty hash to prevent silent config erasure
        load_gem_defaults_fallback
      end
    end

    # Reset configuration (primarily for testing)
    def self.reset_config!
      @config = nil
    end

    # Load gem defaults directly as fallback when cascade resolution fails
    # This ensures configuration is never silently erased due to YAML errors
    # or user config issues
    # @return [Hash] Defaults hash or empty hash if defaults also fail
    def self.load_gem_defaults_fallback
      gem_root = Gem.loaded_specs["ace-docs"]&.gem_dir ||
        File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", "docs", "config.yml")

      return {} unless File.exist?(defaults_path)

      YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
    rescue
      {} # Only return empty hash if even defaults fail to load
    end
    private_class_method :load_gem_defaults_fallback

    # Check if debug mode is enabled
    # @return [Boolean] True if debug mode is enabled
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end
  end
end
