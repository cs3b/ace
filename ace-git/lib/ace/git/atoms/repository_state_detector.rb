# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Detect repository state: clean, dirty, rebasing, merging
      # Pure function that uses CommandExecutor for git commands
      module RepositoryStateDetector
        class << self
          # Detect current repository state
          # @param executor [Module] Command executor (default: CommandExecutor)
          # @return [Symbol] One of :clean, :dirty, :rebasing, :merging, :unknown
          def detect(executor: CommandExecutor)
            return :unknown unless executor.in_git_repo?

            # Check for rebase in progress
            return :rebasing if rebasing?(executor: executor)

            # Check for merge in progress
            return :merging if merging?(executor: executor)

            # Check for uncommitted changes
            return :dirty if dirty?(executor: executor)

            :clean
          end

          # Check if repository is in a clean state
          # @param executor [Module] Command executor
          # @return [Boolean] True if clean
          def clean?(executor: CommandExecutor)
            detect(executor: executor) == :clean
          end

          # Check if repository has uncommitted changes
          # @param executor [Module] Command executor
          # @return [Boolean] True if dirty
          def dirty?(executor: CommandExecutor)
            # Check git status for changes
            result = executor.execute("git", "status", "--porcelain")
            return false unless result[:success]

            !result[:output].strip.empty?
          end

          # Check if repository is in rebase state
          # @param executor [Module] Command executor
          # @return [Boolean] True if rebasing
          def rebasing?(executor: CommandExecutor)
            # Check for rebase-apply or rebase-merge directories
            git_dir = executor.execute("git", "rev-parse", "--git-dir")
            return false unless git_dir[:success]

            git_path = git_dir[:output].strip
            File.exist?(File.join(git_path, "rebase-apply")) ||
              File.exist?(File.join(git_path, "rebase-merge"))
          end

          # Check if repository is in merge state
          # @param executor [Module] Command executor
          # @return [Boolean] True if merging
          def merging?(executor: CommandExecutor)
            # Check for MERGE_HEAD file
            git_dir = executor.execute("git", "rev-parse", "--git-dir")
            return false unless git_dir[:success]

            git_path = git_dir[:output].strip
            File.exist?(File.join(git_path, "MERGE_HEAD"))
          end

          # Get human-readable state description
          # @param executor [Module] Command executor
          # @return [String] State description
          def state_description(executor: CommandExecutor)
            case detect(executor: executor)
            when :clean
              "clean (no uncommitted changes)"
            when :dirty
              "dirty (uncommitted changes)"
            when :rebasing
              "rebasing in progress"
            when :merging
              "merge in progress"
            else
              "unknown state"
            end
          end
        end
      end
    end
  end
end
