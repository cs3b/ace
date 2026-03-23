# frozen_string_literal: true

require "pathname"

module Ace
  module Core
    module Atoms
      # Pure file reading functions with safety checks
      module FileReader
        # Default maximum file size (1MB)
        MAX_FILE_SIZE = 1_048_576

        # Binary file detection patterns
        BINARY_EXTENSIONS = %w[
          .jpg .jpeg .png .gif .bmp .ico .webp .svg
          .pdf .doc .docx .xls .xlsx .ppt .pptx
          .zip .tar .gz .bz2 .7z .rar
          .exe .dll .so .dylib .app
          .mp3 .mp4 .avi .mov .wmv .flv
          .ttf .otf .woff .woff2 .eot
          .class .jar .war .ear
          .pyc .pyo .o .a
        ].freeze

        module_function

        # Read file with size limit
        # @param path [String] Path to file
        # @param max_size [Integer] Maximum file size in bytes
        # @return [Hash] {success: Boolean, content: String, error: String}
        def read(path, max_size: MAX_FILE_SIZE)
          return {success: false, error: "Path cannot be nil"} if path.nil?

          expanded_path = File.expand_path(path)

          unless File.exist?(expanded_path)
            return {success: false, error: "File not found: #{path}"}
          end

          unless File.file?(expanded_path)
            return {success: false, error: "Not a file: #{path}"}
          end

          file_size = File.size(expanded_path)
          if file_size > max_size
            return {
              success: false,
              error: "File too large: #{file_size} bytes (max: #{max_size})"
            }
          end

          if binary?(expanded_path)
            return {
              success: false,
              error: "Binary file detected: #{path}"
            }
          end

          content = File.read(expanded_path, encoding: "UTF-8")
          {success: true, content: content, size: file_size}
        rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
          {success: false, error: "File contains invalid UTF-8: #{path}"}
        rescue => e
          {success: false, error: "Failed to read file: #{e.message}"}
        end

        # Check if file exists and is readable
        # @param path [String] Path to file
        # @return [Boolean] true if file exists and is readable
        def readable?(path)
          return false if path.nil?

          expanded_path = File.expand_path(path)
          File.exist?(expanded_path) && File.file?(expanded_path) && File.readable?(expanded_path)
        end

        # Check if file appears to be binary
        # @param path [String] Path to file
        # @return [Boolean] true if file appears to be binary
        def binary?(path)
          return false if path.nil?

          # Check extension first
          ext = File.extname(path).downcase
          return true if BINARY_EXTENSIONS.include?(ext)

          # Sample first 8KB of file for null bytes
          expanded_path = File.expand_path(path)
          return false unless File.exist?(expanded_path)

          sample_size = [File.size(expanded_path), 8192].min
          sample = File.read(expanded_path, sample_size, mode: "rb")

          # Check for null bytes (common in binary files)
          # Also check for common binary file markers
          return true if sample.include?("\x00")

          # Check if it's mostly non-printable characters
          # Count non-ASCII printable characters
          non_printable = sample.bytes.count { |b| b < 32 || b > 126 }
          printable = sample.bytes.count { |b| b >= 32 && b <= 126 }

          # If more than 30% non-printable, consider it binary
          non_printable.to_f / (non_printable + printable) > 0.3
        rescue
          # If we can't read it, assume it might be binary
          true
        end

        # Get file metadata
        # @param path [String] Path to file
        # @return [Hash] File metadata
        def metadata(path)
          return {exists: false} if path.nil?

          expanded_path = File.expand_path(path)

          unless File.exist?(expanded_path)
            return {exists: false, path: path}
          end

          stat = File.stat(expanded_path)

          {
            exists: true,
            path: path,
            absolute_path: expanded_path,
            size: stat.size,
            modified: stat.mtime,
            created: stat.ctime,
            readable: File.readable?(expanded_path),
            writable: File.writable?(expanded_path),
            directory: stat.directory?,
            file: stat.file?,
            binary: binary?(expanded_path)
          }
        rescue => e
          {exists: false, path: path, error: e.message}
        end

        # Read lines from file with line limit
        # @param path [String] Path to file
        # @param limit [Integer] Maximum number of lines
        # @param offset [Integer] Starting line number (0-based)
        # @return [Hash] {success: Boolean, lines: Array, total_lines: Integer, error: String}
        def read_lines(path, limit: 100, offset: 0)
          return {success: false, error: "Path cannot be nil"} if path.nil?

          expanded_path = File.expand_path(path)

          unless File.exist?(expanded_path)
            return {success: false, error: "File not found: #{path}"}
          end

          if binary?(expanded_path)
            return {success: false, error: "Binary file detected: #{path}"}
          end

          lines = []
          total_lines = 0

          File.foreach(expanded_path, encoding: "UTF-8").with_index do |line, index|
            total_lines = index + 1
            if index >= offset && lines.size < limit
              lines << line.chomp
            end
          end

          {
            success: true,
            lines: lines,
            total_lines: total_lines,
            offset: offset,
            limit: limit
          }
        rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
          {success: false, error: "File contains invalid UTF-8: #{path}"}
        rescue => e
          {success: false, error: "Failed to read lines: #{e.message}"}
        end
      end
    end
  end
end
