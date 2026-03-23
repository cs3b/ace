# frozen_string_literal: true

require_relative "../atoms/path_expander"

module Ace
  module Support
    module Fs
      module Molecules
        # Traverses directory tree to find configuration directories
        class DirectoryTraverser
          attr_reader :config_dir

          # Initialize traverser
          # @param config_dir [String] Name of config directory to find (default: ".ace")
          # @param start_path [String] Path to start traversal from
          def initialize(config_dir: ".ace", start_path: nil)
            @config_dir = config_dir
            @start_path = start_path ? Atoms::PathExpander.expand(start_path) : Dir.pwd
          end

          # Traverse from current directory up to project root or filesystem root
          # @return [Array<String>] Ordered list of directories containing config folders
          def traverse
            directories = []
            current_path = @start_path
            visited = Set.new

            # Find project root
            project_root = ProjectRootFinder.find(start_path: @start_path)

            # Traverse up from current directory
            loop do
              # Avoid infinite loops
              break if visited.include?(current_path)
              visited.add(current_path)

              # Check if config directory exists at this level
              config_path = File.join(current_path, @config_dir)
              directories << current_path if Dir.exist?(config_path)

              # Get parent directory
              parent = File.dirname(current_path)

              # Stop if we've reached filesystem root
              break if parent == current_path

              # Stop if we've gone past project root (if it exists)
              # We check after adding current_path to allow project root itself
              if project_root && current_path == project_root
                # Already processed project root, can stop
                break
              end

              current_path = parent
            end

            directories
          end

          # Find all config directories in the traversal path
          # @return [Array<String>] Full paths to config directories
          def find_config_directories
            traverse.map { |dir| File.join(dir, @config_dir) }
          end

          # Get the directory hierarchy from current to root
          # @return [Array<String>] All directories from current to project/filesystem root
          def directory_hierarchy
            hierarchy = []
            current_path = @start_path

            # Find project root
            project_root = ProjectRootFinder.find(start_path: @start_path)
            stop_at = project_root || "/"

            loop do
              hierarchy << current_path

              # Stop if we've reached our stopping point
              break if current_path == stop_at

              # Get parent directory
              parent = File.dirname(current_path)

              # Stop if we've reached filesystem root
              break if parent == current_path

              current_path = parent
            end

            hierarchy
          end

          # Build cascade paths with priorities
          # @return [Hash<String, Integer>] Map of directory paths to priorities
          def build_cascade_priorities
            priorities = {}
            directories = find_config_directories

            # Assign priorities - closer to cwd = higher priority (lower number)
            directories.each_with_index do |dir, index|
              priorities[dir] = index * 10
            end

            # Add home directory with lower priority
            home_config = File.expand_path("~/#{@config_dir}")
            if Dir.exist?(home_config) && !priorities.key?(home_config)
              priorities[home_config] = (directories.length + 1) * 10
            end

            priorities
          end
        end
      end
    end
  end
end
