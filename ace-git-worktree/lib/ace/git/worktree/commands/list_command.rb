# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Commands
        # List command
        #
        # Lists worktrees with various formatting and filtering options.
        # Supports task-aware listing and search capabilities.
        #
        # @example List all worktrees
        #   ListCommand.new.run([])
        #
        # @example List with JSON output
        #   ListCommand.new.run(["--format", "json"])
        #
        # @example List only task-associated worktrees
        #   ListCommand.new.run(["--task-associated"])
        class ListCommand
          # Initialize a new ListCommand
          def initialize
            @manager = Organisms::WorktreeManager.new
          end

          # Run the list command
          #
          # @param args [Array<String>] Command arguments
          # @return [Integer] Exit code (0 for success, 1 for error)
          def run(args = [])
            begin
              options = parse_arguments(args)
              return show_help if options[:help]

              validate_options(options)

              # Convert format to symbol for WorktreeLister compatibility
              options[:format] = options[:format].to_sym if options[:format]

              result = @manager.list_all(options)

              if result[:success]
                display_list_result(result, options)
                0
              else
                puts "Failed to list worktrees: #{result[:error]}"
                1
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

          # Show help for the list command
          #
          # @return [Integer] Exit code
          def show_help
            puts <<~HELP
              ace-git-worktree list - List worktrees

              USAGE:
                  ace-git-worktree list [OPTIONS]

              OUTPUT FORMATS:
                  --format <format>       Output format: table, json, simple (default: table)
                  --show-tasks            Include task associations

              FILTERING:
                  --task-associated       Show only task-associated worktrees
                  --no-task-associated    Show only non-task worktrees
                  --usable               Show only usable worktrees
                  --no-usable            Show only unusable worktrees
                  --search <pattern>      Filter by branch name pattern

              EXAMPLES:
                  # List all worktrees in table format
                  ace-git-worktree list

                  # List with task associations in JSON format
                  ace-git-worktree list --show-tasks --format json

                  # List only task-associated worktrees
                  ace-git-worktree list --task-associated

                  # Search for worktrees with "auth" in branch name
                  ace-git-worktree list --search auth

                  # List only usable worktrees
                  ace-git-worktree list --usable

              OUTPUT:
                  Table format columns:
                  - Task: Task ID (or - for non-task worktrees)
                  - Branch: Git branch name
                  - Path: Worktree directory path
                  - Status: worktree status (task, normal, bare, detached, etc.)

                  JSON format includes full worktree details and metadata.
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
              format: "table",
              show_tasks: false,
              task_associated: nil,
              usable: nil,
              search: nil,
              help: false
            }

            i = 0
            while i < args.length
              arg = args[i]

              case arg
              when "--format"
                i += 1
                format = args[i]&.downcase
                if %w[table json simple].include?(format)
                  options[:format] = format
                else
                  raise ArgumentError, "Invalid format: #{format}. Use: table, json, simple"
                end
              when "--show-tasks"
                options[:show_tasks] = true
              when "--task-associated"
                options[:task_associated] = true
              when "--no-task-associated"
                options[:task_associated] = false
              when "--usable"
                options[:usable] = true
              when "--no-usable"
                options[:usable] = false
              when "--search"
                i += 1
                options[:search] = args[i]
              when "--help", "-h"
                options[:help] = true
              when /^--/
                raise ArgumentError, "Unknown option: #{arg}"
              else
                raise ArgumentError, "Unexpected argument: #{arg}"
              end

              i += 1
            end

            options
          end

          # Validate parsed options
          #
          # @param options [Hash] Parsed options
          def validate_options(options)
            if options[:search] && options[:search].empty?
              raise ArgumentError, "Search pattern cannot be empty"
            end

            if options[:format] && !%w[table json simple].include?(options[:format])
              raise ArgumentError, "Invalid format: #{options[:format]}"
            end

            # Security validation for search patterns
            if options[:search] && contains_dangerous_patterns?(options[:search])
              raise ArgumentError, "Search pattern contains potentially dangerous characters"
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
              /\|\|/         # OR operator
            ]

            dangerous_patterns.any? { |pattern| value.match?(pattern) }
          end

          # Display list result
          #
          # @param result [Hash] List result
          # @param options [Hash] Command options
          def display_list_result(result, options)
            if result[:worktrees].empty?
              puts "No worktrees found."
              return
            end

            # Display the formatted output
            puts result[:formatted_output]

            # Display summary if requested or if not JSON format
            if options[:format] != :json
              display_summary(result, options)
            end
          end

          # Display summary information
          #
          # @param result [Hash] List result
          # @param options [Hash] Command options
          def display_summary(result, options)
            stats = result[:statistics]
            puts "\nSummary:"
            puts "  Total worktrees: #{stats[:total]}"
            puts "  Task-associated: #{stats[:task_associated]}"
            puts "  Usable: #{stats[:usable]}"

            if options[:show_tasks] && stats[:task_ids].any?
              puts "  Tasks with worktrees: #{stats[:task_ids].join(', ')}"
            end

            if stats[:branches].any?
              puts "  Branches: #{stats[:branches].join(', ')}"
            end

            # Show active worktrees count
            active_count = result[:worktrees].count { |wt| wt.exists? && wt.usable? }
            puts "  Active worktrees: #{active_count}"
          end
        end
      end
    end
  end
end
