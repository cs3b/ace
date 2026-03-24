# frozen_string_literal: true

# Load ace-config for configuration cascade management
require "ace/support/config"

# Try to load ace-bundle if available (required for full functionality)
begin
  require "ace/bundle"
rescue LoadError
  # ace-bundle is required for context processing
  # Will raise MissingDependencyError when needed
end

# Load ace-git (required dependency for git operations)
require "ace/git"

require_relative "review/version"
require_relative "review/errors"

# Require atoms
require_relative "review/atoms/context_limit_resolver"
require_relative "review/atoms/diff_boundary_finder"
require_relative "review/atoms/feedback_id_generator"
require_relative "review/atoms/feedback_slug_generator"
require_relative "review/atoms/feedback_state_validator"
require_relative "review/atoms/pr_comment_formatter"
require_relative "review/atoms/preset_validator"
require_relative "review/atoms/priority_filter"
require_relative "review/atoms/slug_generator"
require_relative "review/atoms/token_estimator"

# Require all necessary components explicitly
require_relative "review/molecules/context_composer"
require_relative "review/molecules/context_extractor"
require_relative "review/molecules/llm_executor"
require_relative "review/molecules/preset_manager"
require_relative "review/molecules/prompt_composer"
require_relative "review/molecules/nav_prompt_resolver"
require_relative "review/molecules/subject_extractor"
require_relative "review/molecules/gh_cli_executor"
require_relative "review/molecules/gh_pr_fetcher"
require_relative "review/molecules/gh_pr_comment_fetcher"
require_relative "review/molecules/gh_comment_poster"
require_relative "review/molecules/gh_comment_resolver"
require_relative "review/molecules/multi_model_executor"
require_relative "review/molecules/feedback_file_writer"
require_relative "review/molecules/feedback_file_reader"
require_relative "review/molecules/feedback_directory_manager"
require_relative "review/molecules/feedback_synthesizer"
require_relative "review/molecules/subject_filter"
require_relative "review/molecules/subject_strategy"
require_relative "review/molecules/pr_task_spec_resolver"

require_relative "review/organisms/review_manager"
require_relative "review/organisms/feedback_manager"

require_relative "review/models/review_options"
require_relative "review/models/feedback_item"
require_relative "review/models/reviewer"

require_relative "review/cli"
require_relative "review/cli/feedback_cli"

module Ace
  module Review
    # Define module namespaces
    module Atoms; end
    module Molecules; end
    module Organisms; end
    module Models; end
    module Commands; end

    class << self
      # Configuration accessor
      # Follows ADR-022: Configuration Default and Override Pattern
      # Uses Ace::Support::Config.create() for configuration cascade resolution
      def config
        @config ||= begin
          gem_root = Gem.loaded_specs["ace-review"]&.gem_dir ||
            File.expand_path("../..", __dir__)

          resolver = Ace::Support::Config.create(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: gem_root
          )

          # Resolve config for review namespace
          config = resolver.resolve_namespace("review")
          config.data
        rescue => e
          warn "Warning: Could not load ace-review config: #{e.message}" if debug?
          # Fall back to gem defaults instead of empty hash to prevent silent config erasure
          load_gem_defaults_fallback
        end
      end

      private

      # Load gem defaults directly as fallback when cascade resolution fails
      # This ensures configuration is never silently erased due to YAML errors
      # or user config issues
      def load_gem_defaults_fallback
        gem_root = Gem.loaded_specs["ace-review"]&.gem_dir ||
          File.expand_path("../..", __dir__)
        defaults_path = File.join(gem_root, ".ace-defaults", "review", "config.yml")

        return {} unless File.exist?(defaults_path)

        YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
      rescue Psych::SyntaxError, Errno::ENOENT, Errno::EACCES
        {} # Only return empty hash if even defaults fail to load
      end

      public

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
