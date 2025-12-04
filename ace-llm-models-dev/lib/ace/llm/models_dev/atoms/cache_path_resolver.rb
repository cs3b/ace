# frozen_string_literal: true

module Ace
  module LLM
    module ModelsDev
      module Atoms
        # Resolves the cache directory path following XDG conventions
        class CachePathResolver
          DEFAULT_CACHE_DIR = "ace-llm-models-dev"

          class << self
            # Resolve the cache directory path
            # @return [String] Full path to cache directory
            def resolve
              base_dir = xdg_cache_home || default_cache_home
              File.join(base_dir, DEFAULT_CACHE_DIR)
            end

            private

            # Get XDG_CACHE_HOME if set
            # @return [String, nil] XDG cache home or nil
            def xdg_cache_home
              xdg = ENV["XDG_CACHE_HOME"]
              xdg if xdg && !xdg.empty?
            end

            # Get default cache home (~/.cache)
            # @return [String] Default cache directory
            def default_cache_home
              File.join(Dir.home, ".cache")
            end
          end
        end
      end
    end
  end
end
