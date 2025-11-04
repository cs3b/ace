# frozen_string_literal: true

require_relative "../organisms/worktree_manager"

module Ace
  module Git
    module Worktree
      module Commands
        # Handles the list command
        class ListCommand
          def execute(args)
            options = parse_options(args)

            # Create worktree manager
            manager = Organisms::WorktreeManager.new

            # List worktrees
            result = manager.list(options)

            # Output results
            if result[:success]
              if options[:format] == "json"
                require 'json'
                puts JSON.pretty_generate(result[:worktrees])
              else
                puts result[:output]
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

          def parse_options(args)
            options = {}

            while args.any?
              arg = args.shift

              case arg
              when "--format"
                format = args.shift
                unless %w[json table].include?(format)
                  puts "Error: Invalid format '#{format}'. Use 'json' or 'table'"
                  exit 1
                end
                options[:format] = format
              when "--show-tasks"
                options[:show_tasks] = true
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
              Usage: ace-git-worktree list [options]

              List all git worktrees with optional task associations.

              Options:
                --format <json|table>  Output format (default: table)
                --show-tasks          Include associated task IDs in output
                --help                Show this help message

              Examples:
                # List all worktrees in table format
                ace-git-worktree list

                # Show task associations
                ace-git-worktree list --show-tasks

                # Output as JSON for parsing
                ace-git-worktree list --format json --show-tasks
            HELP
          end
        end
      end
    end
  end
end