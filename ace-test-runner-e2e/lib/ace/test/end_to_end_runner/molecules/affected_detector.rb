# frozen_string_literal: true

require "open3"
require "pathname"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Detects packages affected by recent changes
        #
        # Analyzes git diff to determine which packages have changed
        # since the last commit, allowing selective test execution.
        class AffectedDetector
          # Default git reference to compare against
          DEFAULT_REF = "HEAD~1"

          # Detect packages that have changed
          #
          # @param base_dir [String] Base directory for git operations
          # @param ref [String] Git reference to compare against (default: HEAD~1)
          # @return [Array<String>] List of affected package names
          def detect(base_dir: Dir.pwd, ref: DEFAULT_REF)
            diff_files = get_changed_files(base_dir, ref)
            return [] if diff_files.empty?

            diff_files.map { |file| extract_package(file, base_dir) }
              .compact
              .uniq
              .sort
          end

          private

          # Get list of changed files from git
          #
          # @param base_dir [String] Base directory
          # @param ref [String] Git reference
          # @return [Array<String>] Changed file paths
          def get_changed_files(base_dir, ref)
            # Run git diff to get changed files using array-based command for security
            output, stderr, status = Open3.capture3("git", "diff", "--name-only", ref, "--",
              chdir: base_dir)

            unless status.success?
              message = stderr.to_s.strip
              message = "git diff exited with status #{status.exitstatus}" if message.empty?
              warn "Warning: git detection failed: #{message}"
              return []
            end

            output.lines.map(&:strip).reject(&:empty?)
          rescue => e
            # If git command fails, warn and return empty array
            # This can happen in shallow clones or if ref doesn't exist
            warn "Warning: git detection failed: #{e.message}"
            []
          end

          # Extract package name from file path
          #
          # @param file_path [String] Path to changed file
          # @param base_dir [String] Base directory
          # @return [String, nil] Package name or nil if not in a package
          def extract_package(file_path, base_dir)
            # Make path relative to base directory
            relative_path = if file_path.start_with?("/")
              begin
                Pathname.new(file_path).relative_path_from(Pathname.new(base_dir)).to_s
              rescue ArgumentError
                # file_path is not under base_dir, use original path
                file_path
              end
            else
              file_path
            end

            # Split path and check first component
            parts = relative_path.split("/")

            # Check if first part looks like a package name (starts with "ace-")
            package = parts.first
            return nil unless package
            return nil unless package.start_with?("ace-")
            return nil if package == "." # Skip current dir

            # Verify it's actually a directory (a package)
            package_dir = File.join(base_dir, package)
            return nil unless File.directory?(package_dir)

            package
          end
        end
      end
    end
  end
end
