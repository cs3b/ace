# frozen_string_literal: true

module Ace
  module GitCommit
    module Molecules
      # FileStager handles staging files for commit
      class FileStager
        def initialize(git_executor)
          @git = git_executor
        end

        # Stage specific files
        # @param files [Array<String>] Files to stage
        # @return [Boolean] True if successful
        def stage_files(files)
          return false if files.nil? || files.empty?

          @git.execute("add", *files)
          true
        end

        # Stage all changes in the repository
        # @return [Boolean] True if successful
        def stage_all
          @git.execute("add", "-A")
          true
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
        # @return [Array<String>] List of staged file paths
        def staged_files
          @git.execute("diff", "--cached", "--name-only").strip.split("\n")
        end

        # Check if specific files are staged
        # @param files [Array<String>] Files to check
        # @return [Boolean] True if all files are staged
        def files_staged?(files)
          staged = staged_files
          files.all? { |f| staged.include?(f) }
        end
      end
    end
  end
end