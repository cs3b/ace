# frozen_string_literal: true

module Ace
  module Context
    module Commands
      class ListCommand
        def execute
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
