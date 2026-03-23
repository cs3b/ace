# frozen_string_literal: true

module Ace
  module Demo
    module Atoms
      module TapeContentGenerator
        module_function

        def generate(name:, commands:, description: nil, tags: nil, output_path: nil,
          font_size: 16, width: 960, height: 480, timeout: "2s")
          lines = []

          lines << "# Description: #{description}" if description
          lines << "# Tags: #{tags}" if tags
          lines << "" if description || tags

          output = output_path || ".ace-local/demo/#{name}.gif"
          lines << "Output #{output}"
          lines << ""
          lines << "Set FontSize #{font_size}"
          lines << "Set Width #{width}"
          lines << "Set Height #{height}"

          commands.each do |cmd|
            escaped = cmd.gsub("\\", "\\\\\\\\").gsub('"', '\\"')
            lines << ""
            lines << "Type \"#{escaped}\""
            lines << "Enter"
            lines << "Sleep #{timeout}"
          end

          lines.join("\n") + "\n"
        end
      end
    end
  end
end
