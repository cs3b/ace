# frozen_string_literal: true

module Ace
  module Context
    module Atoms
      # File reading utilities
      class FileReader
        MAX_FILE_SIZE = 10 * 1024 * 1024 # 10MB default

        def self.read_file(path, max_size: MAX_FILE_SIZE)
          return { success: false, error: "File not found: #{path}" } unless File.exist?(path)

          file_size = File.size(path)
          if file_size > max_size
            return { success: false, error: "File too large: #{path} (#{file_size} bytes)" }
          end

          content = File.read(path)
          { success: true, content: content, size: file_size }
        rescue => e
          { success: false, error: "Error reading #{path}: #{e.message}" }
        end

        def self.glob_files(pattern, base_dir: Dir.pwd)
          Dir.chdir(base_dir) do
            files = Dir.glob(pattern).select { |f| File.file?(f) }
            files.map { |f| File.expand_path(f, base_dir) }
          end
        rescue
          []
        end

        def self.file_info(path)
          return nil unless File.exist?(path)

          {
            path: path,
            size: File.size(path),
            modified: File.mtime(path),
            readable: File.readable?(path)
          }
        end
      end
    end
  end
end