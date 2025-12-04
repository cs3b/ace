# frozen_string_literal: true

module Ace
  module LLM
    module ModelsDev
      module Molecules
        # Validates model names against cached data
        class ModelValidator
          MAX_SUGGESTIONS = 5

          # Initialize validator
          # @param cache_manager [CacheManager, nil] Cache manager instance
          def initialize(cache_manager: nil)
            @cache_manager = cache_manager || CacheManager.new
          end

          # Validate a model exists
          # @param model_id [String] Model ID (provider:model or just model)
          # @return [Models::ModelInfo] Model info if valid
          # @raise [ProviderNotFoundError] if provider doesn't exist
          # @raise [ModelNotFoundError] if model doesn't exist
          def validate(model_id)
            data = load_data
            provider_id, model_name = parse_model_id(model_id)

            # Check provider exists
            provider_data = data[provider_id]
            raise ProviderNotFoundError, provider_id unless provider_data

            # Check model exists
            model_data = provider_data.dig("models", model_name)
            unless model_data
              suggestions = find_suggestions(provider_data["models"]&.keys || [], model_name)
              raise ModelNotFoundError.new("#{provider_id}:#{model_name}", suggestions: suggestions)
            end

            Models::ModelInfo.from_hash(model_data, provider_id: provider_id)
          end

          # Check if model is valid (no exception)
          # @param model_id [String] Model ID
          # @return [Boolean]
          def valid?(model_id)
            validate(model_id)
            true
          rescue ModelNotFoundError, ProviderNotFoundError
            false
          end

          # Get model info (returns nil instead of raising)
          # @param model_id [String] Model ID
          # @return [Models::ModelInfo, nil]
          def get(model_id)
            validate(model_id)
          rescue ModelNotFoundError, ProviderNotFoundError
            nil
          end

          # List all providers
          # @return [Array<String>] Provider IDs
          def providers
            load_data.keys.sort
          end

          # List models for a provider
          # @param provider_id [String] Provider ID
          # @return [Array<String>] Model IDs
          def models_for(provider_id)
            data = load_data
            provider_data = data[provider_id]
            return [] unless provider_data

            (provider_data["models"]&.keys || []).sort
          end

          private

          def load_data
            data = @cache_manager.read
            raise CacheError, "No cache data. Run 'ace-llm-models sync' first." unless data

            data
          end

          def parse_model_id(model_id)
            if model_id.include?(":")
              parts = model_id.split(":", 2)
              [parts[0], parts[1]]
            else
              # Try to find provider by model name
              data = load_data
              data.each do |provider_id, provider_data|
                if provider_data.dig("models", model_id)
                  return [provider_id, model_id]
                end
              end
              # Default to treating as unknown provider
              raise ValidationError, "Model ID must be in format 'provider:model' (e.g., 'openai:gpt-4o')"
            end
          end

          def find_suggestions(model_names, target)
            return [] if model_names.empty?

            # Simple prefix/substring matching for suggestions
            suggestions = model_names.select do |name|
              name.include?(target) || target.include?(name) ||
                levenshtein_distance(name, target) <= 3
            end

            suggestions.first(MAX_SUGGESTIONS)
          end

          # Simple Levenshtein distance for fuzzy matching
          def levenshtein_distance(s1, s2)
            m = s1.length
            n = s2.length
            return n if m.zero?
            return m if n.zero?

            d = Array.new(m + 1) { Array.new(n + 1) }

            (0..m).each { |i| d[i][0] = i }
            (0..n).each { |j| d[0][j] = j }

            (1..m).each do |i|
              (1..n).each do |j|
                cost = s1[i - 1] == s2[j - 1] ? 0 : 1
                d[i][j] = [
                  d[i - 1][j] + 1,
                  d[i][j - 1] + 1,
                  d[i - 1][j - 1] + cost
                ].min
              end
            end

            d[m][n]
          end
        end
      end
    end
  end
end
