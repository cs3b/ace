# frozen_string_literal: true

require_relative "../commands/config_command"

module Ace
  module Support
    module Timestamp
    module Commands
      # Show current configuration
      class Config < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Show current configuration"

        option :verbose, type: :boolean, aliases: ["-v"], desc: "Show additional config details"

        example [
          "           # Show basic config",
          "--verbose  # Show full config with sources"
        ]

        def call(**options)
          ConfigCommand.execute(options)
        end
      end
    end
  end
  end
end
