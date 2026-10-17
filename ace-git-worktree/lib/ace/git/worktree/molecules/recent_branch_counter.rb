# frozen_string_literal: true

require "open3"

module Ace
  module Git
    module Worktree
      module Molecules
        # Counts branches whose last commit landed inside the activity window but
        # that have no worktree. This count is branch-based: worktree filters
        # never change it.
        class RecentBranchCounter
          # @param worktrees [Array<Models::WorktreeInfo>] selected worktrees
          # @param window_hours [Numeric] activity window in hours
          # @param now [Time] clock snapshot shared with the listing run
          # @param runner [Proc, nil] injectable ref lister returning
          #   `"<branch>\0<committer unix>"` lines (tests)
          def initialize(worktrees:, window_hours:, now: Time.now, runner: nil)
            @worktrees = Array(worktrees)
            @window_hours = window_hours
            @now = now
            @runner = runner
          end

          # @return [Integer]
          def count
            cutoff = @now.to_i - (@window_hours * 3600).to_i
            checked_out = @worktrees.map(&:branch).compact
            primary_branch = @worktrees.first&.branch

            branch_rows.count do |branch, committed_at|
              next false if branch.nil? || branch.empty?
              next false if branch == primary_branch
              next false if checked_out.include?(branch)
              next false if committed_at.nil?

              committed_at >= cutoff
            end
          rescue StandardError
            0
          end

          private

          # @return [Array<Array(String, Integer)>] branch/committer pairs
          def branch_rows
            output = @runner ? @runner.call : default_branch_listing
            return [] if output.nil? || output.empty?

            output.lines.filter_map do |line|
              branch, epoch = line.chomp.split("\x00", 2)
              next if branch.to_s.empty?

              [branch, epoch && Integer(epoch, 10)]
            rescue ArgumentError
              nil
            end
          end

          def default_branch_listing
            stdout, _stderr, status = Open3.capture3(
              "git", "for-each-ref", "--format=%(refname:short)%00%(committerdate:unix)", "refs/heads/"
            )
            status.success? ? stdout : ""
          end
        end
      end
    end
  end
end
