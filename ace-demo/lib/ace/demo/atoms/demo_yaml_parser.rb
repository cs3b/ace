# frozen_string_literal: true

require "yaml"

module Ace
  module Demo
    module Atoms
      module DemoYamlParser
        ALLOWED_ROOT_KEYS = %w[description tags settings setup scenes verify teardown].freeze

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
            "verify" => normalize_verify(data["verify"], source_path: source_path),
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
          normalized["agg_font_family"] = settings["agg_font_family"]&.to_s if settings.key?("agg_font_family")
          normalized["backend"] = normalize_backend(settings["backend"], source_path) if settings.key?("backend")
          normalized["playback_speed"] = normalize_playback_speed(settings["playback_speed"], source_path) if settings.key?("playback_speed")
          normalized["output"] = normalize_output_path(settings["output"], source_path) if settings.key?("output")
          normalized["env"] = normalize_env(settings["env"], source_path: source_path) if settings.key?("env")
          normalized
        end
        private_class_method :normalize_settings

        def normalize_backend(value, source_path)
          backend = value.to_s.strip.downcase
          allowed = %w[asciinema vhs]
          return backend if allowed.include?(backend)

          raise DemoYamlParseError, "Unknown backend '#{backend}'. Valid: asciinema, vhs (#{source_path})"
        end
        private_class_method :normalize_backend

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

        def normalize_verify(verify, source_path:)
          return {} if verify.nil?
          raise DemoYamlParseError, "verify must be a map in #{source_path}" unless verify.is_a?(Hash)

          normalized = {}
          if verify.key?("allow_nonzero_exit")
            normalized["allow_nonzero_exit"] = normalize_boolean(
              verify["allow_nonzero_exit"],
              "verify.allow_nonzero_exit",
              source_path
            )
          end
          normalized["require_vars"] = normalize_string_list(verify["require_vars"], "verify.require_vars", source_path) if verify.key?("require_vars")
          normalized["require_output"] = normalize_string_list(verify["require_output"], "verify.require_output", source_path) if verify.key?("require_output")
          if verify.key?("require_output_sequence")
            normalized["require_output_sequence"] = normalize_string_list(
              verify["require_output_sequence"],
              "verify.require_output_sequence",
              source_path
            )
          end
          normalized["forbid_output"] = normalize_string_list(verify["forbid_output"], "verify.forbid_output", source_path) if verify.key?("forbid_output")
          normalized["assert_commands"] = normalize_string_list(verify["assert_commands"], "verify.assert_commands", source_path) if verify.key?("assert_commands")
          normalized
        end
        private_class_method :normalize_verify

        def normalize_boolean(value, field, source_path)
          return value if value == true || value == false

          raise DemoYamlParseError, "#{field} must be a boolean in #{source_path}"
        end
        private_class_method :normalize_boolean

        def normalize_string_list(value, field, source_path)
          raise DemoYamlParseError, "#{field} must be an array in #{source_path}" unless value.is_a?(Array)

          value.map.with_index do |item, index|
            text = item&.to_s
            if text.nil? || text.strip.empty?
              raise DemoYamlParseError, "#{field}[#{index}] must be a non-empty string in #{source_path}"
            end

            text
          end
        end
        private_class_method :normalize_string_list

        def normalize_command(command, scene_index, command_index, source_path:)
          unless command.is_a?(Hash)
            raise DemoYamlParseError,
              "scenes[#{scene_index}].commands[#{command_index}] must be a map in #{source_path}"
          end

          normalized = {"sleep" => command["sleep"]&.to_s}.compact
          has_type = !command["type"].to_s.strip.empty?
          has_tmux = command["tmux"].is_a?(Hash)

          if has_type && has_tmux
            raise DemoYamlParseError,
              "scenes[#{scene_index}].commands[#{command_index}] cannot define both type and tmux in #{source_path}"
          end

          if has_type
            normalized["type"] = command["type"].to_s
            return normalized
          end

          if has_tmux
            normalized["tmux"] = normalize_tmux_command(
              command["tmux"],
              scene_index,
              command_index,
              source_path: source_path
            )
            return normalized
          end

          raise DemoYamlParseError,
            "scenes[#{scene_index}].commands[#{command_index}] must define either type or tmux in #{source_path}"
        end
        private_class_method :normalize_command

        def normalize_tmux_command(tmux, scene_index, command_index, source_path:)
          directive = tmux.transform_keys(&:to_s)
          action = directive["action"]&.to_s&.strip
          if action.nil? || action.empty?
            raise DemoYamlParseError,
              "scenes[#{scene_index}].commands[#{command_index}].tmux.action is required in #{source_path}"
          end

          allowed = %w[attach detach wait send]
          unless allowed.include?(action)
            raise DemoYamlParseError,
              "Unknown tmux action '#{action}' in #{source_path}. Allowed: #{allowed.join(', ')}"
          end

          normalized = {"action" => action}
          %w[session window pane pattern].each do |field|
            normalized[field] = directive[field].to_s if directive.key?(field)
          end

          case action
          when "attach", "detach"
            normalized["session"] = required_string!(directive, "session", scene_index, command_index, source_path)
          when "wait"
            normalized["for"] = required_string!(directive, "for", scene_index, command_index, source_path)
            normalized["pattern"] = normalized["pattern"] if normalized["pattern"]
            normalized["timeout"] = Float(directive["timeout"]) if directive.key?("timeout")
          when "send"
            command_text = directive["command"]&.to_s&.strip
            key_text = directive["key"]&.to_s&.strip
            if command_text.to_s.empty? == key_text.to_s.empty?
              raise DemoYamlParseError,
                "tmux send must define exactly one of command or key in #{source_path}"
            end
            normalized["command"] = command_text unless command_text.to_s.empty?
            normalized["key"] = key_text unless key_text.to_s.empty?
          end

          normalized
        rescue ArgumentError, TypeError => e
          raise DemoYamlParseError, "#{e.message} (#{source_path})"
        end
        private_class_method :normalize_tmux_command

        def required_string!(directive, field, scene_index, command_index, source_path)
          value = directive[field]&.to_s&.strip
          if value.nil? || value.empty?
            raise DemoYamlParseError,
              "scenes[#{scene_index}].commands[#{command_index}].tmux.#{field} is required in #{source_path}"
          end

          value
        end
        private_class_method :required_string!
      end
    end
  end
end
