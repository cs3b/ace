# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Pure functions for reading files
      module FileReader
        module_function

        # Read a file with error handling
        def read(path)
          return { success: false, content: nil, error: "Path is nil" } unless path
          return { success: false, content: nil, error: "File not found: #{path}" } unless File.exist?(path)

          {
            success: true,
            content: File.read(path),
            error: nil
          }
        rescue StandardError => e
          {
            success: false,
            content: nil,
            error: e.message
          }
        end

        # Read multiple files
        def read_multiple(paths)
          results = {}
          paths.each do |path|
            results[path] = read(path)
          end
          results
        end

        # Read files matching a pattern
        def read_pattern(pattern, base_dir: nil)
          base = base_dir || Dir.pwd
          full_pattern = File.join(base, pattern)

          files = Dir.glob(full_pattern)
          read_multiple(files)
        end

        # Check if a file exists
        def exists?(path)
          File.exist?(path)
        end

        # Get file size
        def size(path)
          return nil unless exists?(path)
          File.size(path)
        end

        # Get file modification time
        def mtime(path)
          return nil unless exists?(path)
          File.mtime(path)
        end
      end
    end
  end
end