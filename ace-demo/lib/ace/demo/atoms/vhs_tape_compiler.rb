# frozen_string_literal: true

module Ace
  module Demo
    module Atoms
      module VhsTapeCompiler
        module_function

        def compile(spec:, output_path:, default_timeout: "2s")
          settings = spec["settings"] || {}
          lines = []

          lines << "Output #{output_path}"
          lines << ""
          lines << "Set FontSize #{settings["font_size"] || 16}"
          lines << "Set Width #{settings["width"] || 960}"
          lines << "Set Height #{settings["height"] || 480}"

          (settings["env"] || {}).each do |key, value|
            lines << "Env #{key} \"#{value}\""
          end

          spec.fetch("scenes", []).each do |scene|
            scene_name = scene["name"]
            lines << ""
            lines << "# Scene: #{scene_name}" unless scene_name.to_s.strip.empty?

            scene.fetch("commands", []).each do |command|
              escaped = command.fetch("type").gsub("\\", "\\\\\\\\").gsub('"', '\\"')
              lines << "Type \"#{escaped}\""
              lines << "Enter"
              lines << "Sleep #{command["sleep"] || default_timeout}"
              lines << ""
            end
          end

          lines.join("\n").rstrip + "\n"
        end
      end
    end
  end
end
