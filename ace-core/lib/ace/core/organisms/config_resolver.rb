# frozen_string_literal: true

require "fileutils"
require_relative "../molecules/yaml_loader"
require_relative "../molecules/config_finder"
require_relative "../atoms/deep_merger"
require_relative "../models/config"

module Ace
  module Core
    module Organisms
      # Complete configuration cascade resolution
      class ConfigResolver
        attr_reader :search_paths, :file_patterns, :merge_strategy

        # Initialize config resolver
        # @param search_paths [Array<String>] Paths to search for configs
        # @param file_patterns [Array<String>] Patterns for config files
        # @param merge_strategy [Symbol] How to merge arrays
        def initialize(search_paths: nil, file_patterns: nil, merge_strategy: :replace)
          @search_paths = search_paths || Molecules::ConfigFinder::DEFAULT_SEARCH_PATHS
          @file_patterns = file_patterns || Molecules::ConfigFinder::DEFAULT_FILE_PATTERNS
          @merge_strategy = merge_strategy
        end

        # Resolve configuration cascade
        # @return [Models::Config] Merged configuration
        def resolve
          finder = Molecules::ConfigFinder.new(
            search_paths: search_paths,
            file_patterns: file_patterns
          )

          cascade_paths = finder.find_all.select(&:exists)

          if cascade_paths.empty?
            return Models::Config.new({}, source: "defaults", merge_strategy: merge_strategy)
          end

          # Load all configs in cascade order
          configs = cascade_paths.map do |cascade_path|
            Molecules::YamlLoader.load_file(cascade_path.path)
          end

          # Merge in reverse order (lowest priority first)
          merged_data = configs.reverse.reduce({}) do |result, config|
            Atoms::DeepMerger.merge(
              result,
              config.data,
              array_strategy: merge_strategy
            )
          end

          sources = cascade_paths.map(&:path).join(" -> ")
          Models::Config.new(
            merged_data,
            source: sources,
            merge_strategy: merge_strategy
          )
        end

        # Resolve and get value by key path
        # @param keys [Array<String,Symbol>] Key path
        # @return [Object] Value at key path
        def get(*keys)
          config = resolve
          config.get(*keys)
        end

        # Resolve configuration for a specific namespace
        # @param namespace [String] Namespace name (e.g., "git", "llm", "test")
        # @param file [String, nil] Specific file within namespace (e.g., "runner" for test/runner.yml)
        # @return [Models::Config] Resolved configuration
        def resolve_namespace(namespace, file: nil)
          # Determine file pattern based on namespace and file
          namespace_patterns = determine_namespace_patterns(namespace, file)

          # Create finder with namespace-specific patterns
          finder = Molecules::ConfigFinder.new(
            search_paths: search_paths,
            file_patterns: namespace_patterns
          )

          cascade_paths = finder.find_all.select(&:exists)

          if cascade_paths.empty?
            return Models::Config.new({}, source: "#{namespace}_defaults", merge_strategy: merge_strategy)
          end

          # Load and merge configs
          configs = cascade_paths.map do |cascade_path|
            Molecules::YamlLoader.load_file(cascade_path.path)
          end

          merged_data = configs.reverse.reduce({}) do |result, config|
            Atoms::DeepMerger.merge(
              result,
              config.data,
              array_strategy: merge_strategy
            )
          end

          sources = cascade_paths.map(&:path).join(" -> ")
          Models::Config.new(
            merged_data,
            source: sources,
            merge_strategy: merge_strategy
          )
        end

        private

        # Determine file patterns for a namespace
        # @param namespace [String] Namespace name
        # @param file [String, nil] Specific file name
        # @return [Array<String>] File patterns to search for
        def determine_namespace_patterns(namespace, file)
          case namespace
          when "core"
            ["core/settings.yml", "core/settings.yaml"]
          when "llm"
            ["llm/query.yml", "llm/query.yaml"]
          when "git"
            ["git/commit.yml", "git/commit.yaml"]
          when "test"
            if file
              ["test/#{file}.yml", "test/#{file}.yaml"]
            else
              ["test/*.yml", "test/*.yaml"]
            end
          else
            if file
              ["#{namespace}/#{file}.yml", "#{namespace}/#{file}.yaml"]
            else
              ["#{namespace}/config.yml", "#{namespace}/config.yaml"]
            end
          end
        end

        # Find config files
        # @return [Array<Models::CascadePath>] All potential config paths
        def find_configs
          finder = Molecules::ConfigFinder.new(
            search_paths: search_paths,
            file_patterns: file_patterns
          )
          finder.find_all
        end

        # Get config from specific type
        # @param type [Symbol] Config type (:local, :home, :gem)
        # @return [Models::Config, nil] Config from that type
        def resolve_type(type)
          finder = Molecules::ConfigFinder.new(
            search_paths: search_paths,
            file_patterns: file_patterns
          )

          paths = finder.find_by_type(type).select(&:exists)
          return nil if paths.empty?

          # Merge configs of same type
          configs = paths.map do |path|
            Molecules::YamlLoader.load_file(path.path)
          end

          merged_data = configs.reduce({}) do |result, config|
            Atoms::DeepMerger.merge(
              result,
              config.data,
              array_strategy: merge_strategy
            )
          end

          Models::Config.new(
            merged_data,
            source: "#{type}_configs",
            merge_strategy: merge_strategy
          )
        end

        # Create default config structure
        # @param path [String] Where to create config
        # @return [Models::Config] Created configuration
        def self.create_default(path = "./.ace/settings.yml")
          default_config = {
            "ace" => {
              "version" => VERSION,
              "config_cascade" => {
                "enabled" => true,
                "search_paths" => ["./.ace", "~/.ace"],
                "merge_strategy" => "deep"
              },
              "environment" => {
                "load_dotenv" => true,
                "dotenv_files" => [".env.local", ".env"]
              }
            }
          }

          # Ensure directory exists
          dir = File.dirname(path)
          FileUtils.mkdir_p(dir)

          # Save config
          config = Models::Config.new(default_config, source: path)
          Molecules::YamlLoader.save_file(config, path)

          config
        end
      end
    end
  end
end