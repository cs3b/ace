# frozen_string_literal: true

require "ace/support/cli"
require_relative "shared_helpers"
require_relative "../../commands/cleanup_command"

module Ace
  module Git
    module Worktree
      module CLI
        module Commands
          class Cleanup < Ace::Support::Cli::Command
            include SharedHelpers

            desc "Report cleanup plan for merged worktrees and refs"

            example [
              "--target main                # Report against main",
              "--target main --format json  # JSON output",
              "--target main --offline      # Skip remote refresh"
            ]

            option :target, desc: "Target ref for ancestry proof (required)", type: :string, aliases: []
            option :remote, desc: "Remote name (default: origin)", type: :string, default: "origin", aliases: []
            option :offline, desc: "Skip remote evidence refresh", type: :boolean, aliases: []
            option :format, desc: "Output format (table, json)", type: :string, default: "table", aliases: []
            option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress non-essential output"
            option :debug, type: :boolean, aliases: ["-d"], desc: "Show debug output"

            def call(**options)
              display_config_summary("cleanup", options)

              args = options_to_args(options)

              Ace::Git::Worktree::Commands::CleanupCommand.new.run(args)
            end
          end
        end
      end
    end
  end
end
