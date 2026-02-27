# frozen_string_literal: true

require "json"
require "yaml"
require "tempfile"

module Ace
  module Taskflow
    module Molecules
      # Default LLM-backed executor for next-phase simulation stages.
      class NextPhaseStageExecutor
        WORKFLOW_URIS = {
          "draft" => "wfi://task/draft",
          "plan" => "wfi://task/plan",
          "work" => "wfi://task/work"
        }.freeze

        VALID_STATUSES = %w[ok partial failed].freeze

        def initialize(llm_query: nil, file_reader: nil, model_resolver: nil, bundle_load_file: nil)
          @llm_query = llm_query || method(:default_llm_query)
          @file_reader = file_reader || method(:default_file_reader)
          @model_resolver = model_resolver || method(:default_model)
          @bundle_load_file = bundle_load_file || method(:default_bundle_load_file)
        end

        def call(resolved_source:, mode:, run_id:, previous_stage_output: nil, model: nil)
          source_path = resolved_source[:path]
          raise ArgumentError, "Missing source path for stage execution" if source_path.nil? || source_path.strip.empty?

          source_body = @file_reader.call(source_path)
          previous_artifact = build_previous_context(previous_stage_output)

          # 1. Generate ace-bundle config file
          config_content = build_bundle_config(mode)

          # 2. Write config to temp file and load via ace-bundle
          bundle = load_bundle_from_config(config_content)

          # 3. System prompt = ace-bundle formatted output (project context + workflow in XML)
          system_prompt = bundle.content

          # 4. User prompt = pure idea content (+ previous artifact for plan stage)
          user_prompt = build_user_prompt(source_body, previous_artifact)

          # 5. Call LLM
          response = @llm_query.call(
            model || @model_resolver.call,
            user_prompt,
            system: system_prompt,
            sandbox: { mode: "read-only", intent: "taskflow-next-phase-simulation" },
            temperature: 0.2,
            max_tokens: 32_000
          )

          # 6. Return payload with prompts + config for saving
          payload = normalize_payload(response[:text], mode: mode)
          payload[:system_prompt] = system_prompt
          payload[:user_prompt] = user_prompt
          payload[:bundle_config] = config_content
          payload
        rescue StandardError => e
          raise e.class, "Next-phase stage '#{mode}' execution failed: #{e.message}", e.backtrace
        end

        private

        def build_bundle_config(mode)
          workflow_uri = WORKFLOW_URIS[mode]
          raise ArgumentError, "Unsupported simulation mode '#{mode}'" unless workflow_uri

          mode == "draft" ? build_draft_bundle_config(workflow_uri) : build_single_workflow_bundle_config(workflow_uri)
        end

        def build_draft_bundle_config(workflow_uri)
          <<~MARKDOWN
            ---
            bundle:
              params:
                format: markdown-xml
              sections:
                project_context:
                  title: "Project Context"
                  description: "Architecture, conventions, and tooling docs from the project preset."
                  priority: 1
                  presets:
                    - project
                draft_workflow:
                  title: "Draft Workflow"
                  description: "The real draft workflow for this stage. Follow its quality guidance completely."
                  priority: 2
                  files:
                    - #{workflow_uri}
                review_workflow:
                  title: "Review Workflow"
                  description: "The real review workflow with readiness criteria. Use to evaluate the draft."
                  priority: 3
                  files:
                    - wfi://task/review
              embed_document_source: true
            ---

            # Simulation: Draft + Review

            Return a single YAML payload — nothing else:

            ```yaml
            status: ok|partial|failed
            artifact: |
              [Complete draft spec following <draft_workflow>]
            review_artifact: |
              [Readiness review following <review_workflow> checklist]
            questions:
              - "Questions from the review"
            refinements:
              - "Input improvements from the review"
            ```

            ## Process

            1. **Draft**: Generate `artifact` following `<draft_workflow>`. Use `<project_context>` for grounding.
            2. **Review**: Evaluate that artifact against `<review_workflow>` readiness criteria. Produce `review_artifact`.
            3. **Extract** questions and refinements from the review.

            ## Guardrails

            - Simulation only — do not create or modify files.
            - `review_artifact` follows the review workflow's structure: checklist results, gaps, readiness status.

            ## Reference Sections

            1. `<project_context>` — Project architecture and conventions
            2. `<draft_workflow>` — Full draft quality guidance
            3. `<review_workflow>` — Full readiness checklist
          MARKDOWN
        end

        def build_single_workflow_bundle_config(workflow_uri)
          mode_label = WORKFLOW_URIS.key(workflow_uri) || "stage"

          <<~MARKDOWN
            ---
            bundle:
              params:
                format: markdown-xml
              sections:
                project_context:
                  title: "Project Context"
                  description: "Architecture, conventions, and tooling docs from the project preset."
                  priority: 1
                  presets:
                    - project
                workflow:
                  title: "Workflow Instruction"
                  description: "The real workflow for this stage. Follow its quality guidance completely."
                  priority: 2
                  files:
                    - #{workflow_uri}
              embed_document_source: true
            ---

            # Simulation: #{mode_label.capitalize} Stage

            Return a single YAML payload — nothing else:

            ```yaml
            status: ok|partial|failed
            artifact: |
              [Complete artifact following <workflow>]
            questions:
              - "Assumptions made"
            refinements:
              - "Input improvements"
            ```

            ## Guardrails

            - Simulation only — do not create or modify files.
            - After generating the artifact, audit it against the source input for assumptions and ambiguities.

            ## Reference Sections

            1. `<project_context>` — Project architecture and conventions
            2. `<workflow>` — Full workflow quality guidance
          MARKDOWN
        end

        def load_bundle_from_config(config_content)
          Tempfile.create(["simulation-bundle-", ".md"]) do |tmpfile|
            tmpfile.write(config_content)
            tmpfile.flush
            @bundle_load_file.call(tmpfile.path)
          end
        end

        def build_user_prompt(source_body, previous_artifact)
          if previous_artifact == "null"
            source_body
          else
            "#{source_body}\n\n---\n\n#{previous_artifact}"
          end
        end

        def build_previous_context(previous_stage_output)
          return "null" if previous_stage_output.nil?

          # Pass the artifact as readable text when available (plan stage gets the draft spec)
          artifact = previous_stage_output[:artifact] || previous_stage_output["artifact"]
          return artifact.to_s.strip if artifact && !artifact.to_s.strip.empty?

          JSON.pretty_generate(previous_stage_output)
        end

        def normalize_payload(raw_text, mode:)
          text = raw_text.to_s.strip
          raise ArgumentError, "LLM returned empty response for mode '#{mode}'" if text.empty?

          parsed = parse_payload(text)
          status = parsed["status"].to_s.strip.downcase
          status = "partial" unless VALID_STATUSES.include?(status)

          artifact = parsed["artifact"].to_s.strip
          review_artifact = parsed["review_artifact"].to_s.strip
          findings = normalize_list(parsed["findings"])
          questions = normalize_list(parsed["questions"])
          refinements = normalize_list(parsed["refinements"])
          unresolved_gaps = normalize_list(parsed["unresolved_gaps"])

          if artifact.empty? && findings.empty? && questions.empty? && refinements.empty?
            unresolved_gaps << "Model output omitted expected fields."
          end

          payload = {
            status: status,
            findings: findings,
            questions: questions,
            refinements: refinements
          }
          payload[:artifact] = artifact unless artifact.empty?
          payload[:review_artifact] = review_artifact unless review_artifact.empty?
          payload[:unresolved_gaps] = unresolved_gaps.uniq unless unresolved_gaps.empty?
          payload
        end

        def parse_payload(text)
          candidates = [text]
          fenced = fenced_block(text)
          candidates << fenced if fenced

          candidates.each do |candidate|
            begin
              parsed = JSON.parse(candidate)
              return stringify_keys(parsed) if parsed.is_a?(Hash)
            rescue JSON::ParserError
              nil
            end

            begin
              parsed = YAML.safe_load(candidate, permitted_classes: [Time], aliases: false)
              return stringify_keys(parsed) if parsed.is_a?(Hash)
            rescue Psych::SyntaxError
              nil
            end
          end

          parse_semantic_text(text)
        end

        def parse_semantic_text(text)
          sections = {}
          current = nil

          text.each_line do |line|
            stripped = line.strip
            next if stripped.empty?

            inline_key, inline_value = parse_inline_header(stripped)
            if inline_key
              current = inline_key
              sections[current] ||= []
              sections[current] << inline_value unless inline_value.empty?
              next
            end

            header = extract_header(stripped)
            if header
              current = header
              sections[current] ||= []
              next
            end

            next unless current

            entry = stripped.sub(/\A[-*]\s*/, "").strip
            sections[current] << entry unless entry.empty?
          end

          {
            "status" => sections["status"]&.first || "partial",
            "artifact" => sections["artifact"]&.join("\n") || "",
            "review_artifact" => sections["review_artifact"]&.join("\n") || "",
            "findings" => sections["findings"] || [],
            "questions" => sections["questions"] || [],
            "refinements" => sections["refinements"] || [],
            "unresolved_gaps" => sections["unresolved_gaps"] || []
          }
        end

        def parse_inline_header(line)
          match = line.match(/\A(status|review[_ ]artifact|artifact|findings|questions|refinements|unresolved[_ ]gaps)\s*:\s*(.*)\z/i)
          return [nil, nil] unless match

          key = extract_header(match[1])
          value = match[2].to_s.strip.sub(/\A[-*]\s*/, "")
          [key, value]
        end

        def extract_header(line)
          normalized = line.downcase.sub(/:\z/, "")
          return "status" if normalized.start_with?("status")
          return "review_artifact" if normalized.start_with?("review artifact")
          return "review_artifact" if normalized.start_with?("review_artifact")
          return "artifact" if normalized.start_with?("artifact")
          return "findings" if normalized.start_with?("findings")
          return "questions" if normalized.start_with?("questions")
          return "refinements" if normalized.start_with?("refinements")
          return "unresolved_gaps" if normalized.start_with?("unresolved gaps")
          return "unresolved_gaps" if normalized.start_with?("unresolved_gaps")

          nil
        end

        def normalize_list(value)
          Array(value).flatten.map(&:to_s).map(&:strip).reject(&:empty?).uniq
        end

        def stringify_keys(value)
          return {} unless value.is_a?(Hash)

          value.each_with_object({}) do |(key, val), acc|
            normalized = extract_header(key.to_s) || key.to_s.strip.downcase
            acc[normalized] = val
          end
        end

        def fenced_block(text)
          match = text.match(/```(?:json|yaml|yml)?\s*(.*?)```/m)
          match && match[1]&.strip
        end

        def default_llm_query(model, prompt, **kwargs)
          require "ace/llm/query_interface"
          # Workaround for lazy-load issues in ace-llm alias resolution.
          require "ace/llm/molecules/llm_alias_resolver"

          Ace::LLM::QueryInterface.query(model, prompt, **kwargs)
        end

        def default_bundle_load_file(path)
          require "ace/bundle"
          Ace::Bundle.load_file(path)
        end

        def default_file_reader(path)
          File.read(path)
        end

        def default_model
          Ace::Taskflow.configuration.next_phase_review_model ||
            Ace::Taskflow.configuration.config.dig("defaults", "llm_model") ||
            "glite"
        end
      end
    end
  end
end
