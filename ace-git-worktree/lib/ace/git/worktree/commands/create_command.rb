# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Commands
        # Create command
        #
        # Handles worktree creation with support for both task-aware and traditional
        # worktree creation. Provides various options for customization.
        #
        # @example Task-aware worktree creation
        #   CreateCommand.new.run(["--task", "081"])
        #
        # @example Traditional worktree creation
        #   CreateCommand.new.run(["feature-branch"])
        #
        # @example Dry run
        #   CreateCommand.new.run(["--task", "081", "--dry-run"])
        class CreateCommand
          # Initialize a new CreateCommand
          def initialize
            @manager = Organisms::WorktreeManager.new
          end

          # Run the create command
          #
          # @param args [Array<String>] Command arguments
          # @return [Integer] Exit code (0 for success, 1 for error)
          def run(args = [])
            begin
              options = parse_arguments(args)
              return show_help if options[:help]

              validate_options(options)

              if options[:task]
                create_task_worktree(options)
              else
                create_traditional_worktree(options)
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

          # Show help for the create command
          #
          # @return [Integer] Exit code
          def show_help
            puts <<~HELP
              ace-git-worktree create - Create a new worktree

              USAGE:
                  ace-git-worktree create <branch-name> [OPTIONS]
                  ace-git-worktree create --task <task-id> [OPTIONS]

              TASK-AWARE CREATION:
                  --task <task-id>         Create worktree for a specific task
                                         Task ID formats: 081, task.081, v.0.9.0+081

              OPTIONS:
                  --path <path>           Custom worktree path (default: from config)
                  --no-mise-trust         Skip automatic mise trust
                  --dry-run               Show what would be created without creating
                  --no-status-update      Skip marking task as in-progress
                  --no-commit             Skip committing task changes
                  --commit-message <msg>  Custom commit message for task updates
                  --force                 Create even if worktree already exists
                  --help, -h              Show this help message

              EXAMPLES:
                  # Create task-aware worktree
                  ace-git-worktree create --task 081

                  # Create traditional worktree
                  ace-git-worktree create feature-branch

                  # Custom path and dry run
                  ace-git-worktree create --task 081 --path ~/worktrees --dry-run

                  # Skip automatic actions
                  ace-git-worktree create --task 081 --no-status-update --no-mise-trust

              CONFIGURATION:
                  Worktree creation is controlled by .ace/git/worktree.yml:
                  - root_path: Default worktree root directory
                  - task.auto_*: Automation settings for task workflows
                  - mise_trust_auto: Automatic mise trust behavior
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
              path: nil,
              dry_run: false,
              no_mise_trust: false,
              no_status_update: false,
              no_commit: false,
              commit_message: nil,
              force: false,
              help: false
            }

            i = 0
            while i < args.length
              arg = args[i]

              case arg
              when "--task"
                i += 1
                options[:task] = args[i]
              when "--path"
                i += 1
                options[:path] = args[i]
              when "--dry-run"
                options[:dry_run] = true
              when "--no-mise-trust"
                options[:no_mise_trust] = true
              when "--no-status-update"
                options[:no_status_update] = true
              when "--no-commit"
                options[:no_commit] = true
              when "--commit-message"
                i += 1
                options[:commit_message] = args[i]
              when "--force"
                options[:force] = true
              when "--help", "-h"
                options[:help] = true
              when /^--/
                raise ArgumentError, "Unknown option: #{arg}"
              else
                # Positional argument - branch name for traditional creation
                if options[:branch_name]
                  raise ArgumentError, "Multiple branch names specified: #{options[:branch_name]} and #{arg}"
                end
                options[:branch_name] = arg
              end

              i += 1
            end

            options
          end

          # Validate parsed options
          #
          # @param options [Hash] Parsed options
          def validate_options(options)
            if options[:task] && options[:branch_name]
              raise ArgumentError, "Cannot specify both --task and branch name"
            end

            if !options[:task] && !options[:branch_name]
              raise ArgumentError, "Must specify either --task <task-id> or <branch-name>"
            end

            if options[:task] && options[:task].empty?
              raise ArgumentError, "Task ID cannot be empty"
            end

            if options[:branch_name] && options[:branch_name].empty?
              raise ArgumentError, "Branch name cannot be empty"
            end

            if options[:commit_message] && options[:commit_message].empty?
              raise ArgumentError, "Commit message cannot be empty"
            end
          end

          # Create a task-aware worktree
          #
          # @param options [Hash] Command options
          # @return [Integer] Exit code
          def create_task_worktree(options)
            puts "Creating worktree for task: #{options[:task]}"

            # Check ace-taskflow availability first
            availability_check = check_task_dependency_availability
            unless availability_check[:available]
              puts "Error: ace-taskflow is required for task-aware worktree creation."
              puts
              puts availability_check[:message]
              puts
              puts "Alternative: Use traditional worktree creation:"
              puts "  ace-git-worktree create <branch-name>"
              puts
              return 1
            end

            # Prepare creation options
            creation_options = {
              dry_run: options[:dry_run],
              no_mise_trust: options[:no_mise_trust],
              no_status_update: options[:no_status_update],
              no_commit: options[:no_commit],
              commit_message: options[:commit_message],
              force: options[:force]
            }.compact

            # Create the worktree
            result = @manager.create_task(options[:task], creation_options)

            if result[:success]
              display_task_creation_result(result, options[:dry_run])
              0
            else
              puts "Failed to create worktree: #{result[:error]}"
              display_warnings(result[:warnings]) if result[:warnings]

              # Provide helpful guidance based on error type
              if result[:error]&.include?("ace-taskflow")
                puts
                puts "ace-taskflow issue detected. Check that:"
                puts "  1. ace-taskflow is installed: gem install ace-taskflow"
                puts "  2. ace-taskflow is in your PATH: which ace-taskflow"
                puts "  3. Task '#{options[:task]}' exists in the current release"
              elsif result[:error]&.include?("not found")
                puts
                puts "Task not found suggestions:"
                puts "  1. Check task ID format (try: #{options[:task]}, task.#{options[:task]}, v.0.9.0+#{options[:task]})"
                puts "  2. List available tasks: ace-taskflow tasks"
                puts "  3. Verify you're in the correct project directory"
              end

              1
            end
          end

          # Check if task dependencies are available with helpful messages
          #
          # @return [Hash] { available: boolean, message: string }
          def check_task_dependency_availability
            require_relative "../molecules/task_fetcher"
            fetcher = Ace::Git::Worktree::Molecules::TaskFetcher.new
            fetcher.check_availability_with_message
          end

          # Create a traditional worktree
          #
          # @param options [Hash] Command options
          # @return [Integer] Exit code
          def create_traditional_worktree(options)
            puts "Creating worktree for branch: #{options[:branch_name]}"

            # Prepare creation options
            creation_options = {
              path: options[:path],
              no_mise_trust: options[:no_mise_trust],
              force: options[:force]
            }.compact

            # Create the worktree
            result = @manager.create(options[:branch_name], creation_options)

            if result[:success]
              display_traditional_creation_result(result)
              0
            else
              puts "Failed to create worktree: #{result[:error]}"
              1
            end
          end

          # Display task worktree creation result
          #
          # @param result [Hash] Creation result
          # @param dry_run [Boolean] Whether this was a dry run
          def display_task_creation_result(result, dry_run = false)
            if dry_run
              puts "\nDry run - no changes made:"
              puts "Would create worktree at: #{result[:would_create][:worktree_path]}"
              puts "Would create branch: #{result[:would_create][:branch]}"
              puts "Task ID: #{result[:task_id]}"
              puts "Task title: #{result[:task_title]}"
              puts "\nPlanned steps:"
              result[:steps_planned].each_with_index do |step, i|
                puts "  #{i + 1}. #{step.gsub('_', ' ')}"
              end
            else
              puts "\nWorktree created successfully!"
              puts "Task ID: #{result[:task_id]}"
              puts "Task title: #{result[:task_title]}" if result[:task_title]
              puts "Worktree path: #{result[:worktree_path]}"
              puts "Branch: #{result[:branch]}"
              puts "Directory: #{result[:directory_name]}" if result[:directory_name]
              puts "\nSteps completed:"
              result[:steps_completed].each_with_index do |step, i|
                puts "  ✓ #{step.gsub('_', ' ')}"
              end
            end

            display_warnings(result[:warnings]) if result[:warnings]
            display_navigation_hint(result[:worktree_path]) unless dry_run
          end

          # Display traditional worktree creation result
          #
          # @param result [Hash] Creation result
          def display_traditional_creation_result(result)
            puts "\nWorktree created successfully!"
            puts "Worktree path: #{result[:worktree_path]}"
            puts "Branch: #{result[:branch]}"
            puts "Git root: #{result[:git_root]}"

            display_warnings(result[:warnings]) if result[:warnings]
            display_navigation_hint(result[:worktree_path])
          end

          # Display warnings
          #
          # @param warnings [Array<String>] Array of warning messages
          def display_warnings(warnings)
            return unless warnings&.any?

            puts "\nWarnings:"
            warnings.each { |warning| puts "  ⚠️  #{warning}" }
          end

          # Display navigation hint
          #
          # @param worktree_path [String] Path to the worktree
          def display_navigation_hint(worktree_path)
            return unless worktree_path

            puts "\nTo navigate to the worktree:"
            puts "  cd #{worktree_path}"
          end
        end
      end
    end
  end
end