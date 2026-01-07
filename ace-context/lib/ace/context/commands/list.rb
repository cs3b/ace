# frozen_string_literal: true

require_relative "list_command"

module Ace
  module Context
    module Commands
      # dry-cli Command class for the list command
      #
      # This wraps the existing ListCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class List < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "List available context presets"

        example [
          '                      # List all presets (same as --list)',
          '--list               # Alternative way to list presets'
        ]

        def call(**options)
          # Use the existing ListCommand logic
          command = ListCommand.new
          command.execute
        end
      end
    end
  end
end
