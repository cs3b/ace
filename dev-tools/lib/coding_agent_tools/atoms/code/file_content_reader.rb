# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    module Code
      # Reads file contents with error handling
      # This is an atom - it has no dependencies on other gem components
      class FileContentReader
        # Read file contents
        # @param path [String] file path to read
        # @return [Hash] {content: String, success: Boolean, error: String}
        def read(path)
          validate_path(path)

          begin
            content = File.read(path)
            {
              content: content,
              success: true,
              error: nil
            }
          rescue Errno::ENOENT
            {
              content: nil,
              success: false,
              error: "File not found: #{path}"
            }
          rescue Errno::EACCES
            {
              content: nil,
              success: false,
              error: "Permission denied: #{path}"
            }
          rescue => e
            {
              content: nil,
              success: false,
              error: "Error reading file: #{e.message}"
            }
          end
        end

        # Read file contents with size limit
        # @param path [String] file path to read
        # @param max_size [Integer] maximum file size in bytes
        # @return [Hash] {content: String, success: Boolean, error: String}
        def read_with_limit(path, max_size)
          validate_path(path)

          begin
            file_size = File.size(path)
            if file_size > max_size
              return {
                content: nil,
                success: false,
                error: "File too large: #{file_size} bytes (max: #{max_size})"
              }
            end

            read(path)
          rescue => e
            {
              content: nil,
              success: false,
              error: "Error checking file size: #{e.message}"
            }
          end
        end

        # Check if file exists and is readable
        # @param path [String] file path to check
        # @return [Boolean] true if file exists and is readable
        def readable?(path)
          File.exist?(path) && File.readable?(path) && File.file?(path)
        end

        # Get file metadata
        # @param path [String] file path
        # @return [Hash] {exists: Boolean, size: Integer, mtime: Time, readable: Boolean}
        def metadata(path)
          if File.exist?(path)
            {
              exists: true,
              size: File.size(path),
              mtime: File.mtime(path),
              readable: File.readable?(path)
            }
          else
            {
              exists: false,
              size: 0,
              mtime: nil,
              readable: false
            }
          end
        rescue => e
          {
            exists: false,
            size: 0,
            mtime: nil,
            readable: false,
            error: e.message
          }
        end

        private

        # Validate file path
        # @param path [String] file path
        # @raise [ArgumentError] if path is invalid
        def validate_path(path)
          raise ArgumentError, "Path cannot be nil" if path.nil?
          raise ArgumentError, "Path must be a string" unless path.is_a?(String)
          raise ArgumentError, "Path cannot be empty" if path.empty?
        end
      end
    end
  end
end
