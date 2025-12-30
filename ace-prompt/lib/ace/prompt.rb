# frozen_string_literal: true

require_relative "prompt/version"

# Load ace-core for config management
require "ace/core"

module Ace
  module Prompt
    class Error < StandardError; end

    # Default LLM model for enhancement
    DEFAULT_MODEL = "glite"

    # Valid temperature range for LLM generation
    TEMPERATURE_MIN = 0.0
    TEMPERATURE_MAX = 2.0
  end
end

# Atoms
require_relative "prompt/atoms/timestamp_generator"
require_relative "prompt/atoms/content_hasher"
require_relative "prompt/atoms/frontmatter_extractor"
require_relative "prompt/atoms/task_path_resolver"

# Molecules
require_relative "prompt/molecules/prompt_reader"
require_relative "prompt/molecules/prompt_archiver"
require_relative "prompt/molecules/template_resolver"
require_relative "prompt/molecules/template_manager"
require_relative "prompt/molecules/context_loader"
require_relative "prompt/molecules/enhancement_tracker"

# Organisms
require_relative "prompt/organisms/prompt_processor"
require_relative "prompt/organisms/prompt_initializer"
require_relative "prompt/organisms/enhancement_session_manager"
require_relative "prompt/organisms/prompt_enhancer"

# CLI (loaded after constants defined)
require_relative "prompt/cli"

# Reopen module for additional methods
module Ace
  module Prompt

    # Load ace-prompt configuration using ace-core config cascade
    # Follows ADR-022: Configuration Default and Override Pattern
    # Priority: gem defaults < user config
    # @return [Hash] Configuration hash with defaults merged
    def self.config
      @config ||= begin
        require 'yaml'
        require 'ace/core/atoms/deep_merger'

        # Load gem defaults from .ace-defaults/prompt/config.yml
        gem_defaults = load_gem_defaults

        # Load user config via ace-core cascade
        user_config = Ace::Core.get("prompt", file: "config") || {}

        # Merge gem defaults with user config
        Ace::Core::Atoms::DeepMerger.merge(gem_defaults, user_config)
      rescue StandardError => e
        warn "Warning: Could not load ace-prompt config: #{e.message}"
        load_gem_defaults || {}
      end
    end

    # Load gem defaults from .ace-defaults/prompt/config.yml
    # Per ADR-022: gem MUST include .ace-defaults/ - missing file is a packaging error
    # @return [Hash] Default configuration from gem
    # @raise [Error] If default config file is missing (gem packaging error)
    def self.load_gem_defaults
      gem_root = Gem.loaded_specs["ace-prompt"]&.gem_dir ||
                 File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", "prompt", "config.yml")

      unless File.exist?(defaults_path)
        raise Error, "Default config not found: #{defaults_path}. " \
              "This is a gem packaging error - .ace-defaults/ must be included in the gem."
      end

      YAML.safe_load_file(defaults_path, permitted_classes: [], aliases: true) || {}
    end
    private_class_method :load_gem_defaults

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
    end
  end
end
