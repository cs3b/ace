# frozen_string_literal: true

require_relative "../organisms/worktree_manager"

module Ace
  module Git
    module Worktree
      module Commands
        # Handles the remove command
        class RemoveCommand
          def execute(args)
            options = parse_options(args)
            identifier = args.first

            # Validate input
            if identifier.nil? || identifier.empty?
              puts "Error: Worktree identifier required"
              puts "Usage: ace-git-worktree remove <identifier> [options]"
              return 1
            end

            # Create worktree manager
            manager = Organisms::WorktreeManager.new

            # Remove worktree
            result = manager.remove(identifier, options)

            # Output results
            if result[:success]
              puts result[:output] || "Worktree removed successfully"
              0
            else
              puts "Error: #{result[:error]}"
              if result[:error].include?("uncommitted changes")
                puts "Use --force to remove anyway"
              end
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

          def print_help
            puts <<~HELP
              Usage: ace-git-worktree remove <identifier> [options]

              Remove a worktree and optionally clean up task metadata.

              Arguments:
                identifier    Task ID, branch name, or worktree path

              Options:
                --force      Remove even if there are uncommitted changes
                --help       Show this help message

              Examples:
                # Remove by task ID
                ace-git-worktree remove 081

                # Remove by branch
                ace-git-worktree remove feature-branch

                # Force removal with uncommitted changes
                ace-git-worktree remove 081 --force
            HELP
          end
        end
      end
    end
  end
end