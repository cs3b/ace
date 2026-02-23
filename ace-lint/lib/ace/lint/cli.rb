# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../lint"

module Ace
  module Lint
    # CLI namespace for ace-lint single-command entrypoint.
    #
    # ace-lint uses a single-command dry-cli entrypoint that calls
    # CLI::Commands::Lint directly from the executable.
    module CLI
      # Entry point for CLI invocation (used by tests via cli_helpers)
      #
      # Mirrors exe behavior: empty args show help.
      #
      # @param args [Array<String>] Command-line arguments
      def self.start(args)
        args = ["--help"] if args.empty?
        Dry::CLI.new(Commands::Lint).call(arguments: args)
      end
    end
  end
end
