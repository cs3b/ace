# frozen_string_literal: true

require_relative "../models/worktree_info"
require_relative "../atoms/git_command"

module Ace
  module Git
    module Worktree
      module Molecules
        # Lists worktrees with task associations
        class WorktreeLister
          # List all worktrees
          # @param options [Hash] Options for listing
          # @return [Array<Models::WorktreeInfo>] List of worktrees
          def self.list(options = {})
            result = Atoms::GitCommand.execute("worktree", "list", "--porcelain")
            return [] unless result[:success]

            worktrees = parse_porcelain_output(result[:output])

            # Add task associations if requested
            if options[:include_tasks]
              worktrees = add_task_associations(worktrees, options)
            end

            worktrees
          end

          # Find a worktree by identifier (task ID, branch, or path)
          # @param identifier [String] Identifier to search for
          # @return [Models::WorktreeInfo, nil] Worktree info or nil
          def self.find(identifier)
            return nil if identifier.nil? || identifier.empty?

            worktrees = list(include_tasks: true)

            # Try to find by various criteria
            worktrees.find do |wt|
              # Check exact path match
              wt.path == identifier ||
                # Check directory name match
                wt.directory == identifier ||
                # Check branch name match
                wt.branch == identifier ||
                # Check task ID match (if associated)
                wt.task_id == identifier ||
                # Check task number match
                (wt.task_id && wt.task_id.include?("task.#{identifier}")) ||
                # Check if path ends with the identifier
                wt.path.end_with?("/#{identifier}")
            end
          end

          # Get worktrees associated with tasks
          # @return [Array<Models::WorktreeInfo>] Task-associated worktrees
          def self.task_worktrees
            list(include_tasks: true).select(&:task?)
          end

          # Check if a worktree exists for a given path
          # @param path [String] Path to check
          # @return [Boolean] true if worktree exists
          def self.exists?(path)
            return false if path.nil? || path.empty?

            expanded_path = File.expand_path(path)
            list.any? { |wt| File.expand_path(wt.path) == expanded_path }
          end

          private

          # Parse git worktree list --porcelain output
          def self.parse_porcelain_output(output)
            worktrees = []
            current = nil

            output.lines.each do |line|
              line = line.strip
              next if line.empty?

              case line
              when /^worktree (.+)$/
                # Save previous worktree if exists
                if current
                  worktrees << Models::WorktreeInfo.new(**current)
                end
                current = { path: $1 }
              when /^HEAD ([a-f0-9]+)$/
                current[:commit] = $1 if current
              when /^branch refs\/heads\/(.+)$/
                current[:branch] = $1 if current
              when /^detached$/
                current[:branch] = "HEAD (detached)" if current
              when /^locked$/
                current[:locked] = true if current
              when /^prunable$/
                current[:prunable] = true if current
              end
            end

            # Don't forget the last one
            if current
              worktrees << Models::WorktreeInfo.new(**current)
            end

            worktrees
          end

          # Add task associations to worktrees
          def self.add_task_associations(worktrees, options = {})
            config = options[:config] || Worktree.configuration

            worktrees.map do |wt|
              task_id = extract_task_id(wt, config)
              if task_id
                Models::WorktreeInfo.new(
                  path: wt.path,
                  branch: wt.branch,
                  commit: wt.commit,
                  directory: wt.directory,
                  task_id: task_id,
                  locked: wt.locked?,
                  prunable: wt.prunable?
                )
              else
                wt
              end
            end
          end

          # Extract task ID from worktree based on naming patterns
          def self.extract_task_id(worktree, config)
            # Try to extract from directory name
            dir_pattern = config.task_directory_format
            if dir_pattern && dir_pattern.include?("{id}")
              # Simple pattern matching for task.{id} format
              if worktree.directory =~ /task\.(\d+)/
                task_num = $1
                # Try to resolve to full task ID
                return resolve_task_id(task_num)
              end
            end

            # Try to extract from branch name
            branch_pattern = config.task_branch_format
            if branch_pattern && branch_pattern.include?("{id}")
              # Pattern matching for {id}-{slug} format
              if worktree.branch =~ /^(\d+)-/
                task_num = $1
                return resolve_task_id(task_num)
              end
            end

            nil
          end

          # Resolve task number to full task ID
          def self.resolve_task_id(task_number)
            # For now, just return the formatted task reference
            # In a full implementation, we might query ace-taskflow
            "task.#{task_number}"
          end
        end
      end
    end
  end
end