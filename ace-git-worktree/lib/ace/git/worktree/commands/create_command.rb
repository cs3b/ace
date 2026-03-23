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
          # Pattern for validating PR numbers (digits only)
          PR_NUMBER_PATTERN = /^\d+$/

          # Initialize a new CreateCommand
          #
          # @param manager [Object] Optional manager dependency for testing
          def initialize(manager: nil)
            @manager = manager || Ace::Git::Worktree::Organisms::WorktreeManager.new
          end

          # Run the create command
          #
          # @param args [Array<String>] Command arguments
          # @return [Integer] Exit code (0 for success, 1 for error)
          def run(args = [])
            # Show help if no arguments provided
            return show_help if args.empty?

            options = parse_arguments(args)
            return show_help if options[:help]

            validate_options(options)

            if options[:task]
              create_task_worktree(options)
            elsif options[:pr]
              create_pr_worktree(options)
            elsif options[:branch]
              create_branch_worktree(options)
            else
              create_traditional_worktree(options)
            end
          rescue ArgumentError => e
            puts "Error: #{e.message}"
            puts
            show_help
            1
          rescue Ace::Git::PrNotFoundError,
            Ace::Git::GhAuthenticationError,
            Ace::Git::GhNotInstalledError,
            Ace::Git::TimeoutError => e
            puts "Error: #{e.message}"
            1
          rescue Ace::Git::Error => e
            # Catch other ace-git specific errors
            puts "Error: #{e.message}"
            puts "Debug: #{e.class}" if ENV["DEBUG"]
            1
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
                  ace-git-worktree create --pr <pr-number> [OPTIONS]
                  ace-git-worktree create --branch <branch> [OPTIONS]

              TASK-AWARE CREATION:
                  --task <task-id>         Create worktree for a specific task
                                         Task ID formats: 081, task.081, v.0.9.0+081

              PR-AWARE CREATION:
                  --pr <number>           Create worktree for a GitHub pull request
                  --pull-request <number> (alias for --pr)
                                         Requires gh CLI to be installed and authenticated

              BRANCH-AWARE CREATION:
                  -b <branch>             Create worktree from a branch (local or remote)
                  --branch <branch>       (alias for -b)
                                         Remote branches: origin/feature, upstream/main
                                         Local branches: feature-name

              OPTIONS:
                  --path <path>           Custom worktree path (default: from config)
                  --source <ref>          Git ref to use as branch start-point (default: current branch)
                                        Examples: main, origin/develop, HEAD~3, commit-sha
                  --dry-run               Show what would be created without creating
                  --no-status-update      Skip marking task as in-progress (task mode only)
                  --no-commit             Skip committing task changes (task mode only)
                  --no-push               Skip pushing task changes to remote (task mode only)
                  --no-upstream           Skip pushing worktree branch with upstream tracking (task mode only)
                  --no-pr                 Skip creating draft PR (task mode only)
                  --push-remote <name>    Remote to push to (default: origin) (task mode only)
                  --no-auto-navigate      Stay in current directory (default: navigate to worktree)
                  --commit-message <msg>  Custom commit message for task updates (task mode only)
                  --force                 Create even if worktree already exists
                  --help, -h              Show this help message

              EXAMPLES:
                  # Create task-aware worktree
                  ace-git-worktree create --task 081

                  # Create task worktree based on main instead of current branch
                  ace-git-worktree create --task 081 --source main

                  # Create PR worktree
                  ace-git-worktree create --pr 26

                  # Create worktree from remote branch
                  ace-git-worktree create -b origin/feature/auth

                  # Create worktree from local branch
                  ace-git-worktree create -b my-feature

                  # Create traditional worktree
                  ace-git-worktree create feature-branch

                  # Create traditional worktree based on specific commit
                  ace-git-worktree create feature-branch --source HEAD~3

                  # Custom path and dry run
                  ace-git-worktree create --pr 26 --path ~/worktrees --dry-run

              CONFIGURATION:
                  Worktree creation is controlled by .ace/git/worktree.yml:
                  - root_path: Default worktree root directory
                  - task.auto_*: Automation settings for task workflows
                  - pr.directory_format: PR worktree naming format (default: ace-pr-{number})
                  - pr.branch_format: PR branch naming format (default: pr-{number}-{slug})
                    Variables: {number}, {slug}, {title_slug}, {base_branch}
                  - hooks.after_create: Commands to run after worktree creation

              REQUIREMENTS:
                  PR-aware creation requires GitHub CLI (gh):
                  - Install: brew install gh
                  - Authenticate: gh auth login
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
              pr: nil,
              branch: nil,
              path: nil,
              source: nil,
              dry_run: false,
              no_status_update: false,
              no_commit: false,
              no_push: false,
              no_upstream: false,
              no_pr: false,
              push_remote: nil,
              no_auto_navigate: false,
              commit_message: nil,
              target_branch: nil,
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
              when "--pr", "--pull-request"
                i += 1
                options[:pr] = args[i]
              when "-b", "--branch"
                i += 1
                options[:branch] = args[i]
              when "--path"
                i += 1
                options[:path] = args[i]
              when "--source"
                i += 1
                options[:source] = args[i]
              when "--dry-run"
                options[:dry_run] = true
              when "--no-status-update"
                options[:no_status_update] = true
              when "--no-commit"
                options[:no_commit] = true
              when "--no-push"
                options[:no_push] = true
              when "--no-upstream"
                options[:no_upstream] = true
              when "--no-pr"
                options[:no_pr] = true
              when "--push-remote"
                i += 1
                options[:push_remote] = args[i]
              when "--no-auto-navigate"
                options[:no_auto_navigate] = true
              when "--commit-message"
                i += 1
                options[:commit_message] = args[i]
              when "--target-branch"
                i += 1
                options[:target_branch] = args[i]
              when "--force"
                options[:force] = true
              when "--no-mise-trust"
                options[:no_mise_trust] = true
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

          # Detect which creation mode(s) are specified
          #
          # @param options [Hash] Parsed options
          # @return [Array<Symbol>] List of detected modes (:task, :pr, :branch, :traditional)
          def detect_creation_modes(options)
            modes = []
            modes << :task if options[:task]
            modes << :pr if options[:pr]
            modes << :branch if options[:branch]
            modes << :traditional if options[:branch_name]
            modes
          end

          # Validate parsed options
          #
          # @param options [Hash] Parsed options
          def validate_options(options)
            # Detect creation modes
            modes = detect_creation_modes(options)

            # Check for conflicts
            if modes.length > 1
              raise ArgumentError, "Cannot use multiple creation modes: #{modes.join(", ")}. " \
                                   "Use only one of --task, --pr, --branch, or <branch-name>"
            end

            # Require at least one mode
            if modes.empty?
              raise ArgumentError, "Must specify either --task <task-id>, --pr <number>, --branch <branch>, or <branch-name>"
            end

            # Validate each mode's input
            if options[:task] && options[:task].empty?
              raise ArgumentError, "Task ID cannot be empty"
            end

            # Security validation for task IDs
            if options[:task] && contains_dangerous_patterns?(options[:task])
              raise ArgumentError, "Task ID contains potentially dangerous characters"
            end

            if options[:pr] && options[:pr].empty?
              raise ArgumentError, "PR number cannot be empty"
            end

            if options[:branch] && options[:branch].empty?
              raise ArgumentError, "Branch name cannot be empty"
            end

            if options[:branch_name] && options[:branch_name].empty?
              raise ArgumentError, "Branch name cannot be empty"
            end

            # Validate PR number is numeric
            if options[:pr] && !options[:pr].match?(/^\d+$/)
              raise ArgumentError, "PR number must be a positive integer"
            end

            if options[:commit_message] && options[:commit_message].empty?
              raise ArgumentError, "Commit message cannot be empty"
            end

            # Security validation for paths
            if options[:path] && contains_dangerous_patterns?(options[:path])
              raise ArgumentError, "Path contains potentially dangerous characters"
            end
          end

          # Check if a string contains dangerous patterns
          #
          # Matches TaskFetcher's validation to ensure consistent security boundaries.
          # Rejects shell metacharacters, null bytes, newlines, redirects, and path traversal.
          #
          # @param value [String] Value to check
          # @return [Boolean] true if dangerous patterns found
          def contains_dangerous_patterns?(value)
            return false if value.nil?

            # Patterns from TaskFetcher.valid_task_reference? for consistency
            dangerous_patterns = [
              /[;&|`$(){}\[\]]/,  # Shell metacharacters
              /\x00/,           # Null bytes
              /[\r\n]/,         # Newlines
              /[<>]/,           # Redirects
              /\.\./           # Path traversal
            ]

            dangerous_patterns.any? { |pattern| value.match?(pattern) }
          end

          # Create a task-aware worktree
          #
          # @param options [Hash] Command options
          # @return [Integer] Exit code
          def create_task_worktree(options)
            @options = options
            puts "Creating worktree for task: #{options[:task]}"

            # Check ace-task availability first
            availability_check = check_task_dependency_availability
            unless availability_check[:available]
              puts "Error: ace-task is required for task-aware worktree creation."
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
              path: options[:path],
              source: options[:source],
              dry_run: options[:dry_run],
              no_status_update: options[:no_status_update],
              no_commit: options[:no_commit],
              no_push: options[:no_push],
              no_upstream: options[:no_upstream],
              no_pr: options[:no_pr],
              push_remote: options[:push_remote],
              commit_message: options[:commit_message],
              target_branch: options[:target_branch],
              no_mise_trust: options[:no_mise_trust],
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
              if result[:error]&.include?("ace-task")
                puts
                puts "ace-task issue detected. Check that:"
                puts "  1. ace-task is installed: gem install ace-task"
                puts "  2. ace-task is in your PATH: which ace-task"
                puts "  3. Task '#{options[:task]}' exists"
              elsif result[:error]&.include?("not found")
                puts
                puts "Task not found suggestions:"
                puts "  1. Check task ID format (try: #{options[:task]})"
                puts "  2. List available tasks: ace-task list"
                puts "  3. Verify you're in the correct project directory"
              end

              1
            end
          end

          # Create a PR worktree
          #
          # @param options [Hash] Command options
          # @return [Integer] Exit code
          def create_pr_worktree(options)
            @options = options
            pr_input = options[:pr].to_s.strip

            # Validate PR number is numeric to provide clear error message
            unless pr_input.match?(PR_NUMBER_PATTERN)
              puts "Error: Invalid PR number '#{pr_input}'. Please provide a numeric PR number."
              return 1
            end

            pr_number = pr_input.to_i

            # Validate PR number is within reasonable bounds
            if pr_number <= 0 || pr_number > 999_999
              puts "Error: PR number must be between 1 and 999999."
              return 1
            end

            puts "Creating worktree for PR ##{pr_number}..."

            # Check gh CLI availability using ace-git's PrMetadataFetcher
            unless Ace::Git::Molecules::PrMetadataFetcher.gh_installed?
              puts "Error: gh CLI is required for PR worktree creation."
              puts
              puts gh_not_available_message
              return 1
            end

            unless Ace::Git::Molecules::PrMetadataFetcher.gh_authenticated?
              puts "Error: gh CLI is not authenticated."
              puts
              puts "Authenticate with: gh auth login"
              return 1
            end

            # Fetch PR data
            puts "Fetching PR information..."
            begin
              result = Ace::Git::Molecules::PrMetadataFetcher.fetch_metadata(pr_number.to_s)

              unless result[:success]
                puts "Error: #{result[:error]}"
                return 1
              end

              metadata = result[:metadata]

              # Convert to pr_data format expected by worktree creator
              pr_data = pr_data_from_metadata(metadata)

              # Show PR details
              puts "PR ##{pr_data[:number]}: #{pr_data[:title]}"
              puts "Branch: #{pr_data[:head_branch]} -> #{pr_data[:base_branch]}"

              # Warn about fork PRs
              if pr_data[:is_cross_repository]
                puts
                puts "Warning: This PR is from a fork (#{pr_data[:head_repository_owner]})."
                puts "You will not be able to push to the PR branch directly."
              end
              puts

              # Prepare creation options
              creation_options = {
                path: options[:path],
                dry_run: options[:dry_run],
                no_mise_trust: options[:no_mise_trust],
                force: options[:force]
              }.compact

              # Create the worktree
              result = @manager.create_pr(pr_number, pr_data, creation_options)

              if result[:success]
                display_pr_creation_result(result, options[:dry_run])
                0
              else
                puts "Failed to create worktree: #{result[:error]}"
                display_warnings(result[:warnings]) if result[:warnings]
                1
              end
            rescue Ace::Git::PrNotFoundError, Ace::Git::GhAuthenticationError,
              Ace::Git::GhNotInstalledError => e
              # Let specific ace-git errors be handled by handle_pr_fetch_error
              # Other errors will bubble up to the top-level rescue in run()
              handle_pr_fetch_error(e, pr_number)
            end
          end

          # Create a branch worktree
          #
          # @param options [Hash] Command options
          # @return [Integer] Exit code
          def create_branch_worktree(options)
            @options = options
            branch_name = options[:branch]
            puts "Creating worktree for branch: #{branch_name}..."

            # Detect if remote branch
            require_relative "../molecules/worktree_creator"
            creator = Molecules::WorktreeCreator.new
            remote_info = creator.send(:detect_remote_branch, branch_name)

            if remote_info
              puts "Detected remote branch: #{remote_info[:remote]}/#{remote_info[:branch]}"
              puts "Will create with tracking..."
            else
              puts "Creating worktree from local branch..."
            end
            puts

            # Prepare creation options
            creation_options = {
              path: options[:path],
              dry_run: options[:dry_run],
              no_mise_trust: options[:no_mise_trust],
              force: options[:force]
            }.compact

            # Create the worktree
            result = @manager.create_branch(branch_name, creation_options)

            if result[:success]
              display_branch_creation_result(result, options[:dry_run])
              0
            else
              puts "Failed to create worktree: #{result[:error]}"
              display_warnings(result[:warnings]) if result[:warnings]

              # Provide helpful guidance
              if result[:error]&.include?("not found")
                puts
                puts "Branch not found suggestions:"
                if remote_info
                  puts "  1. Fetch the remote: git fetch #{remote_info[:remote]}"
                  puts "  2. List remote branches: git branch -r"
                  puts "  3. Verify branch name: git ls-remote #{remote_info[:remote]}"
                else
                  puts "  1. List local branches: git branch"
                  puts "  2. Create the branch: git branch #{branch_name}"
                  puts "  3. Or use a remote branch: -b origin/#{branch_name}"
                end
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

            if fetcher.ace_task_available?
              {available: true, message: "ace-task is available"}
            else
              {available: false, message: "ace-task is not available. Install with: gem install ace-task"}
            end
          end

          # Create a traditional worktree
          #
          # @param options [Hash] Command options
          # @return [Integer] Exit code
          def create_traditional_worktree(options)
            @options = options
            puts "Creating worktree for branch: #{options[:branch_name]}"

            # Prepare creation options
            creation_options = {
              path: options[:path],
              source: options[:source],
              dry_run: options[:dry_run],
              no_mise_trust: options[:no_mise_trust],
              force: options[:force]
            }.compact

            # Create the worktree
            result = @manager.create(options[:branch_name], creation_options)

            if result[:success]
              display_traditional_creation_result(result, options[:dry_run])
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
              puts "Target branch: #{result[:would_create][:target_branch]}" if result[:would_create][:target_branch]
              puts "Task ID: #{result[:task_id]}"
              puts "Task title: #{result[:task_title]}"
              if result[:would_create][:task_push]
                puts "Would push to: #{result[:would_create][:push_remote]}"
              end
              if result[:would_create][:upstream_push]
                puts "Would setup upstream: #{result[:would_create][:push_remote]}/#{result[:would_create][:branch]}"
              end
              if result[:would_create][:create_pr]
                puts "Would create draft PR: #{result[:would_create][:pr_title]}"
              end
              puts "\nPlanned steps:"
              result[:steps_planned].each_with_index do |step, i|
                puts "  #{i + 1}. #{step.tr("_", " ")}"
              end
            else
              puts "\nWorktree created successfully!"
              puts "Task ID: #{result[:task_id]}"
              puts "Task title: #{result[:task_title]}" if result[:task_title]
              puts "Worktree path: #{result[:worktree_path]}"
              puts "Branch: #{result[:branch]}"
              puts "Directory: #{result[:directory_name]}" if result[:directory_name]
              puts "Start point: #{result[:start_point]}" if result[:start_point]
              puts "Pushed to: #{result[:pushed_to]}" if result[:pushed_to]

              # Display PR info if created
              if result[:pr_number]
                existing_label = result[:pr_existing] ? " (existing)" : ""
                puts "PR: ##{result[:pr_number]}#{existing_label} - #{result[:pr_url]}"
              end

              puts "\nSteps completed:"
              result[:steps_completed].each_with_index do |step, i|
                puts "  ✓ #{step.tr("_", " ")}"
              end

              # Display hooks results if available
              if result[:hooks_results] && result[:hooks_results].any?
                puts "\nHooks executed:"
                result[:hooks_results].each do |hook_result|
                  status = hook_result[:success] ? "✓" : "✗"
                  command = (hook_result[:command].length > 60) ? "#{hook_result[:command][0..57]}..." : hook_result[:command]
                  puts "  #{status} #{command}"
                  unless hook_result[:success]
                    puts "    Error: #{hook_result[:error]}" if hook_result[:error]
                  end
                end
              end
            end

            display_warnings(result[:warnings]) if result[:warnings]

            # Display cd command or launch tmux
            unless dry_run
              puts ""
              launch_tmux_or_display_cd(result[:worktree_path])
            end
          end

          # Display PR worktree creation result
          #
          # @param result [Hash] Creation result
          # @param dry_run [Boolean] Whether this was a dry run
          def display_pr_creation_result(result, dry_run = false)
            if dry_run
              puts "\nDry run - no changes made:"
              puts "Would create worktree at: #{result[:would_create][:worktree_path]}"
              puts "Would create branch: #{result[:would_create][:branch]}"
              puts "Would track: #{result[:would_create][:tracking]}"
              puts "PR: ##{result[:pr_number]} - #{result[:pr_title]}"
            else
              puts "\nWorktree created successfully!"
              puts "✓ PR ##{result[:pr_number]}: #{result[:pr_title]}" if result[:pr_title]
              puts "✓ Remote branch: #{result[:tracking]}" if result[:tracking]
              puts "✓ Created worktree: #{result[:directory_name]}" if result[:directory_name]
              puts "✓ Branch: #{result[:branch]} tracking #{result[:tracking]}"
              puts "✓ Location: #{result[:worktree_path]}"
              puts

              # Display hooks results if available
              if result[:hooks_results] && result[:hooks_results].any?
                puts "Hooks executed:"
                result[:hooks_results].each do |hook_result|
                  status = hook_result[:success] ? "✓" : "✗"
                  command = (hook_result[:command].length > 60) ? "#{hook_result[:command][0..57]}..." : hook_result[:command]
                  puts "  #{status} #{command}"
                  unless hook_result[:success]
                    puts "    Error: #{hook_result[:error]}" if hook_result[:error]
                  end
                end
                puts
              end
            end

            display_warnings(result[:warnings]) if result[:warnings]

            # Display cd command or launch tmux
            unless dry_run
              launch_tmux_or_display_cd(result[:worktree_path])
            end
          end

          # Display branch worktree creation result
          #
          # @param result [Hash] Creation result
          # @param dry_run [Boolean] Whether this was a dry run
          def display_branch_creation_result(result, dry_run = false)
            if dry_run
              puts "\nDry run - no changes made:"
              puts "Would create worktree at: #{result[:would_create][:worktree_path]}"
              puts "Would create branch: #{result[:would_create][:branch]}"
              if result[:would_create][:tracking]
                puts "Would track: #{result[:would_create][:tracking]}"
              else
                puts "Local branch (no tracking)"
              end
            else
              puts "\nWorktree created successfully!"
              puts "✓ Created worktree: #{result[:directory_name]}" if result[:directory_name]
              if result[:tracking]
                puts "✓ Branch: #{result[:branch]} tracking #{result[:tracking]}"
              else
                puts "✓ Branch: #{result[:branch]} (local, no tracking)"
              end
              puts "✓ Location: #{result[:worktree_path]}"
              puts

              # Display hooks results if available
              if result[:hooks_results] && result[:hooks_results].any?
                puts "Hooks executed:"
                result[:hooks_results].each do |hook_result|
                  status = hook_result[:success] ? "✓" : "✗"
                  command = (hook_result[:command].length > 60) ? "#{hook_result[:command][0..57]}..." : hook_result[:command]
                  puts "  #{status} #{command}"
                  unless hook_result[:success]
                    puts "    Error: #{hook_result[:error]}" if hook_result[:error]
                  end
                end
                puts
              end
            end

            display_warnings(result[:warnings]) if result[:warnings]

            # Display cd command or launch tmux
            unless dry_run
              launch_tmux_or_display_cd(result[:worktree_path])
            end
          end

          # Display traditional worktree creation result
          #
          # @param result [Hash] Creation result
          # @param dry_run [Boolean] Whether this was a dry run
          def display_traditional_creation_result(result, dry_run = false)
            if dry_run
              puts "\nDry run - no changes made:"
              puts "Would create worktree at: #{result[:would_create][:worktree_path]}"
              puts "Would create branch: #{result[:would_create][:branch]}"
              puts "Branch exists: #{result[:would_create][:branch_exists]}"
              puts "Source: #{result[:would_create][:source]}"
            else
              puts "\nWorktree created successfully!"
              puts "Worktree path: #{result[:worktree_path]}"
              puts "Branch: #{result[:branch]}"
              puts "Git root: #{result[:git_root]}"

              display_warnings(result[:warnings]) if result[:warnings]
              puts ""
              launch_tmux_or_display_cd(result[:worktree_path])
            end
          end

          # Display warnings
          #
          # @param warnings [Array<String>] Array of warning messages
          def display_warnings(warnings)
            return unless warnings&.any?

            puts "\nWarnings:"
            warnings.each { |warning| puts "  ⚠️  #{warning}" }
          end

          # Check if auto-navigation should be performed
          #
          # @return [Boolean] true if auto-navigation should be performed
          def should_auto_navigate?
            # Check CLI flag first
            return false if @options[:no_auto_navigate]

            # Then check configuration by loading it directly
            begin
              require_relative "../molecules/config_loader"
              config_loader = Ace::Git::Worktree::Molecules::ConfigLoader.new
              config = config_loader.load
              return false unless config

              config.auto_navigate?
            rescue
              # If configuration loading fails, default to no auto-navigation
              false
            end
          end

          # Launch tmux session or display cd hint for navigation
          #
          # When tmux config is enabled and ace-tmux is available, launches a tmux
          # session rooted at the worktree path (replaces current process).
          # Otherwise falls back to displaying the cd command.
          #
          # @param worktree_path [String] Path to the worktree
          def launch_tmux_or_display_cd(worktree_path)
            return unless worktree_path

            if tmux_enabled?
              if ace_tmux_available?
                Kernel.exec("ace-tmux", "--root", worktree_path)
              else
                puts "Warning: tmux is enabled in config but ace-tmux is not installed."
                puts "Install ace-tmux or disable tmux in .ace/git/worktree.yml"
                puts "cd #{worktree_path}"
              end
            else
              puts "cd #{worktree_path}"
            end
          end

          # Check if tmux integration is enabled in config
          #
          # @return [Boolean] true if tmux is enabled
          def tmux_enabled?
            require_relative "../molecules/config_loader"
            config_loader = Ace::Git::Worktree::Molecules::ConfigLoader.new
            config = config_loader.load
            return false unless config

            config.tmux?
          rescue
            false
          end

          # Check if ace-tmux binary is available on PATH
          #
          # @return [Boolean] true if ace-tmux is installed
          def ace_tmux_available?
            system("which ace-tmux > /dev/null 2>&1")
          end

          # Convert PR metadata from gh CLI to internal pr_data format
          #
          # Anti-corruption layer that translates gh CLI JSON output to internal format.
          # This isolates worktree creation from gh CLI output structure changes.
          #
          # Expected metadata schema from ace-git PrMetadataFetcher (via gh pr view --json):
          #   {
          #     "number" => Integer,
          #     "title" => String,
          #     "headRefName" => String (PR source branch),
          #     "baseRefName" => String (PR target branch),
          #     "isCrossRepository" => Boolean (true for fork PRs),
          #     "headRepositoryOwner" => { "login" => String } (fork owner info)
          #   }
          #
          # @param metadata [Hash] PR metadata from gh CLI
          # @return [Hash] pr_data format expected by worktree creator
          def pr_data_from_metadata(metadata)
            {
              number: metadata["number"],
              title: metadata["title"],
              head_branch: metadata["headRefName"],
              base_branch: metadata["baseRefName"],
              is_cross_repository: metadata["isCrossRepository"] || false,
              head_repository_owner: metadata.dig("headRepositoryOwner", "login") || "unknown"
            }
          end

          # Handle errors during PR metadata fetch
          #
          # @param error [Exception] The error that occurred
          # @param pr_number [Integer] PR number for context in error messages
          # @return [Integer] Exit code (always 1 for errors)
          def handle_pr_fetch_error(error, pr_number)
            case error
            when Ace::Git::PrNotFoundError
              handle_pr_not_found(error, pr_number)
            when Ace::Git::GhAuthenticationError
              handle_gh_auth_error(error)
            when Ace::Git::GhNotInstalledError
              handle_gh_not_installed(error)
            else
              handle_unknown_error(error)
            end
            1
          end

          # Handle PR not found error with helpful suggestions
          def handle_pr_not_found(error, pr_number)
            puts "Error: #{error.message}"
            puts
            puts "Suggestions:"
            puts "  1. Verify the PR number is correct"
            puts "  2. Check if the PR exists: gh pr view #{pr_number}"
            puts "  3. Ensure you're in the correct repository"
          end

          # Handle GitHub authentication error with troubleshooting steps
          def handle_gh_auth_error(error)
            puts "Error: #{error.message}"
            puts
            puts "Troubleshooting:"
            puts "  1. Verify GitHub authentication: gh auth status"
            puts "  2. Re-authenticate if needed: gh auth login"
            puts "  3. Check repository access permissions"
          end

          # Handle gh CLI not installed error with installation guidance
          def handle_gh_not_installed(error)
            puts "Error: #{error.message}"
            puts
            puts gh_not_available_message
          end

          # Handle unknown/unexpected errors with debug info
          def handle_unknown_error(error)
            puts "Error: #{error.message}"
            if ENV["DEBUG"]
              puts "Debug: #{error.class}"
              puts "Debug: #{error.backtrace&.first}" if error.backtrace
            end
          end

          # Get helpful error message when gh CLI is unavailable
          #
          # @return [String] User-friendly error message with installation guidance
          def gh_not_available_message
            <<~MESSAGE
              gh CLI is required for PR worktrees but is not installed.

              Install gh CLI:
              - macOS: brew install gh
              - Linux: See https://github.com/cli/cli#installation
              - Windows: See https://github.com/cli/cli#installation

              After installation, authenticate with: gh auth login
            MESSAGE
          end
        end
      end
    end
  end
end
