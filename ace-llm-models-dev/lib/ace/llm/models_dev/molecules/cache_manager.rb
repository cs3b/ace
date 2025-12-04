# frozen_string_literal: true

require "time"

module Ace
  module LLM
    module ModelsDev
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
          # @return [Boolean]
          def clear
            Atoms::FileWriter.delete(api_cache_path)
            Atoms::FileWriter.delete(previous_cache_path)
            Atoms::FileWriter.delete(metadata_path)
            true
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
        end
      end
    end
  end
end
