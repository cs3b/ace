# frozen_string_literal: true

require "yaml"

module Ace
  module Demo
    module Organisms
      class TapeCreator
        def initialize(writer: Molecules::TapeWriter.new)
          @writer = writer
        end

        def create(name:, commands:, description: nil, tags: nil,
          font_size: 16, width: 960, height: 480, timeout: "2s",
          format: "gif", force: false, dry_run: false)
          safe_name = Atoms::DemoNameSanitizer.sanitize(name)
          scene_commands = Array(commands).reject { |command| command.to_s.strip.empty? }
          scene_commands = ["echo 'Hello from #{safe_name}'"] if scene_commands.empty?

          content = build_yaml_template(
            name: safe_name,
            commands: scene_commands,
            description: description,
            tags: tags,
            font_size: font_size,
            width: width,
            height: height,
            timeout: timeout,
            format: format
          )

          path = nil
          unless dry_run
            path = @writer.write(name: safe_name, content: content, force: force, extension: ".tape.yml")
          end

          {content: content, path: path, dry_run: dry_run}
        end

        private

        def build_yaml_template(name:, commands:, description:, tags:, font_size:, width:, height:, timeout:, format:)
          rendered_tags = Array(tags).flat_map { |value| value.to_s.split(",") }.map(&:strip).reject(&:empty?)
          template = {
            "description" => description.to_s,
            "tags" => rendered_tags,
            "settings" => {
              "font_size" => font_size,
              "width" => width,
              "height" => height,
              "format" => format
            },
            "setup" => ["sandbox"],
            "scenes" => [
              {
                "name" => "Example scene",
                "commands" => commands.map { |command| {"type" => command.to_s, "sleep" => timeout} }
              }
            ],
            "teardown" => ["cleanup"]
          }

          YAML.dump(template)
        end
      end
    end
  end
end
