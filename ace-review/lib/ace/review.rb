# frozen_string_literal: true

# Try to load ace-core if available
begin
  require "ace/core"
rescue LoadError
  # ace-core is optional for basic functionality
end

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
      # Priority: gem defaults < user config
      def config
        @config ||= begin
          require 'yaml'
          require 'ace/core/atoms/deep_merger'

          # Load gem defaults from .ace.example/review/config.yml
          gem_defaults = load_gem_defaults

          # Load user config via ace-core cascade
          user_config = Ace::Core.get("review", file: "config") || {}

          # Merge gem defaults with user config
          Ace::Core::Atoms::DeepMerger.merge(gem_defaults, user_config)
        rescue StandardError => e
          warn "Warning: Could not load ace-review config: #{e.message}" if debug?
          load_gem_defaults || {}
        end
      end

      private

      # Load gem defaults from .ace.example/review/config.yml
      # ADR-022: .ace.example/ is the single source of truth for defaults
      # @return [Hash] Default configuration from gem
      # @raise [RuntimeError] If default config file is missing (gem packaging error)
      def load_gem_defaults
        gem_root = Gem.loaded_specs["ace-review"]&.gem_dir ||
                   File.expand_path("../..", __dir__)
        defaults_path = File.join(gem_root, ".ace.example", "review", "config.yml")

        # ADR-022: Missing .ace.example/ file is a packaging error, not a fallback case
        unless File.exist?(defaults_path)
          raise "Default config not found: #{defaults_path}. " \
                "This is a gem packaging error - .ace.example/ must be included in the gem."
        end

        YAML.safe_load_file(defaults_path, permitted_classes: [], aliases: true) || {}
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
