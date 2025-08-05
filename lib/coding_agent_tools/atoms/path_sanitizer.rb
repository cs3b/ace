# frozen_string_literal: true

require 'pathname'

module CodingAgentTools
  module Atoms
    # PathSanitizer provides path validation and sanitization utilities
    # This is an atom - it has no dependencies on other parts of this gem
    class PathSanitizer
      # Common path traversal patterns to detect
      TRAVERSAL_PATTERNS = [
        /\.\./,           # Parent directory reference
        /~\//,            # Home directory expansion
        /\$[A-Z_]+/,      # Environment variable expansion
        /%[A-Z_]+%/,      # Windows environment variable
        /\0/,             # Null byte
        /[\x00-\x1f\x7f]/ # Control characters
      ].freeze

      # Validate a path for safety
      # @param path [String, Pathname] Path to validate
      # @return [Boolean] true if path is safe
      def self.safe?(path)
        return false if path.nil? || path.to_s.empty?

        path_str = path.to_s

        # Check for traversal patterns
        TRAVERSAL_PATTERNS.none? { |pattern| path_str.match?(pattern) }
      end

      # Sanitize a path by removing unsafe components
      # @param path [String, Pathname] Path to sanitize
      # @return [String] Sanitized path
      def self.sanitize(path)
        return '' if path.nil?

        path_str = path.to_s

        # Remove null bytes and control characters
        sanitized = path_str.gsub(/[\x00-\x1f\x7f]/, '')

        # Remove parent directory references
        sanitized = sanitized.gsub(/\.\.\//, '')

        # Remove home directory references
        sanitized = sanitized.gsub(/~\//, '')

        # Remove environment variables
        sanitized = sanitized.gsub(/\$[A-Z_]+/, '')
        sanitized = sanitized.gsub(/%[A-Z_]+%/, '')

        # Normalize path separators
        sanitized = sanitized.gsub(/[\\\/]+/, '/')

        # Remove leading/trailing slashes and whitespace
        sanitized.strip.gsub(/^\/+|\/+$/, '')
      end

      # Normalize a path to a consistent format
      # @param path [String, Pathname] Path to normalize
      # @param base [String, Pathname] Base directory for relative paths
      # @return [Pathname] Normalized path
      def self.normalize(path, base: nil)
        return Pathname.new('') if path.nil? || path.to_s.empty?

        pathname = path.is_a?(Pathname) ? path : Pathname.new(path.to_s)

        # Expand relative paths if base is provided
        if base && pathname.relative?
          base_path = base.is_a?(Pathname) ? base : Pathname.new(base.to_s)
          pathname = base_path / pathname
        end

        # Clean up the path
        pathname.cleanpath
      end

      # Check if a path is absolute
      # @param path [String, Pathname] Path to check
      # @return [Boolean] true if path is absolute
      def self.absolute?(path)
        return false if path.nil? || path.to_s.empty?

        pathname = path.is_a?(Pathname) ? path : Pathname.new(path.to_s)
        pathname.absolute?
      end

      # Check if a path is within a base directory
      # @param path [String, Pathname] Path to check
      # @param base [String, Pathname] Base directory
      # @return [Boolean] true if path is within base
      def self.within?(path, base)
        return false if path.nil? || base.nil?

        normalized_path = normalize(path, base: base).expand_path
        normalized_base = normalize(base).expand_path

        normalized_path.to_s.start_with?(normalized_base.to_s)
      rescue
        false
      end

      # Join path components safely
      # @param parts [Array<String>] Path components
      # @return [String] Joined path
      def self.join(*parts)
        # Filter out nil and empty parts
        clean_parts = parts.compact.reject(&:empty?)

        # Sanitize each part
        sanitized_parts = clean_parts.map { |part| sanitize(part) }

        # Join with single separator
        sanitized_parts.join('/')
      end
    end
  end
end
