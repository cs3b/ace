# frozen_string_literal: true

require_relative "../organisms/worktree_manager"

module Ace
  module Git
    module Worktree
      module Commands
        # Handles the create command
        class CreateCommand
          def execute(args)
            options = parse_options(args)
            identifier = args.first unless args.empty?

            # Validate inputs
            if options[:task]
              # Task mode - task reference is required
              task_ref = options[:task] == true ? identifier : options[:task]
              if task_ref.nil? || task_ref.empty?
                puts "Error: Task reference required with --task flag"
                puts "Usage: ace-git-worktree create --task <task-id>"
                return 1
              end
            elsif identifier.nil? || identifier.empty?
              # Traditional mode - branch name required
              puts "Error: Branch name required"
              puts "Usage: ace-git-worktree create <branch-name> [options]"
              puts "   or: ace-git-worktree create --task <task-id> [options]"
              return 1
            end

            # Create worktree manager
            manager = Organisms::WorktreeManager.new

            # Execute creation
            result = manager.create(identifier, options)

            # Output results
            if result[:success]
              if result[:dry_run]
                output_dry_run(result[:would_create])
              else
                output_success(result)
              end
              0
            else
              puts "Error: #{result[:error]}"
              1
            end
          rescue => e
            puts "Error: #{e.message}"
            puts e.backtrace if ENV["DEBUG"]
            1
          end

          private

          def parse_options(args)
            options = {}

            while args.any? && args.first.start_with?("--")
              arg = args.shift

              case arg
              when "--task"
                # Check if next arg is the task ID or if it's another flag
                if args.any? && !args.first.start_with?("--")
                  options[:task] = args.shift
                else
                  options[:task] = true
                end
              when "--path"
                options[:path] = args.shift
              when "--no-mise-trust"
                options[:no_mise_trust] = true
              when "--dry-run"
                options[:dry_run] = true
              when "--no-status-update"
                options[:no_status_update] = true
              when "--no-commit"
                options[:no_commit] = true
              when "--commit-message"
                options[:commit_message] = args.shift
              when "--force"
                options[:force] = true
              when "--help"
                print_help
                exit 0
              else
                puts "Unknown option: #{arg}"
                print_help
                exit 1
              end
            end

            options
          end

          def output_dry_run(details)
            puts "[DRY RUN] Would create worktree:"
            puts "  Directory: #{details[:directory]}"
            puts "  Branch: #{details[:branch]}"

            if details[:task]
              puts "  Task: #{details[:task][:id]} - #{details[:task][:title]}"
              puts "  Mark in-progress: #{details[:task][:would_mark_in_progress] ? 'yes' : 'no'}"
              puts "  Add metadata: #{details[:task][:would_add_metadata] ? 'yes' : 'no'}"
              puts "  Commit changes: #{details[:task][:would_commit] ? 'yes' : 'no'}"
            end

            puts "  Mise trust: #{details[:mise_trust] ? 'yes' : 'no'}"
            puts ""
            puts "No changes made."
          end

          def output_success(result)
            if result[:task]
              puts "Fetching task metadata from ace-taskflow..."
              puts "Task found: #{result[:task][:id]} - #{result[:task][:title]}"

              if result[:task][:status] == "in-progress"
                puts "Task status: already in-progress"
              else
                puts "Updating task status to in-progress..."
              end
            end

            puts "Creating worktree at: #{result[:outputs][:relative_path]}"
            puts "Creating branch: #{result[:branch]}"

            if result[:warnings]
              result[:warnings].each do |warning|
                puts warning
              end
            else
              puts "✓ Worktree created successfully"
            end

            puts ""
            puts "Path: #{result[:outputs][:absolute_path]}"
            puts "Branch: #{result[:branch]}"
            puts "Task Status: #{result[:task][:status]}" if result[:task]
          end

          def print_help
            puts <<~HELP
              Usage: ace-git-worktree create [options] [branch-name]
                     ace-git-worktree create --task <task-id> [options]

              Create a new git worktree with optional task integration.

              Arguments:
                branch-name         Branch name for traditional worktree creation
                task-id            Task ID when using --task flag (e.g., 081, task.081)

              Options:
                --task <id>        Create task-aware worktree for specified task
                --path <path>      Custom worktree path (overrides default)
                --no-mise-trust    Skip automatic mise trust
                --dry-run          Preview what would be created without creating
                --no-status-update Skip marking task as in-progress (task mode only)
                --no-commit        Skip committing task changes (task mode only)
                --commit-message   Custom commit message for task update
                --force            Force creation even if directory exists
                --help             Show this help message

              Examples:
                # Create task-aware worktree
                ace-git-worktree create --task 081

                # Traditional worktree creation
                ace-git-worktree create feature-branch --path .worktrees/feature

                # Dry run to preview
                ace-git-worktree create --task 081 --dry-run
            HELP
          end
        end
      end
    end
  end
end