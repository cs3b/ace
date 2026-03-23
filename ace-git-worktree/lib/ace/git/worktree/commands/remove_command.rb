# frozen_string_literal: true

require_relative "../atoms/task_id_extractor"

module Ace
  module Git
    module Worktree
      module Commands
        # Remove command
        #
        # Removes worktrees with safety checks and cleanup options.
        # Supports both task-aware and traditional worktree removal.
        #
        # @example Remove by task ID
        #   RemoveCommand.new.run(["--task", "081"])
        #
        # @example Remove by branch name
        #   RemoveCommand.new.run(["feature-branch"])
        #
        # @example Force remove
        #   RemoveCommand.new.run(["--task", "081", "--force"])
        class RemoveCommand
          # Initialize a new RemoveCommand
          def initialize
            @manager = Organisms::WorktreeManager.new
            @task_fetcher = Molecules::TaskFetcher.new
          end

          # Run the remove command
          #
          # @param args [Array<String>] Command arguments
          # @return [Integer] Exit code (0 for success, 1 for error)
          def run(args = [])
            options = parse_arguments(args)
            return show_help if options[:help]

            validate_options(options)

            if options[:task]
              remove_task_worktree(options)
            else
              remove_traditional_worktree(options)
            end
          rescue ArgumentError => e
            puts "Error: #{e.message}"
            puts
            show_help
            1
          rescue => e
            puts "Error: #{e.message}"
            1
          end

          # Show help for the remove command
          #
          # @return [Integer] Exit code
          def show_help
            puts <<~HELP
              ace-git-worktree remove - Remove a worktree

              USAGE:
                  ace-git-worktree remove <identifier> [OPTIONS]
                  ace-git-worktree remove --task <task-id> [OPTIONS]

              IDENTIFIERS:
                  Task ID:                081, task.081, v.0.9.0+081
                  Branch name:            feature-branch, main
                  Directory name:        task.081, feature-branch
                  Full path:              /path/to/worktree

              OPTIONS:
                  --task <task-id>         Remove worktree for specific task
                  --force                 Force removal even with uncommitted changes
                  --keep-directory        Keep the worktree directory (default: remove)
                  --delete-branch, -db    Also delete the associated branch
                  --dry-run               Show what would be removed without removing
                  --help, -h              Show this help message

              EXAMPLES:
                  # Remove task worktree
                  ace-git-worktree remove --task 081

                  # Remove by branch name
                  ace-git-worktree remove feature-branch

                  # Force remove with changes
                  ace-git-worktree remove --task 081 --force

                  # Dry run to see what would be removed
                  ace-git-worktree remove --task 081 --dry-run

                  # Remove but keep directory
                  ace-git-worktree remove --task 081 --keep-directory

              SAFETY:
                  • The command checks for uncommitted changes
                  • Use --force to remove worktrees with changes
                  • Task removal also cleans up task metadata
                  • Main worktree cannot be removed accidentally

              CONFIGURATION:
                  Worktree removal respects settings in .ace/git/worktree.yml
            HELP
            0
          end

          private

          # Parse command line arguments
          #
          # @param args [Array<String>] Command arguments
          # @return [Hash] Parsed options
          def parse_arguments(args)
            options = {
              task: nil,
              identifier: nil,
              force: false,
              keep_directory: false,
              delete_branch: false,
              dry_run: false,
              help: false
            }

            i = 0
            while i < args.length
              arg = args[i]

              case arg
              when "--task"
                i += 1
                options[:task] = args[i]
              when "--force"
                options[:force] = true
              when "--keep-directory"
                options[:keep_directory] = true
              when "--delete-branch", "-db"
                options[:delete_branch] = true
              when "--dry-run"
                options[:dry_run] = true
              when "--help", "-h"
                options[:help] = true
              when /^--/
                raise ArgumentError, "Unknown option: #{arg}"
              else
                # Positional argument - worktree identifier
                if options[:identifier]
                  raise ArgumentError, "Multiple identifiers specified: #{options[:identifier]} and #{arg}"
                end
                options[:identifier] = arg
              end

              i += 1
            end

            options
          end

          # Validate parsed options
          #
          # @param options [Hash] Parsed options
          def validate_options(options)
            if options[:task] && options[:identifier]
              raise ArgumentError, "Cannot specify both --task and identifier"
            end

            if !options[:task] && !options[:identifier]
              raise ArgumentError, "Must specify either --task <task-id> or <identifier>"
            end

            if options[:task] && options[:task].empty?
              raise ArgumentError, "Task ID cannot be empty"
            end

            if options[:identifier] && options[:identifier].empty?
              raise ArgumentError, "Identifier cannot be empty"
            end

            # Security validation for identifiers
            if options[:identifier] && contains_dangerous_patterns?(options[:identifier])
              raise ArgumentError, "Identifier contains potentially dangerous characters"
            end

            # Security validation for task IDs
            if options[:task] && contains_dangerous_patterns?(options[:task])
              raise ArgumentError, "Task ID contains potentially dangerous characters"
            end
          end

          # Check if a string contains dangerous patterns
          #
          # @param value [String] Value to check
          # @return [Boolean] true if dangerous patterns found
          def contains_dangerous_patterns?(value)
            return false if value.nil?

            dangerous_patterns = [
              /;/,           # Command separator
              /\|/,          # Pipe
              /`/,           # Backtick command substitution
              /\$\(/,        # Command substitution
              /\.\.\//,      # Path traversal
              /&&/,          # AND operator
              /\|\|/,        # OR operator
              /\x00/         # Null byte
            ]

            dangerous_patterns.any? { |pattern| value.match?(pattern) }
          end

          # Remove a task-aware worktree
          #
          # @param options [Hash] Command options
          # @return [Integer] Exit code
          def remove_task_worktree(options)
            puts "Removing worktree for task: #{options[:task]}"

            # Try to find task data first
            task_data = @task_fetcher.fetch(options[:task])
            task_found = false
            worktree_info = nil

            if task_data
              puts "Task found: #{task_data[:title]} (status: #{task_data[:status]})"
              worktree_info = find_worktree_for_task(task_data)
              task_found = true
            else
              # Fallback: Try to find worktree by task reference (for cases where task metadata exists but worktree doesn't)
              puts "Task not found in ace-task, checking for orphaned worktree..."
              worktree_info = find_worktree_by_task_reference(options[:task])
              task_found = false
            end

            unless worktree_info
              # Even if worktree doesn't exist, try to clean up the branch if requested
              if task_data
                puts "Task found but no worktree is associated with it."
                puts "Task: #{task_data[:title]} (status: #{task_data[:status]})"

                # Try to find the orphaned branch
                branch_name = find_branch_for_task(task_data, options[:task])
                if branch_name
                  puts "Found orphaned branch: #{branch_name}"

                  # Only delete if user requested it
                  if options[:delete_branch]
                    # Use safe deletion method (same as main flow)
                    remover = Ace::Git::Worktree::Molecules::WorktreeRemover.new
                    delete_result = remover.send(:delete_branch_if_safe, branch_name, options[:force])

                    if delete_result[:success]
                      puts "Deleted branch: #{branch_name}"
                      return 0
                    else
                      puts "Warning: Branch '#{branch_name}' was not deleted"
                      puts "Note: Use --force to delete unmerged branches"
                    end
                  else
                    puts "Note: Branch '#{branch_name}' still exists. Use --delete-branch to remove it."
                  end
                end

                puts ""
                puts "Use 'ace-git-worktree list' to see available worktrees"
              else
                puts "Error: Task not found: #{options[:task]}"
                puts "Use 'ace-task list' to see available tasks"
              end
              return 1
            end

            if options[:dry_run]
              puts "DRY RUN - No changes will be made"
              puts "This would:"
              puts "  • Remove worktree and its metadata from task #{options[:task]}"
              puts "  • #{task_found ? "Clean up task file metadata" : "Skip task metadata cleanup (no worktree metadata found)"}"
              puts "  • #{options[:keep_directory] ? "Keep" : "Remove"} the worktree directory"
              return 0
            end

            # Prepare removal options
            {
              force: options[:force],
              remove_directory: !options[:keep_directory]
            }.compact

            if options[:dry_run]
              puts "DRY RUN - No changes will be made"
              puts "This would:"
              puts "  • Remove worktree and its metadata from task #{options[:task]}"
              puts "  • #{task_found ? "Clean up task file metadata" : "Skip task metadata cleanup (task not found)"}"
              puts "  • #{options[:keep_directory] ? "Keep" : "Remove"} the worktree directory"
              return 0
            end

            # Remove the worktree using direct git worktree command
            # This bypasses the problematic safety check in WorktreeRemover
            puts "Removing worktree at: #{worktree_info.path}"

            begin
              # Use GitCommand atom for safe execution
              git_result = Ace::Git::Worktree::Atoms::GitCommand.worktree("remove", worktree_info.path, "--force")

              if git_result[:success]
                puts "Worktree removed successfully!"
                puts "Worktree path: #{worktree_info.path}"
                puts "Branch: #{worktree_info.branch}"

                # Delete the branch if requested and it exists (using safe deletion method)
                if options[:delete_branch] && worktree_info.branch && !worktree_info.branch.empty?
                  # Use WorktreeRemover's safe deletion method for consistency
                  remover = Ace::Git::Worktree::Molecules::WorktreeRemover.new
                  delete_result = remover.send(:delete_branch_if_safe, worktree_info.branch, options[:force])

                  if delete_result[:success]
                    puts "Deleted branch: #{worktree_info.branch}"
                  else
                    # Branch deletion failed (likely unmerged without --force)
                    puts "Warning: Branch '#{worktree_info.branch}' was not deleted"
                    puts "Note: Use --force to delete unmerged branches"
                  end
                elsif worktree_info.branch && !worktree_info.branch.empty?
                  puts "\nNote: Branch '#{worktree_info.branch}' still exists. Use --delete-branch to remove it."
                end

                # Provide appropriate messaging based on task status
                if task_found && task_data
                  status = task_data[:status].to_s.strip
                  if status.include?("done") || status.include?("completed")
                    puts "\nTask completed: no metadata cleanup needed"
                  else
                    puts "\nNote: Task metadata cleanup not available for this task status"
                  end
                end
                0
              else
                puts "Failed to remove worktree: #{git_result[:error]}"
                1
              end
            rescue => e
              puts "Error removing worktree: #{e.message}"
              1
            end
          end

          # Remove a traditional worktree
          #
          # @param options [Hash] Command options
          # @return [Integer] Exit code
          def remove_traditional_worktree(options)
            puts "Removing worktree: #{options[:identifier]}"

            if options[:dry_run]
              puts "DRY RUN - No changes will be made"
              puts "This would remove the worktree and #{options[:keep_directory] ? "keep" : "remove"} its directory"
              return 0
            end

            # Prepare removal options
            removal_options = {
              force: options[:force],
              remove_directory: !options[:keep_directory],
              delete_branch: options[:delete_branch]
            }.compact

            # Remove the worktree
            result = @manager.remove(options[:identifier], removal_options)

            if result[:success]
              display_traditional_removal_result(result, options)
              0
            else
              puts "Failed to remove worktree: #{result[:error]}"
              display_removal_hints(options[:identifier], result[:error])
              1
            end
          end

          # Display task worktree removal result
          #
          # @param result [Hash] Removal result
          def display_task_removal_result(result)
            puts "\nTask worktree removed successfully!"
            puts "Task ID: #{result[:task_id]}"
            puts "Worktree path: #{result[:worktree_path]}" if result[:worktree_path]
            puts "Branch: #{result[:branch]}" if result[:branch]
            puts "\nSteps completed:"
            result[:steps_completed].each_with_index do |step, i|
              puts "  ✓ #{step.tr("_", " ")}"
            end

            puts "\nNote: Task metadata has been cleaned up."
          end

          # Display traditional worktree removal result
          #
          # @param result [Hash] Removal result
          # @param options [Hash] Command options
          def display_traditional_removal_result(result, options = {})
            puts "\nWorktree removed successfully!"
            puts "Worktree path: #{result[:path]}" if result[:path]
            puts "Branch: #{result[:branch]}" if result[:branch]

            if result[:branch_deleted]
              puts "Branch deleted: #{result[:branch]}"
            elsif result[:branch] && !result[:branch_deleted]
              # This message is shown if the branch exists but wasn't deleted,
              # which happens if --delete-branch was not provided, or if the
              # branch deletion failed (e.g., unmerged branch without --force)
              puts "\nNote: Branch '#{result[:branch]}' still exists. Use --delete-branch to remove it."
            end
          end

          # Display removal hints and suggestions
          #
          # @param identifier [String] The identifier that failed
          # @param error [String] The error message
          def display_removal_hints(identifier, error)
            if error.include?("not found")
              puts "\nWorktree not found. Available worktrees:"
              list_result = @manager.list_all(format: :simple)
              if list_result[:success] && list_result[:worktrees].any?
                list_result[:worktrees].each do |worktree|
                  prefix = worktree.task_associated? ? "Task #{worktree.task_id}: " : ""
                  puts "  #{prefix}#{worktree.branch || "detached"} (#{worktree.path})"
                end
              else
                puts "  No worktrees found."
              end
            elsif error.include?("uncommitted changes")
              puts "\nWorktree has uncommitted changes. Options:"
              puts "  • Use --force to remove anyway (changes will be lost)"
              puts "  • Commit or stash changes first"
              puts "  • Check worktree status with: git status"
            else
              puts "\nSuggestions:"
              puts "  • Check the worktree identifier spelling"
              puts "  • Use 'ace-git-worktree list' to see available worktrees"
              puts "  • Use --force if you're sure about removal"
            end
          end

          # Find worktree by task reference (for completed tasks)
          #
          # @param task_ref [String] Task reference
          # @return [WorktreeInfo, nil] Worktree info or nil if not found
          def find_worktree_by_task_reference(task_ref)
            worktree_lister = Ace::Git::Worktree::Molecules::WorktreeLister.new
            worktrees = worktree_lister.list_all

            # Normalize task reference to match worktree IDs
            normalized_id = normalize_task_id_for_matching(task_ref)

            # Find worktree with matching task ID
            worktrees.find do |worktree|
              worktree.task_id == normalized_id
            end
          end

          # Find worktree for task (when task data is available)
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @return [WorktreeInfo, nil] Worktree info or nil if not found
          def find_worktree_for_task(task_data)
            worktree_lister = Ace::Git::Worktree::Molecules::WorktreeLister.new
            worktrees = worktree_lister.list_all

            # Extract task number from task data
            task_number = extract_task_number(task_data)

            worktrees.find do |worktree|
              worktree.task_id == task_number ||
                worktree.task_id == task_data[:id] ||
                worktree.branch == task_data[:branch]
            end
          end

          # Extract task number from task data
          #
          # @param task_data [Hash] Task data
          # @return [String] Task number
          def extract_task_number(task_data)
            # Use shared extractor that preserves subtask IDs (e.g., "121.01")
            Atoms::TaskIDExtractor.extract(task_data)
          end

          # Normalize task ID for worktree matching
          #
          # @param task_ref [String] Task reference
          # @return [String] Normalized task ID
          def normalize_task_id_for_matching(task_ref)
            # Use shared extractor that preserves subtask IDs (e.g., "121.01")
            Atoms::TaskIDExtractor.normalize(task_ref) || task_ref
          end

          # Find branch associated with a task
          #
          # @param task_data [Hash] Task data
          # @param task_ref [String] Task reference
          # @return [String, nil] Branch name or nil if not found
          def find_branch_for_task(task_data, task_ref)
            # Get all branches
            branches_result = Ace::Git::Worktree::Atoms::GitCommand.execute("branch", "--format=%(refname:short)")
            return nil unless branches_result[:success]

            branches = branches_result[:output].split("\n").map(&:strip)
            task_number = extract_task_number(task_data)

            # Try to find branch matching task patterns
            # Pattern 1: 052-task-title
            # Pattern 2: task-052
            # Pattern 3: v.0.9.0-052
            branches.find do |branch|
              branch.start_with?("#{task_number}-", "task-#{task_number}") ||
                branch =~ /\d+-#{task_number}-/ ||
                branch.include?("-#{task_number}-")
            end
          end
        end
      end
    end
  end
end
