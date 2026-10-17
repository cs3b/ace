# frozen_string_literal: true

require "open3"
require "time"

module Ace
  module Git
    module Worktree
      module Molecules
        # Read-only inspection of one worktree, designed to run inside a forked
        # probe child (see {Organisms::WorktreeProbeRunner}).
        #
        # The probe reports raw signals only: HEAD commit metadata, uncommitted
        # change counts, task files changed in the worktree, and the resolved
        # `_current` symlink target. The parent process owns clock reads,
        # rendering, and task/PR resolution so ordering and ages stay
        # deterministic.
        #
        # All git calls pass the worktree explicitly via `-C <path>` (ADR-031);
        # the probe never changes the parent process working directory and
        # never writes repository state.
        class WorktreeProbe
          # Marker for a task-tree-relative path prefix.
          TASK_TREE_PREFIX = ".ace-tasks/"

          # @param project_root [String] primary project root (contains `.ace-tasks/`)
          # @param base_ref [String, nil] primary worktree HEAD sha used as the
          #   merge-base reference for committed task-file diffs
          def initialize(project_root:, base_ref: nil)
            @project_root = project_root
            @base_ref = base_ref
            @task_root = project_root ? File.join(project_root, ".ace-tasks") : nil
          end

          # Probe one worktree.
          #
          # @param path [String] worktree directory
          # @return [Hash, nil] serializable probe payload, or nil when the
          #   worktree cannot be inspected (missing path / git failure)
          def probe(path)
            return nil unless path && File.directory?(path)

            head = head_metadata(path)
            status = status_snapshot(path)
            return nil if status.nil?

            committed_task_files = committed_task_paths(path, head && head[:sha])

            {
              head_sha: head && head[:sha],
              head_committer_epoch: head && head[:committer_epoch],
              head_subject: head && head[:subject],
              staged: status[:staged],
              unstaged: status[:unstaged],
              untracked: status[:untracked],
              uncommitted_paths: status[:paths],
              changed_task_files: status[:paths].select { |p| task_tree_path?(p) },
              committed_task_files: committed_task_files,
              symlink_target: current_task_target(path)
            }
          rescue StandardError
            nil
          end

          # Resolve the `_current` symlink at a worktree root when it points
          # into the project task tree.
          #
          # @param path [String] worktree directory
          # @return [String, nil] absolute task directory
          def current_task_target(path)
            symlink = File.join(path, "_current")
            return nil unless File.symlink?(symlink) && @task_root

            target = canonical_path(File.expand_path(File.readlink(symlink), path))
            root = canonical_path(@task_root)
            target.start_with?("#{root}/") ? target : nil
          rescue StandardError
            nil
          end

          # Canonical comparison form for paths that may be reached through a
          # symlinked root (e.g. macOS /var -> /private/var).
          def canonical_path(value)
            File.realpath(value)
          rescue StandardError
            File.expand_path(value)
          end

          # Deep-scan fallback for the task tree only: untracked files under
          # `.ace-tasks/`. This walk is expensive on large trees, so the probe
          # itself never performs it; callers run it selectively (second round)
          # for worktrees the cheap association tiers could not resolve.
          #
          # @param path [String] worktree directory
          # @return [Array<String>] repo-relative untracked task paths
          def untracked_task_files(path)
            return [] unless path && File.directory?(path)

            output = git(path, "ls-files", "--others", "--exclude-standard", "--", TASK_TREE_PREFIX)
            return [] if output.nil?

            output.lines.map { |line| scrub(line.chomp) }.reject(&:empty?).select { |p| task_tree_path?(p) }
          rescue StandardError
            []
          end

          private

          # @return [Hash, nil] `{sha:, committer_epoch:, subject:}` for HEAD
          def head_metadata(path)
            output = git(path, "log", "-1", "--format=%H%x1f%ct%x1f%s")
            return nil if output.nil?

            sha, epoch, subject = output.chomp.split("\x1f", 3)
            return nil if sha.to_s.empty?

            {sha: sha, committer_epoch: Integer(epoch, 10), subject: subject.to_s}
          rescue ArgumentError
            nil
          end

          # @return [Hash, nil] staged/unstaged counts and changed paths
          # (tracked files only; untracked discovery is opt-in via
          # {#untracked_task_files})
          def status_snapshot(path)
            output = git(path, "status", "--porcelain=v1", "-z", "--untracked-files=no")
            return nil if output.nil?

            staged = 0
            unstaged = 0
            untracked = 0
            paths = []
            records = output.split("\x00")
            index = 0

            while index < records.length
              record = records[index]
              index += 1
              next if record.nil? || record.length < 4

              xy = record[0, 2]
              file = scrub(record[3..].to_s)
              # Rename/copy records carry the original path in the next record.
              index += 1 if xy[0] == "R" || xy[0] == "C"

              if xy == "??"
                untracked += 1
              else
                staged += 1 unless xy[0] == " " || xy[0] == "?"
                unstaged += 1 unless xy[1] == " " || xy[1] == "?"
              end
              paths << file
            end

            {staged: staged, unstaged: unstaged, untracked: untracked, paths: paths}
          end

          # Task-tree files changed by this worktree's commits, relative to the
          # merge-base with the primary worktree. Falls back to the HEAD
          # commit's changed files when no merge-base exists.
          #
          # @return [Array<String>] repo-relative `.ace-tasks/` paths
          def committed_task_paths(path, head_sha)
            return [] if head_sha.nil?

            merge_base = @base_ref ? git(path, "merge-base", @base_ref, head_sha)&.strip : nil
            output = if merge_base && !merge_base.empty?
              git(path, "diff", "--name-only", merge_base, head_sha, "--", ".ace-tasks")
            else
              git(path, "diff-tree", "--no-commit-id", "--name-only", "-r", head_sha, "--", ".ace-tasks")
            end
            return [] if output.nil?

            output.lines.map { |line| scrub(line.chomp) }.reject(&:empty?).select { |p| task_tree_path?(p) }
          end

          def task_tree_path?(relative_path)
            relative_path.start_with?(TASK_TREE_PREFIX)
          end

          # Run git in the worktree; nil on any failure.
          #
          # @return [String, nil]
          def git(path, *args)
            stdout, _stderr, status = Open3.capture3("git", "-C", path, *args)
            status.success? ? stdout : nil
          end

          def scrub(value)
            value.dup.force_encoding(Encoding::UTF_8).scrub
          end
        end
      end
    end
  end
end
