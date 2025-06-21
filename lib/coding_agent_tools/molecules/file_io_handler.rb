# frozen_string_literal: true

require "fileutils"
require "pathname"

module CodingAgentTools
  module Molecules
    # FileIoHandler provides shared file I/O utilities for LLM query commands
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

        # Check if it's a valid file path that exists
        begin
          path = Pathname.new(input.strip)
          return false if path.to_s.include?("\n") || path.to_s.include?("\r")
          File.exist?(path.to_s)
        rescue
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

      # Write content to file with format handling
      # @param content [String] Content to write
      # @param file_path [String] Output file path
      # @param format [String, nil] Format override (json, markdown, text)
      # @return [String] Inferred or specified format
      # @raise [Error] If file cannot be written
      def write_content(content, file_path, format: nil)
        inferred_format = format || infer_format_from_path(file_path)

        # Ensure output directory exists
        dir_path = File.dirname(file_path)
        FileUtils.mkdir_p(dir_path) unless File.directory?(dir_path)

        # Write content to file
        File.write(file_path, content, encoding: "UTF-8")

        inferred_format
      rescue => e
        raise Error, "Failed to write file #{file_path}: #{e.message}"
      end

      # Infer output format from file extension
      # @param file_path [String] Path to check for extension
      # @return [String] Inferred format (json, markdown, text)
      def infer_format_from_path(file_path)
        return "text" if file_path.nil? || file_path.strip.empty?

        extension = File.extname(file_path.strip).downcase
        FORMAT_EXTENSIONS.fetch(extension, "text")
      end

      # Check if path has supported format extension
      # @param file_path [String] Path to check
      # @return [Boolean] True if extension is supported
      def supported_format?(file_path)
        return false if file_path.nil? || file_path.strip.empty?

        extension = File.extname(file_path.strip).downcase
        FORMAT_EXTENSIONS.key?(extension)
      end

      # Get list of supported format extensions
      # @return [Array<String>] List of supported extensions
      def supported_extensions
        FORMAT_EXTENSIONS.keys
      end

      # Validate that a file path can be written to
      # @param file_path [String] Path to validate
      # @return [Boolean] True if path is writable
      def writable_path?(file_path)
        return false if file_path.nil? || file_path.strip.empty?

        begin
          path = Pathname.new(file_path.strip)
          dir_path = path.dirname

          # Check if directory exists or can be created
          if File.directory?(dir_path)
            File.writable?(dir_path)
          else
            # Check if parent directories are writable for creation
            existing_parent = dir_path
            while !File.exist?(existing_parent) && existing_parent.to_s != "/"
              existing_parent = existing_parent.dirname
            end
            File.writable?(existing_parent)
          end
        rescue
          false
        end
      end

      private

      # Read content from file with validation
      # @param file_path [String] Path to file
      # @return [String] File contents
      # @raise [Error] If file cannot be read or is too large
      def read_file_content(file_path)
        unless File.exist?(file_path)
          raise Error, "File not found: #{file_path}"
        end

        unless File.readable?(file_path)
          raise Error, "Permission denied reading file: #{file_path}"
        end

        file_size = File.size(file_path)
        if file_size > @max_file_size
          raise Error, "File too large: #{file_size} bytes (max: #{@max_file_size})"
        end

        File.read(file_path, encoding: "UTF-8").strip
      rescue Errno::EACCES
        raise Error, "Permission denied reading file: #{file_path}"
      rescue Errno::ENOENT
        raise Error, "File not found: #{file_path}"
      rescue => e
        raise Error, "Error reading file #{file_path}: #{e.message}"
      end

      # Validate inline content
      # @param content [String] Content to validate
      # @return [String] Validated content
      # @raise [Error] If content is empty
      def validate_inline_content(content)
        if content.nil? || content.strip.empty?
          raise Error, "Content cannot be empty"
        end

        content.strip
      end
    end
  end
end
