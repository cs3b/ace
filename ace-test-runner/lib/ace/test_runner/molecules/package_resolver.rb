# frozen_string_literal: true

require "pathname"
require "ace/support/fs"

module Ace
  module TestRunner
    module Molecules
      # Resolves package names or paths to absolute package directories
      # Supports: package name (ace-bundle), relative path (./ace-bundle), absolute path
      #
      # Note: This class depends on ace-support-fs which provides ProjectRootFinder.
      class PackageResolver
        # Initialize resolver
        # @param project_root [String, nil] Override project root (for testing)
        def initialize(project_root: nil)
          @project_root = project_root || Ace::Support::Fs::Molecules::ProjectRootFinder.find
        end

        # Resolve a package name or path to an absolute directory path
        # @param name_or_path [String] Package name, relative path, or absolute path
        # @return [String, nil] Absolute path to package directory, or nil if not found
        def resolve(name_or_path)
          return nil if name_or_path.nil? || name_or_path.empty?

          path = if absolute_path?(name_or_path)
            resolve_absolute(name_or_path)
          elsif relative_path?(name_or_path)
            resolve_relative(name_or_path)
          else
            resolve_by_name(name_or_path)
          end

          # Validate the resolved path has a test directory
          return nil unless path && valid_package?(path)

          path
        end

        # List all available packages in the mono-repo.
        # Results are memoized since filesystem glob operations are relatively expensive.
        # @return [Array<String>] List of package names
        def available_packages
          return [] unless @project_root

          @available_packages ||= Dir.glob(File.join(@project_root, "ace-*"))
            .select { |path| File.directory?(path) && has_test_directory?(path) }
            .map { |path| File.basename(path) }
            .sort
        end

        # Get the project root
        # @return [String, nil] Project root path
        attr_reader :project_root

        private

        def absolute_path?(path)
          path.start_with?("/")
        end

        def relative_path?(path)
          path == "." || path == ".." || path.start_with?("./") || path.start_with?("../")
        end

        def resolve_absolute(path)
          return nil unless Dir.exist?(path)

          File.realpath(path)
        end

        def resolve_relative(path)
          expanded = File.expand_path(path, Dir.pwd)
          return nil unless Dir.exist?(expanded)

          File.realpath(expanded)
        end

        def resolve_by_name(name)
          return nil unless @project_root

          # Try exact match first (ace-bundle)
          exact_path = File.join(@project_root, name)
          return File.realpath(exact_path) if Dir.exist?(exact_path)

          # Try with ace- prefix (bundle -> ace-bundle)
          prefixed_path = File.join(@project_root, "ace-#{name}")
          return File.realpath(prefixed_path) if Dir.exist?(prefixed_path)

          nil
        end

        def valid_package?(path)
          return false unless Dir.exist?(path)

          has_test_directory?(path)
        end

        def has_test_directory?(path)
          test_dir = File.join(path, "test")
          Dir.exist?(test_dir)
        end
      end
    end
  end
end
