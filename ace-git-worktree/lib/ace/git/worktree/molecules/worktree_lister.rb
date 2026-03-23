# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Molecules
        # Worktree lister molecule
        #
        # Lists and manages git worktrees with task association capabilities.
        # Provides filtering, searching, and formatting of worktree information.
        #
        # @example List all worktrees
        #   lister = WorktreeLister.new
        #   worktrees = lister.list_all
        #
        # @example Find worktree by task ID
        #   worktree = lister.find_by_task_id("081")
        #
        # @example List with task associations
        #   worktrees = lister.list_with_tasks
        class WorktreeLister
          # Fallback timeout for git commands
          # Used only when config is unavailable
          FALLBACK_TIMEOUT = 30

          # Initialize a new WorktreeLister
          #
          # @param timeout [Integer, nil] Command timeout in seconds (uses config default if nil)
          def initialize(timeout: nil)
            @timeout = timeout || config_timeout
          end

          private

          # Get timeout from config or fallback
          # @return [Integer] Timeout in seconds
          def config_timeout
            Ace::Git::Worktree.list_timeout
          rescue
            FALLBACK_TIMEOUT
          end

          public

          # List all worktrees in the repository
          #
          # @return [Array<WorktreeInfo>] Array of worktree information
          #
          # @example
          #   lister = WorktreeLister.new
          #   worktrees = lister.list_all
          #   worktrees.each { |wt| puts "#{wt.branch} at #{wt.path}" }
          def list_all
            output = execute_git_worktree_list
            return [] unless output

            Models::WorktreeInfo.from_git_output_list(output)
          end

          # List worktrees with task associations resolved
          #
          # @return [Array<WorktreeInfo>] Array of worktree information with task IDs
          #
          # @example
          #   worktrees = lister.list_with_tasks
          #   worktrees.each { |wt| puts "Task #{wt.task_id}: #{wt.branch}" if wt.task_associated? }
          def list_with_tasks
            worktrees = list_all
            resolve_task_associations(worktrees)
          end

          # Find worktree by task ID
          #
          # @param task_id [String] Task ID to search for
          # @return [WorktreeInfo, nil] Matching worktree or nil
          #
          # @example
          #   worktree = lister.find_by_task_id("081")
          #   if worktree
          #     puts "Found worktree for task 081: #{worktree.path}"
          #   end
          def find_by_task_id(task_id)
            worktrees = list_with_tasks
            Models::WorktreeInfo.find_by_task_id(worktrees, task_id.to_s)
          end

          # Find worktree by branch name
          #
          # @param branch_name [String] Branch name to search for
          # @return [WorktreeInfo, nil] Matching worktree or nil
          #
          # @example
          #   worktree = lister.find_by_branch("081-fix-auth")
          def find_by_branch(branch_name)
            worktrees = list_all
            Models::WorktreeInfo.find_by_branch(worktrees, branch_name.to_s)
          end

          # Find worktree by directory name
          #
          # @param directory [String] Directory name to search for
          # @return [WorktreeInfo, nil] Matching worktree or nil
          #
          # @example
          #   worktree = lister.find_by_directory("task.081")
          def find_by_directory(directory)
            worktrees = list_all
            Models::WorktreeInfo.find_by_directory(worktrees, directory.to_s)
          end

          # Find worktree by path
          #
          # @param path [String] Path to search for
          # @return [WorktreeInfo, nil] Matching worktree or nil
          #
          # @example
          #   worktree = lister.find_by_path("/project/.ace-wt/task.081")
          def find_by_path(path)
            worktrees = list_all
            expanded_path = File.expand_path(path)
            worktrees.find { |wt| File.expand_path(wt.path) == expanded_path }
          end

          # Filter worktrees by criteria
          #
          # @param worktrees [Array<WorktreeInfo>] Worktrees to filter
          # @param task_associated [Boolean, nil] Filter by task association
          # @param usable [Boolean, nil] Filter by usability
          # @param branch_pattern [String, nil] Filter by branch name pattern
          # @return [Array<WorktreeInfo>] Filtered worktrees
          #
          # @example
          #   # Get only task-associated worktrees
          #   task_worktrees = lister.filter(worktrees, task_associated: true)
          #
          #   # Get only usable worktrees
          #   usable_worktrees = lister.filter(worktrees, usable: true)
          #
          #   # Get worktrees with branches matching a pattern
          #   auth_worktrees = lister.filter(worktrees, branch_pattern: "auth")
          def filter(worktrees, task_associated: nil, usable: nil, branch_pattern: nil)
            filtered = Array(worktrees)

            # Filter by task association
            if task_associated == true
              filtered = filtered.select(&:task_associated?)
            elsif task_associated == false
              filtered = filtered.reject(&:task_associated?)
            end

            # Filter by usability
            if usable == true
              filtered = filtered.select(&:usable?)
            elsif usable == false
              filtered = filtered.reject(&:usable?)
            end

            # Filter by branch pattern
            if branch_pattern
              pattern = Regexp.new(branch_pattern, Regexp::IGNORECASE)
              filtered = filtered.select { |wt| wt.branch&.match?(pattern) }
            end

            filtered
          end

          # Search worktrees by various criteria
          #
          # @param query [String] Search query
          # @param search_in [Array<Symbol>] Where to search ([:branch, :path, :task_id])
          # @return [Array<WorktreeInfo>] Matching worktrees
          #
          # @example
          #   results = lister.search("auth", search_in: [:branch, :task_id])
          def search(query, search_in: [:branch, :path, :task_id])
            return [] if query.nil? || query.empty?

            worktrees = list_with_tasks
            pattern = Regexp.new(query, Regexp::IGNORECASE)

            worktrees.select do |worktree|
              search_in.any? do |field|
                case field
                when :branch
                  worktree.branch&.match?(pattern)
                when :path
                  worktree.path.match?(pattern)
                when :task_id
                  worktree.task_id&.match?(pattern)
                else
                  false
                end
              end
            end
          end

          # Get worktree statistics
          #
          # @param worktrees [Array<WorktreeInfo>, nil] Optional pre-filtered worktree list
          # @return [Hash] Statistics about worktrees
          #
          # @example
          #   stats = lister.get_statistics
          #   puts "Total worktrees: #{stats[:total]}"
          #   puts "Task-associated: #{stats[:task_associated]}"
          #   puts "Usable: #{stats[:usable]}"
          def get_statistics(worktrees = nil)
            worktrees = worktrees ? Array(worktrees) : list_with_tasks

            {
              total: worktrees.length,
              task_associated: worktrees.count(&:task_associated?),
              non_task_associated: worktrees.reject(&:task_associated?).length,
              usable: worktrees.count(&:usable?),
              unusable: worktrees.reject(&:usable?).length,
              bare: worktrees.count(&:bare),
              detached: worktrees.count(&:detached),
              branches: worktrees.map(&:branch).compact,
              task_ids: worktrees.map(&:task_id).compact.uniq
            }
          end

          # Format worktree list for display
          #
          # @param worktrees [Array<WorktreeInfo>] Worktrees to format
          # @param format [Symbol] Output format (:table, :json, :simple)
          # @return [String] Formatted output
          #
          # @example
          #   output = lister.format_for_display(worktrees, :table)
          #   puts output
          def format_for_display(worktrees, format = :table)
            case format
            when :table
              format_as_table(worktrees)
            when :json
              format_as_json(worktrees)
            when :simple
              format_as_simple(worktrees)
            else
              format_as_table(worktrees)
            end
          end

          private

          # Execute git worktree list command
          #
          # @return [String, nil] Command output or nil if failed
          def execute_git_worktree_list
            require_relative "../atoms/git_command"
            result = Atoms::GitCommand.worktree("list", "--porcelain", timeout: @timeout)
            result[:success] ? result[:output] : nil
          end

          # Resolve task associations for worktrees
          #
          # @param worktrees [Array<WorktreeInfo>] Worktrees to process
          # @return [Array<WorktreeInfo>] Worktrees with resolved task associations
          def resolve_task_associations(worktrees)
            return worktrees if worktrees.empty?

            # Try to resolve task associations from worktree metadata
            # This would typically involve looking up task files
            # For now, we'll use the automatic extraction from WorktreeInfo

            worktrees
          end

          # Format worktrees as a table
          #
          # @param worktrees [Array<WorktreeInfo>] Worktrees to format
          # @return [String] Table-formatted string
          def format_as_table(worktrees)
            return "No worktrees found.\n" if worktrees.empty?

            # Calculate column widths
            max_path_width = [worktrees.map { |wt| wt.path.length }.max, 40].max
            max_branch_width = [worktrees.map { |wt| (wt.branch || "detached").length }.max, 15].max
            max_task_width = [worktrees.map { |wt| (wt.task_id || "-").length }.max, 8].max

            # Build header
            header = sprintf("%-#{max_task_width}s %-#{max_branch_width}s %-#{max_path_width}s %s",
              "Task", "Branch", "Path", "Status")
            separator = "-" * header.length

            # Build table rows
            rows = worktrees.map do |wt|
              status = if wt.bare
                "bare"
              elsif wt.detached
                "detached"
              elsif wt.task_associated?
                "task"
              else
                "normal"
              end

              sprintf("%-#{max_task_width}s %-#{max_branch_width}s %-#{max_path_width}s %s",
                wt.task_id || "-",
                wt.branch || "detached",
                wt.path,
                status)
            end

            [header, separator, *rows].join("\n") + "\n"
          end

          # Format worktrees as JSON
          #
          # @param worktrees [Array<WorktreeInfo>] Worktrees to format
          # @return [String] JSON-formatted string
          def format_as_json(worktrees)
            require "json"
            worktrees.map(&:to_h).to_json
          end

          # Format worktrees as simple list
          #
          # @param worktrees [Array<WorktreeInfo>] Worktrees to format
          # @return [String] Simple list string
          def format_as_simple(worktrees)
            return "No worktrees found.\n" if worktrees.empty?

            worktrees.map do |wt|
              if wt.task_associated?
                "Task #{wt.task_id}: #{wt.branch} at #{wt.path}"
              else
                "#{wt.branch || "detached"} at #{wt.path}"
              end
            end.join("\n") + "\n"
          end
        end
      end
    end
  end
end
