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
    # Follows ace-* pattern: ./.ace/prompt/config.yml → ~/.ace/prompt/config.yml
    # @return [Hash] Configuration hash with defaults merged
    def self.config
      @config ||= begin
        base_config = Ace::Core.config
        user_config = base_config.get("ace", "prompt") || {}
        merge_config(default_config, user_config)
      rescue StandardError => e
        warn "Warning: Could not load ace-prompt config: #{e.message}"
        default_config
      end
    end

    # Default configuration when no config file exists
    # @return [Hash] Default configuration
    def self.default_config
      {
        "context" => {
          "enabled" => false
        },
        "enhance" => {
          "enabled" => false,
          "model" => DEFAULT_MODEL,
          "temperature" => 0.3,
          "system_prompt" => "prompt://prompt-enhance-instructions.system"
        },
        "security" => {
          "max_file_size_mb" => 10
        },
        "debug" => {
          "enabled" => false,
          "context_loading" => false
        }
      }
    end

    # Deep merge user config with defaults
    # @param defaults [Hash] Default configuration
    # @param user_config [Hash] User configuration
    # @return [Hash] Merged configuration
    def self.merge_config(defaults, user_config)
      defaults.each_with_object({}) do |(key, default_value), result|
        user_value = user_config[key]
        result[key] = if default_value.is_a?(Hash) && user_value.is_a?(Hash)
                        merge_config(default_value, user_value)
                      elsif user_value.nil?
                        default_value
                      else
                        user_value
                      end
      end
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
    end

    private_class_method :merge_config
  end
end
