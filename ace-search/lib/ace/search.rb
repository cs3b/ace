# frozen_string_literal: true

require_relative "search/version"
require "ace/core"

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
    # Priority: gem defaults < user config
    def self.config
      @config ||= begin
        require 'yaml'
        require 'ace/core/atoms/deep_merger'

        # Load gem defaults from .ace-defaults/search/config.yml
        gem_defaults = load_gem_defaults

        # Load user config via ace-core cascade
        base_config = Ace::Core.config
        user_config = base_config.get("ace", "search") || {}

        # Merge gem defaults with user config
        Ace::Core::Atoms::DeepMerger.merge(gem_defaults, user_config)
      end
    end

    # Load gem defaults from .ace-defaults/search/config.yml
    # Per ADR-022: gem MUST include .ace-defaults/ - missing file is a packaging error
    # @return [Hash] Default configuration from gem
    # @raise [Error] If default config file is missing (gem packaging error)
    def self.load_gem_defaults
      gem_root = Gem.loaded_specs["ace-search"]&.gem_dir ||
                 File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", "search", "config.yml")

      unless File.exist?(defaults_path)
        raise Error, "Default config not found: #{defaults_path}. " \
              "This is a gem packaging error - .ace-defaults/ must be included in the gem."
      end

      content = YAML.safe_load_file(defaults_path, permitted_classes: [], aliases: true) || {}
      # Extract the ace.search section
      content.dig("ace", "search") || {}
    end
    private_class_method :load_gem_defaults
  end
end
