# frozen_string_literal: true

require "pathname"

module Ace
  module Git
    module Worktree
      module Atoms
        # Pure functions for path expansion and validation
        class PathExpander
          # Expand a path relative to a base directory
          # @param path [String] Path to expand (may contain ~, ./, ../, etc.)
          # @param base [String] Base directory for relative paths (default: current dir)
          # @return [String] Absolute expanded path
          def self.expand(path, base: Dir.pwd)
            return nil if path.nil? || path.empty?

            # Handle home directory expansion first
            expanded = path.start_with?("~") ? File.expand_path(path) : path

            # Convert to Pathname for easier manipulation
            pathname = Pathname.new(expanded)

            # If already absolute, return as-is
            return pathname.to_s if pathname.absolute?

            # Otherwise, make it relative to base
            base_path = Pathname.new(base)
            (base_path + pathname).cleanpath.to_s
          end

          # Validate that a path is safe (no traversal attacks)
          # @param path [String] Path to validate
          # @param allowed_root [String] Root directory that path must be within
          # @return [Boolean] true if path is safe
          def self.safe?(path, allowed_root:)
            return false if path.nil? || allowed_root.nil?

            expanded = expand(path)
            root = expand(allowed_root)

            # Ensure the expanded path is within the allowed root
            expanded.start_with?(root)
          end

          # Make a path relative to a base directory
          # @param path [String] Path to make relative
          # @param base [String] Base directory
          # @return [String] Relative path
          def self.relative(path, base: Dir.pwd)
            return nil if path.nil? || path.empty?

            expanded_path = Pathname.new(expand(path))
            expanded_base = Pathname.new(expand(base))

            expanded_path.relative_path_from(expanded_base).to_s
          rescue ArgumentError
            # Paths are on different drives or one doesn't exist
            path
          end

          # Join path components safely
          # @param parts [Array<String>] Path components to join
          # @return [String] Joined path
          def self.join(*parts)
            # Filter out nil and empty strings
            clean_parts = parts.compact.reject(&:empty?)
            return "" if clean_parts.empty?

            File.join(*clean_parts)
          end

          # Check if a path exists and is a directory
          # @param path [String] Path to check
          # @return [Boolean] true if path is a directory
          def self.directory?(path)
            return false if path.nil? || path.empty?

            File.directory?(expand(path))
          end

          # Check if a path exists and is a file
          # @param path [String] Path to check
          # @return [Boolean] true if path is a file
          def self.file?(path)
            return false if path.nil? || path.empty?

            File.file?(expand(path))
          end

          # Ensure a directory exists, creating it if necessary
          # @param path [String] Directory path
          # @return [Boolean] true if directory exists or was created
          def self.ensure_directory(path)
            return false if path.nil? || path.empty?

            expanded = expand(path)
            return true if File.directory?(expanded)

            FileUtils.mkdir_p(expanded)
            true
          rescue => e
            false
          end

          # Get the parent directory of a path
          # @param path [String] Path
          # @return [String] Parent directory path
          def self.parent(path)
            return nil if path.nil? || path.empty?

            File.dirname(expand(path))
          end

          # Get the basename of a path
          # @param path [String] Path
          # @return [String] Base name
          def self.basename(path)
            return nil if path.nil? || path.empty?

            File.basename(path)
          end
        end
      end
    end
  end
end