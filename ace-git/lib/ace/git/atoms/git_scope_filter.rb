# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Filters files by git status (staged, tracked, changed)
      # Consolidated from ace-search GitScopeFilter (adapted to use CommandExecutor)
      module GitScopeFilter
        class << self
          # Get files based on git scope
          # @param scope [Symbol] :staged, :tracked, or :changed
          # @param executor [Module] Command executor (default: CommandExecutor)
          # @return [Array<String>] List of file paths
          def get_files(scope, executor: CommandExecutor)
            case scope
            when :staged
              get_staged_files(executor: executor)
            when :tracked
              get_tracked_files(executor: executor)
            when :changed
              get_changed_files(executor: executor)
            else
              []
            end
          end

          # Get staged files
          # @param executor [Module] Command executor
          # @return [Array<String>] List of staged file paths
          def get_staged_files(executor: CommandExecutor)
            result = executor.execute("git", "diff", "--cached", "--name-only")
            return [] unless result[:success]

            result[:output].lines.map(&:strip).reject(&:empty?)
          end

          # Get tracked files
          # @param executor [Module] Command executor
          # @return [Array<String>] List of tracked file paths
          def get_tracked_files(executor: CommandExecutor)
            result = executor.execute("git", "ls-files")
            return [] unless result[:success]

            result[:output].lines.map(&:strip).reject(&:empty?)
          end

          # Get changed files (modified, not staged)
          # @param executor [Module] Command executor
          # @return [Array<String>] List of changed file paths
          def get_changed_files(executor: CommandExecutor)
            result = executor.execute("git", "diff", "--name-only")
            return [] unless result[:success]

            result[:output].lines.map(&:strip).reject(&:empty?)
          end

          # Get both staged and changed files (all uncommitted)
          # @param executor [Module] Command executor
          # @return [Array<String>] List of all uncommitted file paths
          def get_uncommitted_files(executor: CommandExecutor)
            (get_staged_files(executor: executor) + get_changed_files(executor: executor)).uniq
          end

          # Check if in git repository
          # @param executor [Module] Command executor
          # @return [Boolean] True if in git repository
          def in_git_repo?(executor: CommandExecutor)
            executor.in_git_repo?
          end

          # Get files changed between two refs
          # @param from_ref [String] Start reference (e.g., "origin/main")
          # @param to_ref [String] End reference (default: "HEAD")
          # @param executor [Module] Command executor
          # @return [Array<String>] List of changed file paths
          def get_files_between(from_ref, to_ref = "HEAD", executor: CommandExecutor)
            result = executor.execute("git", "diff", "--name-only", "#{from_ref}...#{to_ref}")
            return [] unless result[:success]

            result[:output].lines.map(&:strip).reject(&:empty?)
          end
        end
      end
    end
  end
end
