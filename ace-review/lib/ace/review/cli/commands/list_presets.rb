# frozen_string_literal: true

module Ace
  module Review
    module CLI
      module Commands
      # dry-cli Command class for the list-presets command
      #
      # Lists all available review presets with descriptions and sources.
      class ListPresets < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "List all available review presets with descriptions and sources"

        example [
          '# List all presets'
        ]

        def call(**options)
          manager = Organisms::ReviewManager.new

          presets = manager.list_presets
          if presets.empty?
            puts "No presets found"
            puts "Create presets in .ace/review/config.yml or .ace/review/presets/"
            return
          end

          puts "Available Review Presets:"
          puts

          # Header
          puts format("%-20s %-50s %-10s", "Preset", "Description", "Source")
          puts "-" * 80

          # Load preset manager to get descriptions
          preset_manager = Molecules::PresetManager.new

          presets.each do |name|
            preset = preset_manager.load_preset(name)
            description = preset&.dig("description") || "-"

            # Determine source
            source = if preset_manager.send(:load_preset_from_file, name)
                       "file"
                     elsif preset_manager.send(:load_preset_from_config, name)
                       "config"
                     else
                       "default"
                     end

            puts format("%-20s %-50s %-10s", name, description, source)
          end
        end
      end
    end
  end
end
end
