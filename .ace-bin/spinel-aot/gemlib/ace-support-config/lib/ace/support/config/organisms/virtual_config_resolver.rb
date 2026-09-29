# frozen_string_literal: true

module Ace
  module Support
    module Config
      module Organisms
        # Resolves configuration files using a cascade system
        # Provides a virtual filesystem view where nearest config wins
        class VirtualConfigResolver
          attr_reader :start_path, :virtual_map, :config_dir, :defaults_dir, :gem_path

          # Initialize with configurable folder names
          # @param config_dir [String] Config folder name (default: ".ace")
          # @param defaults_dir [String] Defaults folder name (default: ".ace-defaults")
          # @param start_path [String, nil] Starting path for traversal
          # @param gem_path [String, nil] Gem root path for defaults (lowest priority)
          def initialize(config_dir: ".ace", defaults_dir: ".ace-defaults", start_path: nil, gem_path: nil)
            @config_dir = config_dir
            @defaults_dir = defaults_dir
            @start_path = start_path || Dir.pwd
            @gem_path = gem_path
            @virtual_map = build_virtual_map
          end

          # Get absolute path for a relative config path
          # @param relative_path [String] Path relative to config directory
          # @return [String, nil] Absolute path to the file, or nil if not found
          def resolve_path(relative_path)
            normalized = normalize_path(relative_path)
            @virtual_map[normalized]
          end

          # Get all files matching a pattern
          # @param pattern [String] Glob pattern relative to config dir
          # @return [Hash<String, String>] Map of relative paths to absolute paths
          def glob(pattern)
            results = {}

            @virtual_map.each do |relative_path, absolute_path|
              # FNM_PATHNAME ensures * doesn't match /
              # FNM_DOTMATCH ensures hidden files are matched if pattern starts with .
              if File.fnmatch?(pattern, relative_path, File::FNM_PATHNAME | File::FNM_DOTMATCH)
                results[relative_path] = absolute_path
              end
            end

            results
          end

          # Check if a relative path exists in the virtual map
          # @param relative_path [String] Path relative to config directory
          # @return [Boolean]
          def exists?(relative_path)
            @virtual_map.key?(normalize_path(relative_path))
          end

          # Get all discovered config directories in priority order
          # @return [Array<String>] Paths to config directories (nearest first)
          def config_directories
            @config_directories ||= discover_config_directories
          end

          # Reload the virtual map (useful if config files change)
          def reload!
            @virtual_map = build_virtual_map
            @config_directories = nil
          end

          private

          def build_virtual_map
            map = {}

            # Get all config directories in reverse order (farthest first)
            # so that nearer configs override farther ones
            dirs = discover_config_directories.reverse

            dirs.each do |config_directory|
              next unless Dir.exist?(config_directory)

              # Get absolute path of config directory for validation
              config_dir_abs = File.expand_path(config_directory)

              # Find all files under this config directory
              Dir.glob(File.join(config_directory, "**", "*")).each do |file_path|
                next unless File.file?(file_path)

                # Validate path stays within config directory (prevent traversal)
                file_abs = File.expand_path(file_path)
                next unless file_abs.start_with?(config_dir_abs + File::SEPARATOR) ||
                  file_abs == config_dir_abs

                # Get path relative to config directory
                relative_path = file_abs.sub("#{config_dir_abs}/", "")

                # Store in map (later entries override earlier ones)
                map[relative_path] = file_path
              end
            end

            map
          end

          def discover_config_directories
            # Use DirectoryTraverser to find all config directories
            traverser = Ace::Support::Fs::Molecules::DirectoryTraverser.new(
              config_dir: @config_dir,
              start_path: @start_path
            )

            # Get config directories from current to project root
            dirs = traverser.find_config_directories

            # Add user home config if it exists and not already included
            home_config = File.expand_path("~/#{@config_dir}")
            if Dir.exist?(home_config) && !dirs.include?(home_config)
              dirs << home_config
            end

            # Add gem defaults if gem_path is provided (lowest priority)
            if @gem_path
              gem_defaults = File.join(@gem_path, @defaults_dir)
              if Dir.exist?(gem_defaults) && !dirs.include?(gem_defaults)
                dirs << gem_defaults
              end
            end

            dirs
          end

          def normalize_path(path)
            # Remove leading ./ or config_dir/ if present
            path = path.to_s
            path = path.sub(/^\.\//, "")
            path.sub(/^#{Regexp.escape(@config_dir)}\//, "")
          end
        end
      end
    end
  end
end
