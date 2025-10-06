# frozen_string_literal: true

# Try to load ace-core if available
begin
  require "ace/core"
rescue LoadError
  # ace-core is optional for basic functionality
end

require "ace/context"

require_relative "review/version"

# Require all necessary components explicitly
require_relative "review/atoms/file_reader"
require_relative "review/atoms/git_extractor"

require_relative "review/molecules/context_extractor"
require_relative "review/molecules/llm_executor"
require_relative "review/molecules/preset_manager"
require_relative "review/molecules/prompt_composer"
require_relative "review/molecules/nav_prompt_resolver"
require_relative "review/molecules/prompt_resolver"  # Keep for backwards compatibility
require_relative "review/molecules/subject_extractor"

require_relative "review/organisms/review_manager"

require_relative "review/models/review_options"

require_relative "review/cli"

module Ace
  module Review
    class Error < StandardError; end

    # Define module namespaces
    module Atoms; end
    module Molecules; end
    module Organisms; end
    module Models; end

    class << self
      # Configuration accessor
      def config
        @config ||= begin
          base_config = Ace::Core.config
          base_config.get("ace", "review") || default_config
        rescue StandardError
          default_config
        end
      end

      # Default configuration
      def default_config
        {
          "defaults" => {
            "model" => "google:gemini-2.5-flash",
            "output_format" => "markdown",
            "context" => "project"
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