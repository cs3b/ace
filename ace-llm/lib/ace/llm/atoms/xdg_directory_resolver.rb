# frozen_string_literal: true

require "fileutils"
require "pathname"

module Ace
  module LLM
    module Atoms
      # XDGDirectoryResolver provides XDG Base Directory Specification
      # compliant directory resolution for cache and data storage.
      # This atom has no dependencies on other parts of this gem.
      class XDGDirectoryResolver
        # Application name used in directory paths
        APP_NAME = "ace-llm"

        # Environment variable names
        XDG_CACHE_HOME = "XDG_CACHE_HOME"
        XDG_CONFIG_HOME = "XDG_CONFIG_HOME"
        XDG_DATA_HOME = "XDG_DATA_HOME"
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

        # Resolve XDG-compliant config directory path
        # @param env_reader [Hash, #[]] Environment variable source (defaults to ENV)
        # @return [String] Absolute path to config directory
        def self.config_directory(env_reader = ENV)
          xdg_config_home = env_reader[XDG_CONFIG_HOME]
          home_dir = env_reader[HOME]

          # Use XDG_CONFIG_HOME if set and non-empty
          config_base = if xdg_config_home && !xdg_config_home.strip.empty?
            File.expand_path(xdg_config_home.strip)
          elsif home_dir && !home_dir.strip.empty?
            # Fall back to ~/.config if HOME is available
            File.expand_path(".config", home_dir.strip)
          else
            # Last resort: use current directory
            File.expand_path(".config")
          end

          File.join(config_base, APP_NAME)
        end

        # Resolve XDG-compliant data directory path
        # @param env_reader [Hash, #[]] Environment variable source (defaults to ENV)
        # @return [String] Absolute path to data directory
        def self.data_directory(env_reader = ENV)
          xdg_data_home = env_reader[XDG_DATA_HOME]
          home_dir = env_reader[HOME]

          # Use XDG_DATA_HOME if set and non-empty
          data_base = if xdg_data_home && !xdg_data_home.strip.empty?
            File.expand_path(xdg_data_home.strip)
          elsif home_dir && !home_dir.strip.empty?
            # Fall back to ~/.local/share if HOME is available
            File.expand_path(".local/share", home_dir.strip)
          else
            # Last resort: use current directory
            File.expand_path(".local/share")
          end

          File.join(data_base, APP_NAME)
        end

        # Ensure directory exists with proper permissions
        # @param directory [String] Directory path
        # @param permissions [Integer] Directory permissions (default: 0700)
        # @return [String] The created directory path
        # @raise [SystemCallError] If directory cannot be created
        def self.ensure_directory(directory, permissions = DEFAULT_DIR_PERMISSIONS)
          FileUtils.mkdir_p(directory, mode: permissions)
          directory
        end

        # Get cache subdirectory path for specific cache type
        # @param cache_type [String] Type of cache (e.g., 'models', 'http', 'pricing')
        # @param env_reader [Hash, #[]] Environment variable source (defaults to ENV)
        # @return [String] Path to cache subdirectory
        def self.cache_subdirectory(cache_type, env_reader = ENV)
          base_cache_dir = cache_directory(env_reader)
          File.join(base_cache_dir, cache_type.to_s)
        end

        # Resolve and ensure cache subdirectory exists
        # @param cache_type [String] Type of cache
        # @param env_reader [Hash, #[]] Environment variable source (defaults to ENV)
        # @param permissions [Integer] Directory permissions (default: 0700)
        # @return [String] Path to existing cache subdirectory
        def self.ensure_cache_subdirectory(cache_type, env_reader = ENV, permissions = DEFAULT_DIR_PERMISSIONS)
          subdir_path = cache_subdirectory(cache_type, env_reader)
          ensure_directory(subdir_path, permissions)
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

        # Instance method to get config directory
        # @return [String] Config directory path
        def config_directory
          self.class.config_directory(@env_reader)
        end

        # Instance method to get data directory
        # @return [String] Data directory path
        def data_directory
          self.class.data_directory(@env_reader)
        end

        # Instance method to ensure directory exists
        # @param directory [String] Directory path
        # @param permissions [Integer] Directory permissions (default: 0700)
        # @return [String] The created directory path
        def ensure_directory(directory, permissions = DEFAULT_DIR_PERMISSIONS)
          self.class.ensure_directory(directory, permissions)
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
      end
    end
  end
end
