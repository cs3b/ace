# frozen_string_literal: true

module Ace
  module GitCommit
    module Molecules
      # FileStager handles staging files for commit
      class FileStager
        attr_reader :last_error

        def initialize(git_executor)
          @git = git_executor
          @last_error = nil
        end

        # Stage specific files
        # @param files [Array<String>] Files to stage
        # @return [Boolean] True if successful
        def stage_files(files)
          return false if files.nil? || files.empty?

          @last_error = nil
          @git.execute("add", *files)
          true
        rescue GitError => e
          @last_error = e.message
          false
        end

        # Stage all changes in the repository
        # @return [Boolean] True if successful
        def stage_all
          @last_error = nil
          @git.execute("add", "-A")
          true
        rescue GitError => e
          @last_error = e.message
          false
        end

        # Unstage specific files
        # @param files [Array<String>] Files to unstage
        # @return [Boolean] True if successful
        def unstage_files(files)
          return false if files.nil? || files.empty?

          @git.execute("reset", "HEAD", *files)
          true
        rescue GitError
          # If HEAD doesn't exist (new repo), use rm --cached
          @git.execute("rm", "--cached", *files)
          true
        end

        # Get list of staged files
        # Uses --no-renames to ensure deleted files from directory renames are included
        # @return [Array<String>] List of staged file paths
        def staged_files
          @git.execute("diff", "--cached", "--name-only", "--no-renames").strip.split("\n")
        end

        # Check if specific files are staged
        # @param files [Array<String>] Files to check
        # @return [Boolean] True if all files are staged
        def files_staged?(files)
          staged = staged_files
          files.all? { |f| staged.include?(f) }
        end

        # Stage only files within specified paths
        # Resets staging area first, then stages only files in paths
        # @param paths [Array<String>] Paths to stage (files or directories)
        # @return [Boolean] True if successful
        def stage_paths(paths)
          return false if paths.nil? || paths.empty?

          @last_error = nil

          begin
            # Reset staging area to clear everything
            @git.execute("reset", "--quiet")

            # Stage only files in specified paths
            # Let git add handle path validation (supports deleted files)
            paths.each do |path|
              @git.execute("add", path)
            end

            true
          rescue GitError => e
            @last_error = e.message
            false
          end
        end
      end
    end
  end
end