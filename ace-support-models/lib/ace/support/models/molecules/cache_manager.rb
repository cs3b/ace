# frozen_string_literal: true

require "time"

module Ace
  module Support
    module Models
      module Molecules
        # Manages local cache of API data
        class CacheManager
          API_CACHE_FILE = "api.json"
          PREVIOUS_CACHE_FILE = "api.previous.json"
          METADATA_FILE = "metadata.json"

          attr_reader :cache_dir

          # Initialize cache manager
          # @param cache_dir [String, nil] Cache directory (default: from CachePathResolver)
          def initialize(cache_dir: nil)
            @cache_dir = cache_dir || Atoms::CachePathResolver.resolve
          end

          # Read current API cache
          # @return [Hash, nil] Parsed API data or nil
          def read
            content = Atoms::FileReader.read(api_cache_path)
            return nil unless content

            Atoms::JsonParser.parse(content)
          end

          # Read previous API cache (for diff)
          # @return [Hash, nil] Parsed previous API data or nil
          def read_previous
            content = Atoms::FileReader.read(previous_cache_path)
            return nil unless content

            Atoms::JsonParser.parse(content)
          end

          # Write API data to cache
          # @param data [Hash] API data
          # @return [Boolean] true on success
          def write(data)
            # Move current to previous first
            if Atoms::FileReader.exist?(api_cache_path)
              Atoms::FileWriter.rename(api_cache_path, previous_cache_path)
            end

            # Write new data
            json = Atoms::JsonParser.to_json(data, pretty: false)
            Atoms::FileWriter.write(api_cache_path, json)

            # Update metadata
            update_metadata

            true
          end

          # Read cache metadata
          # @return [Hash] Metadata hash
          def metadata
            content = Atoms::FileReader.read(metadata_path)
            return default_metadata unless content

            Atoms::JsonParser.parse(content)
          rescue ApiError
            default_metadata
          end

          # Check if cache exists
          # @return [Boolean]
          def exists?
            Atoms::FileReader.exist?(api_cache_path)
          end

          # Alias for exists? for clearer CLI usage
          # @return [Boolean]
          def cached?
            exists?
          end

          # List all providers with model counts
          # @return [Array<Hash>] Provider info hashes
          def list_providers
            data = read
            return [] unless data

            normalize_providers(data).map do |provider_id, provider_data|
              models = normalize_models(provider_data)
              {
                id: provider_id,
                model_count: models.size
              }
            end
          end

          # Get provider details with models
          # @param provider_id [String] Provider ID
          # @return [Hash, nil] Provider data or nil if not found
          def get_provider(provider_id)
            data = read
            return nil unless data

            provider_data = normalize_providers(data)[provider_id]
            return nil unless provider_data

            models = normalize_models(provider_data).map do |model_id, model_data|
              {
                id: model_id,
                name: model_data["name"] || model_id,
                deprecated: model_data["deprecated"] == true
              }
            end

            {
              id: provider_id,
              models: models.sort_by { |m| m[:id] }
            }
          end

          # Check if cache is fresh (less than max_age old)
          # @param max_age [Integer] Max age in seconds (default: 24 hours)
          # @return [Boolean]
          def fresh?(max_age: 86_400)
            mtime = Atoms::FileReader.mtime(api_cache_path)
            return false unless mtime

            (Time.now - mtime) < max_age
          end

          # Get last sync time
          # @return [Time, nil]
          def last_sync_at
            meta = metadata
            return nil unless meta["last_sync_at"]

            Time.parse(meta["last_sync_at"])
          rescue ArgumentError
            nil
          end

          # Clear cache
          # @return [Hash] Result with status and deleted files
          def clear
            deleted_files = []
            [api_cache_path, previous_cache_path, metadata_path].each do |path|
              if Atoms::FileReader.exist?(path)
                Atoms::FileWriter.delete(path)
                deleted_files << File.basename(path)
              end
            end

            {
              status: :success,
              deleted_files: deleted_files,
              message: deleted_files.empty? ? "Cache was already empty" : "Deleted #{deleted_files.size} files"
            }
          end

          private

          def api_cache_path
            File.join(cache_dir, API_CACHE_FILE)
          end

          def previous_cache_path
            File.join(cache_dir, PREVIOUS_CACHE_FILE)
          end

          def metadata_path
            File.join(cache_dir, METADATA_FILE)
          end

          def update_metadata
            meta = {
              "last_sync_at" => Time.now.utc.iso8601,
              "version" => VERSION
            }
            json = Atoms::JsonParser.to_json(meta, pretty: true)
            Atoms::FileWriter.write(metadata_path, json)
          end

          def default_metadata
            {
              "last_sync_at" => nil,
              "version" => VERSION
            }
          end

          def normalize_providers(data)
            return {} unless data.is_a?(Hash)

            wrapped = data["providers"]
            return normalize_provider_collection(wrapped) unless wrapped.nil?

            data
          end

          def normalize_provider_collection(providers)
            case providers
            when Hash
              providers
            when Array
              providers.each_with_object({}) do |provider, acc|
                next unless provider.is_a?(Hash)

                provider_id = provider["id"]
                acc[provider_id] = provider if provider_id
              end
            else
              {}
            end
          end

          def normalize_models(provider_data)
            models = provider_data["models"]

            case models
            when Hash
              models
            when Array
              models.each_with_object({}) do |model, acc|
                next unless model.is_a?(Hash)

                model_id = model["id"]
                acc[model_id] = model if model_id
              end
            else
              {}
            end
          end
        end
      end
    end
  end
end
