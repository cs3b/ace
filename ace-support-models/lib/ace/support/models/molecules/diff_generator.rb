# frozen_string_literal: true

require "time"

module Ace
  module Support
    module Models
      module Molecules
        # Generates diff between cached API versions
        class DiffGenerator
          TRACKED_FIELDS = %w[name cost limit status modalities].freeze

          # Initialize diff generator
          # @param cache_manager [CacheManager, nil] Cache manager instance
          def initialize(cache_manager: nil)
            @cache_manager = cache_manager || CacheManager.new
          end

          # Generate diff between current and previous cache
          # @return [Models::DiffResult] Diff result
          def generate
            current = @cache_manager.read
            previous = @cache_manager.read_previous

            unless current
              return Models::DiffResult.new(
                current_sync_at: Time.now
              )
            end

            unless previous
              # No previous - everything is "new"
              all_models = extract_all_models(current)
              return Models::DiffResult.new(
                added_models: all_models,
                added_providers: current.keys,
                current_sync_at: @cache_manager.last_sync_at
              )
            end

            compare(previous, current)
          end

          private

          def compare(previous, current)
            added_models = []
            removed_models = []
            updated_models = []

            prev_providers = Set.new(previous.keys)
            curr_providers = Set.new(current.keys)

            # New providers
            added_providers = (curr_providers - prev_providers).to_a

            # Removed providers
            removed_providers = (prev_providers - curr_providers).to_a

            # All models from removed providers are removed
            removed_providers.each do |provider_id|
              extract_provider_models(previous, provider_id).each do |model_id|
                removed_models << model_id
              end
            end

            # All models from new providers are added
            added_providers.each do |provider_id|
              extract_provider_models(current, provider_id).each do |model_id|
                added_models << model_id
              end
            end

            # Compare models in shared providers
            (prev_providers & curr_providers).each do |provider_id|
              prev_models = previous.dig(provider_id, "models") || {}
              curr_models = current.dig(provider_id, "models") || {}

              prev_model_ids = Set.new(prev_models.keys)
              curr_model_ids = Set.new(curr_models.keys)

              # Added models
              (curr_model_ids - prev_model_ids).each do |model_id|
                added_models << "#{provider_id}:#{model_id}"
              end

              # Removed models
              (prev_model_ids - curr_model_ids).each do |model_id|
                removed_models << "#{provider_id}:#{model_id}"
              end

              # Check for updates in shared models
              (prev_model_ids & curr_model_ids).each do |model_id|
                changes = detect_changes(prev_models[model_id], curr_models[model_id])
                if changes.any?
                  updated_models << Models::ModelUpdate.new(
                    model_id: "#{provider_id}:#{model_id}",
                    changes: changes
                  )
                end
              end
            end

            Models::DiffResult.new(
              added_models: added_models.sort,
              removed_models: removed_models.sort,
              updated_models: updated_models,
              added_providers: added_providers.sort,
              removed_providers: removed_providers.sort,
              previous_sync_at: @cache_manager.metadata["last_sync_at"] ? Time.parse(@cache_manager.metadata["last_sync_at"]) : nil,
              current_sync_at: @cache_manager.last_sync_at
            )
          end

          def extract_all_models(data)
            models = []
            data.each do |provider_id, provider_data|
              (provider_data["models"] || {}).each_key do |model_id|
                models << "#{provider_id}:#{model_id}"
              end
            end
            models.sort
          end

          def extract_provider_models(data, provider_id)
            provider_data = data[provider_id]
            return [] unless provider_data

            (provider_data["models"] || {}).keys.map { |m| "#{provider_id}:#{m}" }
          end

          def detect_changes(prev_model, curr_model)
            changes = {}

            TRACKED_FIELDS.each do |field|
              prev_val = prev_model[field]
              curr_val = curr_model[field]

              next if prev_val == curr_val

              # Deep compare for nested objects
              if prev_val.is_a?(Hash) && curr_val.is_a?(Hash)
                nested = detect_nested_changes(prev_val, curr_val)
                nested.each do |key, (old_v, new_v)|
                  changes["#{field}.#{key}"] = [old_v, new_v]
                end
              else
                changes[field] = [prev_val, curr_val]
              end
            end

            changes
          end

          def detect_nested_changes(prev_hash, curr_hash)
            changes = {}
            all_keys = (prev_hash.keys + curr_hash.keys).uniq

            all_keys.each do |key|
              prev_val = prev_hash[key]
              curr_val = curr_hash[key]
              changes[key] = [prev_val, curr_val] unless prev_val == curr_val
            end

            changes
          end
        end
      end
    end
  end
end
