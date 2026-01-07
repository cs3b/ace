# frozen_string_literal: true

require_relative "list_presets_command"

module Ace
  module Review
    module Commands
      # dry-cli Command class for the list-presets command
      #
      # This wraps the existing ListPresetsCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class ListPresets < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "List all available review presets with descriptions and sources"

        example [
          '# List all presets'
        ]

        def call(**options)
          # Use the existing ListPresetsCommand logic
          ListPresetsCommand.new.execute
        end
      end
    end
  end
end
