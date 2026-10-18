# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Pure validation of a raw coworker config hash.
      #
      # Produces field-specific errors; no IO, no guesses, no defaults
      # beyond the documented ones (reporting.channel, errors.on_failure).
      class ConfigSchema
        REQUIRED_FIELDS = %w[role instructions task assignment overseer].freeze
        PROTOCOL_PREFIXES = %w[wfi:// prompt:// tmpl://].freeze
        CHANNELS = %w[hitl].freeze
        ON_FAILURE = %w[report stop].freeze

        # @param raw [Hash, nil] parsed config hash
        # @return [Array<String>] field-specific error messages (empty when valid)
        def self.errors(raw)
          return ["config is empty"] if raw.nil? || (!raw.is_a?(Hash) && raw.to_s.strip.empty?)
          return ["config must be a mapping, got #{raw.class}"] unless raw.is_a?(Hash)

          errors = []
          REQUIRED_FIELDS.each do |field|
            value = raw[field]
            if value.nil? || value.to_s.strip.empty?
              errors << "missing required field '#{field}'"
            end
          end

          errors.concat(prompt_errors(raw))
          errors.concat(reporting_errors(raw))
          errors.concat(error_rules_errors(raw))
          errors
        end

        # @param raw [Hash] validated config hash
        # @return [Hash] normalized hash with defaults applied
        def self.normalize(raw)
          {
            "role" => str(raw["role"]),
            "instructions" => str(raw["instructions"]),
            "start_prompt" => start_prompt_value(raw),
            "start_prompt_file" => str(raw["start_prompt_file"]),
            "task" => str(raw["task"]),
            "assignment" => str(raw["assignment"]),
            "overseer" => str(raw["overseer"]),
            "reporting" => {"channel" => str(raw.dig("reporting", "channel")).empty? ? "hitl" : str(raw.dig("reporting", "channel"))},
            "errors" => {"on_failure" => str(raw.dig("errors", "on_failure")).empty? ? "report" : str(raw.dig("errors", "on_failure"))}
          }
        end

        # Protocol instructions reference an external resource; plain paths
        # are files resolved against the project root.
        def self.protocol?(instructions)
          PROTOCOL_PREFIXES.any? { |prefix| instructions.to_s.start_with?(prefix) }
        end

        def self.errors_for_field(raw, field)
          errors(raw).select { |e| e.include?("'#{field}'") }
        end

        def self.prompt_errors(raw)
          prompt = str(raw["start_prompt"])
          prompt_file = str(raw["start_prompt_file"])
          if prompt.empty? && prompt_file.empty?
            ["missing required field 'start_prompt' (or 'start_prompt_file')"]
          elsif !prompt.empty? && !prompt_file.empty?
            ["'start_prompt' and 'start_prompt_file' are mutually exclusive"]
          else
            []
          end
        end
        private_class_method :prompt_errors

        def self.reporting_errors(raw)
          channel = str(raw.dig("reporting", "channel"))
          return [] if channel.empty?

          CHANNELS.include?(channel) ? [] : ["reporting.channel '#{channel}' is not one of: #{CHANNELS.join(', ')}"]
        end
        private_class_method :reporting_errors

        def self.error_rules_errors(raw)
          on_failure = str(raw.dig("errors", "on_failure"))
          return [] if on_failure.empty?

          ON_FAILURE.include?(on_failure) ? [] : ["errors.on_failure '#{on_failure}' is not one of: #{ON_FAILURE.join(', ')}"]
        end
        private_class_method :error_rules_errors

        def self.start_prompt_value(raw)
          prompt = str(raw["start_prompt"])
          return prompt unless prompt.empty?

          str(raw["start_prompt_file"])
        end

        def self.str(value)
          value.to_s.strip
        end
        private_class_method :str
      end
    end
  end
end
