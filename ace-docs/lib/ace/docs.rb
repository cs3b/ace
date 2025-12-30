# frozen_string_literal: true

require_relative "docs/version"
require "ace/core" # For config cascade

module Ace
  module Docs
    class Error < StandardError; end

    # Main entry point for ace-docs gem
    # Provides documentation management with frontmatter,
    # change analysis, and intelligent updates
    def self.root
      File.expand_path("../..", __dir__)
    end

    # Get configuration using ace-core config cascade
    # Follows ADR-022: Configuration Default and Override Pattern
    # Priority: gem defaults < user config
    # @return [Hash] Configuration hash with defaults merged
    def self.config
      @config ||= begin
        require 'yaml'
        require 'ace/core/atoms/deep_merger'

        # Load gem defaults from .ace-defaults/docs/config.yml
        gem_defaults = load_gem_defaults

        # Load user config via ace-core cascade
        user_config = Ace::Core.config.get("ace", "docs") || {}

        # Merge gem defaults with user config
        Ace::Core::Atoms::DeepMerger.merge(gem_defaults, user_config)
      end
    end

    # Load gem defaults from .ace-defaults/docs/config.yml
    # Per ADR-022: gem MUST include .ace-defaults/ - missing file is a packaging error
    # @return [Hash] Default configuration from gem
    # @raise [Error] If default config file is missing (gem packaging error)
    def self.load_gem_defaults
      gem_root = Gem.loaded_specs["ace-docs"]&.gem_dir ||
                 File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", "docs", "config.yml")

      unless File.exist?(defaults_path)
        raise Error, "Default config not found: #{defaults_path}. " \
              "This is a gem packaging error - .ace-defaults/ must be included in the gem."
      end

      YAML.safe_load_file(defaults_path, permitted_classes: [], aliases: true) || {}
    end
    private_class_method :load_gem_defaults

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
