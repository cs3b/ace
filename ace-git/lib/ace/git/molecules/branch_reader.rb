# frozen_string_literal: true

module Ace
  module Git
    module Molecules
      # Reads git branch information
      # Consolidated from ace-review GitBranchReader (adapted to use CommandExecutor)
      class BranchReader
        class << self
          # Get current git branch name or commit SHA if detached
          # @param executor [Module] Command executor
          # @return [String|nil] branch name, commit SHA (if detached), or nil if not in git repo
          def current_branch(executor: Atoms::CommandExecutor)
            executor.current_branch
          end

          # Check if HEAD is detached
          # @param executor [Module] Command executor
          # @return [Boolean] true if HEAD is detached
          def detached?(executor: Atoms::CommandExecutor)
            result = executor.execute("git", "rev-parse", "--abbrev-ref", "HEAD")
            return false unless result[:success]

            result[:output].strip == "HEAD"
          end

          # Get remote tracking branch
          # @param executor [Module] Command executor
          # @return [String|nil] tracking branch name or nil
          def tracking_branch(executor: Atoms::CommandExecutor)
            executor.tracking_branch
          end

          # Get remote tracking status (ahead/behind counts)
          # @param executor [Module] Command executor
          # @return [Hash] { ahead: Integer, behind: Integer }
          def tracking_status(executor: Atoms::CommandExecutor)
            result = executor.execute("git", "rev-list", "--left-right", "--count", "@{upstream}...HEAD")

            unless result[:success]
              return {ahead: 0, behind: 0, error: "No tracking branch or not in git repo"}
            end

            parts = result[:output].strip.split(/\s+/)
            {
              ahead: parts[1].to_i,
              behind: parts[0].to_i
            }
          end

          # Get full branch information
          # @param executor [Module] Command executor
          # @return [Hash] Branch information
          def full_info(executor: Atoms::CommandExecutor)
            branch = current_branch(executor: executor)

            return {error: "Not in git repository or no branch"} if branch.nil?

            tracking = tracking_branch(executor: executor)
            status = tracking_status(executor: executor)

            {
              name: branch,
              detached: detached?(executor: executor),
              tracking: tracking,
              ahead: status[:ahead],
              behind: status[:behind],
              up_to_date: status[:ahead] == 0 && status[:behind] == 0,
              status_description: format_status(status[:ahead], status[:behind])
            }
          end

          # Format tracking status as human-readable string
          # @param ahead [Integer] Commits ahead of remote
          # @param behind [Integer] Commits behind remote
          # @return [String] Status description
          def format_status(ahead, behind)
            if ahead == 0 && behind == 0
              "up to date"
            elsif ahead > 0 && behind > 0
              "#{ahead} ahead, #{behind} behind"
            elsif ahead > 0
              "#{ahead} ahead"
            else
              "#{behind} behind"
            end
          end
        end
      end
    end
  end
end
