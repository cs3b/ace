# frozen_string_literal: true

require "fileutils"
require "pathname"

module Ace
  module LLM
    module Molecules
      # FileIoHandler provides file I/O utilities for LLM query commands
      # This is a molecule - it handles specific file operations with validation
      class FileIoHandler
        # File extensions that indicate different output formats
        FORMAT_EXTENSIONS = {
          ".json" => "json",
          ".md" => "markdown",
          ".markdown" => "markdown",
          ".txt" => "text",
          ".text" => "text"
        }.freeze

        # Maximum file size to read (10MB)
        MAX_FILE_SIZE = 10 * 1024 * 1024

        # Initialize file I/O handler
        # @param options [Hash] Configuration options
        # @option options [Integer] :max_file_size Maximum file size to read
        def initialize(**options)
          @max_file_size = options.fetch(:max_file_size, MAX_FILE_SIZE)
        end

        # Detect if input is a file path or inline content
        # @param input [String] Input string to analyze
        # @return [Boolean] True if input appears to be a file path
        def file_path?(input)
          return false if input.nil? || input.strip.empty?

          # File paths must be single line strings
          input_str = input.strip
          return false if input_str.include?("\n") || input_str.include?("\r")

          # Only consider it a file path if the file actually exists
          begin
            path = Pathname.new(input_str)
            File.exist?(path.to_s)
          rescue ArgumentError, SystemCallError
            # Invalid path characters or other path-related errors
            false
          end
        end

        # Read content from file or return inline content
        # @param input [String] File path or inline content
        # @param auto_detect [Boolean] Whether to auto-detect file vs inline content
        # @return [String] Content text
        # @raise [Error] If file cannot be read or is too large
        def read_content(input, auto_detect: true)
          if auto_detect && file_path?(input)
            read_file_content(input.strip)
          else
            validate_inline_content(input)
          end
        end

        # Read content from a file with size validation
        # @param file_path [String] Path to file to read
        # @return [String] File content
        # @raise [Error] If file cannot be read or is too large
        def read_file_content(file_path)
          path = Pathname.new(file_path).expand_path

          # Check file size
          file_size = File.size(path)
          if file_size > @max_file_size
            raise Ace::LLM::Error, "File too large: #{file_size} bytes (max: #{@max_file_size} bytes)"
          end

          # Read file content
          File.read(path)
        rescue Errno::ENOENT
          raise Ace::LLM::Error, "File not found: #{file_path}"
        rescue Errno::EACCES
          raise Ace::LLM::Error, "Permission denied reading file: #{file_path}"
        rescue SystemCallError => e
          raise Ace::LLM::Error, "Error reading file: #{e.message}"
        end

        # Validate inline content
        # @param content [String] Content to validate
        # @return [String] The content (unchanged if valid)
        # @raise [Error] If content is invalid
        def validate_inline_content(content)
          raise Ace::LLM::Error, "Content cannot be nil or empty" if content.nil? || content.strip.empty?
          content
        end

        # Write content to file with format handling
        # @param content [String] Content to write
        # @param file_path [String] Output file path
        # @param format [String, nil] Format override (json, markdown, text)
        # @param force [Boolean] Whether to force overwrite without confirmation
        # @return [String] Inferred or specified format
        # @raise [Error] If file cannot be written
        def write_content(content, file_path, format: nil, force: false)
          path = Pathname.new(file_path).expand_path

          # Check if file exists and handle overwrite
          if !force && File.exist?(path)
            raise Ace::LLM::Error, "File already exists: #{file_path}. Use --force to overwrite."
          end

          # Ensure parent directory exists
          FileUtils.mkdir_p(path.dirname)

          # Write content
          File.write(path, content)

          # Return format (inferred from extension or specified)
          format || infer_format(file_path)
        rescue Errno::EACCES
          raise Ace::LLM::Error, "Permission denied writing to: #{file_path}"
        rescue SystemCallError => e
          raise Ace::LLM::Error, "Error writing file: #{e.message}"
        end

        # Infer output format from file extension
        # @param file_path [String] File path
        # @return [String] Format name (json, markdown, or text)
        def infer_format(file_path)
          return "text" if file_path.nil? || file_path.empty?

          ext = File.extname(file_path).downcase
          FORMAT_EXTENSIONS.fetch(ext, "text")
        end

        # Check if a path is safe to write to
        # @param path [String] Path to check
        # @return [Boolean] True if path appears safe
        def safe_path?(path)
          return false if path.nil? || path.empty?

          # Reject paths with null bytes
          return false if path.include?("\0")

          # Reject paths trying to traverse up directories
          return false if path.include?("..")

          begin
            expanded = Pathname.new(path).expand_path
            # Must be absolute after expansion
            expanded.absolute?
          rescue
            false
          end
        end
      end
    end
  end
end