# frozen_string_literal: true

module Ace
  module LLM
    module ModelsDev
      module Molecules
        # Searches for models with fuzzy matching
        class ModelSearcher
          # Initialize searcher
          # @param cache_manager [CacheManager, nil] Cache manager instance
          def initialize(cache_manager: nil)
            @cache_manager = cache_manager || CacheManager.new
          end

          # Search for models matching query
          # @param query [String] Search query
          # @param provider [String, nil] Limit to specific provider
          # @param limit [Integer] Max results
          # @return [Array<Models::ModelInfo>] Matching models
          def search(query, provider: nil, limit: 20)
            data = load_data
            results = []

            providers_to_search = provider ? [provider] : data.keys

            providers_to_search.each do |provider_id|
              provider_data = data[provider_id]
              next unless provider_data

              (provider_data["models"] || {}).each do |model_id, model_data|
                score = match_score(query, model_id, model_data["name"])
                if score > 0
                  results << {
                    model: Models::ModelInfo.from_hash(model_data, provider_id: provider_id),
                    score: score
                  }
                end
              end
            end

            # Sort by score and return models
            results.sort_by { |r| -r[:score] }
                   .first(limit)
                   .map { |r| r[:model] }
          end

          # List all models
          # @param provider [String, nil] Limit to specific provider
          # @return [Array<Models::ModelInfo>] All models
          def all(provider: nil)
            data = load_data
            models = []

            providers_to_search = provider ? [provider] : data.keys

            providers_to_search.each do |provider_id|
              provider_data = data[provider_id]
              next unless provider_data

              (provider_data["models"] || {}).each do |_model_id, model_data|
                models << Models::ModelInfo.from_hash(model_data, provider_id: provider_id)
              end
            end

            models.sort_by(&:full_id)
          end

          # Count models
          # @param provider [String, nil] Limit to specific provider
          # @return [Integer] Model count
          def count(provider: nil)
            data = load_data
            total = 0

            providers_to_search = provider ? [provider] : data.keys

            providers_to_search.each do |provider_id|
              provider_data = data[provider_id]
              next unless provider_data

              total += (provider_data["models"] || {}).size
            end

            total
          end

          # Get stats about the data
          # @return [Hash] Stats
          def stats
            data = load_data
            provider_count = data.size
            model_count = 0
            models_by_provider = {}

            data.each do |provider_id, provider_data|
              count = (provider_data["models"] || {}).size
              models_by_provider[provider_id] = count
              model_count += count
            end

            {
              providers: provider_count,
              models: model_count,
              models_by_provider: models_by_provider.sort_by { |_, v| -v }.to_h
            }
          end

          private

          def load_data
            data = @cache_manager.read
            raise CacheError, "No cache data. Run 'ace-llm-models sync' first." unless data

            data
          end

          def match_score(query, model_id, model_name)
            query_down = query.downcase
            id_down = model_id.downcase
            name_down = (model_name || "").downcase

            score = 0

            # Exact match
            return 100 if id_down == query_down || name_down == query_down

            # Starts with
            score += 50 if id_down.start_with?(query_down) || name_down.start_with?(query_down)

            # Contains
            score += 25 if id_down.include?(query_down) || name_down.include?(query_down)

            # Word match
            query_words = query_down.split(/[-_\s]/)
            id_words = id_down.split(/[-_\s]/)
            name_words = name_down.split(/[-_\s]/)

            query_words.each do |qw|
              score += 10 if id_words.any? { |w| w.start_with?(qw) }
              score += 10 if name_words.any? { |w| w.start_with?(qw) }
            end

            score
          end
        end
      end
    end
  end
end
