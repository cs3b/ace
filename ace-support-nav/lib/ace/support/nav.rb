# frozen_string_literal: true

require_relative "nav/version"
require "ace/support/config"

# Load all ace-support-nav components
require_relative "nav/cli"
require_relative "nav/atoms/gem_resolver"
require_relative "nav/atoms/path_normalizer"
require_relative "nav/atoms/uri_parser"
require_relative "nav/molecules/config_loader"
require_relative "nav/molecules/handbook_scanner"
require_relative "nav/molecules/protocol_scanner"
require_relative "nav/molecules/resource_resolver"
require_relative "nav/molecules/source_registry"
require_relative "nav/organisms/navigation_engine"
require_relative "nav/organisms/command_delegator"
require_relative "nav/models/handbook_source"
require_relative "nav/models/protocol_source"
require_relative "nav/models/resource"
require_relative "nav/models/resource_uri"

module Ace
  module Support
    module Nav
      class Error < StandardError; end

      # Initialize mutex for thread-safe config access
      @config_mutex = Mutex.new

      # Returns the gem root directory
      # Used by command files to locate .ace-defaults/ configuration
      # Centralizes the path calculation to avoid duplication across commands
      # @return [String] Path to the gem root directory
      def self.gem_root
        @gem_root ||= Gem.loaded_specs["ace-support-nav"]&.gem_dir ||
          File.expand_path("../../..", __dir__)
      end

      # Check if debug mode is enabled
      # @return [Boolean] True if debug mode is enabled
      def self.debug?
        ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
      end

      # Load ace-support-nav configuration using ace-config cascade
      # Follows ADR-022: Configuration Default and Override Pattern
      # Uses Ace::Support::Config.create() for configuration cascade resolution
      # Thread-safe: uses mutex for initialization
      # @return [Hash] Configuration hash with defaults merged
      def self.config
        # Fast path: return cached config if already initialized
        return @config if defined?(@config) && @config

        # Thread-safe initialization
        @config_mutex.synchronize do
          @config ||= load_config
        end
      end

      # Reset config cache (useful for testing)
      # Thread-safe: uses mutex to prevent race conditions
      def self.reset_config!
        @config_mutex.synchronize do
          @config = nil
        end
      end

      # Load configuration using Ace::Support::Config cascade
      # @return [Hash] Merged configuration
      def self.load_config
        resolver = Ace::Support::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve config for nav namespace
        config = resolver.resolve_namespace("nav")
        config.data
      rescue => e
        warn "ace-support-nav: Could not load config: #{e.class} - #{e.message}" if debug?
        # Fall back to gem defaults instead of empty hash to prevent silent config erasure
        load_gem_defaults_fallback
      end
      private_class_method :load_config

      # Load gem defaults directly as fallback when cascade resolution fails
      # This ensures configuration is never silently erased due to YAML errors
      # or user config issues
      # @return [Hash] Defaults hash or empty hash if defaults also fail
      def self.load_gem_defaults_fallback
        defaults_path = File.join(gem_root, ".ace-defaults", "nav", "config.yml")

        return {} unless File.exist?(defaults_path)

        YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
      rescue
        {} # Only return empty hash if even defaults fail to load
      end
      private_class_method :load_gem_defaults_fallback
    end
  end
end
