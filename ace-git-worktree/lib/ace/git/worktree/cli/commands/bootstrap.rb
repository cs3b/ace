# frozen_string_literal: true

require "ace/support/cli"
require_relative "shared_helpers"
require_relative "../../commands/bootstrap_command"

module Ace
  module Git
    module Worktree
      module CLI
        module Commands
          class Bootstrap < Ace::Support::Cli::Command
            include SharedHelpers

            desc "Rerun preparation phases (toolchain trust and bootstrap policy) for an existing worktree"

            example [
              "081                     # Rerun bootstrap for task 081",
              "t.081 --json            # Output retry status in JSON format"
            ]

            argument :identifier, required: true, desc: "Task ID, branch, or worktree identifier"

            option :json, desc: "Format output as JSON", type: :boolean, aliases: []
            option :verbose, desc: "Show verbose output", type: :boolean, aliases: ["-v"]
            option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress non-essential output"
            option :debug, type: :boolean, aliases: ["-d"], desc: "Show debug output"

            def call(identifier: nil, **options)
              display_config_summary("bootstrap", options)

              args = []
              args << identifier if identifier
              args << "--json" if options[:json]

              Ace::Git::Worktree::Commands::BootstrapCommand.new.run(args)
            end
          end
        end
      end
    end
  end
end
