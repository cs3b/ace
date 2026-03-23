# frozen_string_literal: true

module Ace
  module GitCommit
    module Molecules
      # FileStager handles staging files for commit
      class FileStager
        attr_reader :last_error, :last_skipped_files

        def initialize(git_executor, gitignore_checker: nil)
          @git = git_executor
          @gitignore_checker = gitignore_checker || Atoms::GitignoreChecker.new
          @last_error = nil
          @last_skipped_files = []
          @had_valid_files = false
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
        # @param quiet [Boolean] Suppress output about skipped files
        # @return [Boolean] True if successful (including when all files skipped)
        def stage_paths(paths, quiet: false)
          return false if paths.nil? || paths.empty?

          @last_error = nil
          @last_skipped_files = []
          @had_valid_files = false

          begin
            # Categorize paths: valid (not gitignored), force_add (gitignored but tracked), skipped (gitignored and untracked)
            result = @gitignore_checker.categorize_paths(paths, @git)

            # Track skipped files (gitignored and not tracked)
            if result[:skipped].any?
              @last_skipped_files = result[:skipped]
              unless quiet
                warn "⚠ Skipping gitignored files (not tracked):"
                result[:skipped].each do |info|
                  if info[:pattern]
                    warn "  #{info[:path]}"
                    warn "  (matches pattern: #{info[:pattern]})"
                  else
                    warn "  #{info[:path]}"
                  end
                end
              end
            end

            # Combine valid paths and force_add paths
            # Force add paths need -f flag because they're in gitignored locations but are tracked
            normal_paths = result[:valid]
            force_add_paths = result[:force_add].map { |f| f[:path] }

            all_paths = normal_paths + force_add_paths

            # If all files are skipped (gitignored and untracked), return success
            if all_paths.empty?
              return true
            end

            @had_valid_files = true

            # Reset staging area to clear everything
            @git.execute("reset", "--quiet")

            # Stage normal files (retry with -f if path is ignored)
            normal_paths.each do |path|
              @git.execute("add", path)
            rescue GitError => e
              # If git says path is ignored but we expected it to work, try force add
              if e.message.include?("ignored by one of your .gitignore files")
                @git.execute("add", "-f", path)
              else
                raise
              end
            end

            # Stage tracked files in gitignored locations with force flag
            force_add_paths.each do |path|
              @git.execute("add", "-f", path)
            end

            true
          rescue GitError => e
            @last_error = e.message
            false
          end
        end

        # Check if the last stage_paths call had all files gitignored
        # @return [Boolean] True if all files were skipped due to gitignore
        def all_files_skipped?
          @last_skipped_files.any? && !@had_valid_files && @last_error.nil?
        end
      end
    end
  end
end
