# frozen_string_literal: true

require_relative "../atoms/task_id_extractor"

module Ace
  module Git
    module Worktree
      module Models
        # Worktree information model
        #
        # Represents information about a git worktree, including its path,
        # branch, commit, and associated task metadata.
        #
        # @example Create from git worktree list output
        #   info = WorktreeInfo.from_git_output("/path/to/worktree abc123 [branch-name]")
        #
        # @example Create manually
        #   info = WorktreeInfo.new(
        #     path: "/project/.ace-wt/task.081",
        #     branch: "081-fix-auth-bug",
        #     commit: "abc123",
        #     task_id: "081"
        #   )
        class WorktreeInfo
          attr_reader :path, :branch, :commit, :task_id, :bare, :detached, :created_at

          # Initialize a new WorktreeInfo
          #
          # @param path [String] Path to the worktree directory
          # @param branch [String, nil] Branch name (nil if detached HEAD)
          # @param commit [String] Commit hash
          # @param task_id [String, nil] Associated task ID
          # @param bare [Boolean] Whether this is a bare worktree
          # @param detached [Boolean] Whether worktree is in detached HEAD state
          # @param created_at [Time, nil] When the worktree was created
          def initialize(path:, commit:, branch: nil, task_id: nil, bare: false, detached: false, created_at: nil)
            @path = path
            @branch = branch
            @commit = commit
            @task_id = task_id
            @bare = bare
            @detached = detached
            @created_at = created_at
          end

          # Check if the worktree is associated with a task
          #
          # @return [Boolean] true if task_id is present
          def task_associated?
            !@task_id.nil? && !@task_id.empty?
          end

          # Check if the worktree is in a usable state
          #
          # @return [Boolean] true if worktree is not bare or detached
          def usable?
            !@bare && !@detached
          end

          # Get the worktree directory name
          #
          # @return [String] Directory name (basename of path)
          def directory_name
            File.basename(@path)
          end

          # Check if the worktree directory exists
          #
          # @return [Boolean] true if directory exists
          def exists?
            File.directory?(@path)
          end

          # Check if the worktree directory is empty
          #
          # @return [Boolean] true if directory is empty
          def empty?
            return true unless exists?

            Dir.empty?(@path)
          end

          # Get a human-readable description
          #
          # @return [String] Human-readable description
          def description
            if task_associated?
              "Task #{@task_id}: #{@branch} at #{@path}"
            else
              "#{@branch || @commit[0, 8]} at #{@path}"
            end
          end

          # Parse git worktree list output line
          #
          # @param line [String] Output line from `git worktree list`
          # @return [WorktreeInfo, nil] Parsed worktree info or nil if parsing failed
          #
          # @example
          #   WorktreeInfo.from_git_output("/path/to/worktree abc123 [branch-name]")
          #   WorktreeInfo.from_git_output("/path/to/worktree abc123 (detached HEAD)")
          def self.from_git_output(line)
            return nil if line.nil? || line.strip.empty?

            # Git worktree list format:
            # /path/to/worktree abc123 [branch-name]
            # /path/to/worktree abc123 (detached HEAD)
            # /path/to/worktree abc123 + [branch-name]  (worktree has changes)

            parts = line.strip.split(/\s+/, 3)
            return nil if parts.length < 2

            path = parts[0]
            commit = parts[1]
            branch = nil
            bare = false
            detached = false

            # Parse the third part if present
            if parts.length >= 3
              third_part = parts[2]

              if third_part.include?("[") && third_part.include?("]")
                # Branch worktree: [branch-name]
                branch_match = third_part.match(/\[([^\]]+)\]/)
                branch = branch_match[1] if branch_match
                bare = third_part.include?("bare")
              elsif third_part.include?("detached HEAD")
                # Detached HEAD worktree
                detached = true
              end
            end

            # Try to extract task ID from path or branch
            task_id = extract_task_id(path, branch)

            new(
              path: path,
              branch: branch,
              commit: commit,
              task_id: task_id,
              bare: bare,
              detached: detached
            )
          end

          # Parse multiple lines from git worktree list output
          #
          # @param output [String] Full output from `git worktree list --porcelain`
          # @return [Array<WorktreeInfo>] Array of parsed worktree info
          #
          # @example
          #   worktrees = WorktreeInfo.from_git_output_list(`git worktree list --porcelain`)
          def self.from_git_output_list(output)
            return [] if output.nil? || output.empty?

            # Split by blank lines to get per-worktree blocks
            blocks = output.strip.split(/\n\n+/)
            worktrees = []

            blocks.each do |block|
              lines = block.strip.split("\n").map(&:strip)
              next unless lines.first&.start_with?("worktree ")

              path = lines.first.sub(/^worktree\s+/, "")
              commit = nil
              branch = nil
              detached = false
              bare = false

              lines[1..].each do |line|
                if line.start_with?("HEAD ")
                  commit = line.sub(/^HEAD\s+/, "")
                elsif line.start_with?("branch ")
                  branch_ref = line.sub(/^branch\s+/, "")
                  if branch_ref.start_with?("refs/heads/")
                    branch = branch_ref.sub(/^refs\/heads\//, "")
                  end
                elsif line == "detached"
                  detached = true
                elsif line == "bare"
                  bare = true
                end
                # skip: locked, prunable, empty lines
              end

              # Detached if no branch line was found and not bare
              detached = true if branch.nil? && !bare && commit

              task_id = extract_task_id(path, branch)
              worktrees << new(path: path, branch: branch, commit: commit,
                task_id: task_id, bare: bare, detached: detached)
            end

            worktrees
          end

          # Find worktree info by task ID
          #
          # @param worktrees [Array<WorktreeInfo>] List of worktree info
          # @param task_id [String] Task ID to search for
          # @return [WorktreeInfo, nil] Matching worktree info or nil
          def self.find_by_task_id(worktrees, task_id)
            worktrees.find { |worktree| worktree.task_id == task_id.to_s }
          end

          # Find worktree info by directory name
          #
          # @param worktrees [Array<WorktreeInfo>] List of worktree info
          # @param directory [String] Directory name to search for
          # @return [WorktreeInfo, nil] Matching worktree info or nil
          def self.find_by_directory(worktrees, directory)
            worktrees.find { |worktree| worktree.directory_name == directory.to_s }
          end

          # Find worktree info by branch name
          #
          # @param worktrees [Array<WorktreeInfo>] List of worktree info
          # @param branch [String] Branch name to search for
          # @return [WorktreeInfo, nil] Matching worktree info or nil
          def self.find_by_branch(worktrees, branch)
            worktrees.find { |worktree| worktree.branch == branch.to_s }
          end

          # Convert to hash
          #
          # @return [Hash] Worktree info as hash
          def to_h
            {
              path: @path,
              branch: @branch,
              commit: @commit,
              task_id: @task_id,
              bare: @bare,
              detached: @detached,
              created_at: @created_at,
              usable: usable?,
              task_associated: task_associated?,
              exists: exists?,
              empty: empty?
            }
          end

          # Convert to JSON
          #
          # @return [String] JSON representation
          def to_json(*args)
            to_h.to_json(*args)
          end

          # Equality comparison
          #
          # @param other [WorktreeInfo] Other worktree info
          # @return [Boolean] true if equal
          def ==(other)
            return false unless other.is_a?(WorktreeInfo)

            @path == other.path &&
              @branch == other.branch &&
              @commit == other.commit &&
              @task_id == other.task_id
          end

          alias_method :eql?, :==

          # Hash for using as hash keys
          #
          # @return [Integer] Hash value
          def hash
            [@path, @branch, @commit, @task_id].hash
          end

          private

          # Extract task ID from path or branch name
          #
          # @param path [String] Worktree path
          # @param branch [String, nil] Branch name
          # @return [String, nil] Extracted task ID or nil
          def self.extract_task_id(path, branch)
            # Try to extract from path first (e.g., task.081, 081-work)
            path_task_id = extract_task_id_from_string(File.basename(path))
            return path_task_id if path_task_id

            # Try to extract from branch name (e.g., 081-fix-something)
            extract_task_id_from_string(branch)
          end

          # Extract task ID from a string using common patterns
          #
          # @param string [String, nil] String to search
          # @return [String, nil] Extracted task ID or nil (preserves subtask IDs like "121.01")
          def self.extract_task_id_from_string(string)
            return nil if string.nil? || string.empty?

            # Use shared extractor that preserves subtask IDs (e.g., "121.01")
            Atoms::TaskIDExtractor.normalize(string)
          end
        end
      end
    end
  end
end
