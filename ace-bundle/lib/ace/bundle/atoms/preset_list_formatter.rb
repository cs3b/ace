# frozen_string_literal: true

module Ace
  module Bundle
    module Atoms
      # Formats preset list for display
      #
      # Pure function that takes preset data and returns formatted strings.
      # Used by the List command to display available presets.
      module PresetListFormatter
        # Format a list of presets for display
        #
        # @param presets [Array<Hash>] Array of preset data hashes
        # @return [Array<String>] Formatted lines ready for output
        def self.format(presets)
          return empty_message if presets.empty?

          lines = ["Available presets:"]

          presets.each do |preset|
            lines << "  #{preset[:name]}"
            lines << "    Description: #{preset[:description]}" if preset[:description]
            lines << "    Default output: #{preset[:output] || "stdio"}"
            lines << "    Source: #{preset[:source_file]}" if preset[:source_file]
            lines << ""
          end

          lines
        end

        # Message when no presets are found
        #
        # @return [Array<String>] Help message lines
        def self.empty_message
          [
            "No presets found in .ace/bundle/presets/",
            "Create markdown files with YAML frontmatter in .ace/bundle/presets/ to define presets.",
            "Example presets are available in the ace-bundle gem at .ace-defaults/bundle/"
          ]
        end
      end
    end
  end
end
