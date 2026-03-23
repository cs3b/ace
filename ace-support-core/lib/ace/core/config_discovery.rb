# frozen_string_literal: true

require "ace/support/config"
require "ace/support/fs"

module Ace
  module Core
    # Public API for configuration discovery across the project hierarchy
    # Wraps ace-config with ace-specific defaults (.ace config directory)
    class ConfigDiscovery
      attr_reader :start_path

      # Initialize config discovery
      # @param start_path [String] Starting path for discovery (default: current directory)
      def initialize(start_path: nil)
        @start_path = start_path || Dir.pwd
        @finder = ::Ace::Support::Config::Molecules::ConfigFinder.new(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          use_traversal: true,
          start_path: @start_path
        )
      end

      # Find the first matching config file in the cascade
      # @param filename [String] Config filename to find
      # @return [String, nil] Path to the config file or nil if not found
      def find_config_file(filename)
        @finder.find_file(filename)
      end

      # Find all matching config files in cascade order
      # @param filename [String] Config filename to find
      # @return [Array<String>] All matching file paths in priority order
      def find_all_config_files(filename)
        @finder.find_all_files(filename)
      end

      # Get the project root directory
      # @return [String, nil] Project root path or nil if not in a project
      def project_root
        ::Ace::Support::Fs::Molecules::ProjectRootFinder.find(start_path: @start_path)
      end

      # Check if we're in a project
      # @return [Boolean] true if project root is found
      def in_project?
        !project_root.nil?
      end

      # Get all configuration search paths in order
      # @return [Array<String>] Ordered list of config directories being searched
      def config_search_paths
        @finder.search_paths
      end

      # Get relative path from project root
      # @param path [String] Path to make relative
      # @return [String, nil] Relative path or nil if not in project
      def relative_path(path)
        root = project_root
        return nil unless root

        expanded = File.expand_path(path)
        return nil unless expanded.start_with?(root)

        require "pathname"
        Pathname.new(expanded).relative_path_from(Pathname.new(root)).to_s
      end

      # Load configuration from the cascade for a specific file
      # @param filename [String] Config file to load
      # @param resolve_paths [Boolean] Whether to resolve relative paths (default: true)
      # @return [Hash, nil] Merged configuration or nil if no files found
      def load_config(filename, resolve_paths: true)
        files = find_all_config_files(filename)
        return nil if files.empty?

        require "yaml"
        config = {}

        # Load in reverse order so higher priority overwrites lower
        files.reverse_each do |file|
          file_config = YAML.load_file(file)
          if file_config.is_a?(Hash)
            # Resolve relative paths if requested
            if resolve_paths
              base_dir = File.dirname(file)
              # Determine project root for resolving plain paths
              proj_root = project_root
              file_config = resolve_relative_paths(file_config, base_dir, proj_root)
            end
            config = ::Ace::Support::Config::Atoms::DeepMerger.merge(config, file_config)
          end
        rescue => e
          warn "Error loading config from #{file}: #{e.message}"
        end

        config
      end

      # Class method shortcuts
      class << self
        # Find a config file from current directory
        # @param filename [String] Config filename to find
        # @return [String, nil] Path to config file
        def find(filename)
          new.find_config_file(filename)
        end

        # Find all config files from current directory
        # @param filename [String] Config filename to find
        # @return [Array<String>] All matching file paths
        def find_all(filename)
          new.find_all_config_files(filename)
        end

        # Get project root from current directory
        # @return [String, nil] Project root path
        def project_root
          new.project_root
        end

        # Load merged configuration
        # @param filename [String] Config file to load
        # @return [Hash, nil] Merged configuration
        def load(filename)
          new.load_config(filename)
        end
      end

      private

      # Recursively resolve relative paths in a configuration structure
      # @param obj [Object] Configuration object (hash, array, or value)
      # @param base_dir [String] Base directory to resolve paths against
      # @param project_root [String] Project root directory for plain paths
      # @return [Object] Configuration with resolved paths
      def resolve_relative_paths(obj, base_dir, project_root = nil)
        case obj
        when Hash
          obj.transform_values { |v| resolve_relative_paths(v, base_dir, project_root) }
        when Array
          obj.map { |v| resolve_relative_paths(v, base_dir, project_root) }
        when String
          # Check if this looks like a relative path with dots
          if obj.start_with?("./", "../")
            # Resolve relative to the config file's directory
            File.expand_path(File.join(base_dir, obj))
          elsif project_root && looks_like_project_path?(obj)
            # Plain paths that look like project directories/files
            # are resolved relative to project root
            File.join(project_root, obj)
          else
            obj
          end
        else
          obj
        end
      end

      # Check if a string looks like a project-relative path
      # @param str [String] String to check
      # @return [Boolean] true if it looks like a project path
      def looks_like_project_path?(str)
        # Don't treat absolute paths, URLs, or special values as project paths
        return false if str.start_with?("/", "http://", "https://", "~")
        return false if str.include?(":") # URLs, Windows paths

        # Check if it looks like a path (contains slash or common project directories)
        # or matches common project directory names
        str.include?("/") || str.match?(/^(ace-|lib|src|bin|test|spec|app|config|vendor|node_modules)/)
      end
    end
  end
end
