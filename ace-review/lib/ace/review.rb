# frozen_string_literal: true

# Load ace-config for configuration cascade management
require "ace/config"

# Try to load ace-context if available (required for full functionality)
begin
  require "ace/context"
rescue LoadError
  # ace-context is required for context processing
  # Will raise MissingDependencyError when needed
end

# Load ace-git (required dependency for git operations)
require "ace/git"

require_relative "review/version"
require_relative "review/errors"

# Require atoms
require_relative "review/atoms/context_normalizer"
require_relative "review/atoms/preset_validator"
require_relative "review/atoms/slug_generator"
require_relative "review/atoms/pr_comment_formatter"

# Require all necessary components explicitly
require_relative "review/molecules/context_composer"
require_relative "review/molecules/context_extractor"
require_relative "review/molecules/llm_executor"
require_relative "review/molecules/preset_manager"
require_relative "review/molecules/prompt_composer"
require_relative "review/molecules/nav_prompt_resolver"
require_relative "review/molecules/prompt_resolver"  # Keep for backwards compatibility
require_relative "review/molecules/subject_extractor"
require_relative "review/molecules/gh_cli_executor"
require_relative "review/molecules/gh_pr_fetcher"
require_relative "review/molecules/gh_pr_comment_fetcher"
require_relative "review/molecules/gh_comment_poster"
require_relative "review/molecules/gh_comment_resolver"
require_relative "review/molecules/multi_model_executor"
require_relative "review/molecules/report_synthesizer"

require_relative "review/organisms/review_manager"

require_relative "review/models/review_options"

require_relative "review/cli"

module Ace
  module Review
    # Define module namespaces
    module Atoms; end
    module Molecules; end
    module Organisms; end
    module Models; end

    class << self
      # Configuration accessor
      # Follows ADR-022: Configuration Default and Override Pattern
      # Uses Ace::Config.create() for configuration cascade resolution
      def config
        @config ||= begin
          gem_root = Gem.loaded_specs["ace-review"]&.gem_dir ||
                     File.expand_path("../..", __dir__)

          resolver = Ace::Config.create(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: gem_root
          )

          # Resolve config for review namespace
          config = resolver.resolve_namespace("review")
          config.data
        rescue StandardError => e
          warn "Warning: Could not load ace-review config: #{e.message}" if debug?
          {}
        end
      end

      # Get configuration value with dot notation
      def get(*keys)
        keys.reduce(config) do |hash, key|
          hash.is_a?(Hash) ? hash[key.to_s] : nil
        end
      end

      # Reset cached configuration (useful for testing)
      def reset_config!
        @config = nil
      end

      # Check if running in debug mode
      def debug?
        ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
      end
    end
  end
end
