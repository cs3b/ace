# frozen_string_literal: true

require_relative "../organisms/worktree_manager"

module Ace
  module Git
    module Worktree
      module Commands
        # Handles the prune command
        class PruneCommand
          def execute(args)
            # Check for help
            if args.include?("--help")
              print_help
              return 0
            end

            # Create worktree manager
            manager = Organisms::WorktreeManager.new

            # Prune worktrees
            result = manager.prune

            # Output results
            if result[:success]
              if result[:pruned_count] && result[:pruned_count] > 0
                puts "Pruned #{result[:pruned_count]} worktree(s):"
                result[:pruned_paths].each do |path|
                  puts "  - #{path}"
                end
              else
                puts "No worktrees to prune"
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

          def print_help
            puts <<~HELP
              Usage: ace-git-worktree prune

              Clean up worktree references for deleted directories.

              This command removes worktree entries from git's metadata when
              the worktree directory has been manually deleted from the filesystem.

              Options:
                --help    Show this help message

              Examples:
                # Clean up deleted worktrees
                ace-git-worktree prune
            HELP
          end
        end
      end
    end
  end
end