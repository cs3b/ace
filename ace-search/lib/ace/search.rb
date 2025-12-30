# frozen_string_literal: true

require_relative "search/version"
require "ace/config"

module Ace
  module Search
    class Error < StandardError; end

    # Check if debug mode is enabled
    # @return [Boolean] True if debug mode is enabled
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end

    # Configuration
    # Follows ADR-022: Configuration Default and Override Pattern
    # Uses Ace::Config.create() for configuration cascade resolution
    def self.config
      @config ||= begin
        gem_root = Gem.loaded_specs["ace-search"]&.gem_dir ||
                   File.expand_path("../..", __dir__)

        resolver = Ace::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve config for search namespace
        config = resolver.resolve_for(["search/config.yml", "search/config.yaml"])
        # Extract the ace.search section from defaults (for backward compatibility)
        raw_data = config.data
        raw_data.dig("ace", "search") || raw_data
      rescue StandardError => e
        warn "Warning: Could not load ace-search config: #{e.message}" if debug?
        {}
      end
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
    end
  end
end
