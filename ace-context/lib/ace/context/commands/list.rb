# frozen_string_literal: true

require_relative "../atoms/preset_list_formatter"

module Ace
  module Context
    module Commands
      # dry-cli Command class for the list command
      #
      # Lists available context presets from .ace/context/presets/
      class List < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "List available context presets"

        example [
          '                      # List all presets (same as --list)',
          '--list               # Alternative way to list presets'
        ]

        def call(**options)
          presets = Ace::Context.list_presets
          lines = Atoms::PresetListFormatter.format(presets)
          lines.each { |line| puts line }
          0
        end
      end
    end
  end
end
