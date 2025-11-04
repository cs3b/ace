# frozen_string_literal: true

require_relative "../organisms/worktree_manager"

module Ace
  module Git
    module Worktree
      module Commands
        # Handles the switch command
        class SwitchCommand
          def execute(args)
            identifier = args.first

            # Validate input
            if identifier.nil? || identifier.empty?
              puts "Error: Worktree identifier required"
              puts "Usage: ace-git-worktree switch <identifier>"
              return 1
            end

            # Check for help
            if identifier == "--help"
              print_help
              return 0
            end

            # Create worktree manager
            manager = Organisms::WorktreeManager.new

            # Find and switch to worktree
            result = manager.switch(identifier)

            # Output results
            if result[:success]
              # Just output the path for use in shell commands
              puts result[:path]
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
              Usage: ace-git-worktree switch <identifier>

              Navigate to a worktree by task ID, branch name, or directory name.

              Arguments:
                identifier    Task ID (081), task prefix (task.081), branch name,
                             or directory name

              Output:
                Outputs the absolute path to the worktree directory.
                Use with cd: cd $(ace-git-worktree switch 081)

              Examples:
                # Switch by task ID
                ace-git-worktree switch 081

                # Switch by task prefix
                ace-git-worktree switch task.081

                # Switch by branch name
                ace-git-worktree switch 081-fix-bug

                # Use in shell
                cd $(ace-git-worktree switch 081)
            HELP
          end
        end
      end
    end
  end
end