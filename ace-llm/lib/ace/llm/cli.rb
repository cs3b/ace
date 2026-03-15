# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../llm"
# Commands
require_relative "cli/commands/query"

module Ace
  module LLM
    # CLI namespace for ace-llm command loading.
    #
    # ace-llm uses a single-command ace-support-cli entrypoint that calls
    # CLI::Commands::Query directly from the executable.
    module CLI
      # Entry point for CLI invocation (used by tests via cli_helpers)
      #
      # @param args [Array<String>] Command-line arguments
      def self.start(args)
        Ace::Support::Cli::Runner.new(Commands::Query).call(args: args)
      end
    end
  end
end
