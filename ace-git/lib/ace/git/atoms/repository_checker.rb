# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Check repository status: detached HEAD, bare repo, nested worktree
      # Pure function that uses CommandExecutor for git commands
      module RepositoryChecker
        class << self
          # Check if in a git repository
          # @param executor [Module] Command executor
          # @return [Boolean] True if in git repo
          def in_git_repo?(executor: CommandExecutor)
            executor.in_git_repo?
          end

          # Check if HEAD is detached
          # @param executor [Module] Command executor
          # @return [Boolean] True if HEAD is detached
          def detached_head?(executor: CommandExecutor)
            return false unless in_git_repo?(executor: executor)

            result = executor.execute("git", "symbolic-ref", "-q", "HEAD")
            # If symbolic-ref fails, HEAD is detached
            !result[:success]
          end

          # Check if repository is bare
          # @param executor [Module] Command executor
          # @return [Boolean] True if bare repository
          def bare_repository?(executor: CommandExecutor)
            return false unless in_git_repo?(executor: executor)

            result = executor.execute("git", "rev-parse", "--is-bare-repository")
            result[:success] && result[:output].strip == "true"
          end

          # Check if current directory is in a git worktree (not main repo)
          # @param executor [Module] Command executor
          # @return [Boolean] True if in worktree
          def in_worktree?(executor: CommandExecutor)
            return false unless in_git_repo?(executor: executor)

            # Get git directory and common directory
            git_dir = executor.execute("git", "rev-parse", "--git-dir")
            return false unless git_dir[:success]

            git_path = git_dir[:output].strip

            # In worktrees, git-dir contains "worktrees/"
            git_path.include?("/worktrees/")
          end

          # Get repository type description
          # @param executor [Module] Command executor
          # @return [Symbol] :normal, :detached, :bare, :worktree, :not_git
          def repository_type(executor: CommandExecutor)
            return :not_git unless in_git_repo?(executor: executor)
            return :bare if bare_repository?(executor: executor)
            return :worktree if in_worktree?(executor: executor)
            return :detached if detached_head?(executor: executor)

            :normal
          end

          # Get human-readable repository status
          # @param executor [Module] Command executor
          # @return [String] Status description
          def status_description(executor: CommandExecutor)
            case repository_type(executor: executor)
            when :normal
              "normal repository"
            when :detached
              "detached HEAD state"
            when :bare
              "bare repository"
            when :worktree
              "git worktree"
            else
              "not a git repository"
            end
          end

          # Check if repository is in a usable state for typical git operations
          # @param executor [Module] Command executor
          # @return [Boolean] True if usable
          def usable?(executor: CommandExecutor)
            return false unless in_git_repo?(executor: executor)
            return false if bare_repository?(executor: executor)

            true
          end
        end
      end
    end
  end
end
