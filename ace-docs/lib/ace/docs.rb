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
    # @return [Hash] Configuration hash with defaults merged
    def self.config
      @config ||= begin
        loaded_config = Ace::Core.config.get("ace", "docs") || {}
        default_config.merge(loaded_config)
      end
    end

    # Default configuration values
    # @return [Hash] Default configuration
    def self.default_config
      {
        # Cache settings
        "cache_dir" => ".cache/ace-docs",

        # Analysis settings
        "llm_temperature" => 0.3,
        "llm_timeout" => 600, # Timeout in seconds (10 minutes minimum)
        "llm_model" => "glite", # Default to glite (fast model)
        "max_diff_lines_warning" => 100_000,

        # Validation settings
        "validation_enabled" => true,
        "ace_lint_path" => "ace-lint",

        # Document settings
        "default_freshness_days" => {
          "current" => 14,
          "stale" => 30,
          "outdated" => 60
        }
      }
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
