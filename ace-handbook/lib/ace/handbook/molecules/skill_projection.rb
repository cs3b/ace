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
            workflow_uri = frontmatter.dig("skill", "execution", "workflow")
            provider_frontmatter = provider_meta["frontmatter"] || {}

            return render_fork_workflow_body(workflow_uri: workflow_uri) if provider_frontmatter["context"] == "fork" && workflow_uri

            return body unless provider.to_s == "codex"
            return body unless provider_meta["context"] == "ace-llm"
            return body unless provider_meta["ace-llm"]
            return body unless workflow_uri

            prompt_context = provider_meta["prompt_context"]
            return render_codex_ace_llm_run_body(model: provider_meta["ace-llm"], workflow_uri: workflow_uri) unless prompt_context.is_a?(Hash) && prompt_context.any?

            render_codex_ace_llm_body(
              argument_hint: frontmatter["argument-hint"],
              model: provider_meta["ace-llm"],
              prompt_context: prompt_context,
              workflow_uri: workflow_uri
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

          def render_codex_ace_llm_body(argument_hint:, model:, prompt_context:, workflow_uri:)
            variables = build_variables(argument_hint: argument_hint, prompt_context: prompt_context)
            variable_lines = variables.map { |variable| "- #{variable.fetch(:name)}" }.join("\n")
            instruction_lines = variables.map do |variable|
              description = variable.fetch(:instruction, "prepare #{variable.fetch(:name).downcase}")
              "- If #{variable.fetch(:name)} was provided explicitly, use it. Otherwise, #{description}."
            end.join("\n")

            execution_lines = codex_workflow_execution_lines(workflow_uri)
            escaped_prompt = shell_double_quote_escape([
              variables.map { |variable| variable.fetch(:name) }.join("\n\n"),
              execution_lines.join("\n")
            ].join("\n\n"))

            <<~BODY
              ## Variables

              #{variable_lines}

              ## Instructions

              #{instruction_lines}
              #{execution_lines.map { |line| "- #{line}" }.join("\n")}

              Run:
              ```bash
              ace-llm #{model} "#{escaped_prompt}"
              ```
            BODY
          end

          def render_codex_ace_llm_run_body(model:, workflow_uri:)
            execution_lines = codex_workflow_execution_lines(workflow_uri)
            escaped_prompt = shell_double_quote_escape(execution_lines.join("\n"))

            <<~BODY
              ## Instructions

              #{execution_lines.map { |line| "- #{line}" }.join("\n")}

              Run:
              ```bash
              ace-llm #{model} "#{escaped_prompt}"
              ```
            BODY
          end

          def render_fork_workflow_body(workflow_uri:)
            instruction_lines = fork_workflow_execution_lines(workflow_uri)

            <<~BODY
              ## Instructions

              #{instruction_lines.map { |line| "- #{line}" }.join("\n")}
            BODY
          end

          def codex_workflow_execution_lines(workflow_uri)
            [
              "You are working in the current project.",
              "Run `mise exec -- ace-bundle #{workflow_uri}` in the current project to load the workflow instructions.",
              "Read the loaded workflow and execute it end-to-end in this project.",
              "Follow the workflow as the source of truth.",
              "Do the work described by the workflow instead of only summarizing it.",
              "When the workflow requires edits, tests, or commits, perform them in this project."
            ]
          end

          def fork_workflow_execution_lines(workflow_uri)
            [
              "You are working in a forked execution context for the current project.",
              "Run `mise exec -- ace-bundle #{workflow_uri}` in the current project to load the workflow instructions.",
              "Read the loaded workflow and execute it end-to-end in this forked context.",
              "Follow the workflow as the source of truth.",
              "Do the work described by the workflow instead of only summarizing it.",
              "Return results from the executed workflow, not a summary of the workflow text."
            ]
          end

          def build_variables(argument_hint:, prompt_context:)
            variables = []
            seen = {}

            extract_argument_variables(argument_hint).each do |name|
              variables << {
                name: name,
                instruction: prompt_context[normalized_context_key(name)]
              }
              seen[name] = true
            end

            prompt_context.each do |key, description|
              name = placeholder_name(key)
              next if seen[name]

              variables << {name: name, instruction: description}
            end

            variables
          end

          def extract_argument_variables(argument_hint)
            tokens = case argument_hint
                     when Array
                       argument_hint.map(&:to_s)
                     when String
                       argument_hint.scan(/\[[^\]]+\]|<[^>]+>|[^\s]+/)
                     else
                       []
                     end

            tokens.filter_map do |token|
              cleaned = token.to_s
                .delete_prefix("[")
                .delete_suffix("]")
                .delete_prefix("<")
                .delete_suffix(">")
                .sub(/\.\.\.\z/, "")
                .sub(/\A['"]/, "")
                .sub(/['"]\z/, "")

              next if cleaned.empty? || cleaned.start_with?("--")

              name = placeholder_name(cleaned)
              next if name.empty?

              name
            end
          end

          def placeholder_name(key)
            key.to_s.gsub(/[^A-Za-z0-9]+/, "_").gsub(/\A_+|_+\z/, "").upcase
          end

          def normalized_context_key(name)
            name.to_s.downcase
          end

          def shell_double_quote_escape(text)
            text.gsub(/["`\\]/) { |match| "\\#{match}" }
          end
        end
      end
    end
  end
end
