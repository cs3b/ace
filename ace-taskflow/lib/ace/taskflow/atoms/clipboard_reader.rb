# frozen_string_literal: true

require "clipboard"

module Ace
  module Taskflow
    module Atoms
      class ClipboardReader
        # Maximum clipboard content size (100KB)
        MAX_CONTENT_SIZE = 100 * 1024

        # Read clipboard content and detect content type
        # Returns hash with:
        #   { success: true, content: "...", type: :text/:files, files: [...] }
        # or
        #   { success: false, error: "..." }
        def self.read
          content = Clipboard.paste

          # Check if clipboard is empty or whitespace-only
          if content.nil? || content.strip.empty?
            return {
              success: false,
              error: "Clipboard is empty. Provide text argument or copy content to clipboard."
            }
          end

          # Check content size
          if content.bytesize > MAX_CONTENT_SIZE
            return {
              success: false,
              error: "Clipboard content too large (#{content.bytesize} bytes, max #{MAX_CONTENT_SIZE} bytes)"
            }
          end

          # Check for binary content
          if binary_content?(content)
            return {
              success: false,
              error: "Clipboard contains binary data. Only text and file paths are supported."
            }
          end

          # Detect if content contains file paths
          file_paths = detect_file_paths(content)

          if file_paths.any?
            {
              success: true,
              content: content,
              type: :files,
              files: file_paths
            }
          else
            {
              success: true,
              content: content,
              type: :text,
              files: []
            }
          end
        rescue StandardError => e
          {
            success: false,
            error: "Unable to read clipboard: #{e.message}"
          }
        end

        private

        # Check if content contains binary data
        def self.binary_content?(content)
          # Check for null bytes or other control characters
          content.encoding == Encoding::ASCII_8BIT || content.include?("\x00")
        end

        # Detect if clipboard contains file paths
        # Returns array of valid file paths
        def self.detect_file_paths(content)
          lines = content.split("\n").map(&:strip).reject(&:empty?)

          # Check if all non-empty lines are valid file paths
          file_paths = lines.select do |line|
            # Must look like a file path (starts with / or ./ or ../)
            line.start_with?("/", "./", "../") && File.exist?(line) && File.file?(line)
          end

          # Only return file paths if at least one valid path was found
          # and most lines (>50%) are valid paths
          if file_paths.any? && (file_paths.length.to_f / lines.length) > 0.5
            file_paths
          else
            []
          end
        end
      end
    end
  end
end
