# frozen_string_literal: true

module Ace
  module Demo
    module Atoms
      module YamlRecordPlanner
        module_function

        def plan(tape_path:, output:, format:, playback_speed:, retime_output:, yaml_spec:, yaml_parser:, supported_formats:, default_output_path_builder:)
          spec = yaml_spec || yaml_parser.parse_file(tape_path)
          selected_format = (format || spec.dig("settings", "format") || "gif").to_s.downcase
          unless supported_formats.include?(selected_format)
            raise ArgumentError, "Unsupported format: #{selected_format}"
          end

          settings = spec["settings"] || {}
          selected_speed = playback_speed.nil? ? settings["playback_speed"] : playback_speed
          selected_speed = Atoms::PlaybackSpeedParser.parse(selected_speed)
          selected_output = output.nil? ? settings["output"] : output
          selected_retime_output = retime_output || selected_output

          default_output_path = File.expand_path(default_output_path_builder.call(selected_format), Dir.pwd)
          raw_output_path, retime_output_path = resolve_output_paths(
            default_output_path: default_output_path,
            output: selected_output,
            speed: selected_speed,
            retime_output: selected_retime_output
          )

          {
            spec: spec,
            format: selected_format,
            speed: selected_speed,
            selected_output: selected_output,
            raw_output_path: raw_output_path,
            retime_output_path: retime_output_path
          }
        end

        def resolve_output_paths(default_output_path:, output:, speed:, retime_output:)
          return [default_output_path, nil] if output.nil? && speed.nil?
          return [File.expand_path(output, Dir.pwd), nil] if output && speed.nil?
          return [default_output_path, File.expand_path(retime_output, Dir.pwd)] if retime_output
          return [default_output_path, nil] if output.nil?

          [default_output_path, File.expand_path(output, Dir.pwd)]
        end
        private_class_method :resolve_output_paths
      end
    end
  end
end
