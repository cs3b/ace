# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Commands
        # List command
        #
        # Prints the active-worktree table: one enriched row per worktree whose
        # last activity falls inside the activity window (committed or dirty),
        # plus a two-line count footer. `--full` lists every worktree,
        # `--format json` is the machine surface, `--format simple` is the
        # branch-at-path listing.
        #
        # @example Daily driver (last 18h)
        #   ListCommand.new.run([])
        #
        # @example Wider window in JSON
        #   ListCommand.new.run(["--active-within", "3d", "--format", "json"])
        #
        # @example Exhaustive listing
        #   ListCommand.new.run(["--full"])
        class ListCommand
          # Supported output formats
          FORMATS = %w[table json simple].freeze

          # Initialize a new ListCommand
          #
          # @param reporter [Organisms::WorktreeListReport, nil] injectable report
          def initialize(reporter: nil)
            @reporter = reporter
          end

          # Run the list command
          #
          # @param args [Array<String>] Command arguments
          # @return [Integer] Exit code (0 for success, 1 for error)
          def run(args = [])
            options = parse_arguments(args)
            return show_help if options[:help]

            validate_options(options)

            result = reporter.run(options)

            if result[:success]
              puts result[:output] unless result[:output].to_s.empty?
              0
            else
              puts "Failed to list worktrees: #{result[:error]}"
              1
            end
          rescue ArgumentError => e
            puts "Error: #{e.message}"
            1
          rescue => e
            puts "Error: #{e.message}"
            1
          end

          # Show help for the list command
          #
          # @return [Integer] Exit code
          def show_help
            puts <<~HELP
              ace-git-worktree list - List worktrees

              USAGE:
                  ace-git-worktree list [--compact | --full] [--active-within DURATION] [OPTIONS]

              VIEW:
                  --compact               Active worktrees only (default)
                  --full                  List every worktree with absolute paths
                  --active-within <dur>   Activity window: Nm, Nh, Nd, or bare hours (default: 18h)

              OUTPUT:
                  --format <format>       Output format: table, json, simple (default: table)
                  -q, --quiet             Suppress the count footer

              FILTERING:
                  --task-associated       Show only worktrees with a resolved task id
                  --no-task-associated    Show only worktrees without a task id
                  --usable                Show only usable worktrees
                  --no-usable             Show only unusable worktrees
                  --search <pattern>      Filter by branch name pattern

              EXAMPLES:
                  # Worktrees active in the last 18 hours
                  ace-git-worktree list

                  # Everything, including inactive worktrees
                  ace-git-worktree list --full

                  # After a weekend
                  ace-git-worktree list --active-within 3d

                  # Machine-readable output
                  ace-git-worktree list --format json

              COLUMNS:
                  Task     Resolved task id (inferred from metadata, the _current symlink,
                           validated names, or task files changed in the worktree)
                  Branch   Checked-out branch (middle-elided when truncated)
                  Age      Age of the last commit, one compact unit (8m, 3h, 9d, 3w, 2mo, 1y)
                  Commit   Last commit subject (right-truncated)
                  Changes  Uncommitted file count (staged + unstaged + untracked)
                  PR       #N, #N draft, #N merged, #N closed, or - (matched by branch,
                           HEAD commit, or a unique task reference)
                  Path     Worktree path (~ shortened; --full prints it absolute)

                  Columns shrink to fit the terminal width; Path is dropped on very
                  narrow terminals. Probing runs in isolated child processes with a
                  5 second per-worktree budget; unreadable probes render "?".
            HELP
            0
          end

          private

          def reporter
            @reporter || Organisms::WorktreeListReport.new(env: ENV)
          end

          # Parse command line arguments
          #
          # @param args [Array<String>] Command arguments
          # @return [Hash] Parsed options
          def parse_arguments(args)
            options = {
              format: "table",
              compact: false,
              full: false,
              active_within: nil,
              task_associated: nil,
              usable: nil,
              search: nil,
              quiet: false,
              verbose: false,
              debug: false,
              help: false
            }

            i = 0
            while i < args.length
              arg = args[i]

              case arg
              when "--format"
                i += 1
                format = args[i]&.downcase
                unless FORMATS.include?(format)
                  raise ArgumentError, "Invalid format: #{format}. Use: table, json, simple"
                end
                options[:format] = format
              when "--compact"
                options[:compact] = true
              when "--full"
                options[:full] = true
              when "--active-within"
                i += 1
                options[:active_within] = args[i]
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
              when "--quiet", "-q"
                options[:quiet] = true
              when "--verbose", "-v"
                options[:verbose] = true
              when "--debug", "-d"
                options[:debug] = true
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
            if options[:compact] && options[:full]
              raise ArgumentError, "--compact and --full are mutually exclusive"
            end

            if options[:search] && options[:search].empty?
              raise ArgumentError, "Search pattern cannot be empty"
            end

            if options[:format] && !FORMATS.include?(options[:format])
              raise ArgumentError, "Invalid format: #{options[:format]}"
            end

            # Parse eagerly so invalid windows fail before any output.
            if options[:active_within]
              Atoms::DurationParser.parse(options[:active_within])
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
        end
      end
    end
  end
end
