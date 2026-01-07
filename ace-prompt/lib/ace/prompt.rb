# frozen_string_literal: true

require "yaml"
require_relative "prompt/version"

# Load ace-config for configuration cascade management
require "ace/config"

module Ace
  module Prompt
    class Error < StandardError; end

    # Mutex for thread-safe config initialization
    @config_mutex = Mutex.new

    # Default LLM model for enhancement (fallback if config unavailable)
    DEFAULT_MODEL = "glite"

    # Valid temperature range for LLM generation (fallback if config unavailable)
    TEMPERATURE_MIN = 0.0
    TEMPERATURE_MAX = 2.0

    # Get default model from config or use fallback
    # @return [String] Default model
    def self.default_model
      config.dig("defaults", "model") || DEFAULT_MODEL
    end

    # Get temperature min from config or use fallback
    # @return [Float] Temperature min
    def self.temperature_min
      config.dig("defaults", "temperature", "min") || TEMPERATURE_MIN
    end

    # Get temperature max from config or use fallback
    # @return [Float] Temperature max
    def self.temperature_max
      config.dig("defaults", "temperature", "max") || TEMPERATURE_MAX
    end
  end
end

# Atoms
require_relative "prompt/atoms/session_id_generator"
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
    # Check if debug mode is enabled
    # @return [Boolean] True if debug mode is enabled
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end

    # Load ace-prompt configuration using ace-config cascade
    # Follows ADR-022: Configuration Default and Override Pattern
    # Uses Ace::Config.create() for configuration cascade resolution
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

    # Load configuration using Ace::Config cascade
    # @return [Hash] Merged configuration
    def self.load_config
      gem_root = Gem.loaded_specs["ace-prompt"]&.gem_dir ||
                 File.expand_path("../..", __dir__)

      resolver = Ace::Config.create(
        config_dir: ".ace",
        defaults_dir: ".ace-defaults",
        gem_path: gem_root
      )

      # Resolve config for prompt namespace
      config = resolver.resolve_namespace("prompt")
      config.data
    rescue StandardError => e
      warn "ace-prompt: Could not load config: #{e.class} - #{e.message}" if debug?
      # Fall back to gem defaults instead of empty hash to prevent silent config erasure
      load_gem_defaults_fallback
    end
    private_class_method :load_config

    # Load gem defaults directly as fallback when cascade resolution fails
    # This ensures configuration is never silently erased due to YAML errors
    # or user config issues
    # @return [Hash] Defaults hash or empty hash if defaults also fail
    def self.load_gem_defaults_fallback
      gem_root = Gem.loaded_specs["ace-prompt"]&.gem_dir ||
                 File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", "prompt", "config.yml")

      return {} unless File.exist?(defaults_path)

      YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
    rescue StandardError
      {} # Only return empty hash if even defaults fail to load
    end
    private_class_method :load_gem_defaults_fallback
  end
end
