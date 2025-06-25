# frozen_string_literal: true

require "pathname"
require "fileutils"
require "tmpdir"

module CodingAgentTools
  module Molecules
    # SecurePathValidator is a molecule that provides comprehensive path validation
    # and sanitization to prevent path traversal attacks and unauthorized access
    class SecurePathValidator
      # Security validation result
      ValidationResult = Struct.new(:valid?, :sanitized_path, :error_type, :error_message) do
        def invalid?
          !valid?
        end
      end

      # Default configuration for security validation
      DEFAULT_CONFIG = {
        # Allow current directory and common temporary directories by default
        allowed_base_paths: [
          ".",                           # Current directory and subdirectories
          "/tmp",                        # Unix/Linux temporary directory
          "/var/tmp",                    # Unix/Linux alternative temporary directory
          "/var/folders",                # macOS system temporary directories
          "/private/tmp",                # macOS private temporary directory
          "/private/var/tmp"             # macOS private alternative temporary directory
        ],

        # Deny system directories and common sensitive paths
        denied_patterns: [
          %r{^/etc(?:/|$)},           # System configuration
          %r{^/private/etc(?:/|$)},   # macOS system configuration
          %r{^/usr/bin(?:/|$)},       # System binaries
          %r{^/usr/sbin(?:/|$)},      # System admin binaries
          %r{^/bin(?:/|$)},           # Core binaries
          %r{^/sbin(?:/|$)},          # System binaries
          %r{^/var/log(?:/|$)},       # System logs
          %r{^/private/var/log(?:/|$)}, # macOS system logs
          %r{^/proc(?:/|$)},          # Process filesystem
          %r{^/sys(?:/|$)},           # System filesystem
          %r{^/dev(?:/|$)},           # Device files
          %r{^/root(?:/|$)},          # Root home directory
          %r{\.git(?:/|$)},           # Git directories
          %r{\.ssh(?:/|$)},           # SSH directories
          %r{\.aws(?:/|$)},           # AWS config
          %r{\.gem(?:/|$)}           # Ruby gem directories
        ],

        # Maximum path depth to prevent extremely long paths
        max_path_depth: 20,

        # Maximum path length
        max_path_length: 4096
      }.freeze

      attr_reader :config, :security_logger

      # Initialize the secure path validator
      # @param config [Hash] Configuration options
      # @param security_logger [SecurityLogger, nil] Logger for security events
      def initialize(config: {}, security_logger: nil)
        @config = DEFAULT_CONFIG.merge(config)
        
        # Ensure allowed_base_paths is always an Array (not Set or other type)
        @config[:allowed_base_paths] = Array(@config[:allowed_base_paths]).dup
        
        # Add system temporary directories to allowed paths if not already present
        system_temp_dirs = discover_system_temp_directories
        system_temp_dirs.each do |temp_dir|
          unless @config[:allowed_base_paths].include?(temp_dir)
            @config[:allowed_base_paths] << temp_dir
          end
        end
        
        @security_logger = security_logger || create_default_logger
      end

      # Validate a path for security and return validation result
      # @param path [String] Path to validate
      # @param context [Hash] Additional context for validation
      # @option context [Symbol] :operation Type of operation (:read, :write)
      # @option context [Boolean] :allow_create Whether to allow creating new files
      # @return [ValidationResult] Validation result
      def validate_path(path, context = {})
        return invalid_result(:empty_path, "Path cannot be empty") if path.nil? || path.empty?

        # Basic path checks
        basic_check = perform_basic_checks(path)
        return basic_check if basic_check.invalid?

        # Path traversal protection (check before normalization)
        traversal_check = check_path_traversal(path, path)
        return traversal_check if traversal_check.invalid?

        # Normalize and resolve the path
        normalization_result = normalize_path(path)
        return normalization_result if normalization_result.invalid?

        normalized_path = normalization_result.sanitized_path

        # Check denied patterns first (security takes precedence)
        denied_check = check_denied_patterns(normalized_path)
        return denied_check if denied_check.invalid?

        # Check allowed base paths
        allowed_check = check_allowed_paths(normalized_path, context)
        return allowed_check if allowed_check.invalid?

        # Log successful validation
        @security_logger.log_event(:file_operation,
          path: normalized_path,
          metadata: {operation: context[:operation] || "unknown", validated: true})

        ValidationResult.new(true, normalized_path, nil, nil)
      rescue => e
        @security_logger.log_error(e, path: path, context: context)
        invalid_result(:validation_error, "Path validation failed: #{e.message}")
      end

      # Check if a path is safe for the given operation
      # @param path [String] Path to check
      # @param operation [Symbol] Operation type (:read, :write)
      # @return [Boolean] True if path is safe
      def safe_path?(path, operation = :read)
        result = validate_path(path, operation: operation)
        result.valid?
      end

      private

      # Discover system temporary directories from environment variables
      # @return [Array<String>] List of additional temporary directories to allow
      def discover_system_temp_directories
        temp_dirs = []
        
        # Check common environment variables for temporary directories
        %w[TMPDIR TMP TEMP].each do |env_var|
          temp_path = ENV[env_var]
          if temp_path && !temp_path.empty? && File.directory?(temp_path)
            # Resolve to absolute path
            resolved_path = File.realpath(temp_path)
            temp_dirs << resolved_path unless temp_dirs.include?(resolved_path)
          end
        end
        
        # Ruby's default temporary directory
        begin
          ruby_tmp = Dir.tmpdir
          if ruby_tmp && File.directory?(ruby_tmp)
            resolved_path = File.realpath(ruby_tmp)
            temp_dirs << resolved_path unless temp_dirs.include?(resolved_path)
          end
        rescue
          # Ignore errors in discovering Ruby's tmpdir
        end
        
        temp_dirs
      end

      # Create default security logger
      # @return [SecurityLogger] Default logger instance
      def create_default_logger
        require_relative "../atoms/security_logger"
        Atoms::SecurityLogger.new
      end

      # Create an invalid validation result
      # @param error_type [Symbol] Type of error
      # @param message [String] Error message
      # @return [ValidationResult] Invalid result
      def invalid_result(error_type, message)
        ValidationResult.new(false, nil, error_type, message)
      end

      # Perform basic path validation checks
      # @param path [String] Path to check
      # @return [ValidationResult] Validation result
      def perform_basic_checks(path)
        # Check path length
        if path.length > @config[:max_path_length]
          @security_logger.log_event(:invalid_path,
            path: path,
            reason: "Path too long: #{path.length} characters")
          return invalid_result(:path_too_long, "Path exceeds maximum length")
        end

        # Check for null bytes (security risk)
        if path.include?("\0")
          @security_logger.log_event(:path_traversal_attempt,
            path: path,
            reason: "Null byte in path")
          return invalid_result(:null_byte, "Path contains null byte")
        end

        # Check for invalid characters that could be used for attacks
        if path.match?(/[\x00-\x1f\x7f]/)
          @security_logger.log_event(:invalid_path,
            path: path,
            reason: "Control characters in path")
          return invalid_result(:invalid_characters, "Path contains invalid characters")
        end

        ValidationResult.new(true, path, nil, nil)
      end

      # Normalize path and resolve relative components
      # @param path [String] Path to normalize
      # @return [ValidationResult] Validation result with normalized path
      def normalize_path(path)
        # Use Pathname to clean up the path
        pathname = Pathname.new(path)
        cleaned = pathname.cleanpath

        # Check for too many path components (potential DoS)
        components = cleaned.each_filename.to_a
        if components.length > @config[:max_path_depth]
          @security_logger.log_event(:invalid_path,
            path: path,
            reason: "Path depth too deep: #{components.length}")
          return invalid_result(:path_too_deep, "Path exceeds maximum depth")
        end

        # Resolve to absolute path if it exists, otherwise keep relative
        if File.exist?(cleaned.to_s)
          begin
            # Use realpath to resolve symlinks and get canonical path
            resolved = cleaned.realpath.to_s
            ValidationResult.new(true, resolved, nil, nil)
          rescue Errno::ENOENT, Errno::EACCES
            # If realpath fails, use the cleaned path
            ValidationResult.new(true, cleaned.to_s, nil, nil)
          end
        else
          # For non-existent paths, use cleaned path
          ValidationResult.new(true, cleaned.to_s, nil, nil)
        end
      rescue ArgumentError => e
        @security_logger.log_event(:invalid_path,
          path: path,
          reason: "Invalid path format: #{e.message}")
        invalid_result(:invalid_format, "Invalid path format")
      end

      # Check path against denied patterns
      # @param normalized_path [String] Normalized path to check
      # @return [ValidationResult] Validation result
      def check_denied_patterns(normalized_path)
        @config[:denied_patterns].each do |pattern|
          if normalized_path.match?(pattern)
            @security_logger.log_event(:denied_access,
              path: normalized_path,
              reason: "Matches denied pattern: #{pattern.source}")
            return invalid_result(:denied_pattern, "Path matches denied pattern")
          end
        end

        ValidationResult.new(true, normalized_path, nil, nil)
      end

      # Check path against allowed base paths
      # @param normalized_path [String] Normalized path to check
      # @param context [Hash] Operation context
      # @return [ValidationResult] Validation result
      def check_allowed_paths(normalized_path, context)
        allowed = @config[:allowed_base_paths].any? do |base_path|
          expanded_base = File.expand_path(base_path)

          # Allow if the path is within the allowed base
          if normalized_path.start_with?(expanded_base)
            true
          # Also allow if it's a relative path within the base
          elsif Pathname.new(normalized_path).relative?
            expanded_requested = File.expand_path(normalized_path, expanded_base)
            expanded_requested.start_with?(expanded_base)
          else
            false
          end
        end

        unless allowed
          @security_logger.log_event(:denied_access,
            path: normalized_path,
            reason: "Outside allowed base paths")
          return invalid_result(:outside_allowed_paths, "Path is outside allowed directories")
        end

        ValidationResult.new(true, normalized_path, nil, nil)
      end

      # Check for path traversal attempts
      # @param original_path [String] Original path provided
      # @param normalized_path [String] Normalized path
      # @return [ValidationResult] Validation result
      def check_path_traversal(original_path, normalized_path)
        # Check for classic path traversal patterns
        traversal_patterns = [
          "../",
          "..\\",
          "..%2f",
          "..%5c",
          "%2e%2e%2f",
          "%2e%2e%5c"
        ]

        traversal_patterns.each do |pattern|
          if original_path.downcase.include?(pattern)
            @security_logger.log_event(:path_traversal_attempt,
              path: original_path,
              reason: "Contains traversal pattern: #{pattern}")
            return invalid_result(:path_traversal, "Path contains directory traversal pattern")
          end
        end

        # Additional check: if normalized path goes above the current directory
        # and we're working with a relative path that had ../ components
        if original_path.include?("..") && normalized_path.start_with?("/")
          current_dir = Dir.pwd
          unless normalized_path.start_with?(current_dir)
            @security_logger.log_event(:path_traversal_attempt,
              path: original_path,
              reason: "Relative path escapes current directory")
            return invalid_result(:path_traversal, "Path attempts to escape current directory")
          end
        end

        ValidationResult.new(true, normalized_path, nil, nil)
      end
    end
  end
end
