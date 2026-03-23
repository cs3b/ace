# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Commands
        # Prune command
        #
        # Cleans up git metadata for deleted worktrees and removes orphaned
        # worktree directories that are no longer tracked by git.
        #
        # @example Prune deleted worktrees
        #   PruneCommand.new.run([])
        #
        # @example Prune with directory cleanup
        #   PruneCommand.new.run(["--cleanup-directories"])
        class PruneCommand
          # Initialize a new PruneCommand
          def initialize
            @manager = Organisms::WorktreeManager.new
          end

          # Run the prune command
          #
          # @param args [Array<String>] Command arguments
          # @return [Integer] Exit code (0 for success, 1 for error)
          def run(args = [])
            options = parse_arguments(args)
            return show_help if options[:help]

            validate_options(options)

            result = @manager.prune

            if result[:success]
              display_prune_result(result, options)

              # Additional directory cleanup if requested
              if options[:cleanup_directories]
                cleanup_orphaned_directories(options)
              end

              0
            else
              puts "Failed to prune worktrees: #{result[:error]}"
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

          # Show help for the prune command
          #
          # @return [Integer] Exit code
          def show_help
            puts <<~HELP
              ace-git-worktree prune - Clean up deleted worktrees

              USAGE:
                  ace-git-worktree prune [OPTIONS]

              OPTIONS:
                  --dry-run               Show what would be pruned without pruning
                  --cleanup-directories   Remove orphaned worktree directories
                  --verbose, -v           Show detailed pruning information
                  --help, -h              Show this help message

              EXAMPLES:
                  # Prune deleted worktrees (git metadata cleanup only)
                  ace-git-worktree prune

                  # Dry run to see what would be pruned
                  ace-git-worktree prune --dry-run

                  # Prune and cleanup orphaned directories
                  ace-git-worktree prune --cleanup-directories

                  # Verbose output
                  ace-git-worktree prune --verbose

              WHAT IT DOES:
                  1. Prunes git worktree metadata for deleted worktrees
                  2. Removes stale worktree entries from git's tracking
                  3. Optionally removes orphaned worktree directories
                  4. Reports what was cleaned up

              SAFETY:
                  • Only removes worktrees that are no longer tracked by git
                  • Does not affect active worktrees or current worktree
                  • Directory cleanup is optional and requires explicit flag
                  • Dry run available to preview changes

              CONFIGURATION:
                  Pruning behavior can be configured in .ace/git/worktree.yml:
                  - cleanup.on_delete: Automatic cleanup on branch deletion
                  - cleanup.on_merge: Automatic cleanup on branch merge
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
              dry_run: false,
              cleanup_directories: false,
              force: false,
              verbose: false,
              help: false
            }

            i = 0
            while i < args.length
              arg = args[i]

              case arg
              when "--dry-run"
                options[:dry_run] = true
              when "--cleanup-directories"
                options[:cleanup_directories] = true
              when "--force"
                options[:force] = true
              when "--verbose", "-v"
                options[:verbose] = true
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
            # No specific validation needed for prune command
          end

          # Display prune result
          #
          # @param result [Hash] Prune result
          # @param options [Hash] Command options
          def display_prune_result(result, options)
            if result[:pruned_count] && result[:pruned_count] > 0
              puts "Pruned #{result[:pruned_count]} worktree(s) successfully."

              if options[:verbose] && result[:output]
                puts "\nPruned worktrees:"
                result[:output].split("\n").each do |line|
                  next unless line.include?("Pruning worktree")
                  path = line.match(/Pruning worktree (.+)$/)[1]
                  puts "  ✓ #{path}"
                end
              end
            else
              puts "No worktrees to prune. Git metadata is clean."
            end

            if options[:dry_run]
              puts "\nDRY RUN - No changes were made."
            end
          end

          # Clean up orphaned directories
          #
          # @param options [Hash] Command options
          def cleanup_orphaned_directories(options)
            puts "\nChecking for orphaned worktree directories..."

            # Get current worktree root from configuration
            config = @manager.configuration
            worktree_root = config.absolute_root_path

            unless Dir.exist?(worktree_root)
              puts "Worktree root directory does not exist: #{worktree_root}"
              return
            end

            # Get currently tracked worktrees
            list_result = @manager.list_all
            return unless list_result[:success]

            tracked_paths = list_result[:worktrees].map { |wt| File.expand_path(wt.path) }

            # Find directories in worktree root that are not tracked
            orphaned_count = 0
            Dir.glob(File.join(worktree_root, "*")).each do |path|
              next unless File.directory?(path)
              next if tracked_paths.include?(File.expand_path(path))

              # Check if this looks like a worktree directory
              if looks_like_worktree_directory?(path)
                if options[:dry_run]
                  puts "  Would remove orphaned directory: #{File.basename(path)}"
                  orphaned_count += 1
                else
                  if options[:verbose]
                    puts "  Removing orphaned directory: #{File.basename(path)}"
                  end

                  begin
                    FileUtils.rm_rf(path)
                    orphaned_count += 1
                  rescue => e
                    puts "  Failed to remove #{path}: #{e.message}"
                  end
                end
              end
            end

            if orphaned_count > 0
              action = options[:dry_run] ? "Would remove" : "Removed"
              puts "#{action} #{orphaned_count} orphaned director(y/ies)."
            else
              puts "No orphaned directories found."
            end
          end

          # Check if directory looks like a worktree
          #
          # @param path [String] Directory path
          # @return [Boolean] true if it looks like a worktree directory
          def looks_like_worktree_directory?(path)
            # Check for common indicators of a worktree
            indicators = [
              File.join(path, ".git"),  # Git directory (file)
              File.join(path, "mise.toml"),  # Mise configuration
              File.join(path, ".mise"),  # Mise directory
              File.join(path, "package.json"),  # Node.js project
              File.join(path, "Gemfile"),  # Ruby project
              File.join(path, "Cargo.toml")  # Rust project
            ]

            # Check if any indicators exist
            indicators.any? { |indicator| File.exist?(indicator) }
          rescue
            false
          end
        end
      end
    end
  end
end
