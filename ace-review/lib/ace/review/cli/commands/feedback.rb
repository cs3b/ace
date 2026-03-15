# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Review
    module CLI
      module Commands
        # Base feedback command that shows help for subcommands
        #
        # This handles the base "feedback" command:
        # - No arguments: Show help with available subcommands
        #
        # All subcommands (list, show, verify, skip, resolve) are handled
        # by nested ace-support-cli commands in CLI::Commands::FeedbackSubcommands:: namespace.
        class Feedback < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          desc <<~DESC.strip
            Manage feedback items from code reviews

            SYNTAX:
              ace-review feedback <subcommand> [options]

            SUBCOMMANDS:

              Use 'ace-review feedback <subcommand> --help' for details:
              - create:  Create feedback items from review reports
              - list:    List feedback items with optional filters
              - show:    Show feedback item details
              - verify:  Verify a draft feedback item (mark valid/invalid/skip)
              - resolve: Resolve a pending feedback item

            EXAMPLES:

              # Create feedback from most recent session
              $ ace-review feedback create

              # List all pending feedback items
              $ ace-review feedback list --status pending

              # Show a specific feedback item
              $ ace-review feedback show abc123

              # Verify a draft item as valid
              $ ace-review feedback verify abc123 --valid

              # Resolve a pending item
              $ ace-review feedback resolve abc123 --resolution "Fixed in commit def456"
          DESC

          example [
            'create                   # Create from most recent session',
            'list --status pending    # List pending items',
            'show abc123              # Show item details',
            'verify abc123 --valid    # Mark as valid',
            'verify abc123 --skip    # Skip (not applicable)',
            'resolve abc123 --resolution "Fixed"'
          ]

          def call(**options)
            # Show help when no subcommand is provided
            puts "Usage: ace-review feedback <subcommand> [options]"
            puts
            puts "Subcommands:"
            puts "  create   Create feedback items from review reports"
            puts "  list     List feedback items"
            puts "  show     Show feedback item details"
            puts "  verify   Verify a draft feedback item (valid/invalid/skip)"
            puts "  resolve  Resolve a pending feedback item"
            puts
            puts "Run 'ace-review feedback <subcommand> --help' for more information."
          end
        end
      end
    end
  end
end
