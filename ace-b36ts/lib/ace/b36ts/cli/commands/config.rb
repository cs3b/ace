# frozen_string_literal: true

require_relative "../../commands/config_command"

module Ace
  module B36ts
    module CLI
      module Commands
          # Show current configuration
          class Config < Ace::Support::Cli::Command
            include Ace::Core::CLI::Base

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
