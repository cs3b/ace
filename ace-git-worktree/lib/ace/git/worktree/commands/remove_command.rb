# frozen_string_literal: true

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
          end

          # Run the remove command
          #
          # @param args [Array<String>] Command arguments
          # @return [Integer] Exit code (0 for success, 1 for error)
          def run(args = [])
            begin
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
            rescue StandardError => e
              puts "Error: #{e.message}"
              1
            end
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
          end

          # Remove a task-aware worktree
          #
          # @param options [Hash] Command options
          # @return [Integer] Exit code
          def remove_task_worktree(options)
            puts "Removing worktree for task: #{options[:task]}"

            if options[:dry_run]
              puts "DRY RUN - No changes will be made"
              puts "This would:"
              puts "  • Remove worktree and its metadata from task #{options[:task]}"
              puts "  • Clean up task file metadata"
              puts "  • #{options[:keep_directory] ? 'Keep' : 'Remove'} the worktree directory"
              return 0
            end

            # Prepare removal options
            removal_options = {
              force: options[:force],
              remove_directory: !options[:keep_directory]
            }.compact

            # Remove the task worktree
            result = @manager.remove_task(options[:task], removal_options)

            if result[:success]
              display_task_removal_result(result)
              0
            else
              puts "Failed to remove worktree: #{result[:error]}"
              display_removal_hints(options[:task], result[:error])
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
              puts "This would remove the worktree and #{options[:keep_directory] ? 'keep' : 'remove'} its directory"
              return 0
            end

            # Prepare removal options
            removal_options = {
              force: options[:force],
              remove_directory: !options[:keep_directory]
            }.compact

            # Remove the worktree
            result = @manager.remove(options[:identifier], removal_options)

            if result[:success]
              display_traditional_removal_result(result)
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
              puts "  ✓ #{step.gsub('_', ' ')}"
            end

            puts "\nNote: Task metadata has been cleaned up."
          end

          # Display traditional worktree removal result
          #
          # @param result [Hash] Removal result
          def display_traditional_removal_result(result)
            puts "\nWorktree removed successfully!"
            puts "Worktree path: #{result[:path]}" if result[:path]
            puts "Branch: #{result[:branch]}" if result[:branch]
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
                  puts "  #{prefix}#{worktree.branch || 'detached'} (#{worktree.path})"
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
        end
      end
    end
  end
end