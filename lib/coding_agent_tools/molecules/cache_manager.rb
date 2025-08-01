# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'json'
require_relative '../atoms/xdg_directory_resolver'

module CodingAgentTools
  module Molecules
    # CacheManager is a molecule that provides XDG-compliant cache management
    # with backward compatibility and migration support for existing cache data.
    # This molecule uses the XDGDirectoryResolver atom for path resolution.
    class CacheManager
      # Legacy cache directory (for backward compatibility)
      LEGACY_CACHE_DIR = '~/.coding-agent-tools-cache'

      # Migration marker file
      MIGRATION_MARKER = '.migration_complete'

      # Default cache subdirectories
      DEFAULT_CACHE_TYPES = %w[models http temp].freeze

      attr_reader :xdg_resolver, :legacy_cache_path, :migration_completed

      # Initialize cache manager
      # @param xdg_resolver [XDGDirectoryResolver] XDG directory resolver (optional)
      # @param env_reader [Hash, #[]] Environment variable source (defaults to ENV)
      def initialize(xdg_resolver: nil, env_reader: ENV)
        @xdg_resolver = xdg_resolver || CodingAgentTools::Atoms::XDGDirectoryResolver.new(env_reader)
        @legacy_cache_path = File.expand_path(LEGACY_CACHE_DIR)
        @migration_completed = false

        # Perform initial setup
        ensure_cache_structure
        check_migration_status
      end

      # Get cache directory path (XDG-compliant or legacy for compatibility)
      # @return [String] Cache directory path
      def cache_directory
        if use_legacy_cache?
          @legacy_cache_path
        else
          @xdg_resolver.cache_directory
        end
      end

      # Get cache file path for specific provider/type
      # @param filename [String] Cache filename (e.g., "google_models.yml")
      # @param subdirectory [String, nil] Optional subdirectory (e.g., "models")
      # @return [String] Full path to cache file
      def cache_file_path(filename, subdirectory: nil)
        if subdirectory
          cache_subdir = cache_subdirectory(subdirectory)
          File.join(cache_subdir, filename)
        else
          File.join(cache_directory, filename)
        end
      end

      # Get cache subdirectory path
      # @param cache_type [String] Type of cache (e.g., 'models', 'http', 'temp')
      # @return [String] Path to cache subdirectory
      def cache_subdirectory(cache_type)
        if use_legacy_cache?
          # Legacy cache doesn't use subdirectories
          @legacy_cache_path
        else
          @xdg_resolver.cache_subdirectory(cache_type)
        end
      end

      # Check if cache file exists
      # @param filename [String] Cache filename
      # @param subdirectory [String, nil] Optional subdirectory
      # @return [Boolean] True if cache file exists
      def cache_exists?(filename, subdirectory: nil)
        File.exist?(cache_file_path(filename, subdirectory: subdirectory))
      end

      # Write data to cache file
      # @param filename [String] Cache filename
      # @param data [Object] Data to cache (will be serialized as YAML)
      # @param subdirectory [String, nil] Optional subdirectory
      # @return [String] Path to written cache file
      def write_cache(filename, data, subdirectory: nil)
        file_path = cache_file_path(filename, subdirectory: subdirectory)

        # Ensure directory exists
        dir_path = File.dirname(file_path)
        FileUtils.mkdir_p(dir_path) unless File.directory?(dir_path)

        # Write cache data
        File.write(file_path, YAML.dump(data))
        file_path
      end

      # Read data from cache file
      # @param filename [String] Cache filename
      # @param subdirectory [String, nil] Optional subdirectory
      # @return [Object, nil] Cached data or nil if file doesn't exist
      def read_cache(filename, subdirectory: nil)
        file_path = cache_file_path(filename, subdirectory: subdirectory)
        return nil unless File.exist?(file_path)

        begin
          YAML.load_file(file_path)
        rescue StandardError => e
          # Handle corrupted cache files gracefully
          warn "Warning: Failed to read cache file #{file_path}: #{e.message}"
          nil
        end
      end

      # Delete cache file
      # @param filename [String] Cache filename
      # @param subdirectory [String, nil] Optional subdirectory
      # @return [Boolean] True if file was deleted or didn't exist
      def delete_cache(filename, subdirectory: nil)
        file_path = cache_file_path(filename, subdirectory: subdirectory)
        return true unless File.exist?(file_path)

        File.delete(file_path)
        true
      rescue StandardError => e
        warn "Warning: Failed to delete cache file #{file_path}: #{e.message}"
        false
      end

      # Clear all cache data
      # @param confirm [Boolean] Require confirmation for safety
      # @return [Boolean] True if cache was cleared
      def clear_cache(confirm: false)
        return false unless confirm

        cache_dir = cache_directory
        return true unless File.directory?(cache_dir)

        FileUtils.rm_rf(cache_dir)
        ensure_cache_structure
        true
      rescue StandardError => e
        warn "Warning: Failed to clear cache: #{e.message}"
        false
      end

      # Migrate cache data from legacy location to XDG-compliant location
      # @param force [Boolean] Force migration even if already completed
      # @return [Boolean] True if migration was successful or not needed
      def migrate_cache_data(force: false)
        return true if @migration_completed && !force
        return true unless File.directory?(@legacy_cache_path)

        xdg_cache_dir = @xdg_resolver.cache_directory

        # Skip if XDG directory already exists and migration marker present
        if !force && File.directory?(xdg_cache_dir) && migration_marker_exists?
          @migration_completed = true
          return true
        end

        begin
          perform_migration(@legacy_cache_path, xdg_cache_dir)
          create_migration_marker
          @migration_completed = true
          true
        rescue StandardError => e
          warn "Error: Cache migration failed: #{e.message}"
          false
        end
      end

      # Get cache information and statistics
      # @return [Hash] Cache information
      def cache_info
        legacy_exists = File.directory?(@legacy_cache_path)
        xdg_dir = @xdg_resolver.cache_directory
        xdg_exists = File.directory?(xdg_dir)

        {
          current_cache_directory: cache_directory,
          uses_legacy_cache: use_legacy_cache?,
          legacy_cache_exists: legacy_exists,
          xdg_cache_exists: xdg_exists,
          migration_completed: @migration_completed,
          cache_size: calculate_cache_size,
          xdg_info: @xdg_resolver.cache_directory_info
        }
      end

      # Show deprecation warning for legacy cache usage
      def show_deprecation_warning
        return unless use_legacy_cache?

        warn <<~WARNING
          DEPRECATION WARNING: Using legacy cache directory #{@legacy_cache_path}
          Consider migrating to XDG-compliant cache location: #{@xdg_resolver.cache_directory}
          Run your command with --migrate-cache flag to migrate data automatically.
          Support for legacy cache location will be removed in a future version.
        WARNING
      end

      private

      # Check if we should use legacy cache directory
      # @return [Boolean] True if legacy cache should be used
      def use_legacy_cache?
        # Use legacy cache if it exists and migration hasn't been completed
        File.directory?(@legacy_cache_path) && !@migration_completed
      end

      # Ensure cache directory structure exists
      def ensure_cache_structure
        if use_legacy_cache?
          # Legacy cache uses flat structure
          FileUtils.mkdir_p(@legacy_cache_path) unless File.directory?(@legacy_cache_path)
        else
          # XDG cache uses subdirectory structure
          @xdg_resolver.ensure_cache_directory
          DEFAULT_CACHE_TYPES.each do |cache_type|
            @xdg_resolver.ensure_cache_subdirectory(cache_type)
          end
        end
      end

      # Check if migration has been completed
      def check_migration_status
        @migration_completed = migration_marker_exists?
      end

      # Check if migration marker file exists
      # @return [Boolean] True if migration marker exists
      def migration_marker_exists?
        xdg_cache_dir = @xdg_resolver.cache_directory
        return false unless File.directory?(xdg_cache_dir)

        marker_path = File.join(xdg_cache_dir, MIGRATION_MARKER)
        File.exist?(marker_path)
      end

      # Create migration marker file
      def create_migration_marker
        xdg_cache_dir = @xdg_resolver.cache_directory
        marker_path = File.join(xdg_cache_dir, MIGRATION_MARKER)

        marker_data = {
          migrated_at: Time.now.iso8601,
          legacy_cache_path: @legacy_cache_path,
          xdg_cache_path: xdg_cache_dir
        }

        File.write(marker_path, YAML.dump(marker_data))
      end

      # Perform actual cache migration
      # @param source_dir [String] Source directory path
      # @param target_dir [String] Target directory path
      def perform_migration(source_dir, target_dir)
        # Ensure target directory structure exists
        @xdg_resolver.ensure_cache_directory

        # Copy all files from legacy cache to models subdirectory
        models_subdir = @xdg_resolver.ensure_cache_subdirectory('models')

        Dir.glob(File.join(source_dir, '*')).each do |source_file|
          next unless File.file?(source_file)

          filename = File.basename(source_file)
          target_file = File.join(models_subdir, filename)

          # Copy file preserving timestamps
          FileUtils.cp(source_file, target_file, preserve: true)
        end

        puts "INFO: Migrated cache from #{source_dir} to #{target_dir}"
        puts 'INFO: Legacy cache preserved for safety'
      end

      # Calculate total cache size in bytes
      # @return [Integer] Cache size in bytes
      def calculate_cache_size
        cache_dir = cache_directory
        return 0 unless File.directory?(cache_dir)

        total_size = 0
        Dir.glob(File.join(cache_dir, '**', '*')).each do |file|
          total_size += File.size(file) if File.file?(file)
        end
        total_size
      end
    end
  end
end
