# frozen_string_literal: true

require "open3"

module Ace
  module Coworker
    module Molecules
      # Read-only worktree truth for resume: current branch, ahead/behind,
      # dirty entries, last commit. Never issues mutating git subcommands;
      # the worktree state IS the checkpoint (no journal, ADR-034).
      class GitStateProbe
        DEFAULT_RUNNER = ->(argv, cwd) { Open3.capture3(*argv, chdir: cwd) }

        def initialize(project_root:, runner: DEFAULT_RUNNER)
          @project_root = project_root
          @runner = runner
        end

        # @return [Hash] frozen {branch, ahead_behind, dirty_entries, last_commit}
        # @raise [Error] when the worktree is not a git repository
        def state
          status_out, status_err, status = run(%w[status --porcelain=v1 -b])
          unless status.success?
            raise Error, "cannot read worktree state: #{status_err.to_s.strip.empty? ? "git status failed" : status_err.strip}"
          end

          branch_line = status_out.lines.first.to_s.strip
          branch, ahead_behind = parse_branch(branch_line)
          dirty = status_out.lines.drop(1).map(&:strip).reject(&:empty?)

          log_out, _log_err, log_status = run(%w[log -1 --pretty=format:%h|%s])
          last_commit = log_status.success? ? log_out.to_s.strip : nil

          {
            "branch" => branch,
            "ahead_behind" => ahead_behind,
            "dirty_entries" => dirty,
            "last_commit" => last_commit
          }.freeze
        end

        private

        def parse_branch(line)
          # "## main...origin/main [ahead 1, behind 2]"
          header = line.sub(/\A##\s+/, "")
          return [nil, nil] if header.empty? || header.include?("no branch")
          header = header.sub(/\ANo commits yet on /, "")

          branch, tracking = header.split("...", 2)
          ahead_behind = tracking.to_s[/\[(.+)\]/, 1]
          [branch, ahead_behind]
        end

        def run(args)
          @runner.call(["git", *args], @project_root)
        rescue Errno::ENOENT
          raise Error, "cannot read worktree state: git binary not found"
        end
      end
    end
  end
end
