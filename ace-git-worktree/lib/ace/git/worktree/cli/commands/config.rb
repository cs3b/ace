# frozen_string_literal: true

require "ace/support/cli"
require_relative "shared_helpers"
require_relative "../../commands/config_command"

module Ace
  module Git
    module Worktree
      module CLI
        module Commands
          class Config < Ace::Support::Cli::Command
            include SharedHelpers

            desc "Show and manage worktree configuration"

            example [
              "                # Show current configuration",
              "--show          # Show current configuration",
              "--validate      # Validate configuration",
              "--files         # Show config file locations"
            ]

            # Accept extra positional arguments for backward compatibility
            # (e.g., "show", "validate" as positional args instead of flags)
            argument :subcommand, required: false, desc: "Subcommand (show, validate, files)"

            option :show, desc: "Show current configuration", type: :boolean, aliases: []
            option :validate, desc: "Validate configuration", type: :boolean, aliases: []
            option :files, desc: "Show configuration file locations", type: :boolean, aliases: []
            option :verbose, desc: "Show verbose output", type: :boolean, aliases: ["-v"]
            option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress non-essential output"
            option :debug, type: :boolean, aliases: ["-d"], desc: "Show debug output"

            def call(subcommand: nil, **options)
              display_config_summary("config", options)

              # Convert ace-support-cli options to args array format
              args = options_to_args(options)
              # Add subcommand as positional argument if provided
              args << subcommand if subcommand

              Ace::Git::Worktree::Commands::ConfigCommand.new.run(args)
            end
          end
        end
      end
    end
  end
end
