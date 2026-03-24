# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Pure function for resolving model context limits
      #
      # Maps model names to their context window sizes. Handles provider prefixes
      # (google:, anthropic:, openai:) and uses pattern matching for model families.
      #
      # Resolution order:
      # 1. ace-llm provider config (context_limit in providers/*.yml)
      # 2. Hardcoded pattern matching (MODEL_LIMITS)
      # 3. Conservative default for unknown models
      #
      # @example Basic usage
      #   ContextLimitResolver.resolve("google:gemini-2.5-pro")
      #   #=> 1_000_000
      #
      # @example Without provider prefix
      #   ContextLimitResolver.resolve("claude-3-sonnet")
      #   #=> 200_000
      module ContextLimitResolver
        # Conservative default for unknown models
        DEFAULT_LIMIT = 200_000

        # Model patterns and their context limits (fallback when ace-llm config unavailable)
        # Order matters - first match wins
        # Patterns use regex for flexible matching
        MODEL_LIMITS = [
          # Gemini models
          {pattern: /gemini-1\.5-pro/i, limit: 2_000_000},
          {pattern: /gemini-1\.5-flash/i, limit: 1_000_000},
          {pattern: /gemini-2\.5-pro/i, limit: 1_000_000},
          {pattern: /gemini-2\.5-flash/i, limit: 1_000_000},
          {pattern: /gemini-2\.0/i, limit: 1_000_000},
          # Fallback for any other gemini model
          {pattern: /gemini/i, limit: 1_000_000},

          # Claude models (all variants: opus, sonnet, haiku)
          {pattern: /claude.*opus/i, limit: 1_000_000},
          {pattern: /claude.*sonnet/i, limit: 1_000_000},
          {pattern: /claude.*haiku/i, limit: 1_000_000},
          # Fallback for any other claude model
          {pattern: /claude/i, limit: 1_000_000},

          # OpenAI models
          {pattern: /gpt-5\.\d/i, limit: 1_050_000},
          {pattern: /o4-/i, limit: 1_050_000},
          {pattern: /gpt-4o/i, limit: 128_000},
          {pattern: /gpt-4-turbo/i, limit: 128_000},
          {pattern: /gpt-4-32k/i, limit: 32_768},
          {pattern: /gpt-4-\d+-preview/i, limit: 128_000}, # gpt-4-1106-preview, gpt-4-0125-preview
          {pattern: /gpt-4-\d+$/i, limit: 8_192}, # legacy gpt-4-0613, etc.
          {pattern: /gpt-4$/i, limit: 8_192}, # base gpt-4 model
          {pattern: /o1-/i, limit: 200_000},
          {pattern: /o3-/i, limit: 200_000}
        ].freeze

        # Resolve context limit for a model
        #
        # Resolution order:
        # 1. ace-llm provider config (if available and provider specified)
        # 2. Hardcoded pattern matching
        # 3. Default limit
        #
        # @param model_name [String, nil] Model identifier, optionally with provider prefix
        # @return [Integer] Context limit in tokens
        #
        # @example With provider prefix
        #   ContextLimitResolver.resolve("google:gemini-2.5-pro")
        #   #=> 1_000_000
        #
        # @example Without provider prefix
        #   ContextLimitResolver.resolve("claude-3-opus")
        #   #=> 200_000
        #
        # @example Unknown model
        #   ContextLimitResolver.resolve("unknown-model")
        #   #=> 128_000
        def self.resolve(model_name)
          return DEFAULT_LIMIT if model_name.nil? || model_name.empty?

          # Try to get limit from ace-llm provider config first
          limit = load_from_ace_llm(model_name)
          return limit if limit

          # Fall back to hardcoded pattern matching
          normalized = strip_provider_prefix(model_name)
          match = MODEL_LIMITS.find { |entry| normalized.match?(entry[:pattern]) }
          match ? match[:limit] : DEFAULT_LIMIT
        end

        # Get the default limit for unknown models
        #
        # @return [Integer] Default context limit
        def self.default_limit
          DEFAULT_LIMIT
        end

        # Load context limit from ace-llm provider configuration
        #
        # @param model_name [String] Model identifier with provider prefix
        # @return [Integer, nil] Context limit from config, or nil if not found
        def self.load_from_ace_llm(model_name)
          # Extract provider prefix (e.g., "google" from "google:gemini-2.5-pro")
          return nil unless model_name.include?(":")

          provider = model_name.split(":").first
          return nil if provider.nil? || provider.empty?

          # Try to load provider config via ace-llm
          config = load_provider_config(provider)
          return nil unless config

          # Get context_limit from provider config
          limit = config["context_limit"]
          limit.is_a?(Integer) ? limit : nil
        rescue
          nil # Fall back to hardcoded on any error
        end
        private_class_method :load_from_ace_llm

        # Load provider configuration from ace-llm
        #
        # @param provider [String] Provider name (e.g., "google", "anthropic")
        # @return [Hash, nil] Provider config hash or nil
        def self.load_provider_config(provider)
          # Try to use ace-llm's config loader if available
          return nil unless defined?(Ace::LLM::Molecules::ConfigLoader)

          resolver = Ace::Support::Config.create(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: Ace::LLM::Molecules::ConfigLoader.gem_root
          )

          config = resolver.resolve_namespace("llm", filename: "providers/#{provider}")
          config.to_h
        rescue
          nil
        end
        private_class_method :load_provider_config

        # Strip provider prefix from model name
        #
        # @param model_name [String] Model identifier
        # @return [String] Model name without provider prefix
        #
        # @example
        #   strip_provider_prefix("google:gemini-2.5-pro")
        #   #=> "gemini-2.5-pro"
        def self.strip_provider_prefix(model_name)
          # Common provider prefixes
          model_name.sub(/\A(google|anthropic|openai|codex|cli):/, "")
        end

        private_class_method :strip_provider_prefix
      end
    end
  end
end
