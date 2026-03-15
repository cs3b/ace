# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

require_relative "cli/commands/compress"
require_relative "cli/commands/benchmark"
require_relative "version"

module Ace
  module Compressor
    module CLI
      def self.start(args)
        args = ["--help"] if args.empty?
        if args.first == "benchmark"
          Ace::Support::Cli::Runner.new(Commands::Benchmark).call(args: args.drop(1))
        else
          Ace::Support::Cli::Runner.new(Commands::Compress).call(args: args)
        end
      end
    end
  end
end
