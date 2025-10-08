# frozen_string_literal: true

require "open3"

module Ace
  module Search
    module Molecules
      # Filters files by git status (staged, tracked, changed)
      # This is a molecule - composed operation using git commands
      class GitScopeFilter
        # Get files based on git scope
        # @param scope [Symbol] :staged, :tracked, or :changed
        # @return [Array<String>] List of file paths
        def self.get_files(scope)
          case scope
          when :staged
            get_staged_files
          when :tracked
            get_tracked_files
          when :changed
            get_changed_files
          else
            []
          end
        end

        # Get staged files
        def self.get_staged_files
          stdout, _stderr, status = Open3.capture3("git diff --cached --name-only")
          return [] unless status.success?

          stdout.lines.map(&:strip).reject(&:empty?)
        end

        # Get tracked files
        def self.get_tracked_files
          stdout, _stderr, status = Open3.capture3("git ls-files")
          return [] unless status.success?

          stdout.lines.map(&:strip).reject(&:empty?)
        end

        # Get changed files (modified, not staged)
        def self.get_changed_files
          stdout, _stderr, status = Open3.capture3("git diff --name-only")
          return [] unless status.success?

          stdout.lines.map(&:strip).reject(&:empty?)
        end

        # Check if in git repository
        def self.in_git_repo?
          _stdout, _stderr, status = Open3.capture3("git rev-parse --is-inside-work-tree")
          status.success?
        rescue
          false
        end
      end
    end
  end
end
