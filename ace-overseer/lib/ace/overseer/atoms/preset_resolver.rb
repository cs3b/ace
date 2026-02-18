# frozen_string_literal: true

module Ace
  module Overseer
    module Atoms
      module PresetResolver
        def self.resolve(task_frontmatter:, cli_preset:, default:)
          preset = extract_task_preset(task_frontmatter)
          return preset unless blank?(preset)
          return cli_preset unless blank?(cli_preset)

          default
        end

        def self.extract_task_preset(frontmatter)
          return nil unless frontmatter.is_a?(Hash)

          assign = frontmatter["assign"] || frontmatter[:assign]
          if assign.is_a?(Hash)
            return assign["preset"] || assign[:preset]
          end

          frontmatter["preset"] || frontmatter[:preset]
        end
        private_class_method :extract_task_preset

        def self.blank?(value)
          value.nil? || value.to_s.strip.empty?
        end
        private_class_method :blank?
      end
    end
  end
end
