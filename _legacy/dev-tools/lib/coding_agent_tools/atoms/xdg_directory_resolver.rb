# frozen_string_literal: true

require "fileutils"
require "pathname"

module CodingAgentTools
  module Atoms
    # XDGDirectoryResolver is an atom that provides XDG Base Directory Specification
    # compliant directory resolution for cache and data storage.
    # This atom has no dependencies on other parts of this gem.
    class XDGDirectoryResolver
      # Application name used in directory paths
      APP_NAME = "coding-agent-tools"

      # Environment variable names
      XDG_CACHE_HOME = "XDG_CACHE_HOME"
      HOME = "HOME"

      # Default directory permissions
      DEFAULT_DIR_PERMISSIONS = 0o700

      # Resolve XDG-compliant cache directory path
      # @param env_reader [Hash, #[]] Environment variable source (defaults to ENV)
      # @return [String] Absolute path to cache directory
      def self.cache_directory(env_reader = ENV)
        xdg_cache_home = env_reader[XDG_CACHE_HOME]
        home_dir = env_reader[HOME]

        # Use XDG_CACHE_HOME if set and non-empty
        cache_base = if xdg_cache_home && !xdg_cache_home.strip.empty?
          File.expand_path(xdg_cache_home.strip)
        elsif home_dir && !home_dir.strip.empty?
          # Fall back to ~/.cache if HOME is available
          File.expand_path(".cache", home_dir.strip)
        else
          # Last resort: use current directory
          File.expand_path(".cache")
        end

        File.join(cache_base, APP_NAME)
      end

      # Ensure cache directory exists with proper permissions
      # @param cache_dir [String] Cache directory path
      # @param permissions [Integer] Directory permissions (default: 0700)
      # @return [String] The created directory path
      # @raise [SystemCallError] If directory cannot be created
      def self.ensure_cache_directory(cache_dir, permissions = DEFAULT_DIR_PERMISSIONS)
        FileUtils.mkdir_p(cache_dir, mode: permissions)
        cache_dir
      end

      # Check if a directory path is XDG-compliant for caching
      # @param path [String] Directory path to check
      # @param env_reader [Hash, #[]] Environment variable source (defaults to ENV)
      # @return [Boolean] True if path follows XDG specification
      def self.xdg_compliant_cache_path?(path, env_reader = ENV)
        expected_path = cache_directory(env_reader)
        File.expand_path(path) == File.expand_path(expected_path)
      end

      # Get cache subdirectory path for specific cache type
      # @param cache_type [String] Type of cache (e.g., 'models', 'http', 'temp')
      # @param env_reader [Hash, #[]] Environment variable source (defaults to ENV)
      # @return [String] Path to cache subdirectory
      def self.cache_subdirectory(cache_type, env_reader = ENV)
        base_cache_dir = cache_directory(env_reader)
        File.join(base_cache_dir, cache_type.to_s)
      end

      # Resolve and ensure cache subdirectory exists
      # @param cache_type [String] Type of cache (e.g., 'models', 'http', 'temp')
      # @param env_reader [Hash, #[]] Environment variable source (defaults to ENV)
      # @param permissions [Integer] Directory permissions (default: 0700)
      # @return [String] Path to existing cache subdirectory
      # @raise [SystemCallError] If directory cannot be created
      def self.ensure_cache_subdirectory(cache_type, env_reader = ENV, permissions = DEFAULT_DIR_PERMISSIONS)
        subdir_path = cache_subdirectory(cache_type, env_reader)
        ensure_cache_directory(subdir_path, permissions)
      end

      # Get platform-specific cache directory information
      # @param env_reader [Hash, #[]] Environment variable source (defaults to ENV)
      # @return [Hash] Information about cache directory resolution
      def self.cache_directory_info(env_reader = ENV)
        xdg_cache_home = env_reader[XDG_CACHE_HOME]
        home_dir = env_reader[HOME]
        resolved_path = cache_directory(env_reader)

        {
          xdg_cache_home: xdg_cache_home,
          home_directory: home_dir,
          resolved_path: resolved_path,
          uses_xdg_cache_home: !xdg_cache_home.nil? && !xdg_cache_home.strip.empty?,
          uses_home_fallback: xdg_cache_home.nil? || xdg_cache_home.strip.empty?,
          app_name: APP_NAME
        }
      end

      # Validate directory path for security
      # @param path [String] Directory path to validate
      # @return [Boolean] True if path is safe to use
      def self.safe_directory_path?(path)
        return false if path.nil? || path.empty?

        # Reject paths with null bytes (security concern)
        return false if path.include?("\0")

        # Reject paths with parent directory traversal attempts
        return false if path.include?("..")

        # Must be absolute path after expansion
        begin
          expanded = File.expand_path(path)
          pathname = Pathname.new(expanded)
          return false unless pathname.absolute?
        rescue
          return false
        end

        true
      end

      # Instance methods for non-static usage
      def initialize(env_reader = ENV)
        @env_reader = env_reader
      end

      # Instance method to get cache directory
      # @return [String] Cache directory path
      def cache_directory
        self.class.cache_directory(@env_reader)
      end

      # Instance method to ensure cache directory exists
      # @param permissions [Integer] Directory permissions (default: 0700)
      # @return [String] The created directory path
      def ensure_cache_directory(permissions = DEFAULT_DIR_PERMISSIONS)
        cache_dir = cache_directory
        self.class.ensure_cache_directory(cache_dir, permissions)
      end

      # Instance method to get cache subdirectory
      # @param cache_type [String] Type of cache
      # @return [String] Path to cache subdirectory
      def cache_subdirectory(cache_type)
        self.class.cache_subdirectory(cache_type, @env_reader)
      end

      # Instance method to ensure cache subdirectory exists
      # @param cache_type [String] Type of cache
      # @param permissions [Integer] Directory permissions (default: 0700)
      # @return [String] Path to existing cache subdirectory
      def ensure_cache_subdirectory(cache_type, permissions = DEFAULT_DIR_PERMISSIONS)
        self.class.ensure_cache_subdirectory(cache_type, @env_reader, permissions)
      end

      # Instance method to get cache directory info
      # @return [Hash] Cache directory information
      def cache_directory_info
        self.class.cache_directory_info(@env_reader)
      end
    end
  end
end
