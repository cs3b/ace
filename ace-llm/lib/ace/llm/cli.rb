# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../llm"
# Commands
require_relative "cli/commands/query"

module Ace
  module LLM
    # CLI namespace for ace-llm command loading.
    #
    # ace-llm uses a single-command dry-cli entrypoint that calls
    # CLI::Commands::Query directly from the executable.
    module CLI
      # Entry point for CLI invocation (used by tests via cli_helpers)
      #
      # @param args [Array<String>] Command-line arguments
      def self.start(args)
        Dry::CLI.new(Commands::Query).call(arguments: args)
      end
    end
  end
end
