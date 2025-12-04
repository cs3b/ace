# frozen_string_literal: true

module Ace
  module LLM
    module ModelsDev
      module Organisms
        # Orchestrates the sync workflow
        class SyncOrchestrator
          DEFAULT_CACHE_MAX_AGE = 86_400 # 24 hours

          # Initialize orchestrator
          # @param cache_manager [Molecules::CacheManager, nil] Cache manager instance
          def initialize(cache_manager: nil)
            @cache_manager = cache_manager || Molecules::CacheManager.new
          end

          # Sync models from API
          # @param force [Boolean] Force sync even if cache is fresh
          # @param max_age [Integer] Max cache age in seconds
          # @return [Hash] Sync result with stats
          def sync(force: false, max_age: DEFAULT_CACHE_MAX_AGE)
            # Check if we need to sync
            unless force
              if @cache_manager.fresh?(max_age: max_age)
                return {
                  status: :skipped,
                  message: "Cache is fresh (less than #{max_age / 3600}h old)",
                  last_sync_at: @cache_manager.last_sync_at
                }
              end
            end

            # Fetch from API
            start_time = Time.now
            raw_json = Atoms::ApiFetcher.fetch

            # Parse JSON
            data = Atoms::JsonParser.parse(raw_json)

            # Write to cache
            @cache_manager.write(data)

            # Calculate stats
            stats = calculate_stats(data)
            duration = Time.now - start_time

            {
              status: :success,
              message: "Synced #{stats[:model_count]} models from #{stats[:provider_count]} providers",
              duration: duration.round(2),
              stats: stats,
              sync_at: Time.now
            }
          rescue NetworkError, ApiError => e
            {
              status: :error,
              message: e.message,
              error_class: e.class.name
            }
          end

          # Check sync status
          # @return [Hash] Status info
          def status
            if @cache_manager.exists?
              data = @cache_manager.read
              stats = calculate_stats(data) if data

              {
                cached: true,
                fresh: @cache_manager.fresh?,
                last_sync_at: @cache_manager.last_sync_at,
                stats: stats
              }
            else
              {
                cached: false,
                fresh: false,
                last_sync_at: nil,
                stats: nil
              }
            end
          end

          private

          def calculate_stats(data)
            provider_count = data.size
            model_count = 0
            models_by_provider = {}

            data.each do |provider_id, provider_data|
              count = (provider_data["models"] || {}).size
              models_by_provider[provider_id] = count
              model_count += count
            end

            {
              provider_count: provider_count,
              model_count: model_count,
              top_providers: models_by_provider.sort_by { |_, v| -v }.first(10).to_h
            }
          end
        end
      end
    end
  end
end
