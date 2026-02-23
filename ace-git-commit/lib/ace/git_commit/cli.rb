# frozen_string_literal: true

require "dry/cli"
require_relative "../git_commit"
# Commands
require_relative "cli/commands/commit"

module Ace
  module GitCommit
    # CLI namespace for ace-git-commit command loading.
    #
    # ace-git-commit now uses a single-command dry-cli entrypoint that calls
    # CLI::Commands::Commit directly from the executable.
    module CLI
      # Entry point for CLI invocation (used by tests via cli_helpers)
      #
      # @param args [Array<String>] Command-line arguments
      def self.start(args)
        Dry::CLI.new(Commands::Commit).call(arguments: args)
      end
    end
  end
end
