# frozen_string_literal: true

require "yaml"

module Ace
  module Assign
    module Molecules
      # Infers assignment preset from archived source config.
      module PresetInferrer
        DEFAULT_PRESET = "work-on-task"

        def self.infer_from_assignment(assignment)
          return DEFAULT_PRESET unless assignment

          source_path = assignment.source_config.to_s
          return DEFAULT_PRESET if source_path.empty? || !File.exist?(source_path)

          data = YAML.safe_load_file(source_path, aliases: true)
          return DEFAULT_PRESET unless data.is_a?(Hash)

          session_name = data.dig("session", "name").to_s.strip
          return session_name unless session_name.empty?

          DEFAULT_PRESET
        rescue Psych::SyntaxError, Errno::ENOENT
          DEFAULT_PRESET
        end
      end
    end
  end
end
