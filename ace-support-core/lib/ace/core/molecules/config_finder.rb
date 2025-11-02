# frozen_string_literal: true

require_relative "../atoms/path_expander"
require_relative "../models/cascade_path"
require_relative "directory_traverser"
require_relative "project_root_finder"

module Ace
  module Core
    module Molecules
      # Find configuration files in cascade paths
      class ConfigFinder
        # Default search paths for configuration
        DEFAULT_SEARCH_PATHS = [
          "./.ace",
          "~/.ace"
        ].freeze

        # Common config file patterns
        DEFAULT_FILE_PATTERNS = [
          "settings.yml",
          "settings.yaml",
          "config.yml",      # backward compatibility
          "config.yaml"      # backward compatibility
        ].freeze

        # Initialize finder with search paths
        # @param search_paths [Array<String>] Paths to search
        # @param file_patterns [Array<String>] File patterns to look for
        # @param use_traversal [Boolean] Whether to use directory traversal (default: auto-detect)
        def initialize(search_paths: DEFAULT_SEARCH_PATHS,
                       file_patterns: DEFAULT_FILE_PATTERNS,
                       use_traversal: nil)
          @file_patterns = file_patterns

          # Auto-detect: use traversal only if using default search paths
          if use_traversal.nil?
            @use_traversal = (search_paths == DEFAULT_SEARCH_PATHS)
          else
            @use_traversal = use_traversal
          end

          if @use_traversal
            @search_paths = build_traversal_paths
          else
            @search_paths = search_paths.map { |p| Atoms::PathExpander.expand(p) }
          end
        end

        # Find all config files in cascade order
        # @return [Array<Models::CascadePath>] Found config paths
        def find_all
          paths = []

          @search_paths.each_with_index do |base_path, index|
            priority = index * 10  # Lower index = higher priority

            @file_patterns.each do |pattern|
              found = find_in_path(base_path, pattern, priority)
              paths.concat(found)
            end
          end

          # Add gem defaults with lowest priority
          gem_config = find_gem_config
          paths << gem_config if gem_config

          paths.sort
        end

        # Find first existing config file
        # @return [Models::CascadePath, nil] First found config path
        def find_first
          find_all.find(&:exists)
        end

        # Find configs by type
        # @param type [Symbol] Type to filter (:local, :home, :gem)
        # @return [Array<Models::CascadePath>] Configs of given type
        def find_by_type(type)
          find_all.select { |path| path.type == type }
        end

        # Find a specific config file using the cascade
        # @param filename [String] Specific filename to find
        # @return [String, nil] Path to the first found config file
        def find_file(filename)
          # Use traversal to find all possible locations
          traverser = DirectoryTraverser.new
          config_dirs = traverser.find_config_directories

          # Check each config directory in order (closest first)
          config_dirs.each do |dir|
            file_path = File.join(dir, filename)
            return file_path if File.exist?(file_path)
          end

          # Check home directory
          home_path = File.expand_path("~/.ace/#{filename}")
          return home_path if File.exist?(home_path)

          nil
        end

        # Find all instances of a config file in the cascade
        # @param filename [String] Specific filename to find
        # @return [Array<String>] All found file paths in cascade order
        def find_all_files(filename)
          files = []

          # Use traversal to find all possible locations
          traverser = DirectoryTraverser.new
          config_dirs = traverser.find_config_directories

          # Check each config directory
          config_dirs.each do |dir|
            file_path = File.join(dir, filename)
            files << file_path if File.exist?(file_path)
          end

          # Check home directory
          home_path = File.expand_path("~/.ace/#{filename}")
          files << home_path if File.exist?(home_path)

          files
        end

        # Get the search paths being used
        # @return [Array<String>] Ordered list of search paths
        def search_paths
          @search_paths
        end

        private

        # Build search paths using directory traversal
        # @return [Array<String>] Expanded search paths
        def build_traversal_paths
          traverser = DirectoryTraverser.new
          paths = traverser.find_config_directories

          # Add home directory if not already included
          home_config = File.expand_path("~/.ace")
          paths << home_config unless paths.include?(home_config)

          paths
        end

        # Find config files in a specific path with pattern
        # @param base_path [String] Base path to search
        # @param pattern [String] File pattern
        # @param base_priority [Integer] Base priority for found files
        # @return [Array<Models::CascadePath>] Found paths
        def find_in_path(base_path, pattern, base_priority)
          paths = []
          full_pattern = File.join(base_path, pattern)

          # Determine type based on path
          type = determine_type(base_path)

          Dir.glob(full_pattern).each_with_index do |file, index|
            next unless File.file?(file)

            paths << Models::CascadePath.new(
              path: file,
              priority: base_priority + index,
              exists: true,
              type: type
            )
          end

          # If no files found but we're looking for a specific file, add as missing
          if paths.empty? && !pattern.include?("*")
            file_path = File.join(base_path, pattern)
            paths << Models::CascadePath.new(
              path: file_path,
              priority: base_priority,
              exists: false,
              type: type
            )
          end

          paths
        end

        # Find gem's default config
        # @return [Models::CascadePath, nil] Gem config path
        def find_gem_config
          gem_root = File.expand_path("../../../..", __FILE__)
          config_path = File.join(gem_root, "config", "core.yml")

          if File.exist?(config_path)
            Models::CascadePath.new(
              path: config_path,
              priority: 1000,  # Lowest priority
              exists: true,
              type: :gem
            )
          end
        end

        # Determine config type from path
        # @param path [String] Path to check
        # @return [Symbol] Config type
        def determine_type(path)
          expanded = Atoms::PathExpander.expand(path)
          home = Atoms::PathExpander.expand("~")

          if expanded.start_with?(Dir.pwd)
            :local
          elsif expanded.start_with?(home)
            :home
          else
            :gem
          end
        end
      end
    end
  end
end