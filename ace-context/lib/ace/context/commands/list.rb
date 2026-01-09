# frozen_string_literal: true

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

          if presets.empty?
            puts "No presets found in .ace/context/presets/"
            puts "Create markdown files with YAML frontmatter in .ace/context/presets/ to define presets."
            puts "Example presets are available in the ace-context gem at .ace-defaults/context/"
          else
            puts "Available presets:"
            presets.each do |preset|
              puts "  #{preset[:name]}"
              puts "    Description: #{preset[:description]}" if preset[:description]
              puts "    Default output: #{preset[:output] || 'stdio'}"
              puts "    Source: #{preset[:source_file]}" if preset[:source_file]
              puts ""
            end
          end

          0
        end
      end
    end
  end
end
