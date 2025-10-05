# frozen_string_literal: true

require "zeitwerk"
require_relative "review/version"

module Ace
  module Review
    class Error < StandardError; end

    class << self
      # Lazy-load zeitwerk loader
      def loader
        @loader ||= begin
          loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
          loader.inflector.inflect(
            "cli" => "CLI",
            "llm" => "LLM"
          )
          loader.setup
          loader
        end
      end

      # Configuration accessor
      def config
        @config ||= begin
          require "ace/core"
          base_config = Ace::Core.config
          base_config.get("ace", "review") || default_config
        end
      rescue LoadError
        # If ace-core is not available, use defaults
        default_config
      end

      # Default configuration
      def default_config
        {
          "defaults" => {
            "model" => "google:gemini-2.5-flash",
            "output_format" => "markdown",
            "context" => "project"
          },
          "storage" => {
            "base_path" => ".ace-taskflow/%{release}/reviews",
            "auto_organize" => true
          },
          "presets" => default_presets
        }
      end

      # Default presets if no configuration file exists
      def default_presets
        {
          "pr" => {
            "description" => "Pull request review",
            "prompt_composition" => {
              "base" => "prompt://base/system",
              "format" => "prompt://format/standard",
              "guidelines" => [
                "prompt://guidelines/tone",
                "prompt://guidelines/icons"
              ]
            },
            "context" => "project",
            "subject" => {
              "commands" => [
                "git diff origin/main...HEAD",
                "git log origin/main..HEAD --oneline"
              ]
            }
          },
          "security" => {
            "description" => "Security-focused review",
            "prompt_composition" => {
              "base" => "prompt://base/system",
              "format" => "prompt://format/detailed",
              "focus" => ["prompt://focus/quality/security"],
              "guidelines" => [
                "prompt://guidelines/tone",
                "prompt://guidelines/icons"
              ]
            },
            "context" => "project",
            "subject" => {
              "commands" => ["git diff HEAD~5..HEAD"]
            }
          }
        }
      end

      # Get configuration value with dot notation
      def get(*keys)
        keys.reduce(config) do |hash, key|
          hash.is_a?(Hash) ? hash[key.to_s] : nil
        end
      end

      # Check if running in debug mode
      def debug?
        ENV["ACE_DEBUG"] == "true" || ENV["DEBUG"] == "true"
      end
    end
  end
end

# Eager load the loader
Ace::Review.loader