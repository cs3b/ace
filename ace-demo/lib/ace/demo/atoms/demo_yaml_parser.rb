# frozen_string_literal: true

require "yaml"

module Ace
  module Demo
    module Atoms
      module DemoYamlParser
        ALLOWED_ROOT_KEYS = %w[description tags settings setup scenes teardown].freeze

        module_function

        def parse_file(path)
          data = YAML.safe_load_file(path, permitted_classes: [], aliases: false)
          parse_hash(data, source_path: path)
        rescue Psych::SyntaxError => e
          raise DemoYamlParseError, "Invalid YAML in #{path}: #{e.message}"
        end

        def parse_hash(data, source_path: "(inline)")
          unless data.is_a?(Hash)
            raise DemoYamlParseError, "YAML tape must be a map at root: #{source_path}"
          end

          unknown_keys = data.keys.map(&:to_s) - ALLOWED_ROOT_KEYS
          unless unknown_keys.empty?
            allowed = ALLOWED_ROOT_KEYS.join(", ")
            raise DemoYamlParseError,
              "Unknown top-level keys in #{source_path}: #{unknown_keys.join(", ")}. Allowed: #{allowed}"
          end

          spec = {
            "description" => data["description"]&.to_s,
            "tags" => normalize_tags(data["tags"], source_path: source_path),
            "settings" => normalize_settings(data["settings"], source_path: source_path),
            "setup" => normalize_directives(data["setup"], "setup", source_path: source_path),
            "scenes" => normalize_scenes(data["scenes"], source_path: source_path),
            "teardown" => normalize_directives(data["teardown"], "teardown", source_path: source_path)
          }

          raise DemoYamlParseError, "Missing or empty scenes section in #{source_path}" if spec["scenes"].empty?

          spec
        end

        def normalize_tags(tags, source_path:)
          return [] if tags.nil?

          case tags
          when Array
            tags.map(&:to_s)
          when String
            tags.split(",").map(&:strip).reject(&:empty?)
          else
            raise DemoYamlParseError, "tags must be an array or string in #{source_path}"
          end
        end
        private_class_method :normalize_tags

        def normalize_settings(settings, source_path:)
          return {} if settings.nil?
          raise DemoYamlParseError, "settings must be a map in #{source_path}" unless settings.is_a?(Hash)

          normalized = {}
          normalized["font_size"] = integer_or_nil(settings["font_size"], "settings.font_size", source_path)
          normalized["width"] = integer_or_nil(settings["width"], "settings.width", source_path)
          normalized["height"] = integer_or_nil(settings["height"], "settings.height", source_path)
          normalized["format"] = settings["format"]&.to_s
          normalized["playback_speed"] = normalize_playback_speed(settings["playback_speed"], source_path) if settings.key?("playback_speed")
          normalized["output"] = normalize_output_path(settings["output"], source_path) if settings.key?("output")
          normalized["env"] = normalize_env(settings["env"], source_path: source_path) if settings.key?("env")
          normalized
        end
        private_class_method :normalize_settings

        def normalize_playback_speed(value, source_path)
          parsed = Atoms::PlaybackSpeedParser.parse(value)
          parsed && parsed[:label]
        rescue ArgumentError => e
          raise DemoYamlParseError, "#{e.message} (#{source_path})"
        end
        private_class_method :normalize_playback_speed

        def normalize_output_path(value, source_path)
          normalized = value&.to_s
          if normalized.nil? || normalized.strip.empty?
            raise DemoYamlParseError, "settings.output must be a non-empty path in #{source_path}"
          end

          normalized
        end
        private_class_method :normalize_output_path

        def normalize_env(env, source_path:)
          return {} if env.nil?
          raise DemoYamlParseError, "settings.env must be a map in #{source_path}" unless env.is_a?(Hash)

          env.transform_keys(&:to_s).transform_values(&:to_s)
        end
        private_class_method :normalize_env

        def integer_or_nil(value, field, source_path)
          return nil if value.nil?

          Integer(value)
        rescue ArgumentError, TypeError
          raise DemoYamlParseError, "#{field} must be an integer in #{source_path}"
        end
        private_class_method :integer_or_nil

        def normalize_directives(items, section, source_path:)
          return [] if items.nil?
          raise DemoYamlParseError, "#{section} must be an array in #{source_path}" unless items.is_a?(Array)

          items.map.with_index do |item, index|
            case item
            when String
              item
            when Hash
              normalized = item.transform_keys(&:to_s)
              unless normalized.key?("run")
                raise DemoYamlParseError,
                  "#{section}[#{index}] must be a string directive or a map with run: in #{source_path}"
              end
              {"run" => normalized["run"].to_s}
            else
              raise DemoYamlParseError, "#{section} entries must be string or map in #{source_path}"
            end
          end
        end
        private_class_method :normalize_directives

        def normalize_scenes(scenes, source_path:)
          return [] if scenes.nil?
          raise DemoYamlParseError, "scenes must be an array in #{source_path}" unless scenes.is_a?(Array)

          scenes.map.with_index do |scene, scene_index|
            raise DemoYamlParseError, "scenes[#{scene_index}] must be a map in #{source_path}" unless scene.is_a?(Hash)

            commands = scene["commands"]
            unless commands.is_a?(Array) && !commands.empty?
              raise DemoYamlParseError,
                "scenes[#{scene_index}].commands must be a non-empty array in #{source_path}"
            end

            {
              "name" => scene["name"]&.to_s,
              "commands" => commands.map.with_index do |command, command_index|
                normalize_command(command, scene_index, command_index, source_path: source_path)
              end
            }
          end
        end
        private_class_method :normalize_scenes

        def normalize_command(command, scene_index, command_index, source_path:)
          unless command.is_a?(Hash)
            raise DemoYamlParseError,
              "scenes[#{scene_index}].commands[#{command_index}] must be a map in #{source_path}"
          end

          type = command["type"]&.to_s
          if type.nil? || type.strip.empty?
            raise DemoYamlParseError,
              "scenes[#{scene_index}].commands[#{command_index}].type is required in #{source_path}"
          end

          {
            "type" => type,
            "sleep" => command["sleep"]&.to_s
          }
        end
        private_class_method :normalize_command
      end
    end
  end
end
