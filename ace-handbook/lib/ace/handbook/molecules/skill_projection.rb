# frozen_string_literal: true

require "yaml"

module Ace
  module Handbook
    module Molecules
      class SkillProjection
        class << self
          def projection_targets(frontmatter, registry:)
            integration = frontmatter.fetch("integration", {})
            targets = integration["targets"]
            return registry.providers if targets.nil? || targets.empty?

            Array(targets).map(&:to_s).select { |provider| registry.known?(provider) }
          end

          def projected_frontmatter(frontmatter, provider:)
            merged = deep_copy(frontmatter)
            integration = merged.delete("integration") || {}
            provider_meta = integration.fetch("providers", {}).fetch(provider.to_s, {})
            overrides = provider_meta["frontmatter"] || {}

            deep_merge(merged, overrides)
          end

          def render(frontmatter, body)
            yaml = YAML.dump(frontmatter).sub(/\A---\n/, "")
            normalized_body = body.to_s.sub(/\A\n+/, "")
            ["---\n", yaml, "---\n\n", normalized_body].join.rstrip + "\n"
          end

          private

          def deep_copy(data)
            Marshal.load(Marshal.dump(data))
          end

          def deep_merge(base, overrides)
            return overrides unless base.is_a?(Hash) && overrides.is_a?(Hash)

            base.merge(overrides) do |_key, old_value, new_value|
              if old_value.is_a?(Hash) && new_value.is_a?(Hash)
                deep_merge(old_value, new_value)
              else
                new_value
              end
            end
          end
        end
      end
    end
  end
end
