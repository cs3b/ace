# frozen_string_literal: true

require_relative "../organisms/worktree_manager"
require 'yaml'

module Ace
  module Git
    module Worktree
      module Commands
        # Handles the config command
        class ConfigCommand
          def execute(args)
            # Check for help
            if args.include?("--help")
              print_help
              return 0
            end

            # Create worktree manager
            manager = Organisms::WorktreeManager.new

            # Get configuration
            result = manager.show_config

            # Output configuration
            if result[:success]
              puts "Current configuration (.ace/git/worktree.yml):"
              puts ""
              puts result[:configuration].to_yaml
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
              Usage: ace-git-worktree config

              Display the current configuration settings.

              Configuration is loaded from:
                1. Project: .ace/git/worktree.yml
                2. User: ~/.ace/git/worktree.yml
                3. Defaults: Built-in default values

              Options:
                --help    Show this help message

              Examples:
                # Show current configuration
                ace-git-worktree config

              Configuration Options:
                root_path:              Root directory for worktrees
                mise_trust_auto:        Automatically trust mise.toml
                task.directory_format:  Template for task directory names
                task.branch_format:     Template for task branch names
                ... and more

              See .ace.example/git/worktree.yml for all available options.
            HELP
          end
        end
      end
    end
  end
end