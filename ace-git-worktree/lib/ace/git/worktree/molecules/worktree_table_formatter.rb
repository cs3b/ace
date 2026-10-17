# frozen_string_literal: true

require "io/console"
require_relative "../atoms/relative_age_formatter"
require_relative "pr_status_resolver"
require_relative "../atoms/text_truncator"

module Ace
  module Git
    module Worktree
      module Molecules
        # Renders the width-aware listing table.
        #
        # Layout targets (two-space gutters): Task = max(task cells, 4),
        # Branch 25 (min 12), Age 5, Commit 24 (min 10), Changes 7, PR 11,
        # Path 32 (min 10). When the target total exceeds the detected width,
        # columns shrink in priority order Path -> Commit -> Branch down to
        # their minima, then Path is dropped, then Commit. Compact output never
        # exceeds the detected width; `--full` prints untruncated absolute paths
        # and is exempt from width limits.
        class WorktreeTableFormatter
          GUTTER = "  "
          COLUMNS_MIN_WIDTH = 40
          DEFAULT_WIDTH = 120

          BRANCH_TARGET = 25
          BRANCH_MIN = 12
          AGE_WIDTH = 5
          COMMIT_TARGET = 24
          COMMIT_MIN = 10
          CHANGES_WIDTH = 7
          PR_WIDTH = 11
          PATH_TARGET = 32
          PATH_MIN = 10
          TASK_MIN = 4

          # @param width [Integer] detected terminal width
          # @param full [Boolean] exhaustive listing (no truncation)
          # @param env [Hash] environment (HOME shortening, COLUMNS detection)
          def initialize(width: nil, full: false, env: ENV, stdout: $stdout)
            @width = width || self.class.detected_width(env: env, stdout: stdout)
            @full = full
            @env = env
          end

          # Detect the output width.
          #
          # @param env [Hash]
          # @param stdout [IO]
          # @return [Integer]
          def self.detected_width(env: ENV, stdout: $stdout)
            columns = env["COLUMNS"].to_s.strip
            if columns.match?(/\A\d+\z/)
              value = Integer(columns, 10)
              return value if value >= COLUMNS_MIN_WIDTH
            end

            if stdout.respond_to?(:tty?) && stdout.tty?
              winsize = IO.console&.winsize
              return winsize.last if winsize&.last
            end

            DEFAULT_WIDTH
          rescue StandardError
            DEFAULT_WIDTH
          end

          # Render header + separator + rows.
          #
          # @param worktrees [Array<Models::WorktreeInfo>]
          # @return [Array<String>] output lines
          def render(worktrees)
            rows = Array(worktrees)
            layout = compute_layout(rows)
            [header_line(layout), separator_line(layout), *rows.map { |worktree| row_line(worktree, layout) }]
          end

          private

          Layout = Struct.new(:task, :branch, :age, :commit, :changes, :pr, :path, :total_width,
            keyword_init: true)

          def compute_layout(worktrees)
            task_width = [TASK_MIN, *worktrees.map { |wt| task_cell(wt).length }].max
            branch_width = BRANCH_TARGET
            commit_width = COMMIT_TARGET
            path_width = PATH_TARGET

            if @full
              path_width = [PATH_TARGET, *worktrees.map { |wt| full_path(wt).length }].max
              return build_layout(task_width, branch_width, commit_width, path_width)
            end

            while total_width(task_width, branch_width, commit_width, path_width) > @width
              if path_width > PATH_MIN
                path_width -= 1
              elsif commit_width > COMMIT_MIN
                commit_width -= 1
              elsif branch_width > BRANCH_MIN
                branch_width -= 1
              else
                break
              end
            end

            layout = build_layout(task_width, branch_width, commit_width, path_width)
            return layout if layout[:total_width] <= @width

            drop_path(layout)
          end

          def build_layout(task_width, branch_width, commit_width, path_width)
            total = total_width(task_width, branch_width, commit_width, path_width)
            Layout.new(task: task_width, branch: branch_width, age: AGE_WIDTH, commit: commit_width,
              changes: CHANGES_WIDTH, pr: PR_WIDTH, path: path_width, total_width: total)
          end

          def total_width(task_width, branch_width, commit_width, path_width)
            task_width + branch_width + AGE_WIDTH + commit_width + CHANGES_WIDTH + PR_WIDTH +
              path_width + (GUTTER.length * 6)
          end

          # Drop the Path column when even the minimum layout overflows; then
          # drop Commit as the last resort.
          def drop_path(layout)
            without_path = Layout.new(
              task: layout[:task], branch: layout[:branch], age: layout[:age], commit: layout[:commit],
              changes: layout[:changes], pr: layout[:pr], path: 0,
              total_width: layout[:total_width] - layout[:path] - GUTTER.length
            )
            return without_path if without_path[:total_width] <= @width

            Layout.new(
              task: without_path[:task], branch: without_path[:branch], age: without_path[:age],
              commit: 0, changes: without_path[:changes], pr: without_path[:pr], path: 0,
              total_width: without_path[:total_width] - without_path[:commit] - GUTTER.length
            )
          end

          def header_line(layout)
            cells = []
            cells << pad("Task", layout[:task], :left)
            cells << pad("Branch", layout[:branch], :left)
            cells << pad("Age", layout[:age], :right)
            cells << pad("Commit", layout[:commit], :left) if layout[:commit].positive?
            cells << pad("Changes", layout[:changes], :right)
            cells << pad("PR", layout[:pr], :left)
            cells << pad("Path", layout[:path], :left) if layout[:path].positive?
            cells.join(GUTTER).rstrip
          end

          def separator_line(layout)
            "-" * layout[:total_width]
          end

          def row_line(worktree, layout)
            cells = []
            cells << pad(task_cell(worktree), layout[:task], :left)
            cells << pad(branch_cell(worktree, layout[:branch]), layout[:branch], :left)
            cells << pad(age_cell(worktree), layout[:age], :right)
            cells << pad(commit_cell(worktree, layout[:commit]), layout[:commit], :left) if layout[:commit].positive?
            cells << pad(changes_cell(worktree), layout[:changes], :right)
            cells << pad(pr_cell(worktree), layout[:pr], :left)
            cells << pad(path_cell(worktree, layout[:path]), layout[:path], :left) if layout[:path].positive?
            cells.join(GUTTER).rstrip
          end

          # --- Cell contents ---

          def task_cell(worktree)
            return "-" if worktree.task_id.to_s.empty?

            extra = worktree.task_ids.length - 1
            extra.positive? ? "#{worktree.task_id}+#{extra}" : worktree.task_id
          end

          def branch_cell(worktree, width)
            label = worktree.branch.to_s.empty? ? "detached" : worktree.branch
            Atoms::TextTruncator.middle(label, width)
          end

          def age_cell(worktree)
            return "?" if worktree.probe_failed?
            return "never" if worktree.last_commit.nil?

            Atoms::RelativeAgeFormatter.format(worktree.last_commit[:age_hours].to_f * 3600)
          end

          def commit_cell(worktree, width)
            return "?" if worktree.probe_failed?
            return "" if worktree.last_commit.nil?

            Atoms::TextTruncator.right(worktree.last_commit[:subject].to_s, width)
          end

          def changes_cell(worktree)
            return "?" if worktree.probe_failed?
            return "-" if worktree.uncommitted.nil?

            worktree.uncommitted[:total].to_i.to_s
          end

          def pr_cell(worktree)
            PrStatusResolver.cell(worktree.pr)
          end

          def path_cell(worktree, width)
            return "" if width <= 0

            path = @full ? full_path(worktree) : compact_path(worktree)
            Atoms::TextTruncator.left(path, width)
          end

          def full_path(worktree)
            File.expand_path(worktree.path)
          end

          def compact_path(worktree)
            path = worktree.path.to_s
            home = @env["HOME"].to_s
            path = "~#{path[home.length..]}" if !home.empty? && path.start_with?(home)
            path
          end

          def pad(value, width, alignment)
            text = value.to_s
            text = text[0, width].to_s if text.length > width
            return text.ljust(width) if alignment == :left

            text.rjust(width)
          end
        end
      end
    end
  end
end
