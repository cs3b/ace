# frozen_string_literal: true

require "pathname"
require_relative "../atoms/path_expander"

module Ace
  module Support
    module Fs
      module Molecules
        # Find project root directory based on markers
        class ProjectRootFinder
          # Common project root markers in order of preference
          DEFAULT_MARKERS = %w[
            .git
            Gemfile
            package.json
            Cargo.toml
            pyproject.toml
            go.mod
            .hg
            .svn
            Rakefile
            Makefile
          ].freeze

          # Thread-safe cache for project root detection
          @cache = {}
          @cache_mutex = Mutex.new

          class << self
            attr_reader :cache_mutex

            def cache
              @cache ||= {}
            end
          end

          # Initialize finder with optional custom markers
          # @param markers [Array<String>] Project root markers to look for
          # @param start_path [String] Path to start searching from (default: current directory)
          # @raise [ArgumentError] if markers is nil or empty
          def initialize(markers: DEFAULT_MARKERS, start_path: nil)
            if markers.nil? || markers.empty?
              raise ArgumentError, "markers cannot be nil or empty"
            end
            @markers = markers
            @start_path = start_path ? Atoms::PathExpander.expand(start_path) : Dir.pwd
          end

          # Find project root directory with caching
          # @return [String, nil] Project root path or nil if not found
          def find
            # Check environment variable first
            project_root_env = env_project_root
            if project_root_env && !project_root_env.empty?
              project_root = Atoms::PathExpander.expand(project_root_env)
              if Dir.exist?(project_root) && path_within_root?(@start_path, project_root)
                return project_root
              end
            end

            cache_key = "#{@start_path}:#{@markers.join(",")}"

            # Thread-safe cache access
            self.class.cache_mutex.synchronize do
              # Return cached result if available
              return self.class.cache[cache_key] if self.class.cache.key?(cache_key)

              # Find and cache the result
              result = find_without_cache
              self.class.cache[cache_key] = result
              result
            end
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

          # Clear the cache (thread-safe)
          def self.clear_cache!
            cache_mutex.synchronize do
              cache.clear
            end
          end

          # Class method for convenience
          # @return [String, nil] Project root path
          def self.find(start_path: nil, markers: DEFAULT_MARKERS)
            new(start_path: start_path, markers: markers).find
          end

          # Class method to find or use current directory
          # @return [String] Project root path or current directory
          def self.find_or_current(start_path: nil, markers: DEFAULT_MARKERS)
            new(start_path: start_path, markers: markers).find_or_current
          end

          protected

          # Access PROJECT_ROOT_PATH environment variable
          # Extracted to allow test stubbing without modifying global ENV
          def env_project_root
            ENV["PROJECT_ROOT_PATH"]
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

          def path_within_root?(candidate_path, root_path)
            candidate = File.expand_path(candidate_path)
            root = File.expand_path(root_path)
            candidate == root || candidate.start_with?("#{root}/")
          end
        end
      end
    end
  end
end
