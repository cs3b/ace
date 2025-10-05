# frozen_string_literal: true

require "dry/cli"
require_relative "cli/command"

module Ace
  module Review
    module CLI
      # Main CLI module - single command interface
      def self.call(arguments = ARGV)
        Command.new.call(**parse_options(arguments))
      end

      def self.parse_options(arguments)
        # Dry::CLI will handle the parsing when we use it directly
        # This is a placeholder for the executable to use
        {}
      end
    end
  end
end