# frozen_string_literal: true

require_relative "../molecules/directory_traverser"
require_relative "../molecules/project_root_finder"

module Ace
  module Core
    module Organisms
      # Resolves configuration files using the ACE cascade system
      # Provides a virtual filesystem view where nearest config wins
      class VirtualConfigResolver
        attr_reader :start_path, :virtual_map

        def initialize(start_path: nil)
          @start_path = start_path || Dir.pwd
          @virtual_map = build_virtual_map
        end

        # Get absolute path for a relative config path
        # @param relative_path [String] Path relative to .ace directory
        # @return [String, nil] Absolute path to the file, or nil if not found
        def resolve_path(relative_path)
          normalized = normalize_path(relative_path)
          @virtual_map[normalized]
        end

        # Get all files matching a pattern
        # @param pattern [String] Glob pattern relative to .ace
        # @return [Hash<String, String>] Map of relative paths to absolute paths
        def glob(pattern)
          results = {}
          regex = glob_to_regex(pattern)

          @virtual_map.each do |relative_path, absolute_path|
            if relative_path.match?(regex)
              results[relative_path] = absolute_path
            end
          end

          results
        end

        # Check if a relative path exists in the virtual map
        # @param relative_path [String] Path relative to .ace directory
        # @return [Boolean]
        def exists?(relative_path)
          @virtual_map.key?(normalize_path(relative_path))
        end

        # Get all discovered .ace directories in priority order
        # @return [Array<String>] Paths to .ace directories (nearest first)
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

          # Get all .ace directories in reverse order (farthest first)
          # so that nearer configs override farther ones
          dirs = discover_config_directories.reverse

          dirs.each do |ace_dir|
            next unless Dir.exist?(ace_dir)

            # Find all files under this .ace directory
            Dir.glob(File.join(ace_dir, "**", "*")).each do |file_path|
              next unless File.file?(file_path)

              # Get path relative to .ace directory
              relative_path = file_path.sub("#{ace_dir}/", "")

              # Store in map (later entries override earlier ones)
              map[relative_path] = file_path
            end
          end

          map
        end

        def discover_config_directories
          dirs = []

          # Use DirectoryTraverser to find all .ace directories
          traverser = Molecules::DirectoryTraverser.new(
            config_dir_name: ".ace",
            start_path: @start_path
          )

          # Get config directories from current to project root
          dirs = traverser.find_config_directories

          # Add user home .ace if it exists and not already included
          home_ace = File.expand_path("~/.ace")
          if Dir.exist?(home_ace) && !dirs.include?(home_ace)
            dirs << home_ace
          end

          dirs
        end

        def normalize_path(path)
          # Remove leading ./ or .ace/ if present
          path = path.to_s
          path = path.sub(/^\.\//, "")
          path = path.sub(/^\.ace\//, "")
          path
        end

        def glob_to_regex(pattern)
          # Convert glob pattern to regex
          # This is a simplified implementation
          regex_str = pattern
            .gsub(".", "\\.")           # Escape dots
            .gsub("**", "___STARSTAR___") # Temporarily replace **
            .gsub("*", "[^/]*")         # * matches anything except /
            .gsub("___STARSTAR___", ".*") # ** matches anything including /
            .gsub("?", ".")             # ? matches single character

          Regexp.new("^#{regex_str}$")
        end
      end
    end
  end
end