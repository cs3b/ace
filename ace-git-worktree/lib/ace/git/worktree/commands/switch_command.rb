# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Commands
        # Switch command
        #
        # Switches to a worktree by various identifiers (task ID, branch name,
        # directory name, or path). Outputs the path for navigation.
        #
        # @example Switch by task ID
        #   SwitchCommand.new.run(["081"])
        #
        # @example Switch by branch name
        #   SwitchCommand.new.run(["feature-branch"])
        #
        # @example Switch and change directory
        #   cd $(ace-git-worktree switch 081)
        class SwitchCommand
          # Initialize a new SwitchCommand
          #
          # @param manager [Object] Optional manager dependency for testing
          def initialize(manager: nil)
            @manager = manager || Organisms::WorktreeManager.new
          end

          # Run the switch command
          #
          # @param args [Array<String>] Command arguments
          # @return [Integer] Exit code (0 for success, 1 for error)
          def run(args = [])
            options = parse_arguments(args)
            return show_help if options[:help]

            validate_options(options)

            # Handle list option
            if options[:list]
              result = @manager.list_all(format: :simple)
              if result[:success] && result[:worktrees].any?
                result[:worktrees].each do |worktree|
                  prefix = worktree.task_associated? ? "Task #{worktree.task_id}: " : ""
                  puts "  #{prefix}#{worktree.branch || "detached"} (#{worktree.path})"
                end
                return 0
              else
                puts "No worktrees found. Use 'ace-git-worktree create' to create one."
                return 0
              end
            end

            result = @manager.switch(options[:identifier])

            if result[:success]
              display_switch_result(result, options)
              0
            else
              puts "Failed to switch worktree: #{result[:error]}"
              display_alternatives(options[:identifier]) unless result[:error].include?("not found")
              1
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

          # Show help for the switch command
          #
          # @return [Integer] Exit code
          def show_help
            puts <<~HELP
              ace-git-worktree switch - Switch to a worktree

              USAGE:
                  ace-git-worktree switch <identifier>

              IDENTIFIERS:
                  Task ID:                081, task.081, v.0.9.0+081
                  Branch name:            feature-branch, main
                  Directory name:        task.081, feature-branch
                  Full path:              /path/to/worktree

              OPTIONS:
                  --help, -h              Show this help message
                  --list, -l              List available worktrees
                  --verbose, -v           Show detailed information

              EXAMPLES:
                  # Switch by task ID
                  ace-git-worktree switch 081

                  # Switch by branch name
                  ace-git-worktree switch feature-branch

                  # Switch and change directory
                  cd $(ace-git-worktree switch 081)

                  # List available worktrees
                  ace-git-worktree switch --list

              OUTPUT:
                  The command outputs the worktree path for use with cd:
                  $ ace-git-worktree switch 081
                  /project/.ace-wt/task.081

                  To change directory:
                  $ cd $(ace-git-worktree switch 081)

              CONFIGURATION:
                  Worktree paths and naming are controlled by .ace/git/worktree.yml
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
              identifier: nil,
              list: false,
              verbose: false,
              help: false
            }

            i = 0
            while i < args.length
              arg = args[i]

              case arg
              when "--list", "-l"
                options[:list] = true
              when "--branch"
                i += 1
                options[:identifier] = args[i]
              when "--task"
                i += 1
                options[:identifier] = args[i]
              when "--verbose", "-v"
                options[:verbose] = true
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
            if !options[:list] && !options[:identifier]
              raise ArgumentError, "Must specify <identifier> or use --list option"
            end

            if options[:list] && options[:identifier]
              raise ArgumentError, "Cannot specify both identifier and --list option"
            end

            # Security validation for identifiers (can be task ID, branch, or path)
            if options[:identifier] && contains_dangerous_patterns?(options[:identifier])
              raise ArgumentError, "Identifier contains potentially dangerous characters"
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

          # Display switch result
          #
          # @param result [Hash] Switch result
          # @param options [Hash] Command options
          def display_switch_result(result, options)
            # Just output the path for use with cd
            puts result[:worktree_path]

            if options[:verbose]
              puts "\nWorktree details:"
              puts "  Branch: #{result[:branch]}"
              puts "  Task ID: #{result[:task_id]}" if result[:task_id]
              puts "  Description: #{result[:description]}"
            end
          end

          # Display alternatives when worktree not found
          #
          # @param identifier [String] The identifier that wasn't found
          def display_alternatives(identifier)
            puts "\nAvailable worktrees:"

            result = @manager.list_all(format: :simple)
            if result[:success] && result[:worktrees].any?
              result[:worktrees].each do |worktree|
                prefix = worktree.task_associated? ? "Task #{worktree.task_id}: " : ""
                puts "  #{prefix}#{worktree.branch || "detached"} (#{worktree.path})"
              end
            else
              puts "  No worktrees found. Use 'ace-git-worktree create' to create one."
            end

            puts "\nSuggestions:"
            puts "  • Check the worktree identifier spelling"
            puts "  • Use 'ace-git-worktree list' to see available worktrees"
            puts "  • Use 'ace-git-worktree create' to create a new worktree"
          end
        end
      end
    end
  end
end
