# frozen_string_literal: true

require "dry/cli"
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
          Dry::CLI.new(Commands::Benchmark).call(arguments: args.drop(1))
        else
          Dry::CLI.new(Commands::Compress).call(arguments: args)
        end
      end
    end
  end
end
