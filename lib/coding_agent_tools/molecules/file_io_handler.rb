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
      # @option options [SecurityLogger] :security_logger Logger for security events
      # @option options [SecurePathValidator] :path_validator Path security validator
      # @option options [FileOperationConfirmer] :operation_confirmer File operation confirmer
      def initialize(**options)
        @max_file_size = options.fetch(:max_file_size, MAX_FILE_SIZE)
        @security_logger = options[:security_logger] || create_security_logger
        @path_validator = options[:path_validator] || create_path_validator
        @operation_confirmer = options[:operation_confirmer] || create_operation_confirmer
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

      # Validate output path and confirm overwrite (early validation)
      # @param file_path [String] Target file path
      # @param force [Boolean] Force overwrite without confirmation
      # @return [String] The validated and sanitized file path
      # @raise [Error] If validation fails or overwrite is denied
      def validate_write_path(file_path, force: false)
        # Validate path security
        validation_result = @path_validator.validate_path(file_path, operation: :write)
        if validation_result.invalid?
          raise Error, "Path validation failed: #{validation_result.error_message}"
        end

        validated_path = validation_result.sanitized_path

        # Check for overwrite confirmation if file exists
        confirmation_result = @operation_confirmer.confirm_overwrite(validated_path, force: force)
        unless confirmation_result.confirmed?
          raise Error, "File overwrite denied: #{confirmation_result.reason}"
        end

        validated_path
      end

      # Write content to file with format handling and security checks
      # @param content [String] Content to write
      # @param file_path [String] Output file path
      # @param format [String, nil] Format override (json, markdown, text)
      # @param force [Boolean] Whether to force overwrite without confirmation
      # @return [String] Inferred or specified format
      # @raise [Error] If file cannot be written or security checks fail
      def write_content(content, file_path, format: nil, force: false)
        # Validate path security
        validation_result = @path_validator.validate_path(file_path, operation: :write)
        if validation_result.invalid?
          raise Error, "Path validation failed: #{validation_result.error_message}"
        end

        validated_path = validation_result.sanitized_path
        inferred_format = format || infer_format_from_path(validated_path)

        # Check for overwrite confirmation if file exists
        confirmation_result = @operation_confirmer.confirm_overwrite(validated_path, force: force)
        unless confirmation_result.confirmed?
          raise Error, "File overwrite denied: #{confirmation_result.reason}"
        end

        # Ensure output directory exists
        dir_path = File.dirname(validated_path)
        FileUtils.mkdir_p(dir_path) unless File.directory?(dir_path)

        # Write content to file
        File.write(validated_path, content, encoding: "UTF-8")

        @security_logger.log_event(:file_operation,
          path: validated_path,
          metadata: {
            operation: "write",
            format: inferred_format,
            size: content.bytesize,
            forced: force
          })

        inferred_format
      rescue => e
        @security_logger.log_error(e, context: {operation: "write", file_path: file_path})
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

      # Read content from file with security validation
      # @param file_path [String] Path to file
      # @return [String] File contents
      # @raise [Error] If file cannot be read, is too large, or fails security checks
      def read_file_content(file_path)
        # Validate path security
        validation_result = @path_validator.validate_path(file_path, operation: :read)
        if validation_result.invalid?
          raise Error, "Path validation failed: #{validation_result.error_message}"
        end

        validated_path = validation_result.sanitized_path

        unless File.exist?(validated_path)
          raise Error, "File not found: #{file_path}"
        end

        unless File.readable?(validated_path)
          raise Error, "Permission denied reading file: #{file_path}"
        end

        file_size = File.size(validated_path)
        if file_size > @max_file_size
          raise Error, "File too large: #{file_size} bytes (max: #{@max_file_size})"
        end

        content = File.read(validated_path, encoding: "UTF-8").strip

        @security_logger.log_event(:file_operation,
          path: validated_path,
          metadata: {
            operation: "read",
            size: file_size
          })

        content
      rescue Errno::EACCES
        @security_logger.log_error(StandardError.new("Permission denied"), context: {operation: "read", file_path: file_path})
        raise Error, "Permission denied reading file: #{file_path}"
      rescue Errno::ENOENT
        @security_logger.log_error(StandardError.new("File not found"), context: {operation: "read", file_path: file_path})
        raise Error, "File not found: #{file_path}"
      rescue => e
        @security_logger.log_error(e, context: {operation: "read", file_path: file_path})
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

      # Create security logger instance
      # @return [SecurityLogger] Security logger
      def create_security_logger
        require_relative "../atoms/security_logger"
        Atoms::SecurityLogger.new
      end

      # Create secure path validator instance
      # @return [SecurePathValidator] Path validator
      def create_path_validator
        require_relative "secure_path_validator"
        SecurePathValidator.new
      end

      # Create file operation confirmer instance
      # @return [FileOperationConfirmer] Operation confirmer
      def create_operation_confirmer
        require_relative "file_operation_confirmer"
        FileOperationConfirmer.new
      end
    end
  end
end
