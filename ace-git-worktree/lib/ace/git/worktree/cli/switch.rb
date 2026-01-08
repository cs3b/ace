# frozen_string_literal: true

require "dry/cli"
require_relative "shared_helpers"
require_relative "../commands/switch_command"

module Ace
  module Git
    module Worktree
      module CLI
        class Switch < Dry::CLI::Command
          include SharedHelpers

          desc "Switch to a worktree by returning its path"

          example [
            "081                   # Switch by task ID",
            "feature-branch        # Switch by branch name",
            "--list                # List available worktrees"
          ]

          argument :identifier, required: false, desc: "Worktree identifier (task ID, branch, directory, or path)"

          option :list, desc: "List available worktrees", type: :boolean, aliases: ["-l"]
          option :verbose, desc: "Show detailed information", type: :boolean, aliases: ["-v"]
          option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress config summary output"
          option :debug, type: :boolean, aliases: ["-d"], desc: "Debug output"

          def call(identifier: nil, **options)
            display_config_summary("switch", options)

            # Convert dry-cli options to args array format
            args = options_to_args(options)
            args << identifier if identifier

            Commands::SwitchCommand.new.run(args)
          end
        end
      end
    end
  end
end
