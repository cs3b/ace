# frozen_string_literal: true

require_relative "../atoms/path_expander"
require_relative "../models/cascade_path"

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
        def initialize(search_paths: DEFAULT_SEARCH_PATHS,
                       file_patterns: DEFAULT_FILE_PATTERNS)
          @search_paths = search_paths.map { |p| Atoms::PathExpander.expand(p) }
          @file_patterns = file_patterns
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

        private

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