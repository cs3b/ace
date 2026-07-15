# frozen_string_literal: true

require "yaml"

module Ace
  module Handbook
    module Molecules
      class SkillProjection
        class << self
          LEGACY_PROVIDER_TARGETS = %w[claude codex gemini opencode pi].freeze

          def projection_targets(frontmatter, registry:)
            integration = frontmatter.fetch("integration", {})
            targets = integration["targets"]
            return registry.providers if targets.nil? || targets.empty?

            declared_targets = Array(targets).map(&:to_s).uniq
            known_targets = declared_targets.select { |provider| registry.known?(provider) }
            if registry.known?("agents") && legacy_provider_target_set?(declared_targets)
              known_targets = known_targets + ["agents"]
            end

            known_targets.uniq
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

          def legacy_provider_target_set?(targets)
            targets.sort == LEGACY_PROVIDER_TARGETS.sort
          end

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
