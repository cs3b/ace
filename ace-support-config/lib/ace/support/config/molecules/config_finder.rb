# frozen_string_literal: true

module Ace
  module Support
    module Config
      module Molecules
        # Find configuration files in cascade paths
        class ConfigFinder
          # Common config file patterns
          DEFAULT_FILE_PATTERNS = %w[
            settings.yml
            settings.yaml
            config.yml
            config.yaml
          ].freeze

          attr_reader :config_dir, :defaults_dir, :gem_path, :file_patterns, :start_path

          # Initialize finder with configurable paths
          # @param config_dir [String] User config folder name (default: ".ace")
          # @param defaults_dir [String] Gem defaults folder name (default: ".ace-defaults")
          # @param gem_path [String, nil] Gem root path for defaults
          # @param file_patterns [Array<String>] File patterns to look for
          # @param use_traversal [Boolean] Whether to use directory traversal (default: true)
          # @param start_path [String, nil] Starting path for traversal (default: Dir.pwd)
          def initialize(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: nil,
            file_patterns: DEFAULT_FILE_PATTERNS,
            use_traversal: true,
            start_path: nil
          )
            @config_dir = config_dir
            @defaults_dir = defaults_dir
            @gem_path = gem_path
            @file_patterns = file_patterns
            @use_traversal = use_traversal
            @start_path = start_path ? Ace::Support::Fs::Atoms::PathExpander.expand(start_path) : Dir.pwd
            @search_paths = build_search_paths
          end

          # Find all config files in cascade order
          # @return [Array<Models::CascadePath>] Found config paths
          def find_all
            paths = []

            @search_paths.each_with_index do |base_path, index|
              priority = index * 10 # Lower index = higher priority

              @file_patterns.each do |pattern|
                found = find_in_path(base_path, pattern, priority)
                paths.concat(found)
              end
            end

            # Add gem defaults with lowest priority
            gem_config = find_gem_defaults
            paths.concat(gem_config) if gem_config

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
            # Use pre-built search_paths (respects @use_traversal setting)
            @search_paths.each do |dir|
              file_path = File.join(dir, filename)
              return file_path if File.exist?(file_path)
            end

            # Check gem defaults if available
            if @gem_path
              gem_default_path = File.join(@gem_path, @defaults_dir, filename)
              return gem_default_path if File.exist?(gem_default_path)
            end

            nil
          end

          # Find all instances of a config file in the cascade
          # @param filename [String] Specific filename to find
          # @return [Array<String>] All found file paths in cascade order
          def find_all_files(filename)
            files = []

            # Use pre-built search_paths (respects @use_traversal setting)
            @search_paths.each do |dir|
              file_path = File.join(dir, filename)
              files << file_path if File.exist?(file_path)
            end

            # Check gem defaults if available
            if @gem_path
              gem_default_path = File.join(@gem_path, @defaults_dir, filename)
              files << gem_default_path if File.exist?(gem_default_path)
            end

            files
          end

          # Get the search paths being used
          # @return [Array<String>] Ordered list of search paths
          attr_reader :search_paths

          private

          # Build search paths using directory traversal
          # @return [Array<String>] Expanded search paths
          def build_search_paths
            if @use_traversal
              traverser = Ace::Support::Fs::Molecules::DirectoryTraverser.new(
                config_dir: @config_dir,
                start_path: @start_path
              )
              paths = traverser.find_config_directories

              # Add home directory if not already included
              home_config = File.expand_path("~/#{@config_dir}")
              paths << home_config unless paths.include?(home_config)

              paths
            else
              # Simple default paths
              [
                File.join(@start_path, @config_dir),
                File.expand_path("~/#{@config_dir}")
              ]
            end
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

          # Find gem's default configs
          # @return [Array<Models::CascadePath>] Gem default paths
          def find_gem_defaults
            return nil unless @gem_path

            defaults_path = File.join(@gem_path, @defaults_dir)
            return nil unless Dir.exist?(defaults_path)

            paths = []

            @file_patterns.each_with_index do |pattern, index|
              Dir.glob(File.join(defaults_path, pattern)).each do |file|
                next unless File.file?(file)

                paths << Models::CascadePath.new(
                  path: file,
                  priority: 2000 + index, # Very low priority for gem defaults
                  exists: true,
                  type: :gem
                )
              end
            end

            paths.empty? ? nil : paths
          end

          # Determine config type from path
          # @param path [String] Path to check
          # @return [Symbol] Config type
          def determine_type(path)
            expanded = Ace::Support::Fs::Atoms::PathExpander.expand(path)
            home = Ace::Support::Fs::Atoms::PathExpander.expand("~")

            # Use @start_path (stable) instead of Dir.pwd (mutable)
            if expanded.start_with?(@start_path)
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
end
