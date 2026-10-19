# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Pure validation of a raw role preset hash (the shipped
      # .ace-defaults/coworker/roles/*.yml files and their project
      # overrides). Field-specific errors, no IO, no defaults.
      class RolePresetSchema
        REQUIRED_FIELDS = %w[name instructions start_prompt].freeze

        # @param raw [Hash, nil] parsed preset hash
        # @return [Array<String>] field-specific error messages (empty when valid)
        def self.errors(raw)
          return ["preset is empty"] if raw.nil? || (!raw.is_a?(Hash) && raw.to_s.strip.empty?)
          return ["preset must be a mapping, got #{raw.class}"] unless raw.is_a?(Hash)

          errors = []
          REQUIRED_FIELDS.each do |field|
            value = raw[field]
            if value.nil? || value.to_s.strip.empty?
              errors << "missing required field '#{field}'"
            end
          end
          errors.concat(non_empty_string_error(raw, "description")) if raw.key?("description")
          errors.concat(nested_mapping_errors(raw, "reporting"))
          errors.concat(nested_mapping_errors(raw, "errors"))
          errors.concat(reporting_errors(raw))
          errors.concat(error_rules_errors(raw))
          errors
        end

        # Preset → config-shaped hash with the role's own fields only
        # (identity fields are supplied by the commission, not the preset).
        def self.normalize(raw)
          {
            "name" => str(raw["name"]),
            "description" => str(raw["description"]),
            "instructions" => str(raw["instructions"]),
            "start_prompt" => raw["start_prompt"].to_s.strip,
            "reporting" => nested_str(raw, "reporting", "channel"),
            "errors" => nested_str(raw, "errors", "on_failure")
          }
        end

        class << self
          private

          def non_empty_string_error(raw, field)
            value = raw[field]
            value.is_a?(String) && !value.strip.empty? ? [] : ["'#{field}' must be a non-empty string"]
          end

          def reporting_errors(raw)
            channel = nested_str(raw, "reporting", "channel")
            return [] if channel.empty?

            ConfigSchema::CHANNELS.include?(channel) ? [] :
              ["reporting.channel '#{channel}' is not one of: #{ConfigSchema::CHANNELS.join(', ')}"]
          end

          def error_rules_errors(raw)
            on_failure = nested_str(raw, "errors", "on_failure")
            return [] if on_failure.empty?

            ConfigSchema::ON_FAILURE.include?(on_failure) ? [] :
              ["errors.on_failure '#{on_failure}' is not one of: #{ConfigSchema::ON_FAILURE.join(', ')}"]
          end

          def nested_mapping_errors(raw, section)
            value = raw[section]
            return [] if value.nil? || value.is_a?(Hash)

            ["'#{section}' must be a mapping, got #{value.class}"]
          end

          def nested_str(raw, section, key)
            value = raw[section]
            return "" unless value.is_a?(Hash)

            str(value[key])
          end

          def str(value)
            value.to_s.strip
          end
        end
      end
    end
  end
end
