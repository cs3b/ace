# frozen_string_literal: true

require_relative "docs/version"
require "ace/config" # For config cascade

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
    # Uses Ace::Config.create() for configuration cascade resolution
    # @return [Hash] Configuration hash with defaults merged
    def self.config
      @config ||= begin
        gem_root = Gem.loaded_specs["ace-docs"]&.gem_dir ||
                   File.expand_path("../..", __dir__)

        resolver = Ace::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve config for docs namespace
        config = resolver.resolve_namespace("docs")
        config.data
      rescue StandardError => e
        warn "Warning: Could not load ace-docs config: #{e.message}" if debug?
        {}
      end
    end

    # Reset configuration (primarily for testing)
    def self.reset_config!
      @config = nil
    end

    # Check if debug mode is enabled
    # @return [Boolean] True if debug mode is enabled
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end
  end
end
