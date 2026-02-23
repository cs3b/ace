# frozen_string_literal: true

require 'dry/cli'
require 'ace/core'
require_relative '../bundle'
require_relative 'cli/commands/load'

module Ace
  module Bundle
    # CLI namespace for ace-bundle command loading.
    #
    # ace-bundle uses a single-command dry-cli entrypoint that calls
    # CLI::Commands::Load directly from the executable.
    module CLI
      # Entry point for CLI invocation (used by tests via cli_helpers)
      #
      # Mirrors exe behavior: empty args show help.
      #
      # @param args [Array<String>] Command-line arguments
      def self.start(args)
        args = ["--help"] if args.empty?
        Dry::CLI.new(Commands::Load).call(arguments: args)
      end
    end
  end
end
