# frozen_string_literal: true

require_relative "../../commands/config_command"

module Ace
  module B36ts
    module CLI
      module Commands
          # Show current configuration
          class Config < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc "Show current configuration"

            option :verbose, type: :boolean, aliases: ["-v"], desc: "Show verbose output"

            example [
              "           # Show basic config",
              "--verbose  # Show full config with sources"
            ]

            def call(**options)
              Ace::B36ts::Commands::ConfigCommand.execute(options)
            end
          end
      end
    end
  end
end
