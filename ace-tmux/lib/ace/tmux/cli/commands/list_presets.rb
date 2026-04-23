# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Tmux
    module CLI
      module Commands
        class ListPresets < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            List available tmux presets

            Run without a type to list all preset groups, or pass one of:
              sessions
              windows
              panes
          DESC

          example [
            "                     # List all preset groups",
            "sessions             # List session presets",
            "windows              # List window presets",
            "panes                # List pane presets"
          ]

          argument :type, required: false, desc: "Preset type: sessions, windows, or panes"

          def call(type: nil, **_options)
            preset_loader = Molecules::PresetLoader.new(gem_root: Tmux.gem_root)

            if type
              validate_type!(type)
              display_type(type, preset_loader.list(type))
              return
            end

            all = preset_loader.list_all
            all.each { |preset_type, presets| display_type(preset_type, presets) }
            puts "No presets found." if all.empty?
          end

          private

          def validate_type!(type)
            return if Molecules::PresetLoader::PRESET_TYPES.include?(type)

            raise Ace::Support::Cli::Error,
                  "Unknown preset type: #{type}. Valid types: #{Molecules::PresetLoader::PRESET_TYPES.join(", ")}"
          end

          def display_type(type, presets)
            puts "#{type}:"
            if presets.empty?
              puts "  (none)"
            else
              presets.each { |name| puts "  #{name}" }
            end
            puts
          end
        end
      end
    end
  end
end
