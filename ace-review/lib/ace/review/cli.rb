# frozen_string_literal: true

require "dry/cli"

module Ace
  module Review
    module CLI
      # Main CLI module
      module Commands
        extend Dry::CLI::Registry

        # Register commands
        register "code", Code, aliases: ["c"]
      end
    end
  end
end