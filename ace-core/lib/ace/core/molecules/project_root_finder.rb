# frozen_string_literal: true

require_relative "../atoms/path_expander"
require 'pathname'

module Ace
  module Core
    module Molecules
      # Find project root directory based on markers
      class ProjectRootFinder
        # Common project root markers in order of preference
        PROJECT_MARKERS = [
          ".git",           # Git repository
          "Gemfile",        # Ruby project
          "package.json",   # Node.js project
          "Cargo.toml",     # Rust project
          "pyproject.toml", # Python project
          "go.mod",         # Go project
          ".hg",            # Mercurial repository
          ".svn",           # Subversion repository
          "Rakefile",       # Ruby project with rake
          "Makefile"        # Make-based project
        ].freeze

        # Cache for project root detection
        @@cache = {}

        # Initialize finder with optional custom markers
        # @param markers [Array<String>] Project root markers to look for
        # @param start_path [String] Path to start searching from (default: current directory)
        def initialize(markers: PROJECT_MARKERS, start_path: nil)
          @markers = markers
          @start_path = start_path ? Atoms::PathExpander.expand(start_path) : Dir.pwd
        end

        # Find project root directory with caching
        # @return [String, nil] Project root path or nil if not found
        def find
          # Check environment variable first
          if ENV['PROJECT_ROOT_PATH'] && !ENV['PROJECT_ROOT_PATH'].empty?
            project_root = Atoms::PathExpander.expand(ENV['PROJECT_ROOT_PATH'])
            return project_root if Dir.exist?(project_root)
          end

          cache_key = "#{@start_path}:#{@markers.join(',')}"

          # Return cached result if available
          return @@cache[cache_key] if @@cache.key?(cache_key)

          # Find and cache the result
          result = find_without_cache
          @@cache[cache_key] = result
          result
        end

        # Find project root or fall back to current directory
        # @return [String] Project root path or current directory
        def find_or_current
          find || Dir.pwd
        end

        # Check if we're in a project directory
        # @return [Boolean] true if project root is found
        def in_project?
          !find.nil?
        end

        # Get the relative path from project root to a given path
        # @param path [String] Path to make relative
        # @return [String, nil] Relative path or nil if not in project
        def relative_path(path)
          root = find
          return nil unless root

          # Use realpath to handle symlinks and resolve paths
          real_root = File.realpath(root)
          real_path = File.realpath(Atoms::PathExpander.expand(path))

          return nil unless real_path.start_with?(real_root)

          Pathname.new(real_path).relative_path_from(Pathname.new(real_root)).to_s
        end

        # Clear the cache
        def self.clear_cache!
          @@cache.clear
        end

        # Class method for convenience
        # @return [String, nil] Project root path
        def self.find(start_path: nil, markers: PROJECT_MARKERS)
          # Check environment variable first for quick return
          if ENV['PROJECT_ROOT_PATH'] && !ENV['PROJECT_ROOT_PATH'].empty?
            project_root = File.expand_path(ENV['PROJECT_ROOT_PATH'])
            return project_root if Dir.exist?(project_root)
          end

          new(start_path: start_path, markers: markers).find
        end

        # Class method to find or use current directory
        # @return [String] Project root path or current directory
        def self.find_or_current(start_path: nil, markers: PROJECT_MARKERS)
          # Check environment variable first for quick return
          if ENV['PROJECT_ROOT_PATH'] && !ENV['PROJECT_ROOT_PATH'].empty?
            project_root = File.expand_path(ENV['PROJECT_ROOT_PATH'])
            return project_root if Dir.exist?(project_root)
          end

          new(start_path: start_path, markers: markers).find_or_current
        end

        private

        # Find project root without using cache
        # @return [String, nil] Project root path or nil if not found
        def find_without_cache
          path = @start_path

          # Traverse up the directory tree
          loop do
            # Check for any marker in current directory
            @markers.each do |marker|
              marker_path = File.join(path, marker)
              return path if File.exist?(marker_path)
            end

            # Get parent directory
            parent = File.dirname(path)

            # Stop if we've reached the filesystem root
            break if parent == path

            path = parent
          end

          nil
        end
      end
    end
  end
end