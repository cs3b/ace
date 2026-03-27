# frozen_string_literal: true

require "shellwords"

module Ace
  module Demo
    module Atoms
      module AsciinemaTapeCompiler
        module_function

        def compile(spec:, default_timeout: "2s")
          settings = spec["settings"] || {}
          lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            ""
          ]

          env = settings["env"] || {}
          env.each do |key, value|
            lines << "export #{key}=#{Shellwords.escape(value.to_s)}"
          end
          lines << "" unless env.empty?

          spec.fetch("scenes", []).each do |scene|
            scene_name = scene["name"]
            lines << "# Scene: #{scene_name}" unless scene_name.to_s.strip.empty?

            scene.fetch("commands", []).each do |command|
              lines << command.fetch("type")
              sleep_value = validate_sleep!(command["sleep"] || default_timeout)
              lines << "sleep #{sleep_value}"
              lines << ""
            end
          end

          lines.join("\n").rstrip + "\n"
        end

        def validate_sleep!(value)
          sleep_value = value.to_s.strip
          pattern = /\A\d+(?:\.\d+)?(?:ms|s|m|h)?\z/
          return sleep_value if sleep_value.match?(pattern)

          raise ArgumentError, "sleep must be a numeric duration (e.g. 0.5s, 250ms, 2)"
        end
        private_class_method :validate_sleep!
      end
    end
  end
end
