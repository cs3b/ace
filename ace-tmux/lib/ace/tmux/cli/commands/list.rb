# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Tmux
    module CLI
      module Commands
        # List available tmux presets
        class List < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          desc <<~DESC.strip
            List available tmux presets

            SYNTAX:
              ace-tmux list [TYPE]

            EXAMPLES:

              # List all presets
              $ ace-tmux list

              # List only session presets
              $ ace-tmux list sessions

              # List only window presets
              $ ace-tmux list windows
          DESC

          example [
            "                           # List all presets",
            "sessions                   # List session presets",
            "windows                    # List window presets",
            "panes                      # List pane presets"
          ]

          argument :type, required: false, desc: "Preset type: sessions, windows, or panes"

          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(type: nil, **options)
            preset_loader = Molecules::PresetLoader.new(
              gem_root: Tmux.gem_root
            )

            if type
              validate_type!(type)
              presets = preset_loader.list(type)
              display_type(type, presets, verbose: options[:verbose])
            else
              all = preset_loader.list_all
              all.each do |preset_type, presets|
                display_type(preset_type, presets, verbose: options[:verbose])
              end
              puts "No presets found." if all.empty?
            end
          end

          private

          def validate_type!(type)
            unless Molecules::PresetLoader::PRESET_TYPES.include?(type)
              raise Ace::Core::CLI::Error.new(
                "Unknown preset type: #{type}. Valid types: #{Molecules::PresetLoader::PRESET_TYPES.join(", ")}"
              )
            end
          end

          def display_type(type, presets, verbose: false)
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
