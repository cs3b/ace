# frozen_string_literal: true

module Ace
  module Support
    module Models
      module Molecules
        # Searches for models with fuzzy matching
        class ModelSearcher
          # Initialize searcher
          # @param cache_manager [CacheManager, nil] Cache manager instance
          def initialize(cache_manager: nil)
            @cache_manager = cache_manager || CacheManager.new
          end

          # Search for models matching query
          # @param query [String, nil] Search query (nil = match all)
          # @param provider [String, nil] Limit to specific provider
          # @param limit [Integer] Max results
          # @param filters [Hash, nil] Additional filters (key-value pairs)
          # @param with_total [Boolean] Return hash with models and total count
          # @return [Array<Models::ModelInfo>, Hash] Matching models or {models:, total:}
          #
          # Memory optimization: Defers ModelInfo instantiation until after pagination.
          # This avoids materializing thousands of objects for large caches with broad queries.
          def search(query = nil, provider: nil, limit: 20, filters: nil, with_total: false)
            data = load_data
            results = []

            providers_to_search = provider ? [provider] : data.keys

            # Phase 1: Collect lightweight hashes with scores (no ModelInfo instantiation)
            providers_to_search.each do |provider_id|
              provider_data = data[provider_id]
              next unless provider_data

              (provider_data["models"] || {}).each do |model_id, model_data|
                # If no query provided, match all (score = 1)
                score = query ? match_score(query, model_id, model_data["name"]) : 1
                if score > 0
                  results << {
                    data: model_data,
                    provider_id: provider_id,
                    score: score
                  }
                end
              end
            end

            # Phase 2: Sort by score (still lightweight hashes)
            sorted = results.sort_by { |r| -r[:score] }

            # Phase 3: Apply filters if provided (requires ModelInfo for capability checks)
            if filters
              # Must instantiate to filter, but filter early before limit
              models = sorted.map { |r| Models::ModelInfo.from_hash(r[:data], provider_id: r[:provider_id]) }
              models = Atoms::ModelFilter.apply(models, filters)
              total = models.size
              limited = models.first(limit)
            else
              # No filters: instantiate only the limited set
              total = sorted.size
              limited = sorted.first(limit).map do |r|
                Models::ModelInfo.from_hash(r[:data], provider_id: r[:provider_id])
              end
            end

            if with_total
              {models: limited, total: total}
            else
              limited
            end
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
            raise CacheError, "No cache data. Run 'ace-models sync' first." unless data

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
