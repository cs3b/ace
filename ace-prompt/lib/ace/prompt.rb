# frozen_string_literal: true

require_relative "prompt/version"

# Load ace-config for configuration cascade management
require "ace/config"

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

    # Load ace-prompt configuration using ace-config cascade
    # Follows ADR-022: Configuration Default and Override Pattern
    # Uses Ace::Config.create() for configuration cascade resolution
    # @return [Hash] Configuration hash with defaults merged
    def self.config
      @config ||= begin
        gem_root = Gem.loaded_specs["ace-prompt"]&.gem_dir ||
                   File.expand_path("../..", __dir__)

        resolver = Ace::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve config for prompt namespace
        config = resolver.resolve_for(["prompt/config.yml", "prompt/config.yaml"])
        config.data
      rescue StandardError => e
        warn "Warning: Could not load ace-prompt config: #{e.message}"
        {}
      end
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
    end
  end
end
