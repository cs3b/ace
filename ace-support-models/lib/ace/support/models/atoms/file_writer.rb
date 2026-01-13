# frozen_string_literal: true

require "fileutils"

module Ace
  module Support
    module Models
      module Atoms
        # Writes files to the cache
        class FileWriter
          class << self
            # Write content to file
            # @param path [String] File path
            # @param content [String] Content to write
            # @return [Boolean] true on success
            # @raise [CacheError] on write errors
            def write(path, content)
              ensure_directory(File.dirname(path))
              File.write(path, content)
              true
            rescue Errno::EACCES => e
              raise CacheError, "Permission denied writing #{path}: #{e.message}"
            rescue Errno::ENOSPC => e
              raise CacheError, "No space left writing #{path}: #{e.message}"
            end

            # Ensure directory exists
            # @param dir [String] Directory path
            # @return [Boolean] true if created or exists
            def ensure_directory(dir)
              FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
              true
            rescue Errno::EACCES => e
              raise CacheError, "Permission denied creating directory #{dir}: #{e.message}"
            end

            # Delete file
            # @param path [String] File path
            # @return [Boolean] true on success
            def delete(path)
              File.delete(path) if File.exist?(path)
              true
            rescue Errno::EACCES => e
              raise CacheError, "Permission denied deleting #{path}: #{e.message}"
            end

            # Rename/move file
            # @param from [String] Source path
            # @param to [String] Destination path
            # @return [Boolean] true on success
            def rename(from, to)
              ensure_directory(File.dirname(to))
              File.rename(from, to)
              true
            rescue Errno::EACCES => e
              raise CacheError, "Permission denied moving file: #{e.message}"
            end
          end
        end
      end
    end
  end
end
