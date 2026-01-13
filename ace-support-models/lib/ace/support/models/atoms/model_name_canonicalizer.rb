# frozen_string_literal: true

module Ace
  module Support
    module Models
      module Atoms
        # Canonicalizes model names by stripping provider-specific suffixes
        #
        # OpenRouter uses dynamic and static suffixes that modify routing behavior
        # but don't represent different models in the canonical model registry.
        #
        # @see https://openrouter.ai/docs/faq for suffix documentation
        class ModelNameCanonicalizer
          # OpenRouter dynamic suffixes (work across all models, modify routing)
          OPENROUTER_DYNAMIC_SUFFIXES = %w[
            nitro
            floor
            online
          ].freeze

          # OpenRouter static suffixes (apply to specific models only)
          OPENROUTER_STATIC_SUFFIXES = %w[
            free
            extended
            exacto
            thinking
          ].freeze

          # Combined list of all known OpenRouter suffixes
          OPENROUTER_SUFFIXES = (OPENROUTER_DYNAMIC_SUFFIXES + OPENROUTER_STATIC_SUFFIXES).freeze

          # Provider-specific suffix configurations
          # Maps provider ID to array of suffixes to strip
          PROVIDER_SUFFIXES = {
            "openrouter" => OPENROUTER_SUFFIXES
          }.freeze

          class << self
            # Extract the canonical model name by stripping provider-specific suffixes
            #
            # @param model_id [String] The model ID (e.g., "openai/gpt-4:nitro")
            # @param provider [String, nil] The provider ID to determine which suffixes to strip
            # @return [String] The canonical model name (e.g., "openai/gpt-4")
            #
            # @example Strip OpenRouter :nitro suffix
            #   canonicalize("openai/gpt-4:nitro", provider: "openrouter")
            #   # => "openai/gpt-4"
            #
            # @example Preserve model with no suffix
            #   canonicalize("openai/gpt-4", provider: "openrouter")
            #   # => "openai/gpt-4"
            #
            # @example Non-OpenRouter provider keeps suffix
            #   canonicalize("model:variant", provider: "other")
            #   # => "model:variant"
            def canonicalize(model_id, provider: nil)
              return model_id if model_id.nil? || model_id.empty?

              suffixes = PROVIDER_SUFFIXES[provider]
              return model_id unless suffixes

              strip_suffixes(model_id, suffixes)
            end

            # Check if a model ID has a known suffix for the given provider
            #
            # @param model_id [String] The model ID to check
            # @param provider [String, nil] The provider ID
            # @return [Boolean] true if the model has a strippable suffix
            def has_suffix?(model_id, provider: nil)
              return false if model_id.nil? || model_id.empty?

              suffixes = PROVIDER_SUFFIXES[provider]
              return false unless suffixes

              suffix = extract_suffix(model_id)
              suffix && suffixes.include?(suffix)
            end

            # Extract the suffix from a model ID if present
            #
            # @param model_id [String] The model ID
            # @return [String, nil] The suffix without the colon, or nil if no suffix
            def extract_suffix(model_id)
              return nil if model_id.nil? || model_id.empty?

              # Match the last :suffix pattern (handles model IDs like "org/model:suffix")
              match = model_id.match(/:([^:\/]+)$/)
              match&.captures&.first
            end

            # Get all known suffixes for a provider
            #
            # @param provider [String] The provider ID
            # @return [Array<String>] Array of suffix strings (without colons)
            def suffixes_for(provider)
              PROVIDER_SUFFIXES[provider] || []
            end

            private

            # Strip known suffixes from a model ID
            #
            # @param model_id [String] The model ID
            # @param suffixes [Array<String>] Suffixes to strip
            # @return [String] Model ID with suffix stripped
            def strip_suffixes(model_id, suffixes)
              suffix = extract_suffix(model_id)
              return model_id unless suffix && suffixes.include?(suffix)

              # Remove the :suffix from the end
              model_id.sub(/:#{Regexp.escape(suffix)}$/, "")
            end
          end
        end
      end
    end
  end
end
