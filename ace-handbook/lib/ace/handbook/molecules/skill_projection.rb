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

          def projected_body(frontmatter, body, provider:)
            integration = frontmatter.fetch("integration", {})
            provider_meta = integration.fetch("providers", {}).fetch(provider.to_s, {})
            runtime = provider_meta["runtime"] || {}

            return body unless provider.to_s == "codex"
            return body unless runtime["ace-llm"] && runtime["prompt_context"].is_a?(Hash)

            render_codex_runtime_body(
              model: runtime["ace-llm"],
              prompt_context: runtime["prompt_context"],
              body: body
            )
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

          def render_codex_runtime_body(model:, prompt_context:, body:)
            prepare_lines = prompt_context.map do |key, description|
              "- `$#{placeholder_name(key)}`: #{description}"
            end.join("\n")

            prompt_placeholders = prompt_context.keys.map do |key|
              "$#{placeholder_name(key)}"
            end.join("\n\n")

            escaped_body = shell_double_quote_escape(body.to_s.strip)

            <<~BODY
              Prepare:
              #{prepare_lines}

              Run commandline:
              ```bash
              ace-llm #{model} "#{prompt_placeholders}

              #{escaped_body}"
              ```
            BODY
          end

          def placeholder_name(key)
            key.to_s.gsub(/[^A-Za-z0-9]+/, "_").gsub(/\A_+|_+\z/, "").upcase
          end

          def shell_double_quote_escape(text)
            text.gsub(/["`$\\]/) { |match| "\\#{match}" }
          end
        end
      end
    end
  end
end
