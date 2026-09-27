# frozen_string_literal: true

require_relative "herdr/version"
require "ace/support/config"

module Ace
  module Herdr
    class Error < StandardError; end

    # Raised when the caller's herdr workspace/session/pane cannot be resolved
    class TargetResolutionError < Error; end

    # Raised when arguments or refs fail validation
    class ValidationError < Error; end

    # Raised when a bounded wait exceeds its timeout
    class WaitTimeoutError < Error; end
  end
end

# Executor error hierarchy (subclasses Ace::Herdr::Error)
require_relative "herdr/errors"

# Load all ace-herdr components
require_relative "herdr/atoms/answer_digest"
require_relative "herdr/models/delivery_record"
require_relative "herdr/models/dispatch_outcome"
require_relative "herdr/molecules/herdr_executor"
require_relative "herdr/molecules/delivery_record_store"
require_relative "herdr/molecules/preset_loader"
require_relative "herdr/molecules/preset_resolver"
require_relative "herdr/organisms/deliverer"
require_relative "herdr/organisms/dispatcher"
require_relative "herdr/organisms/control_surface"
require_relative "herdr/cli"

module Ace
  module Herdr
    # Returns the gem root directory
    # @return [String] Path to the gem root directory
    def self.gem_root
      @gem_root ||= Gem.loaded_specs["ace-herdr"]&.gem_dir ||
        File.expand_path("../..", __dir__)
    end

    # Check if debug mode is enabled
    # @return [Boolean]
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end

    # Load ace-herdr configuration using ace-config cascade
    # Thread-safe: uses mutex for initialization
    # @return [Hash] Merged configuration hash with defaults
    def self.config
      return @config if defined?(@config) && @config

      @config_mutex.synchronize do
        @config ||= load_config
      end
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config_mutex.synchronize do
        @config = nil
      end
    end

    @config_mutex = Mutex.new

    # Load configuration using Ace::Support::Config cascade
    # @return [Hash] Merged configuration
    def self.load_config
      resolver = Ace::Support::Config.create(
        config_dir: ".ace",
        defaults_dir: ".ace-defaults",
        gem_path: gem_root
      )

      resolver.resolve_namespace("herdr").data
    rescue => e
      warn "ace-herdr: Could not load config: #{e.class} - #{e.message}" if debug?
      load_gem_defaults_fallback
    end
    private_class_method :load_config

    # Load gem defaults directly as fallback
    # @return [Hash] Defaults hash or empty hash
    def self.load_gem_defaults_fallback
      defaults_path = File.join(gem_root, ".ace-defaults", "herdr", "config.yml")
      return {} unless File.exist?(defaults_path)

      require "yaml"
      YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
    rescue
      {}
    end
    private_class_method :load_gem_defaults_fallback
  end
end
