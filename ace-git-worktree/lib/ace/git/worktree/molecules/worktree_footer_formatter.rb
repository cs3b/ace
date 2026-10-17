# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Molecules
        # Renders the listing header, empty-state line, and two-line count footer.
        class WorktreeFooterFormatter
          # @param window_label [String] canonical activity window (e.g. "18h")
          # @param full [Boolean] whether every worktree is listed
          def initialize(window_label:, full: false)
            @window_label = window_label
            @full = full
          end

          # @return [String] e.g. "Active worktrees (last 18h) -- 3 of 88:"
          def header(active_count:, total_count:)
            "Active worktrees (last #{@window_label}) -- #{active_count} of #{total_count}:"
          end

          # @return [String] empty-state line for a zero-active window
          def no_active_message
            "No active worktrees in the last #{@window_label}."
          end

          # @return [Array<String>] the count footer lines
          def lines(inactive:, task_associated:, usable:, recent_branches:)
            inactive_line = if @full
              "Inactive: #{inactive}"
            else
              "Inactive: #{inactive}  (use --full to list all)"
            end
            [
              inactive_line,
              "Task-associated: #{task_associated}    Usable: #{usable}    " \
                "Recent branches without worktrees: #{recent_branches}"
            ]
          end
        end
      end
    end
  end
end
