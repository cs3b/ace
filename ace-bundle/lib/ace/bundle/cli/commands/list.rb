# frozen_string_literal: true

require_relative "../../atoms/preset_list_formatter"

module Ace
  module Bundle
    module CLI
      module Commands
        # dry-cli Command class for the list command
        #
        # Lists available context presets from .ace/bundle/presets/
        class List < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "List available context presets"

          example [
            '                      # List all available presets'
          ]

          def call(**options)
            presets = Ace::Bundle.list_presets
            lines = Atoms::PresetListFormatter.format(presets)
            lines.each { |line| puts line }
            0
          end
        end
      end
    end
  end
end
