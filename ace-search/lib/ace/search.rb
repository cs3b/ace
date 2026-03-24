# frozen_string_literal: true

require_relative "search/version"
require "ace/support/config"

# CLI and commands
require_relative "search/cli"

module Ace
  module Search
    class Error < StandardError; end

    # Define module namespaces
    module Commands; end

    # Check if debug mode is enabled
    # @return [Boolean] True if debug mode is enabled
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end

    # Configuration
    # Follows ADR-022: Configuration Default and Override Pattern
    # Uses Ace::Support::Config.create() for configuration cascade resolution
    def self.config
      @config ||= begin
        gem_root = Gem.loaded_specs["ace-search"]&.gem_dir ||
          File.expand_path("../..", __dir__)

        resolver = Ace::Support::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve config for search namespace
        config = resolver.resolve_namespace("search")
        # Extract the ace.search section from defaults (for backward compatibility)
        raw_data = config.data
        raw_data.dig("ace", "search") || raw_data
      rescue => e
        warn "ace-search: Could not load config: #{e.class} - #{e.message}" if debug?
        # Fall back to gem defaults instead of empty hash to prevent silent config erasure
        load_gem_defaults_fallback
      end
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
    end

    # Load gem defaults from .ace-defaults/search/config.yml
    # Used by ConfigSummary to display effective configuration diffs
    # @return [Hash] Gem defaults hash
    def self.load_gem_defaults
      gem_root = Gem.loaded_specs["ace-search"]&.gem_dir ||
        File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", "search", "config.yml")

      return {} unless File.exist?(defaults_path)

      data = YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
      # Extract the ace.search section for backward compatibility
      data.dig("ace", "search") || data
    end

    # Load gem defaults directly as fallback when cascade resolution fails
    # This ensures configuration is never silently erased due to YAML errors
    # or user config issues
    # @return [Hash] Defaults hash or empty hash if defaults also fail
    def self.load_gem_defaults_fallback
      gem_root = Gem.loaded_specs["ace-search"]&.gem_dir ||
        File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", "search", "config.yml")

      return {} unless File.exist?(defaults_path)

      data = YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
      # Extract the ace.search section for backward compatibility
      data.dig("ace", "search") || data
    rescue
      {} # Only return empty hash if even defaults fail to load
    end
    private_class_method :load_gem_defaults_fallback
  end
end
