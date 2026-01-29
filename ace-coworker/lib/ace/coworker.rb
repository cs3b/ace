# frozen_string_literal: true

require_relative "coworker/version"
require "ace/support/config"

# CLI and commands
require_relative "coworker/cli"

module Ace
  module Coworker
    # Base error class for all ace-coworker exceptions
    # Provides common rescue scope for consumers of the gem
    class Error < StandardError; end

    # Session-related errors
    module SessionErrors
      class NotFound < Error; end
      class NoActive < Error; end
    end

    # Config-related errors
    module ConfigErrors
      class NotFound < Error; end
    end

    # Step-related errors
    module StepErrors
      class NotFound < Error; end
      class InvalidState < Error; end
    end

    # Aliases for backward compatibility
    SessionNotFoundError = SessionErrors::NotFound
    NoActiveSessionError = SessionErrors::NoActive
    ConfigNotFoundError = ConfigErrors::NotFound
    StepNotFoundError = StepErrors::NotFound
    InvalidStepStateError = StepErrors::InvalidState

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
        gem_root = Gem.loaded_specs["ace-coworker"]&.gem_dir ||
                   File.expand_path("../..", __dir__)

        resolver = Ace::Support::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve config for coworker namespace
        config = resolver.resolve_namespace("coworker")
        config.data
      rescue StandardError => e
        warn "ace-coworker: Could not load config: #{e.class} - #{e.message}" if debug?
        load_gem_defaults_fallback
      end
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
    end

    # Default cache directory for sessions
    # @return [String] Cache directory path
    def self.cache_dir
      config["cache_dir"] || ".cache/ace-coworker"
    end

    # Load gem defaults from .ace-defaults/coworker/config.yml
    # @return [Hash] Gem defaults hash
    def self.load_gem_defaults
      gem_root = Gem.loaded_specs["ace-coworker"]&.gem_dir ||
                 File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", "coworker", "config.yml")

      return {} unless File.exist?(defaults_path)

      YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
    end

    # Load gem defaults directly as fallback
    # @return [Hash] Defaults hash or empty hash if defaults also fail
    def self.load_gem_defaults_fallback
      load_gem_defaults
    rescue StandardError
      {}
    end
    private_class_method :load_gem_defaults_fallback
  end
end
