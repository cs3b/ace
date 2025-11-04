# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Models
        # Model representing worktree information
        class WorktreeInfo
          attr_reader :path, :branch, :commit, :directory, :task_id, :locked, :prunable

          def initialize(path:, branch:, commit: nil, directory: nil, task_id: nil, locked: false, prunable: false)
            @path = path
            @branch = branch
            @commit = commit
            @directory = directory || File.basename(path)
            @task_id = task_id
            @locked = locked
            @prunable = prunable
          end

          # Check if this worktree is associated with a task
          def task?
            !task_id.nil? && !task_id.empty?
          end

          # Check if this worktree is locked
          def locked?
            @locked
          end

          # Check if this worktree is prunable
          def prunable?
            @prunable
          end

          # Get absolute path
          def absolute_path
            return path if path.start_with?("/")
            File.expand_path(path)
          end

          # Convert to hash representation
          def to_h
            {
              path: path,
              directory: directory,
              branch: branch,
              commit: commit,
              task_id: task_id,
              locked: locked,
              prunable: prunable
            }.compact
          end

          # Convert to JSON-friendly hash
          def to_json_h
            to_h.merge(absolute_path: absolute_path)
          end

          # Format for table display
          def to_table_row
            [directory, branch, task_id || "-"]
          end

          # Check equality
          def ==(other)
            return false unless other.is_a?(WorktreeInfo)
            path == other.path && branch == other.branch
          end

          # Create from git worktree list output
          def self.from_git_output(line)
            # Git worktree list format:
            # worktree /path/to/worktree
            # HEAD commit_sha
            # branch refs/heads/branch-name
            # or
            # detached (if not on a branch)

            parts = {}
            lines = line.split("\n")

            lines.each do |l|
              case l
              when /^worktree (.+)$/
                parts[:path] = $1
              when /^HEAD ([a-f0-9]+)$/
                parts[:commit] = $1
              when /^branch refs\/heads\/(.+)$/
                parts[:branch] = $1
              when /^detached$/
                parts[:branch] = "HEAD (detached)"
              when /^locked$/
                parts[:locked] = true
              when /^prunable$/
                parts[:prunable] = true
              end
            end

            return nil unless parts[:path]

            new(
              path: parts[:path],
              branch: parts[:branch] || "unknown",
              commit: parts[:commit],
              locked: parts[:locked] || false,
              prunable: parts[:prunable] || false
            )
          end
        end
      end
    end
  end
end