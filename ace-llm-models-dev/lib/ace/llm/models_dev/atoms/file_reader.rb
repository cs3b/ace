# frozen_string_literal: true

module Ace
  module LLM
    module ModelsDev
      module Atoms
        # Reads files from the cache
        class FileReader
          class << self
            # Read file contents
            # @param path [String] File path
            # @return [String, nil] File contents or nil if not found
            def read(path)
              return nil unless File.exist?(path)

              File.read(path)
            rescue Errno::EACCES => e
              raise CacheError, "Permission denied reading #{path}: #{e.message}"
            rescue Errno::ENOENT
              nil
            end

            # Check if file exists
            # @param path [String] File path
            # @return [Boolean] true if file exists
            def exist?(path)
              File.exist?(path)
            end

            # Get file modification time
            # @param path [String] File path
            # @return [Time, nil] Modification time or nil
            def mtime(path)
              return nil unless File.exist?(path)

              File.mtime(path)
            end
          end
        end
      end
    end
  end
end
