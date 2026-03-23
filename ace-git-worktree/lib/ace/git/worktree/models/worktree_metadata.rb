# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Models
        # Worktree metadata model for task frontmatter
        #
        # Represents worktree information that gets added to task frontmatter
        # to track the association between tasks and their worktrees.
        #
        # @example Create for a new worktree
        #   metadata = WorktreeMetadata.new(
        #     branch: "081-fix-authentication-bug",
        #     path: ".ace-wt/task.081",
        #     created_at: Time.now
        #   )
        #
        # @example Load from task frontmatter
        #   metadata = WorktreeMetadata.from_task_data(task_frontmatter_hash)
        class WorktreeMetadata
          attr_reader :branch, :path, :target_branch, :created_at, :updated_at

          # Initialize a new WorktreeMetadata
          #
          # @param branch [String] Git branch name
          # @param path [String] Worktree path (relative to project root)
          # @param target_branch [String, nil] PR target branch (default: nil for main)
          # @param created_at [Time] When the worktree was created
          # @param updated_at [Time] When the worktree was last updated
          def initialize(branch:, path:, target_branch: nil, created_at: Time.now, updated_at: Time.now)
            @branch = branch.to_s
            @path = path.to_s
            @target_branch = target_branch&.to_s
            @created_at = created_at.is_a?(Time) ? created_at : Time.parse(created_at.to_s)
            @updated_at = updated_at.is_a?(Time) ? updated_at : Time.parse(updated_at.to_s)
          end

          # Update the metadata with new information
          #
          # @param branch [String, nil] New branch name
          # @param path [String, nil] New path
          # @return [WorktreeMetadata] Updated metadata
          def update(branch: nil, path: nil)
            WorktreeMetadata.new(
              branch: branch || @branch,
              path: path || @path,
              target_branch: @target_branch,
              created_at: @created_at,
              updated_at: Time.now
            )
          end

          # Check if the worktree is recent (created within last 7 days)
          #
          # @return [Boolean] true if worktree is recent
          def recent?
            @created_at > (Time.now - 7 * 24 * 60 * 60)
          end

          # Check if the worktree is stale (not updated in last 30 days)
          #
          # @return [Boolean] true if worktree is stale
          def stale?
            @updated_at < (Time.now - 30 * 24 * 60 * 60)
          end

          # Get the age of the worktree in days
          #
          # @return [Float] Age in days
          def age_days
            (Time.now - @created_at) / (24 * 60 * 60)
          end

          # Get the time since last update in days
          #
          # @return [Float] Days since last update
          def days_since_update
            (Time.now - @updated_at) / (24 * 60 * 60)
          end

          # Convert to hash for YAML serialization
          #
          # @return [Hash] Hash representation
          def to_h
            {
              "branch" => @branch,
              "path" => @path,
              "created_at" => @created_at.strftime("%Y-%m-%d %H:%M:%S"),
              "updated_at" => @updated_at.strftime("%Y-%m-%d %H:%M:%S")
            }.tap do |hash|
              hash["target_branch"] = @target_branch if @target_branch
            end
          end

          # Convert to YAML string
          #
          # @return [String] YAML representation
          def to_yaml
            to_h.to_yaml
          end

          # Load from task frontmatter hash
          #
          # @param task_data [Hash] Task frontmatter data
          # @return [WorktreeMetadata, nil] Worktree metadata or nil if not found
          #
          # @example
          #   metadata = WorktreeMetadata.from_task_data({
          #     "worktree" => {
          #       "branch" => "081-fix-auth",
          #       "path" => ".ace-wt/task.081",
          #       "target_branch" => "080-parent-branch",
          #       "created_at" => "2025-11-04 13:45:00"
          #     }
          #   })
          def self.from_task_data(task_data)
            worktree_data = task_data["worktree"]
            return nil unless worktree_data.is_a?(Hash)

            branch = worktree_data["branch"]
            path = worktree_data["path"]
            target_branch = worktree_data["target_branch"]
            return nil unless branch && path

            created_at = parse_time(worktree_data["created_at"]) || Time.now
            updated_at = parse_time(worktree_data["updated_at"]) || created_at

            new(
              branch: branch,
              path: path,
              target_branch: target_branch,
              created_at: created_at,
              updated_at: updated_at
            )
          end

          # Create from a worktree info object
          #
          # @param worktree_info [WorktreeInfo] Worktree information
          # @param project_root [String] Project root directory
          # @return [WorktreeMetadata] Worktree metadata
          #
          # @example
          #   metadata = WorktreeMetadata.from_worktree_info(worktree_info, "/project")
          def self.from_worktree_info(worktree_info, project_root = Dir.pwd)
            require_relative "../atoms/path_expander"

            # Make path relative to project root
            relative_path = begin
              Atoms::PathExpander.relative_to_git_root(worktree_info.path, project_root)
            rescue
              worktree_info.path
            end

            new(
              branch: worktree_info.branch,
              path: relative_path,
              created_at: worktree_info.created_at || Time.now
            )
          end

          # Merge worktree metadata into task frontmatter
          #
          # @param task_data [Hash] Existing task frontmatter
          # @param worktree_metadata [WorktreeMetadata] Worktree metadata to merge
          # @return [Hash] Updated task frontmatter
          #
          # @example
          #   updated_data = WorktreeMetadata.merge_into_task_data(
          #     existing_task_data,
          #     worktree_metadata
          #   )
          def self.merge_into_task_data(task_data, worktree_metadata)
            updated_data = task_data.dup
            updated_data["worktree"] = worktree_metadata.to_h
            updated_data
          end

          # Remove worktree metadata from task frontmatter
          #
          # @param task_data [Hash] Task frontmatter
          # @return [Hash] Task frontmatter without worktree metadata
          #
          # @example
          #   clean_data = WorktreeMetadata.remove_from_task_data(task_data)
          def self.remove_from_task_data(task_data)
            updated_data = task_data.dup
            updated_data.delete("worktree")
            updated_data
          end

          # Check if task has worktree metadata
          #
          # @param task_data [Hash] Task frontmatter
          # @return [Boolean] true if worktree metadata is present
          #
          # @example
          #   has_worktree = WorktreeMetadata.present_in_task?(task_data)
          def self.present_in_task?(task_data)
            worktree_data = task_data["worktree"]
            worktree_data.is_a?(Hash) &&
              worktree_data["branch"] &&
              worktree_data["path"]
          end

          # Find worktree metadata by branch name
          #
          # @param tasks [Array<Hash>] Array of task frontmatter hashes
          # @param branch [String] Branch name to search for
          # @return [WorktreeMetadata, nil] Matching metadata or nil
          #
          # @example
          #   metadata = WorktreeMetadata.find_by_branch(tasks, "081-fix-auth")
          def self.find_by_branch(tasks, branch)
            tasks.each do |task_data|
              metadata = from_task_data(task_data)
              return metadata if metadata && metadata.branch == branch
            end
            nil
          end

          # Find worktree metadata by path
          #
          # @param tasks [Array<Hash>] Array of task frontmatter hashes
          # @param path [String] Path to search for
          # @return [WorktreeMetadata, nil] Matching metadata or nil
          #
          # @example
          #   metadata = WorktreeMetadata.find_by_path(tasks, ".ace-wt/task.081")
          def self.find_by_path(tasks, path)
            tasks.each do |task_data|
              metadata = from_task_data(task_data)
              return metadata if metadata && metadata.path == path
            end
            nil
          end

          # Equality comparison
          #
          # @param other [WorktreeMetadata] Other worktree metadata
          # @return [Boolean] true if equal
          def ==(other)
            return false unless other.is_a?(WorktreeMetadata)

            @branch == other.branch && @path == other.path
          end

          alias_method :eql?, :==

          # Hash for using as hash keys
          #
          # @return [Integer] Hash value
          def hash
            [@branch, @path].hash
          end

          # String representation
          #
          # @return [String] String representation
          def to_s
            "#{@branch} at #{@path}"
          end

          # Inspect representation
          #
          # @return [String] Detailed inspect string
          def inspect
            "#<#{self.class.name} branch=#{@branch.inspect} path=#{@path.inspect} created=#{@created_at}>"
          end

          private

          # Parse time from various formats
          #
          # @param time_input [String, Time, nil] Time input
          # @return [Time, nil] Parsed time or nil
          def self.parse_time(time_input)
            return nil if time_input.nil?

            case time_input
            when Time
              time_input
            when String
              Time.parse(time_input)
            end
          rescue ArgumentError
            nil
          end
        end
      end
    end
  end
end
